package me.gileskayo.killersudoku.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class CageLayoutGeneratorTest {
    @Test
    fun everyCellIsCoveredExactlyOnce() {
        val cages = requireNotNull(CageLayoutGenerator.generate(DemoPuzzle.solutionGrid))
        val seen = mutableSetOf<Coordinate>()
        for (cage in cages) for (coordinate in cage.cells) {
            assertTrue(seen.add(coordinate), "duplicate coverage at $coordinate")
        }
        assertEquals(81, seen.size)
    }

    @Test
    fun everyCageSizeIsWithinBounds() {
        val cages = requireNotNull(CageLayoutGenerator.generate(DemoPuzzle.solutionGrid))
        for (cage in cages) assertTrue(cage.cells.size in 2..4)
    }

    @Test
    fun noCageHasARepeatedDigit() {
        val cages = requireNotNull(CageLayoutGenerator.generate(DemoPuzzle.solutionGrid))
        for (cage in cages) {
            val digits = cage.cells.map { DemoPuzzle.solutionGrid[it.row][it.column] }
            assertEquals(digits.toSet().size, digits.size)
        }
    }

    @Test
    fun everyCageIsOrthogonallyConnected() {
        val cages = requireNotNull(CageLayoutGenerator.generate(DemoPuzzle.solutionGrid))
        for (cage in cages) {
            assertTrue(isOrthogonallyConnected(cage.cells), "cage ${cage.id} is not connected: ${cage.cells}")
        }
    }

    /** Regression test for a real hang found while building the Swift port: a region with a
     * cell boxed in by holes on all four sides (no possible cage-mate) is a *structural* dead
     * end -- no amount of retrying with different random growth order can ever succeed. Before
     * maxAttempts was bounded, this looped forever. */
    @Test
    fun givesUpRatherThanHangingOnAStructurallyIsolatedCell() {
        val region = Coordinate.all.toMutableSet()
        region.remove(Coordinate(3, 4))
        region.remove(Coordinate(5, 4))
        region.remove(Coordinate(4, 3))
        region.remove(Coordinate(4, 5))

        val cages = CageLayoutGenerator.cages(DemoPuzzle.solutionGrid, region, startingId = 0, maxAttempts = 50)
        assertNull(cages)
    }

    private fun isOrthogonallyConnected(cells: List<Coordinate>): Boolean {
        val first = cells.firstOrNull() ?: return true
        val reached = mutableSetOf(first)
        val frontier = ArrayDeque(listOf(first))
        val cellSet = cells.toSet()

        while (frontier.isNotEmpty()) {
            val current = frontier.removeLast()
            val neighbors = listOf(-1 to 0, 1 to 0, 0 to -1, 0 to 1).mapNotNull { (rowDelta, columnDelta) ->
                val row = current.row + rowDelta
                val column = current.column + columnDelta
                if (row !in 0..8 || column !in 0..8) null else Coordinate(row, column)
            }
            for (neighbor in neighbors) {
                if (neighbor in cellSet && reached.add(neighbor)) frontier.addLast(neighbor)
            }
        }
        return reached.size == cells.size
    }
}
