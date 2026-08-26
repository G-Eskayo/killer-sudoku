/// Difficulty tiers (ADR 0005: five total, Expert is the single top tier). `.beginner` is
/// hybrid-mode only ([[CONTEXT.md]]) and is always picked directly by the player rather than
/// computed — [[PuzzleGenerator]].generate(difficulty:) special-cases it to hybrid generation.
/// Every other case is classic mode, whose difficulty is given-density, chosen directly at
/// generation time ([[0008]]) rather than graded after the fact.
public enum Difficulty: Int, CaseIterable, Comparable, Sendable, Codable {
    case beginner, easy, medium, hard, expert

    public static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
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
