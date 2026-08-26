public struct Board: Sendable {
    /// One undoable player edit. Pencil-mark toggles are their own inverse, so undoing/redoing
    /// one just re-toggles it; digit edits need the prior value recorded since `nil` (cleared)
    /// is itself a valid "next" state. `eliminatedPeers` on a digit edit are the row/column/box
    /// peers that had this same digit auto-removed from their pencil marks as a side effect —
    /// undo/redo needs to restore/reapply that removal too, in the same step as the digit itself.
    private enum Edit: Sendable {
        case digit(coordinate: Coordinate, previous: Int?, next: Int?, eliminatedPeers: Set<Coordinate>)
        case pencilMark(coordinate: Coordinate, mark: Int)
        case clearedPencilMarks(coordinate: Coordinate, previous: Set<Int>)
    }

    private var cells: [[Cell]]
    public let cages: [Cage]
    private let cageIndexByCoordinate: [Coordinate: Int]
    private var undoStack: [Edit] = []
    private var redoStack: [Edit] = []

    public init(cages: [Cage]) {
        self.init(cages: cages, cells: Array(repeating: Array(repeating: Cell(), count: 9), count: 9))
    }

    /// Restores a board's cage layout and cell contents directly (e.g. from a saved snapshot)
    /// without replaying any edits — undo/redo history is deliberately not part of what's saved
    /// (see [[PuzzleStore]]), so a restored board always starts with a clean history, same as a
    /// freshly generated one.
    public init(cages: [Cage], cells: [[Cell]]) {
        self.cells = cells
        self.cages = cages
        var index: [Coordinate: Int] = [:]
        for (cageIndex, cage) in cages.enumerated() {
            for coordinate in cage.cells {
                index[coordinate] = cageIndex
            }
        }
        self.cageIndexByCoordinate = index
    }

    public func cell(at coordinate: Coordinate) -> Cell {
        cells[coordinate.row][coordinate.column]
    }

    public func cage(at coordinate: Coordinate) -> Cage? {
        cageIndexByCoordinate[coordinate].map { cages[$0] }
    }

    /// A no-op once the board is solved: a finished puzzle is frozen, not just "given cells are
    /// protected" — without this, clearing and retyping a cell's digit could flip `isSolved`
    /// false->true again and re-trigger the completion flow as if it were a fresh solve. Also a
    /// no-op on a given cell (ADR 0008's pre-filled digits aren't a player edit) or when the new
    /// value matches what's already there. Placing a real digit (not clearing one) also
    /// auto-eliminates that same digit from every row/column/box peer's pencil marks — standard
    /// Sudoku assist behavior — recorded as part of this same edit so undo/redo moves both
    /// together.
    public mutating func setDigit(_ digit: Int?, at coordinate: Coordinate) {
        guard !isSolved else { return }
        guard !cells[coordinate.row][coordinate.column].isGiven else { return }
        let previous = cells[coordinate.row][coordinate.column].digit
        guard previous != digit else { return }
        cells[coordinate.row][coordinate.column].digit = digit

        var eliminatedPeers: Set<Coordinate> = []
        if let digit {
            for peer in peerCoordinates(of: coordinate) {
                if cells[peer.row][peer.column].pencilMarks.remove(digit) != nil {
                    eliminatedPeers.insert(peer)
                }
            }
        }
        record(.digit(coordinate: coordinate, previous: previous, next: digit, eliminatedPeers: eliminatedPeers))
    }

    /// A no-op when the cell already holds a digit: `BoardView` only ever renders pencil marks
    /// on an empty cell, so recording one on a filled cell would silently do nothing visible —
    /// and worse, add its own undo entry on top of whatever set that digit.
    public mutating func togglePencilMark(_ mark: Int, at coordinate: Coordinate) {
        guard cells[coordinate.row][coordinate.column].digit == nil else { return }
        applyPencilMarkToggle(mark, at: coordinate)
        record(.pencilMark(coordinate: coordinate, mark: mark))
    }

    /// Clears every player-entered digit and pencil mark, keeping the same cage layout and
    /// givens exactly as generated — restarting this puzzle from scratch rather than replacing
    /// it with a fresh one. Not itself undoable: the undo/redo history is discarded along with
    /// the progress it describes, the same way starting a genuinely new puzzle also begins with
    /// a clean history.
    public mutating func reset() {
        for row in 0..<9 {
            for column in 0..<9 where !cells[row][column].isGiven {
                cells[row][column] = Cell()
            }
        }
        undoStack.removeAll()
        redoStack.removeAll()
    }

    /// Clears every pencil mark in one cell as a single undoable step — e.g. Delete on a cell
    /// that has notes but no digit. A no-op (no undo entry) when there's nothing to clear.
    public mutating func clearPencilMarks(at coordinate: Coordinate) {
        let previous = cells[coordinate.row][coordinate.column].pencilMarks
        guard !previous.isEmpty else { return }
        cells[coordinate.row][coordinate.column].pencilMarks = []
        record(.clearedPencilMarks(coordinate: coordinate, previous: previous))
    }

    /// Every other cell sharing this coordinate's row, column, or 3x3 box — the standard Sudoku
    /// "peer" set used for pencil-mark auto-elimination.
    private func peerCoordinates(of coordinate: Coordinate) -> Set<Coordinate> {
        var peers: Set<Coordinate> = []
        for column in 0..<9 where column != coordinate.column {
            peers.insert(Coordinate(row: coordinate.row, column: column))
        }
        for row in 0..<9 where row != coordinate.row {
            peers.insert(Coordinate(row: row, column: coordinate.column))
        }
        peers.formUnion(boxCoordinates(coordinate.boxIndex))
        peers.remove(coordinate)
        return peers
    }

    /// Undoes the most recent edit (digit set/clear, pencil-mark toggle, or pencil-marks clear),
    /// walking back through the full session history one step at a time. A no-op with nothing
    /// left to undo, or once the board is solved — undoing the move that completed it would
    /// unsolve the board and reopen `setDigit`'s lock, letting the player edit a "finished"
    /// puzzle again through the back door.
    public mutating func undo() {
        guard !isSolved else { return }
        guard let edit = undoStack.popLast() else { return }
        switch edit {
        case .digit(let coordinate, let previous, let next, let eliminatedPeers):
            cells[coordinate.row][coordinate.column].digit = previous
            if let next {
                for peer in eliminatedPeers {
                    cells[peer.row][peer.column].pencilMarks.insert(next)
                }
            }
        case .pencilMark(let coordinate, let mark):
            applyPencilMarkToggle(mark, at: coordinate)
        case .clearedPencilMarks(let coordinate, let previous):
            cells[coordinate.row][coordinate.column].pencilMarks = previous
        }
        redoStack.append(edit)
    }

    /// Redoes the most recently undone edit. A new edit made after an undo truncates this stack
    /// (standard undo/redo semantics) since `record` clears it. Also a no-op once the board is
    /// solved — a stale redo entry from before a completing edit must not reach back in and
    /// mutate a now-finished board.
    public mutating func redo() {
        guard !isSolved else { return }
        guard let edit = redoStack.popLast() else { return }
        switch edit {
        case .digit(let coordinate, _, let next, let eliminatedPeers):
            cells[coordinate.row][coordinate.column].digit = next
            if let next {
                for peer in eliminatedPeers {
                    cells[peer.row][peer.column].pencilMarks.remove(next)
                }
            }
        case .pencilMark(let coordinate, let mark):
            applyPencilMarkToggle(mark, at: coordinate)
        case .clearedPencilMarks(let coordinate, _):
            cells[coordinate.row][coordinate.column].pencilMarks = []
        }
        undoStack.append(edit)
    }

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    private mutating func record(_ edit: Edit) {
        undoStack.append(edit)
        redoStack.removeAll()
    }

    private mutating func applyPencilMarkToggle(_ mark: Int, at coordinate: Coordinate) {
        var cell = cells[coordinate.row][coordinate.column]
        if cell.pencilMarks.contains(mark) {
            cell.pencilMarks.remove(mark)
        } else {
            cell.pencilMarks.insert(mark)
        }
        cells[coordinate.row][coordinate.column] = cell
    }

    /// Digits currently placed in exactly 9 cells on the board. A naive count-based proxy for
    /// "Digit completion state" (CONTEXT.md) — it doesn't account for rule violations (a
    /// duplicate digit still counts toward "9 placed"). Revisit if that turns out to matter in
    /// practice; CONTEXT.md's definition is about placement count, not correctness.
    public func completedDigits() -> Set<Int> {
        var counts: [Int: Int] = [:]
        for row in cells {
            for cell in row {
                guard let digit = cell.digit else { continue }
                counts[digit, default: 0] += 1
            }
        }
        return Set(counts.filter { $0.value == 9 }.keys)
    }

    /// Cells currently in violation of a Killer Sudoku rule: a duplicate digit in the same row,
    /// column, box, or cage, or a cage whose placed digits already make its target sum
    /// unreachable. Per v1-scope.md this only ever reflects digits the player has placed and
    /// never hints at what's missing — the cage-sum check deliberately only reasons about
    /// digits already inside that same cage, not what's used elsewhere on the board, so it
    /// stays a "this is already wrong" signal rather than cage-combination deduction.
    public func mistakenCoordinates() -> Set<Coordinate> {
        var mistaken: Set<Coordinate> = []

        for row in 0..<9 {
            addDuplicates(in: (0..<9).map { Coordinate(row: row, column: $0) }, to: &mistaken)
        }
        for column in 0..<9 {
            addDuplicates(in: (0..<9).map { Coordinate(row: $0, column: column) }, to: &mistaken)
        }
        for boxIndex in 0..<9 {
            addDuplicates(in: boxCoordinates(boxIndex), to: &mistaken)
        }
        for cage in cages {
            addDuplicates(in: cage.cells, to: &mistaken)
            if cageSumIsImpossible(cage) {
                mistaken.formUnion(cage.cells.filter { cell(at: $0).digit != nil })
            }
        }
        return mistaken
    }

    private func addDuplicates(in coordinates: [Coordinate], to mistaken: inout Set<Coordinate>) {
        var firstSeenAt: [Int: Coordinate] = [:]
        for coordinate in coordinates {
            guard let digit = cell(at: coordinate).digit else { continue }
            if let earlier = firstSeenAt[digit] {
                mistaken.insert(coordinate)
                mistaken.insert(earlier)
            } else {
                firstSeenAt[digit] = coordinate
            }
        }
    }

    private func cageSumIsImpossible(_ cage: Cage) -> Bool {
        let placedDigits = cage.cells.compactMap { cell(at: $0).digit }
        let partialSum = placedDigits.reduce(0, +)
        let remainingCount = cage.cells.count - placedDigits.count

        guard remainingCount > 0 else { return partialSum != cage.sum }
        guard partialSum < cage.sum else { return true }

        let available = Set(1...9).subtracting(placedDigits).sorted()
        guard available.count >= remainingCount else { return true }

        let minPossible = partialSum + available.prefix(remainingCount).reduce(0, +)
        let maxPossible = partialSum + available.suffix(remainingCount).reduce(0, +)
        return !(minPossible...maxPossible).contains(cage.sum)
    }

    /// Every cell filled and no rule violations — the puzzle is genuinely finished, not just
    /// full. Used to detect completion for stats recording (issue #9).
    public var isSolved: Bool {
        for row in cells {
            for cell in row where cell.digit == nil {
                return false
            }
        }
        return mistakenCoordinates().isEmpty
    }

    /// Every other cell currently holding the same digit as `coordinate`. Per CONTEXT.md this
    /// only ever reflects digits the player has actually placed — an empty cell has no digit to
    /// match against, so it always returns empty rather than hinting at where that digit
    /// belongs.
    public func sameDigitCoordinates(as coordinate: Coordinate) -> Set<Coordinate> {
        guard let digit = cell(at: coordinate).digit else { return [] }
        var matches: Set<Coordinate> = []
        for row in 0..<9 {
            for column in 0..<9 {
                let candidate = Coordinate(row: row, column: column)
                guard candidate != coordinate, cell(at: candidate).digit == digit else { continue }
                matches.insert(candidate)
            }
        }
        return matches
    }

    /// Cage IDs fully filled with a valid (correct-sum, no-repeat) set of digits right now — a
    /// pure snapshot, not a transition. [[BoardView]] diffs this against its previous value
    /// itself to trigger a one-time completion animation per cage (issue #10).
    public func correctlyCompletedCageIDs() -> Set<Int> {
        var completed: Set<Int> = []
        for cage in cages {
            let digits = cage.cells.compactMap { cell(at: $0).digit }
            guard digits.count == cage.cells.count, Set(digits).count == digits.count,
                  digits.reduce(0, +) == cage.sum else { continue }
            completed.insert(cage.id)
        }
        return completed
    }

    /// Row indices (0-8) with all 9 cells filled and no repeated digit — same snapshot contract
    /// as `correctlyCompletedCageIDs`.
    public func correctlyCompletedRowIndices() -> Set<Int> {
        Set((0..<9).filter { row in
            let digits = (0..<9).compactMap { cell(at: Coordinate(row: row, column: $0)).digit }
            return digits.count == 9 && Set(digits).count == 9
        })
    }

    /// Column indices (0-8) with all 9 cells filled and no repeated digit.
    public func correctlyCompletedColumnIndices() -> Set<Int> {
        Set((0..<9).filter { column in
            let digits = (0..<9).compactMap { cell(at: Coordinate(row: $0, column: column)).digit }
            return digits.count == 9 && Set(digits).count == 9
        })
    }

    /// 3x3 box indices (0-8) with all 9 cells filled and no repeated digit.
    public func correctlyCompletedBoxIndices() -> Set<Int> {
        Set((0..<9).filter { boxIndex in
            let digits = boxCoordinates(boxIndex).compactMap { cell(at: $0).digit }
            return digits.count == 9 && Set(digits).count == 9
        })
    }

    private func boxCoordinates(_ boxIndex: Int) -> [Coordinate] {
        let startRow = (boxIndex / 3) * 3
        let startColumn = (boxIndex % 3) * 3
        var coordinates: [Coordinate] = []
        for row in startRow..<(startRow + 3) {
            for column in startColumn..<(startColumn + 3) {
                coordinates.append(Coordinate(row: row, column: column))
            }
        }
        return coordinates
    }
}

extension Board: Codable {
    private enum CodingKeys: String, CodingKey {
        case cages, cells
    }

    /// Only cage layout and cell contents round-trip — undo/redo history is intentionally not
    /// part of the saved shape (see the `init(cages:cells:)` doc comment).
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let cages = try container.decode([Cage].self, forKey: .cages)
        let cells = try container.decode([[Cell]].self, forKey: .cells)
        self.init(cages: cages, cells: cells)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cages, forKey: .cages)
        try container.encode(cells, forKey: .cells)
    }
}
