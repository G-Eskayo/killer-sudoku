/// Counts solutions to a classic-mode (no givens) Killer Sudoku puzzle defined purely by its
/// cage layout, capped at `cap` so callers checking for uniqueness don't pay for an exhaustive
/// search once a second solution proves the puzzle isn't unique. Used by [[PuzzleGenerator]] to
/// verify a generated layout before presenting it to the player.
public enum PuzzleSolver {
    /// Counts solutions up to `cap`, but gives up and returns nil if the search visits more than
    /// `nodeBudget` tree nodes without resolving — some random cage layouts are genuinely
    /// expensive to prove either way, and it's cheaper for a caller like [[PuzzleGenerator]] to
    /// discard a hard instance and try a fresh one than to fight one search to the end. Node
    /// count (not wall-clock time) makes the cutoff deterministic and machine-independent.
    public static func countSolutions(cages: [Cage], upTo cap: Int, nodeBudget: Int = 20_000) -> Int? {
        let state = SolverState(cages: cages, nodeBudget: nodeBudget)
        state.search(upTo: cap)
        return state.exceededBudget ? nil : state.solutionCount
    }
}

/// Digit `d` (1-9) is tracked as bit `d - 1` throughout — bitmask row/column/box/cage state
/// avoids the `Set<Int>` allocation-per-node cost that made a first version of this solver
/// blow up to tens of seconds on some inputs (backtracking search visits a lot of nodes even
/// with good pruning; per-node cost has to be near-free).
private final class SolverState {
    private let cages: [Cage]
    private let cageIndexByPosition: [Int]
    private var grid: [Int]
    private var rowMask = [Int](repeating: 0, count: 9)
    private var columnMask = [Int](repeating: 0, count: 9)
    private var boxMask = [Int](repeating: 0, count: 9)
    private var cageUsedMask: [Int]
    private var cagePartialSum: [Int]
    private var cageFilledCount: [Int]
    private var cap = 0
    private let nodeBudget: Int
    private var nodesVisited = 0
    private(set) var solutionCount = 0
    private(set) var exceededBudget = false

    init(cages: [Cage], nodeBudget: Int) {
        self.cages = cages
        self.nodeBudget = nodeBudget
        var index = [Int](repeating: -1, count: 81)
        for (cageIndex, cage) in cages.enumerated() {
            for cell in cage.cells { index[cell.row * 9 + cell.column] = cageIndex }
        }
        self.cageIndexByPosition = index
        self.grid = [Int](repeating: 0, count: 81)
        self.cageUsedMask = [Int](repeating: 0, count: cages.count)
        self.cagePartialSum = [Int](repeating: 0, count: cages.count)
        self.cageFilledCount = [Int](repeating: 0, count: cages.count)
    }

    func search(upTo cap: Int) {
        self.cap = cap
        step()
    }

    private func step() {
        guard solutionCount < cap else { return }
        nodesVisited += 1
        guard nodesVisited <= nodeBudget else {
            exceededBudget = true
            return
        }
        guard let (position, candidateMask) = mostConstrainedEmptyPosition() else {
            solutionCount += 1
            return
        }

        let row = position / 9
        let column = position % 9
        let box = (row / 3) * 3 + column / 3
        let cageIndex = cageIndexByPosition[position]

        for digit in digitsAscending(from: candidateMask).shuffled() {
            let bit = 1 << (digit - 1)

            place(digit, bit: bit, position: position, row: row, column: column, box: box, cageIndex: cageIndex)
            step()
            unplace(digit, bit: bit, position: position, row: row, column: column, box: box, cageIndex: cageIndex)

            if solutionCount >= cap || exceededBudget { return }
        }
    }

    private func place(_ digit: Int, bit: Int, position: Int, row: Int, column: Int, box: Int, cageIndex: Int) {
        grid[position] = digit
        rowMask[row] |= bit
        columnMask[column] |= bit
        boxMask[box] |= bit
        guard cageIndex >= 0 else { return }
        cageUsedMask[cageIndex] |= bit
        cagePartialSum[cageIndex] += digit
        cageFilledCount[cageIndex] += 1
    }

