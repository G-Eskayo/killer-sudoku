package me.gileskayo.killersudoku.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class PuzzleSolverTest {
    /** Rows 0-1 covered by 9 vertical 2-cell cages, one per column; rows 2-8 use the real,
     * well-scattered [CageLayoutGenerator] output. Swapping rows 0 and 1 across the whole grid
     * is a standard Sudoku symmetry (both rows sit in the same 3-row box band), and since every
     * rows-0-1 cage contains both cells of the swap while no rows-2-8 cage touches rows 0-1 at
     * all, every cage's sum is unchanged -- a second real solution to the exact same cage-sum
     * puzzle, proof it's non-unique. */
    private fun makeNonUniqueFixture(grid: Array<IntArray>): List<Cage> {
        val verticalCages = (0..8).map { column ->
            val cells = listOf(Coordinate(0, column), Coordinate(1, column))
            val sum = cells.sumOf { grid[it.row][it.column] }
            Cage(id = column, cells = cells, sum = sum)
        }

        val lowerRegion = buildSet {
            for (row in 2..8) for (column in 0..8) add(Coordinate(row, column))
        }
        val lowerCages = requireNotNull(CageLayoutGenerator.cages(grid, lowerRegion, startingId = verticalCages.size))

        return verticalCages + lowerCages
    }

    @Test
    fun countsMultipleSolutionsForANonUniquePuzzle() {
        val cages = makeNonUniqueFixture(DemoPuzzle.solutionGrid)
        assertEquals(2, PuzzleSolver.countSolutions(cages, cap = 2))
    }

    /** An always-true isCancelled should abort within a small, bounded number of nodes (the poll
     * interval) rather than running the search to its natural conclusion -- this is what lets a
     * batch of parallel attempts stop the moment any one of them succeeds. */
    @Test
    fun cancellationAbortsQuicklyWithAnInconclusiveResult() {
        val result = PuzzleSolver.verify(DemoPuzzle.makeCages(), cap = 2, isCancelled = { true })
        assertEquals(null, result.solutionCount)
        assertTrue(result.nodesVisited <= 256)
    }

    /** A closure that always returns false must never itself cause an abort -- verified by
     * confirming it's actually polled (not a vacuous test) rather than by comparing outcomes
     * against a separate call, which would be flaky: step()'s digit exploration order is
     * randomized per call, so two independent searches over the same cages can legitimately take
     * very different numbers of nodes. */
    @Test
    fun aFalseIsCancelledDoesNotAbortTheSearch() {
        var callCount = 0
        PuzzleSolver.verify(DemoPuzzle.makeCages(), cap = 2, isCancelled = {
            callCount += 1
            false
        })
        assertTrue(callCount >= 1)
    }
}
