package me.gileskayo.killersudoku.core

/** Counts solutions to a classic-mode (no givens) Killer Sudoku puzzle defined purely by its
 * cage layout, capped at [VerificationResult] so callers checking for uniqueness don't pay for
 * an exhaustive search once a second solution proves the puzzle isn't unique. Used by
 * [PuzzleGenerator] to verify a generated layout before presenting it to the player. */
object PuzzleSolver {
    /** [nodesVisited] is exposed for informational/diagnostic use -- search effort needed to
     * fully verify uniqueness roughly correlates with how hard a puzzle is to crack, though it
     * isn't consumed by any grading logic (given-density is the difficulty signal instead,
     * decided before this search ever runs). */
    data class VerificationResult(val solutionCount: Int?, val nodesVisited: Int)

    /** Counts solutions up to [cap], but gives up and returns null if the search visits more
     * than [nodeBudget] tree nodes without resolving -- some random cage layouts are genuinely
     * expensive to prove either way, and it's cheaper for a caller like [PuzzleGenerator] to
     * discard a hard instance and try a fresh one than to fight one search to the end. Node
     * count (not wall-clock time) makes the cutoff deterministic and machine-independent.
     *
     * [isCancelled], if given, is polled every 256 nodes and treated the same as exceeding the
     * node budget -- inconclusive, not a definite answer. This is what lets a parallel batch of
     * attempts stop the moment any one of them succeeds, instead of every attempt always running
     * to its own natural conclusion regardless of the others. */
    fun verify(
        cages: List<Cage>, cap: Int, nodeBudget: Int = 20_000, isCancelled: (() -> Boolean)? = null,
    ): VerificationResult {
        val state = SolverState(cages, nodeBudget, isCancelled)
        state.search(cap)
        return VerificationResult(
            solutionCount = if (state.exceededBudget) null else state.solutionCount,
            nodesVisited = state.nodesVisited,
        )
    }

    fun countSolutions(cages: List<Cage>, cap: Int, nodeBudget: Int = 20_000): Int? =
        verify(cages, cap, nodeBudget).solutionCount
}

/** Digit d (1-9) is tracked as bit d-1 throughout -- bitmask row/column/box/cage state avoids
 * per-node allocation cost that backtracking search's high node-visit count would otherwise
 * multiply into real time. */
private class SolverState(
    private val cages: List<Cage>,
    private val nodeBudget: Int,
    private val isCancelled: (() -> Boolean)?,
) {
    private val cageIndexByPosition: IntArray
    private val grid = IntArray(81)
    private val rowMask = IntArray(9)
    private val columnMask = IntArray(9)
    private val boxMask = IntArray(9)
    private val cageUsedMask: IntArray
    private val cagePartialSum: IntArray
    private val cageFilledCount: IntArray
    private var cap = 0
    var nodesVisited = 0
        private set
    var solutionCount = 0
        private set
    var exceededBudget = false
        private set

    init {
        val index = IntArray(81) { -1 }
        cages.forEachIndexed { cageIndex, cage ->
            cage.cells.forEach { cell -> index[cell.row * 9 + cell.column] = cageIndex }
        }
        cageIndexByPosition = index
        cageUsedMask = IntArray(cages.size)
        cagePartialSum = IntArray(cages.size)
        cageFilledCount = IntArray(cages.size)
    }

    fun search(cap: Int) {
        this.cap = cap
        step()
    }

    private fun step() {
        if (solutionCount >= cap) return
        nodesVisited += 1
        if (nodesVisited > nodeBudget) {
            exceededBudget = true
            return
        }
        if ((nodesVisited == 1 || nodesVisited % 256 == 0) && isCancelled?.invoke() == true) {
            exceededBudget = true
            return
        }
        val found = mostConstrainedEmptyPosition()
        if (found == null) {
            solutionCount += 1
            return
        }
        val (position, candidateMask) = found

        val row = position / 9
        val column = position % 9
        val box = (row / 3) * 3 + column / 3
        val cageIndex = cageIndexByPosition[position]

        for (digit in digitsAscending(candidateMask).shuffled()) {
            val bit = 1 shl (digit - 1)

            place(digit, bit, position, row, column, box, cageIndex)
            step()
            unplace(digit, bit, position, row, column, box, cageIndex)

            if (solutionCount >= cap || exceededBudget) return
        }
    }

    private fun place(digit: Int, bit: Int, position: Int, row: Int, column: Int, box: Int, cageIndex: Int) {
        grid[position] = digit
        rowMask[row] = rowMask[row] or bit
        columnMask[column] = columnMask[column] or bit
        boxMask[box] = boxMask[box] or bit
        if (cageIndex < 0) return
        cageUsedMask[cageIndex] = cageUsedMask[cageIndex] or bit
        cagePartialSum[cageIndex] += digit
        cageFilledCount[cageIndex] += 1
    }

    private fun unplace(digit: Int, bit: Int, position: Int, row: Int, column: Int, box: Int, cageIndex: Int) {
        grid[position] = 0
        rowMask[row] = rowMask[row] and bit.inv()
        columnMask[column] = columnMask[column] and bit.inv()
        boxMask[box] = boxMask[box] and bit.inv()
        if (cageIndex < 0) return
        cageUsedMask[cageIndex] = cageUsedMask[cageIndex] and bit.inv()
        cagePartialSum[cageIndex] -= digit
        cageFilledCount[cageIndex] -= 1
    }

    /** Scans every empty cell and returns the one with the fewest legal candidates
     * (most-constrained-variable heuristic), short-circuiting the instant a cell with zero
     * candidates turns up -- that's a dead end no matter what the rest of the board looks like. */
    private fun mostConstrainedEmptyPosition(): Pair<Int, Int>? {
        var best: Pair<Int, Int>? = null
        var bestCount = 10

        for (position in 0 until 81) {
            if (grid[position] != 0) continue
            val row = position / 9
            val column = position % 9
            val box = (row / 3) * 3 + column / 3

            var mask = (rowMask[row] or columnMask[column] or boxMask[box]).inv() and 0x1FF
            val cageIndex = cageIndexByPosition[position]
            if (cageIndex >= 0) {
                mask = mask and cageCandidateMask(cageIndex)
            }

            val count = Integer.bitCount(mask)
            if (count == 0) return position to mask
            if (count < bestCount) {
                bestCount = count
                best = position to mask
            }
        }
        return best
    }

    private fun cageCandidateMask(cageIndex: Int): Int {
        val cage = cages[cageIndex]
        return CageConstraint.candidateMask(
            cage = cage,
            usedMask = cageUsedMask[cageIndex],
            partialSum = cagePartialSum[cageIndex],
            filledCount = cageFilledCount[cageIndex],
        )
    }

    private fun digitsAscending(mask: Int): List<Int> {
        val result = mutableListOf<Int>()
        var remaining = mask
        while (remaining != 0) {
            val bit = remaining and (-remaining)
            remaining = remaining and bit.inv()
            result.add(bit.countTrailingZeroBits() + 1)
        }
        return result
    }
}
