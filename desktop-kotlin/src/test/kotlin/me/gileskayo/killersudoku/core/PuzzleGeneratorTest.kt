package me.gileskayo.killersudoku.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class PuzzleGeneratorTest {
    @Test
    fun generatedBoardCoversEveryCellExactlyOnceWithExactlyOneSolution() {
        val board = PuzzleGenerator.generate(Difficulty.MEDIUM)

        val seen = mutableSetOf<Coordinate>()
        for (cage in board.cages) for (coordinate in cage.cells) {
            assertTrue(seen.add(coordinate), "duplicate coverage at $coordinate")
        }
        assertEquals(81, seen.size)
        assertEquals(1, PuzzleSolver.countSolutions(board.cages, cap = 2))

        // Every cage is a normal 2-4 cell cage -- givens are pre-filled digits inside whatever
        // cage they already belong to, not carved into their own single-cell cage.
        for (cage in board.cages) assertTrue(cage.cells.size in 2..4)
        val givenCount = Coordinate.all.count { board.cellAt(it).digit != null }
        assertTrue(givenCount in 17..24)
    }

    @Test
    fun generateWithDifficultyReturnsGivenDensityMatchingThatTier() {
        val board = PuzzleGenerator.generate(Difficulty.EASY)

        assertEquals(1, PuzzleSolver.countSolutions(board.cages, cap = 2))
        for (cage in board.cages) assertTrue(cage.cells.size in 2..4)
        val givenCount = Coordinate.all.count { board.cellAt(it).digit != null }
        assertTrue(givenCount in 25..40)
    }
}
