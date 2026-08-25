import Foundation
import SwiftData

/// Records and queries completed solves (see [[SolveRecord]]), one per difficulty tier, for
/// issue #9's best-time and solve-history stats. Mirrors [[PuzzleStore]]'s shape.
@MainActor
public enum StatsStore {
    public static func record(
        difficulty: Difficulty, elapsedSeconds: Double, completedAt: Date = Date(), context: ModelContext
    ) {
        context.insert(SolveRecord(difficulty: difficulty, elapsedSeconds: elapsedSeconds, completedAt: completedAt))
        try? context.save()
    }

    public static func bestTime(for difficulty: Difficulty, context: ModelContext) -> Double? {
        recordsForTier(difficulty, context: context).map(\.elapsedSeconds).min()
    }

    public static func solveCount(for difficulty: Difficulty, context: ModelContext) -> Int {
        let raw = difficulty.rawValue
        let descriptor = FetchDescriptor<SolveRecord>(predicate: #Predicate { $0.difficultyRawValue == raw })
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    public static func history(for difficulty: Difficulty, context: ModelContext) -> [SolveRecord] {
        recordsForTier(difficulty, context: context).sorted { $0.completedAt > $1.completedAt }
    }

    private static func recordsForTier(_ difficulty: Difficulty, context: ModelContext) -> [SolveRecord] {
        let raw = difficulty.rawValue
        let descriptor = FetchDescriptor<SolveRecord>(predicate: #Predicate { $0.difficultyRawValue == raw })
        return (try? context.fetch(descriptor)) ?? []
    }
}
