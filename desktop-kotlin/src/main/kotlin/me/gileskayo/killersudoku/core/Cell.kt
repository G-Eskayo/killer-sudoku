package me.gileskayo.killersudoku.core

import kotlinx.serialization.Serializable

@Serializable
data class Cell(
    val digit: Int? = null,
    val pencilMarks: Set<Int> = emptySet(),
    /** True for a cell [PuzzleGenerator] pre-filled rather than one the player set --
     * [Board.setDigit] refuses to change a given, matching standard Sudoku convention. */
    val isGiven: Boolean = false,
)
