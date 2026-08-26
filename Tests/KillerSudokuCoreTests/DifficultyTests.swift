import Testing
@testable import KillerSudokuCore

@Suite struct DifficultyTests {
    /// Regression test (ADR 0011): these values are persisted directly in SavedPuzzle and
    /// SolveRecord. Changing any of them silently reinterprets already-saved data as a different
    /// tier rather than failing — this test exists so that change can't happen by accident.
    @Test func rawValuesAreStable() {
        #expect(Difficulty.easy.rawValue == 0)
        #expect(Difficulty.medium.rawValue == 1)
        #expect(Difficulty.hard.rawValue == 2)
        #expect(Difficulty.expert.rawValue == 3)
    }
}
