package me.gileskayo.killersudoku.core

/**
 * Difficulty tiers. Every tier's difficulty is given-density, chosen directly at generation time
 * rather than graded after the fact -- see [PuzzleGenerator].
 *
 * [rawValue] is explicit and must stay that way: it's persisted directly (see the Swift port's
 * ADR 0011, which learned this the hard way -- Kotlin's own [Enum.ordinal] has the exact same
 * "implicit, position-dependent" pitfall enum.ordinal would have if used for persistence instead).
 * Adding, removing, or reordering an entry must never renumber another.
 */
enum class Difficulty(val rawValue: Int, val displayName: String) {
    EASY(0, "Easy"),
    MEDIUM(1, "Medium"),
    HARD(2, "Hard"),
    EXPERT(3, "Expert"),
    ;

    companion object {
        fun fromRawValue(rawValue: Int): Difficulty? = entries.firstOrNull { it.rawValue == rawValue }
    }
}
