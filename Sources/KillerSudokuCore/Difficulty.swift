/// Classic-mode difficulty tiers (ADR 0005: five tiers total, Expert is the single top tier).
/// Beginner is hybrid-mode only (issue #3) and isn't graded by [[DifficultyGrader]] — it's
/// picked directly, not measured.
public enum Difficulty: Int, CaseIterable, Comparable, Sendable, Codable {
    case easy, medium, hard, expert

    public static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
