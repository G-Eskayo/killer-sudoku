/// Difficulty tiers (ADR 0005: Expert is the single top tier; ADR 0009: four tiers total,
/// hybrid/Beginner mode removed). Every tier is classic mode, whose difficulty is given-density,
/// chosen directly at generation time ([[0008]]) rather than graded after the fact.
public enum Difficulty: Int, CaseIterable, Comparable, Sendable, Codable {
    case easy, medium, hard, expert

    public static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Shared with every UI surface that lists tiers (New Puzzle menu, stats view) so the label
    /// text only has one place to change.
    public var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }
}
