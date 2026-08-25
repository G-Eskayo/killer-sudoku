/// Grades a classic-mode puzzle's difficulty by simulating which solving techniques a human
/// would need — CONTEXT.md's "solving-technique grading," not a structural heuristic like cage
/// count or size. Always greedily applies the easiest technique that makes progress; the tier
/// returned is the hardest technique that was ever necessary at some point in the solve. That's
/// the standard way real Sudoku raters work, not an ad hoc choice.
///
/// Technique catalog, tried in tier order (every technique at the current tier before ever
/// escalating — the textbook-correct way to grade "minimum sufficient difficulty", not just
/// "cheapest technique first"). Deliberately not exhaustive — see below for what's in scope:
/// - **Easy**: naked singles (a cell has exactly one legal candidate — includes basic cage-sum
///   arithmetic, since candidate computation already folds in cage feasibility); the "Rule of
///   45" / innies-and-outies (every row, column, and box sums to 45 regardless of cage
///   boundaries — if the cages fully contained in a unit leave exactly one cell unaccounted for,
///   that cell's value is 45 minus their sums, no candidate narrowing needed); and cage-line
///   elimination (if a digit's only possible cells within a cage all sit in the same row/column/
///   box, it can be eliminated from the rest of that row/column/box outside the cage — the
///   "pointing pair/triple" technique adapted to cages). Classic mode has zero givens (ADR 0002/
///   CONTEXT.md), so naked singles alone have nothing to work with until something narrows the
///   board first. Rule of 45 turned out to be *the* missing piece: every real generated puzzle
///   graded Expert without it, even with cage-line elimination added — it's the technique every
///   source on constructing (not just solving) classic Killer Sudoku calls fundamental, because
///   it's the only reasoning that doesn't need any digit already placed to make progress. See
///   issue #2 for the dead end that led here before this was added.
/// - **Medium**: also needs hidden singles (a digit fits only one cell within some row/column/
///   box/cage).
/// - **Hard**: also needs naked pairs (two cells in a unit share an identical 2-candidate set,
///   eliminating those digits from the rest of the unit). Hidden pairs and other intermediate
///   techniques beyond this are *not* implemented — a real puzzle that needs one of those
///   specifically will over-grade into Expert rather than Hard.
/// - **Expert**: catch-all — the technique catalog above gets stuck before the grid is full.
///   [[PuzzleSolver]] already guarantees the underlying puzzle is uniquely solvable by brute
///   force, so "our techniques aren't enough" is itself a meaningful difficulty signal, not a
///   failure.
public enum DifficultyGrader {
    public static func grade(cages: [Cage]) -> Difficulty {
        grade(cages: cages, initialGrid: [Int](repeating: 0, count: 81))
    }

    /// `initialGrid` (flat, row-major, 0 = empty) is exposed internally so tests can grade a
    /// specific partial position directly instead of needing to hand-solve a full Killer Sudoku
    /// to build a fixture with a known technique requirement. The real, public entry point above
    /// always starts fully empty — classic mode has no givens.
    static func grade(cages: [Cage], initialGrid: [Int]) -> Difficulty {
        var state = GraderState(cages: cages, initialGrid: initialGrid)
        return state.solve()
    }
}

private struct GraderState {
    let cages: [Cage]
    let cageIndexByPosition: [Int]
    let units: [[Int]]
    /// Just rows/columns/boxes, no cages — the only units that always sum to 45 regardless of
    /// cage boundaries, which `findRegionSumSingle` depends on.
    let rowColumnBoxUnits: [[Int]]
    var grid: [Int]
    var rowMask = [Int](repeating: 0, count: 9)
    var columnMask = [Int](repeating: 0, count: 9)
    var boxMask = [Int](repeating: 0, count: 9)
    var cageUsedMask: [Int]
    var cagePartialSum: [Int]
    var cageFilledCount: [Int]
    /// Candidates ruled out by a technique (currently just naked pairs) beyond what row/column/
    /// box/cage constraints alone already exclude.
    var manualElimination = [Int](repeating: 0, count: 81)

    init(cages: [Cage], initialGrid: [Int]) {
        self.cages = cages
        var index = [Int](repeating: -1, count: 81)
        for (cageIndex, cage) in cages.enumerated() {
            for cell in cage.cells { index[cell.row * 9 + cell.column] = cageIndex }
        }
        self.cageIndexByPosition = index
        let rowColumnBoxUnits = Self.buildRowColumnBoxUnits()
        self.rowColumnBoxUnits = rowColumnBoxUnits
        self.units = rowColumnBoxUnits + cages.map { cage in cage.cells.map { $0.row * 9 + $0.column } }
        self.grid = [Int](repeating: 0, count: 81)
        self.cageUsedMask = [Int](repeating: 0, count: cages.count)
        self.cagePartialSum = [Int](repeating: 0, count: cages.count)
        self.cageFilledCount = [Int](repeating: 0, count: cages.count)
        for position in 0..<81 where initialGrid[position] != 0 {
            place(initialGrid[position], at: position)
        }
    }

