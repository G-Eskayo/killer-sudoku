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
    private func makeNonUniqueFixture(grid: [[Int]]) throws -> [Cage] {
        let verticalCages = (0..<9).map { column -> Cage in
            let cells = [Coordinate(row: 0, column: column), Coordinate(row: 1, column: column)]
            let sum = cells.reduce(0) { $0 + grid[$1.row][$1.column] }
            return Cage(id: column, cells: cells, sum: sum)
        }

        var lowerRegion: Set<Coordinate> = []
        for row in 2..<9 {
            for column in 0..<9 { lowerRegion.insert(Coordinate(row: row, column: column)) }
        }
        let lowerCages = try #require(
            CageLayoutGenerator.cages(for: grid, in: lowerRegion, startingID: verticalCages.count)
        )

        return verticalCages + lowerCages
    }

    @Test func countsMultipleSolutionsForANonUniquePuzzle() throws {
        let cages = try makeNonUniqueFixture(grid: DemoPuzzle.solutionGrid)
        let count = PuzzleSolver.countSolutions(cages: cages, upTo: 2)
        #expect(count == 2)
    }

    /// Every cell except (0,0) is a given matching the known solution, and (0,0) belongs to no
    /// cage at all — a hybrid-mode-style setup (givens outside the cage system). If the solver
    /// correctly treats givens as fixed (not searched, but still constraining row/column/box),
    /// the one remaining cell is forced to exactly one value by row/column/box alone.
    @Test func givensConstrainTheSearchEvenOutsideAnyCage() {
        let grid = DemoPuzzle.solutionGrid
        var givens: [Coordinate: Int] = [:]
        for row in 0..<9 {
            for column in 0..<9 where !(row == 0 && column == 0) {
                givens[Coordinate(row: row, column: column)] = grid[row][column]
            }
        }

        let result = PuzzleSolver.verify(cages: [], givens: givens, upTo: 2)

        #expect(result.solutionCount == 1)
    }
}
