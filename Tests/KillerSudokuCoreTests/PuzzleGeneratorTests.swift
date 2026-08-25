import Testing
@testable import KillerSudokuCore

@Suite struct PuzzleGeneratorTests {
    /// Both assertions share one `generate()` call rather than each generating their own puzzle:
    /// generation retries until a candidate verifies as uniquely solvable, which can take a real
    /// number of seconds (see PuzzleSolver's node-budget doc comment) — cheap correctness checks
    /// on a board we already generated shouldn't double that cost by generating a second one.
    @Test func returnedBoardCoversEveryCellExactlyOnceWithExactlyOneSolution() {
        let board = PuzzleGenerator.generate()

        var seen: Set<Coordinate> = []
        for cage in board.cages {
            for coordinate in cage.cells {
                #expect(!seen.contains(coordinate), "duplicate coverage at \(coordinate)")
                seen.insert(coordinate)
            }
        }
        #expect(seen.count == 81)

        #expect(PuzzleSolver.countSolutions(cages: board.cages, upTo: 2) == 1)
    }
}
