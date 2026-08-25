/// Shared cage-sum feasibility reasoning, used by both [[PuzzleSolver]] (hot-loop uniqueness
/// verification, thousands of nodes per candidate puzzle) and `DifficultyGrader` (a handful of
/// calls per candidate puzzle) — the same "which digits could still legally go in this cage
/// cell" question, just asked at very different call frequencies.
enum CageConstraint {
    /// Which digits (as a bitmask) are still legal for an empty cell within its own cage,
    /// combining the no-repeat-digit rule with a sum-feasibility bound: can the cage's other
    /// still-empty cells reach the target sum using distinct digits not already used?
    static func candidateMask(for cage: Cage, usedMask: Int, partialSum: Int, filledCount: Int) -> Int {
        let remainingAfterThis = cage.cells.count - filledCount - 1
        let unusedMask = (~usedMask) & 0x1FF

        guard remainingAfterThis > 0 else {
            let needed = cage.sum - partialSum
            guard (1...9).contains(needed) else { return 0 }
            let neededBit = 1 << (needed - 1)
            return unusedMask & neededBit
        }

        var allowed = 0
        var candidates = unusedMask
        while candidates != 0 {
            let bit = candidates & (~candidates + 1)
            candidates &= ~bit
            let digit = bit.trailingZeroBitCount + 1

            let remainder = cage.sum - (partialSum + digit)
            if subsetSums(to: remainder, using: remainingAfterThis, from: unusedMask & ~bit) {
                allowed |= bit
            }
        }
        return allowed
    }

    /// Does some `count`-element subset of the digits in `mask` sum to exactly `target`? A
    /// min/max-sum bound is *necessary* but not *sufficient* — e.g. {1,2,3,7,8,9} choosing 2
    /// can't reach 6 or 7 despite both sitting between the min (3) and max (17) — so a bound-only
    /// check lets a lot of dead-end digits through. `count` is at most 3 (cage size capped at 4),
    /// so exhaustive search here is cheap — this is the same "which digit combinations can even
    /// fill this cage" reasoning CONTEXT.md calls cage-combination deduction, just applied as a
    /// prune rather than a player-facing hint. Pure bitmask recursion (no array allocation) — see
    /// PuzzleSolver's history for why that matters in its hot loop.
    static func subsetSums(to target: Int, using count: Int, from mask: Int) -> Bool {
        guard count > 0 else { return target == 0 }
        guard target > 0 else { return false }

        var remaining = mask
        while remaining != 0 {
            let bit = remaining & (~remaining + 1)
            remaining &= ~bit
            let value = bit.trailingZeroBitCount + 1
            if value > target { break }
            if subsetSums(to: target - value, using: count - 1, from: remaining) { return true }
        }
        return false
    }
}
