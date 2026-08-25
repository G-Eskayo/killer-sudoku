import Foundation
import SwiftData

/// One completed solve, per docs/v1-scope.md's Stats section: "persisted best time and solve
/// history per difficulty tier." Best time isn't stored separately — [[StatsStore]] derives it
/// from the history (the minimum elapsed time for that tier), avoiding a second source of truth
/// that could drift out of sync.
@Model
public final class SolveRecord {
    /// Stored as `Difficulty`'s raw value rather than the enum directly — SwiftData models need
    /// their stored properties to be primitive/Codable-friendly, and this keeps the persisted
    /// shape stable even if `Difficulty`'s case order or associated behavior changes later.
    public var difficultyRawValue: Int
    public var elapsedSeconds: Double
    public var completedAt: Date

    public init(difficulty: Difficulty, elapsedSeconds: Double, completedAt: Date = Date()) {
        self.difficultyRawValue = difficulty.rawValue
        self.elapsedSeconds = elapsedSeconds
        self.completedAt = completedAt
    }

    public var difficulty: Difficulty {
        Difficulty(rawValue: difficultyRawValue) ?? .easy
    }
}