    mutating func solve() -> Difficulty {
        var hardest = Difficulty.easy
        while true {
            guard grid.contains(0) else { return hardest }

            // Easy tier: try every easy technique before ever escalating.
            if let (position, digit) = findNakedSingle() {
                place(digit, at: position)
                continue
            }
            if let (position, digit) = findRegionSumSingle() {
                place(digit, at: position)
                continue
            }
            if eliminateCageLine() {
                continue
            }

            if let (position, digit) = findHiddenSingle() {
                place(digit, at: position)
                hardest = max(hardest, .medium)
                continue
            }

            if eliminateNakedPair() {
                hardest = max(hardest, .hard)
                continue
            }
            return .expert
        }
    }

    private mutating func place(_ digit: Int, at position: Int) {
        let row = position / 9
        let column = position % 9
        let box = (row / 3) * 3 + column / 3
        let bit = 1 << (digit - 1)

        grid[position] = digit
        rowMask[row] |= bit
        columnMask[column] |= bit
        boxMask[box] |= bit

        let cageIndex = cageIndexByPosition[position]
        guard cageIndex >= 0 else { return }
        cageUsedMask[cageIndex] |= bit
        cagePartialSum[cageIndex] += digit
        cageFilledCount[cageIndex] += 1
    }

    private func candidateMask(at position: Int) -> Int {
        let row = position / 9
        let column = position % 9
        let box = (row / 3) * 3 + column / 3
        var mask = ~(rowMask[row] | columnMask[column] | boxMask[box]) & 0x1FF

        let cageIndex = cageIndexByPosition[position]
        if cageIndex >= 0 {
            mask &= CageConstraint.candidateMask(
                for: cages[cageIndex],
                usedMask: cageUsedMask[cageIndex],
                partialSum: cagePartialSum[cageIndex],
                filledCount: cageFilledCount[cageIndex]
            )
        }
        return mask & ~manualElimination[position]
    }

    private func findNakedSingle() -> (position: Int, digit: Int)? {
        for position in 0..<81 where grid[position] == 0 {
            let mask = candidateMask(at: position)
            if mask.nonzeroBitCount == 1 {
                return (position, mask.trailingZeroBitCount + 1)
            }
        }
        return nil
    }

    private func findHiddenSingle() -> (position: Int, digit: Int)? {
        for unit in units {
            var countByDigit = [Int](repeating: 0, count: 9)
            var positionByDigit = [Int](repeating: -1, count: 9)
            for position in unit where grid[position] == 0 {
                var mask = candidateMask(at: position)
                while mask != 0 {
                    let bit = mask & (~mask + 1)
                    mask &= ~bit
                    let digitIndex = bit.trailingZeroBitCount
                    countByDigit[digitIndex] += 1
                    positionByDigit[digitIndex] = position
                }
            }
            for digitIndex in 0..<9 where countByDigit[digitIndex] == 1 {
                return (positionByDigit[digitIndex], digitIndex + 1)
            }
        }
        return nil
    }

    /// Every row, column, and box sums to 45 no matter how cages cross its boundaries. For each
    /// such unit, sum the cages entirely contained within it; if that leaves exactly one cell
    /// not accounted for by any fully-contained cage, that cell's value is 45 minus the known
    /// sum — no candidate narrowing needed, which is exactly why this works from a blank grid
    /// when nothing else can yet. (The one leftover cell may itself belong to a cage that pokes
    /// outside the unit — an "outie" — the arithmetic works the same either way.)
    private func findRegionSumSingle() -> (position: Int, digit: Int)? {
        for unit in rowColumnBoxUnits {
            if let result = regionSumSingle(in: unit) { return result }
        }
        return nil
    }

    private func regionSumSingle(in unit: [Int]) -> (position: Int, digit: Int)? {
        let unitSet = Set(unit)
        var coveredPositions: Set<Int> = []
        var knownSum = 0
        var consideredCages: Set<Int> = []

        for position in unit {
            let cageIndex = cageIndexByPosition[position]
            guard cageIndex >= 0, !consideredCages.contains(cageIndex) else { continue }
            let cagePositions = Set(cages[cageIndex].cells.map { $0.row * 9 + $0.column })
            guard cagePositions.isSubset(of: unitSet) else { continue }

            consideredCages.insert(cageIndex)
            coveredPositions.formUnion(cagePositions)
            knownSum += cages[cageIndex].sum
        }

        let remaining = unit.filter { !coveredPositions.contains($0) }
        guard remaining.count == 1, let position = remaining.first, grid[position] == 0 else { return nil }

        let digit = 45 - knownSum
        guard (1...9).contains(digit) else { return nil }
        return (position, digit)
    }