    private func unplace(_ digit: Int, bit: Int, position: Int, row: Int, column: Int, box: Int, cageIndex: Int) {
        grid[position] = 0
        rowMask[row] &= ~bit
        columnMask[column] &= ~bit
        boxMask[box] &= ~bit
        guard cageIndex >= 0 else { return }
        cageUsedMask[cageIndex] &= ~bit
        cagePartialSum[cageIndex] -= digit
        cageFilledCount[cageIndex] -= 1
    }

    /// Scans every empty cell and returns the one with the fewest legal candidates (most-
    /// constrained-variable heuristic), short-circuiting the instant a cell with zero candidates
    /// turns up — that's a dead end no matter what the rest of the board looks like.
    private func mostConstrainedEmptyPosition() -> (position: Int, candidateMask: Int)? {
        var best: (position: Int, candidateMask: Int)?
        var bestCount = 10

        for position in 0..<81 where grid[position] == 0 {
            let row = position / 9
            let column = position % 9
            let box = (row / 3) * 3 + column / 3

            var mask = ~(rowMask[row] | columnMask[column] | boxMask[box]) & 0x1FF
            let cageIndex = cageIndexByPosition[position]
            if cageIndex >= 0 {
                mask &= cageCandidateMask(cageIndex)
            }

            let count = mask.nonzeroBitCount
            if count == 0 { return (position, mask) }
            if count < bestCount {
                bestCount = count
                best = (position, mask)
            }
        }
        return best
    }

    /// Which digits (as a bitmask) are still legal for the given cell within its own cage,
    /// combining the no-repeat-digit rule with a sum-feasibility bound: can the cage's other
    /// still-empty cells reach the target sum using distinct digits not already used?
    private func cageCandidateMask(_ cageIndex: Int) -> Int {
        let cage = cages[cageIndex]
        let usedMask = cageUsedMask[cageIndex]
        let remainingAfterThis = cage.cells.count - cageFilledCount[cageIndex] - 1
        let unusedMask = (~usedMask) & 0x1FF

        guard remainingAfterThis > 0 else {
            let needed = cage.sum - cagePartialSum[cageIndex]
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

            let remainder = cage.sum - (cagePartialSum[cageIndex] + digit)
            if Self.maskSubsetSums(to: remainder, using: remainingAfterThis, from: unusedMask & ~bit) {
                allowed |= bit
            }
        }
        return allowed
    }

    /// Does some `count`-element subset of the digits in `mask` sum to exactly `target`? A
    /// min/max-sum bound is *necessary* but not *sufficient* — e.g. {1,2,3,7,8,9} choosing 2
    /// can't reach 6 or 7 despite both sitting between the min (3) and max (17) — so a bound-only
    /// check lets a lot of dead-end digits through and only discovers the contradiction many
    /// levels deeper in the search. `count` is at most 3 (cage size capped at 4), so exhaustive
    /// search here is cheap — this is the same "which digit combinations can even fill this cage"
    /// reasoning CONTEXT.md calls cage-combination deduction, just applied as a solver-side prune
    /// rather than a player-facing hint. Pure bitmask recursion (no array allocation) since this
    /// runs at every node of the outer search — allocating here was the actual cost driver in an
    /// earlier version that made verification blow up to tens of seconds on some layouts.
    private static func maskSubsetSums(to target: Int, using count: Int, from mask: Int) -> Bool {
        guard count > 0 else { return target == 0 }
        guard target > 0 else { return false }

        var remaining = mask
        while remaining != 0 {
            let bit = remaining & (~remaining + 1)
            remaining &= ~bit
            let value = bit.trailingZeroBitCount + 1
            if value > target { break }
            if maskSubsetSums(to: target - value, using: count - 1, from: remaining) { return true }
        }
        return false
    }

    private func digitsAscending(from mask: Int) -> [Int] {
        var result: [Int] = []
        var remaining = mask
        while remaining != 0 {
            let bit = remaining & (~remaining + 1)
            remaining &= ~bit
            result.append(bit.trailingZeroBitCount + 1)
        }
        return result
    }
}
