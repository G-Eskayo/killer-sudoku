import Foundation
import Testing
import SwiftData
@testable import KillerSudokuCore

@Suite struct StatsStoreTests {
    private static func makeInMemoryContext() -> ModelContext {
        let container = try! ModelContainer(
            for: SolveRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test @MainActor func bestTimeIsNilWhenNothingRecordedForThatTier() {
        let context = Self.makeInMemoryContext()
        #expect(StatsStore.bestTime(for: .easy, context: context) == nil)
    }

    @Test @MainActor func bestTimeIsTheMinimumElapsedTimeAmongRecordsForThatTier() {
        let context = Self.makeInMemoryContext()
        StatsStore.record(difficulty: .easy, elapsedSeconds: 120, context: context)
        StatsStore.record(difficulty: .easy, elapsedSeconds: 45, context: context)
        StatsStore.record(difficulty: .easy, elapsedSeconds: 90, context: context)

        #expect(StatsStore.bestTime(for: .easy, context: context) == 45)
    }

    @Test @MainActor func bestTimeIsScopedToItsOwnDifficultyTier() {
        let context = Self.makeInMemoryContext()
        StatsStore.record(difficulty: .easy, elapsedSeconds: 30, context: context)
        StatsStore.record(difficulty: .expert, elapsedSeconds: 500, context: context)

        #expect(StatsStore.bestTime(for: .expert, context: context) == 500)
    }

    @Test @MainActor func solveCountReflectsOnlyRecordsForThatTier() {
        let context = Self.makeInMemoryContext()
        StatsStore.record(difficulty: .medium, elapsedSeconds: 60, context: context)
        StatsStore.record(difficulty: .medium, elapsedSeconds: 70, context: context)
        StatsStore.record(difficulty: .hard, elapsedSeconds: 200, context: context)

        #expect(StatsStore.solveCount(for: .medium, context: context) == 2)
        #expect(StatsStore.solveCount(for: .hard, context: context) == 1)
        #expect(StatsStore.solveCount(for: .beginner, context: context) == 0)
    }

    @Test @MainActor func historyIsOrderedMostRecentFirst() {
        let context = Self.makeInMemoryContext()
        let earlier = Date(timeIntervalSince1970: 1000)
        let later = Date(timeIntervalSince1970: 2000)
        StatsStore.record(difficulty: .hard, elapsedSeconds: 100, completedAt: earlier, context: context)
        StatsStore.record(difficulty: .hard, elapsedSeconds: 200, completedAt: later, context: context)

        let history = StatsStore.history(for: .hard, context: context)

        #expect(history.map(\.elapsedSeconds) == [200, 100])
    }
}
