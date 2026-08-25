import Testing
@testable import KillerSudokuCore

@Suite struct DifficultyTests {
    @Test func lowNodeCountGradesEasy() {
        #expect(Difficulty.fromSearchEffort(nodesVisited: 352) == .easy)
    }

    @Test func highNodeCountGradesExpert() {
        #expect(Difficulty.fromSearchEffort(nodesVisited: 13808) == .expert)
    }

    @Test func midRangeNodeCountsGradeMediumOrHard() {
        #expect(Difficulty.fromSearchEffort(nodesVisited: 3000) == .medium)
        #expect(Difficulty.fromSearchEffort(nodesVisited: 5995) == .hard)
    }

    @Test func boundariesAreHalfOpenOnTheLowerEdge() {
        #expect(Difficulty.fromSearchEffort(nodesVisited: 1499) == .easy)
        #expect(Difficulty.fromSearchEffort(nodesVisited: 1500) == .medium)
        #expect(Difficulty.fromSearchEffort(nodesVisited: 4499) == .medium)
        #expect(Difficulty.fromSearchEffort(nodesVisited: 4500) == .hard)
        #expect(Difficulty.fromSearchEffort(nodesVisited: 8499) == .hard)
        #expect(Difficulty.fromSearchEffort(nodesVisited: 8500) == .expert)
    }
}
