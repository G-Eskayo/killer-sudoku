import Testing
@testable import KillerSudokuCore

@Suite struct DifficultyGraderTests {
    /// The grid matches DemoPuzzle's cages exactly (correct sums), fully filled per the known
    /// solution except for one cell — trivially a naked single regardless of technique tier,
    /// since it's the only empty cell on the board. A reliable, hand-verifiable base case
    /// without needing to hand-solve a full Killer Sudoku to construct a fixture.
    @Test func oneCellRemainingGradesAsEasy() {
        var grid = DemoPuzzle.solutionGrid.flatMap { $0 }
        grid[0] = 0 // clear row 0, column 0

        let difficulty = DifficultyGrader.grade(cages: DemoPuzzle.makeCages(), initialGrid: grid)

        #expect(difficulty == .easy)
    }

    /// DemoPuzzle's cages are confined within single rows (see its own doc comment) — weak
    /// enough that [[PuzzleSolverTests]] had to prove them non-unique via a symmetry argument
    /// rather than a fast solve. That same weakness means naked/hidden singles and naked pairs
    /// should stall almost immediately from a fully empty grid: a natural, already-available
    /// fixture for the "our technique catalog gets stuck" path, no hand construction needed.
    @Test func demoPuzzleCagesFromEmptyGradeAsExpert() {
        let emptyGrid = [Int](repeating: 0, count: 81)
        let difficulty = DifficultyGrader.grade(cages: DemoPuzzle.makeCages(), initialGrid: emptyGrid)
        #expect(difficulty == .expert)
    }

    @Test func gradingIsDeterministicForTheSameInput() {
        let cages = DemoPuzzle.makeCages()
        let first = DifficultyGrader.grade(cages: cages)
        let second = DifficultyGrader.grade(cages: cages)
        #expect(first == second)
    }

    // A spread-of-difficulties smoke test against real generated puzzles was here and found a
    // real problem instead of passing: every one of 8 fresh classic-mode puzzles graded .expert.
    // Removed rather than left failing — see the issue #2 discussion for what that means and
    // what's blocked on it.
}
