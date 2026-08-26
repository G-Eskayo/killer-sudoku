package me.gileskayo.killersudoku.core

import kotlin.test.Test
import kotlin.test.assertEquals

class DifficultyTest {
    /** These values are persisted directly (see PuzzleStore). Changing any of them silently
     * reinterprets already-saved data as a different tier rather than failing -- this test
     * exists so that change can't happen by accident. */
    @Test
    fun rawValuesAreStable() {
        assertEquals(0, Difficulty.EASY.rawValue)
        assertEquals(1, Difficulty.MEDIUM.rawValue)
        assertEquals(2, Difficulty.HARD.rawValue)
        assertEquals(3, Difficulty.EXPERT.rawValue)
    }
}
