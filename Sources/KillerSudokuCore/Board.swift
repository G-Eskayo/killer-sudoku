public struct Board: Sendable {
    private var cells: [[Cell]]
    public let cages: [Cage]
    private let cageIndexByCoordinate: [Coordinate: Int]

    public init(cages: [Cage]) {
        self.cells = Array(repeating: Array(repeating: Cell(), count: 9), count: 9)
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

    public mutating func setDigit(_ digit: Int?, at coordinate: Coordinate) {
        cells[coordinate.row][coordinate.column].digit = digit
    }

    public mutating func togglePencilMark(_ mark: Int, at coordinate: Coordinate) {
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
