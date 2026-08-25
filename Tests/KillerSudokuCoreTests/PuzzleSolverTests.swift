import Testing
@testable import KillerSudokuCore

@Suite struct PuzzleSolverTests {
    /// A hybrid fixture: rows 0-1 are covered by 9 vertical 2-cell cages, one per column
    /// ({(0,c),(1,c)}), and rows 2-8 use the real, well-scattered `CageLayoutGenerator` output
    /// (kept realistic so the solver isn't stress-tested against a fundamentally weak, all-row-
    /// confined layout that no practical backtracking solver handles quickly). Swapping rows 0
    /// and 1 across the whole grid is a standard Sudoku symmetry (both rows sit in the same
    /// 3-row box band), and since every rows-0-1 cage contains both cells of the swap while no
    /// rows-2-8 cage touches rows 0-1 at all, every cage's sum is unchanged. That's a second real
    /// solution to the exact same cage-sum puzzle — proof it's non-unique.
    private func makeNonUniqueFixture(grid: [[Int]]) -> [Cage] {
        let verticalCages = (0..<9).map { column -> Cage in
            let cells = [Coordinate(row: 0, column: column), Coordinate(row: 1, column: column)]
            let sum = cells.reduce(0) { $0 + grid[$1.row][$1.column] }
            return Cage(id: column, cells: cells, sum: sum)
        }

        var lowerRegion: Set<Coordinate> = []
        for row in 2..<9 {
            for column in 0..<9 { lowerRegion.insert(Coordinate(row: row, column: column)) }
        }
        let lowerCages = CageLayoutGenerator.cages(for: grid, in: lowerRegion, startingID: verticalCages.count)

        return verticalCages + lowerCages
    }

    @Test func countsMultipleSolutionsForANonUniquePuzzle() {
        let cages = makeNonUniqueFixture(grid: DemoPuzzle.solutionGrid)
        let count = PuzzleSolver.countSolutions(cages: cages, upTo: 2)
        #expect(count == 2)
    }
}
