package me.gileskayo.killersudoku.core

/** Produces a random, fully-solved, valid 9x9 Sudoku grid (every row, column, and 3x3 box a
 * permutation of 1-9) via randomized backtracking. Used as the seed grid for cage-based puzzle
 * generation ([PuzzleGenerator]). */
object SudokuGridGenerator {
    fun generate(): Array<IntArray> {
        val grid = Array(9) { IntArray(9) }
        val filled = fill(grid, 0)
        check(filled) { "backtracking search must always find a solution for an empty grid" }
        return grid
    }

    private fun fill(grid: Array<IntArray>, position: Int): Boolean {
        if (position >= 81) return true
        val row = position / 9
        val column = position % 9

        for (digit in (1..9).shuffled()) {
            if (!SudokuRules.canPlace(digit, row, column, grid)) continue
            grid[row][column] = digit
            if (fill(grid, position + 1)) return true
            grid[row][column] = 0
        }
        return false
    }
}
