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

        // ADR 0006: classic mode's given baseline is pre-filled directly, not left for the
        // player to notice a single-cell cage's sum equals its own digit.
        let givenCages = board.cages.filter { $0.cells.count == 1 }
        #expect((2...4).contains(givenCages.count))
        for cage in givenCages {
            #expect(board.cell(at: cage.cells[0]).digit == cage.sum)
        }
    }

    @Test func generateWithDifficultyReturnsAPuzzleGradingAtThatTier() {
        let board = PuzzleGenerator.generate(difficulty: .easy)

        let result = PuzzleSolver.verify(cages: board.cages, upTo: 2)
        #expect(result.solutionCount == 1)
        #expect(Difficulty.fromSearchEffort(nodesVisited: result.nodesVisited) == .easy)
    }
}