    /// Finds two cells in the same unit with an identical 2-candidate set and eliminates those
    /// digits from every other cell in that unit. Returns whether it actually changed anything —
    /// re-finding the same already-applied pair with nothing left to eliminate doesn't count as
    /// progress, so the caller knows to fall through to `.expert` instead of looping forever.
    private mutating func eliminateNakedPair() -> Bool {
        for unit in units {
            let emptyPositions = unit.filter { grid[$0] == 0 }
            for i in 0..<emptyPositions.count {
                let maskI = candidateMask(at: emptyPositions[i])
                guard maskI.nonzeroBitCount == 2 else { continue }

                for j in (i + 1)..<emptyPositions.count {
                    let positionJ = emptyPositions[j]
                    guard candidateMask(at: positionJ) == maskI else { continue }

                    var changed = false
                    for k in 0..<emptyPositions.count where k != i && k != j {
                        let position = emptyPositions[k]
                        if candidateMask(at: position) & maskI != 0 {
                            manualElimination[position] |= maskI
                            changed = true
                        }
                    }
                    if changed { return true }
                }
            }
        }
        return false
    }

    /// For each cage and each digit, if every cell within the cage that could still hold that
    /// digit shares the same row (or column, or box), the digit can be eliminated from every
    /// other cell of that row/column/box outside the cage — standard "pointing pair/triple"
    /// reasoning, just anchored on a cage instead of a box. Returns whether anything was
    /// actually eliminated.
    private mutating func eliminateCageLine() -> Bool {
        for cage in cages {
            let cellPositions = cage.cells.map { $0.row * 9 + $0.column }
            let emptyPositions = cellPositions.filter { grid[$0] == 0 }
            guard emptyPositions.count > 1 else { continue }

            for digitIndex in 0..<9 {
                let bit = 1 << digitIndex
                let cellsWithDigit = emptyPositions.filter { candidateMask(at: $0) & bit != 0 }
                guard cellsWithDigit.count > 1 else { continue }

                if let row = sharedRow(of: cellsWithDigit), eliminate(bit, fromRow: row, outsideCellPositions: Set(cellPositions)) {
                    return true
                }
                if let column = sharedColumn(of: cellsWithDigit), eliminate(bit, fromColumn: column, outsideCellPositions: Set(cellPositions)) {
                    return true
                }
                if let box = sharedBox(of: cellsWithDigit), eliminate(bit, fromBox: box, outsideCellPositions: Set(cellPositions)) {
                    return true
                }
            }
        }
        return false
    }

    private func sharedRow(of positions: [Int]) -> Int? {
        let rows = Set(positions.map { $0 / 9 })
        return rows.count == 1 ? rows.first : nil
    }

    private func sharedColumn(of positions: [Int]) -> Int? {
        let columns = Set(positions.map { $0 % 9 })
        return columns.count == 1 ? columns.first : nil
    }

    private func sharedBox(of positions: [Int]) -> Int? {
        let boxes = Set(positions.map { position -> Int in
            let row = position / 9
            let column = position % 9
            return (row / 3) * 3 + column / 3
        })
        return boxes.count == 1 ? boxes.first : nil
    }

    private mutating func eliminate(_ bit: Int, fromRow row: Int, outsideCellPositions: Set<Int>) -> Bool {
        eliminate(bit, from: (0..<9).map { row * 9 + $0 }, outsideCellPositions: outsideCellPositions)
    }

    private mutating func eliminate(_ bit: Int, fromColumn column: Int, outsideCellPositions: Set<Int>) -> Bool {
        eliminate(bit, from: (0..<9).map { $0 * 9 + column }, outsideCellPositions: outsideCellPositions)
    }

    private mutating func eliminate(_ bit: Int, fromBox box: Int, outsideCellPositions: Set<Int>) -> Bool {
        let startRow = (box / 3) * 3
        let startColumn = (box % 3) * 3
        var positions: [Int] = []
        for row in startRow..<(startRow + 3) {
            for column in startColumn..<(startColumn + 3) {
                positions.append(row * 9 + column)
            }
        }
        return eliminate(bit, from: positions, outsideCellPositions: outsideCellPositions)
    }

    private mutating func eliminate(_ bit: Int, from unitPositions: [Int], outsideCellPositions: Set<Int>) -> Bool {
        var changed = false
        for position in unitPositions where grid[position] == 0 && !outsideCellPositions.contains(position) {
            if candidateMask(at: position) & bit != 0 {
                manualElimination[position] |= bit
                changed = true
            }
        }
        return changed
    }

    private static func buildRowColumnBoxUnits() -> [[Int]] {
        var units: [[Int]] = []
        for row in 0..<9 {
            units.append((0..<9).map { row * 9 + $0 })
        }
        for column in 0..<9 {
            units.append((0..<9).map { $0 * 9 + column })
        }
        for box in 0..<9 {
            let startRow = (box / 3) * 3
            let startColumn = (box % 3) * 3
            var cells: [Int] = []
            for row in startRow..<(startRow + 3) {
                for column in startColumn..<(startColumn + 3) {
                    cells.append(row * 9 + column)
                }
            }
            units.append(cells)
        }
        return units
    }
}
