/// Difficulty tiers (ADR 0005: Expert is the single top tier; ADR 0009: four tiers total,
/// hybrid/Beginner mode removed). Every tier is classic mode, whose difficulty is given-density,
/// chosen directly at generation time ([[0008]]) rather than graded after the fact.
///
/// Raw values are explicit and must stay that way (ADR 0011): [[SavedPuzzle]] and [[SolveRecord]]
/// persist `rawValue` directly, and ADR 0009 briefly broke that contract by removing `.beginner`
/// while every case still relied on implicit (declaration-order) values — every remaining case's
/// number silently shifted, so already-persisted data reinterpreted as the *wrong* tier rather
/// than failing to decode. Adding, removing, or reordering a case must never renumber another.
public enum Difficulty: Int, CaseIterable, Comparable, Sendable, Codable {
    case easy = 0, medium = 1, hard = 2, expert = 3

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
