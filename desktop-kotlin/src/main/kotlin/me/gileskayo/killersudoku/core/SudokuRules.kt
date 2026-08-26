package me.gileskayo.killersudoku.core

/** Standard Sudoku row/column/3x3-box uniqueness check, shared by anything that needs to place a
 * digit into a partially-filled 9x9 grid: [SudokuGridGenerator] and [PuzzleSolver]. */
object SudokuRules {
    fun canPlace(digit: Int, row: Int, column: Int, grid: Array<IntArray>): Boolean {
        for (otherColumn in 0..8) if (grid[row][otherColumn] == digit) return false
        for (otherRow in 0..8) if (grid[otherRow][column] == digit) return false

        val boxRow = (row / 3) * 3
        val boxColumn = (column / 3) * 3
        for (r in boxRow until boxRow + 3) {
            for (c in boxColumn until boxColumn + 3) if (grid[r][c] == digit) return false
        }
        return true
    }
}
