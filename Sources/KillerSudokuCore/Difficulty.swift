/// Difficulty tiers (ADR 0005: five total, Expert is the single top tier). `.beginner` is
/// hybrid-mode only ([[CONTEXT.md]]) and is always picked directly by the player rather than
/// computed — [[PuzzleGenerator]].generate(difficulty:) special-cases it to hybrid generation,
/// and neither [[DifficultyGrader]] nor `fromSearchEffort` ever produce it. Every other case is
/// classic mode, graded via `fromSearchEffort`.
public enum Difficulty: Int, CaseIterable, Comparable, Sendable, Codable {
    case beginner, easy, medium, hard, expert

    public static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Classic mode's active difficulty signal (ADR 0007): how many search-tree nodes
    /// [[PuzzleSolver]] needed to fully verify a puzzle's unique solution. Solving-technique
    /// simulation ([[DifficultyGrader]]) never differentiated real generated puzzles at all —
    /// this reuses a search the generator already runs for uniqueness, at no extra cost.
    /// Thresholds are calibrated from a 10-puzzle real sample (352-13808 nodes, log-scale
    /// spread) — a reasonable v1 starting point, not a precise calibration; see the ADR.
    public static func fromSearchEffort(nodesVisited: Int) -> Difficulty {
        switch nodesVisited {
        case ..<1500: return .easy
        case 1500..<4500: return .medium
        case 4500..<8500: return .hard
        default: return .expert
        }
    }

    /// Shared with every UI surface that lists tiers (New Puzzle menu, stats view) so the label
    /// text only has one place to change.
    public var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }
}
