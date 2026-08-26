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

        // ADR 0008: every classic-mode cage is a normal 2-4 cell cage — givens (the ungraded
        // app-launch puzzle falls back to Medium's range) are pre-filled digits inside whatever
        // cage they already belong to, not carved into their own single-cell cage.
        for cage in board.cages {
            #expect((2...4).contains(cage.cells.count))
        }
        let givenCount = Coordinate.all.filter { board.cell(at: $0).digit != nil }.count
        #expect((17...24).contains(givenCount))
    }

    @Test func generateWithDifficultyReturnsGivenDensityMatchingThatTier() {
        let board = PuzzleGenerator.generate(difficulty: .easy)

        #expect(PuzzleSolver.countSolutions(cages: board.cages, upTo: 2) == 1)
        for cage in board.cages {
            #expect((2...4).contains(cage.cells.count))
        }
        // ADR 0008's Easy range.
        let givenCount = Coordinate.all.filter { board.cell(at: $0).digit != nil }.count
        #expect((25...40).contains(givenCount))
    }
}
