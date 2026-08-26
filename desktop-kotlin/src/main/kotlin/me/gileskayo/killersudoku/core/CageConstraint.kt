package me.gileskayo.killersudoku.core

/** Shared cage-sum feasibility reasoning, used by [PuzzleSolver]'s hot-loop uniqueness
 * verification -- "which digits could still legally go in this cage cell." */
object CageConstraint {
    /** Which digits (as a bitmask) are still legal for an empty cell within its own cage,
     * combining the no-repeat-digit rule with a sum-feasibility bound: can the cage's other
     * still-empty cells reach the target sum using distinct digits not already used? */
    fun candidateMask(cage: Cage, usedMask: Int, partialSum: Int, filledCount: Int): Int {
        val remainingAfterThis = cage.cells.size - filledCount - 1
        val unusedMask = usedMask.inv() and 0x1FF

        if (remainingAfterThis <= 0) {
            val needed = cage.sum - partialSum
            if (needed !in 1..9) return 0
            val neededBit = 1 shl (needed - 1)
            return unusedMask and neededBit
        }

        var allowed = 0
        var candidates = unusedMask
        while (candidates != 0) {
            val bit = candidates and (-candidates)
            candidates = candidates and bit.inv()
            val digit = bit.countTrailingZeroBits() + 1

            val remainder = cage.sum - (partialSum + digit)
            if (subsetSums(remainder, remainingAfterThis, unusedMask and bit.inv())) {
                allowed = allowed or bit
            }
        }
        return allowed
    }

    /** Does some [count]-element subset of the digits in [mask] sum to exactly [target]? A
     * min/max-sum bound is *necessary* but not *sufficient*, so this exhaustively searches --
     * `count` is at most 3 (cage size capped at 4), so that's cheap. Pure bitmask recursion, no
     * array allocation, since this runs in the solver's hot loop. */
    fun subsetSums(target: Int, count: Int, mask: Int): Boolean {
        if (count <= 0) return target == 0
        if (target <= 0) return false

        var remaining = mask
        while (remaining != 0) {
            val bit = remaining and (-remaining)
            remaining = remaining and bit.inv()
            val value = bit.countTrailingZeroBits() + 1
            if (value > target) break
            if (subsetSums(target - value, count - 1, remaining)) return true
        }
        return false
    }
}
