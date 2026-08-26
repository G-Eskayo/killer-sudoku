package me.gileskayo.killersudoku.core

/** A known, fixed, valid cage layout for tests that need a genuine solvable/solved puzzle to
 * work with. Cage groups are deliberately kept within single rows so "no repeated digit in a
 * cage" holds automatically (a Sudoku row is always all-distinct digits). */
object DemoPuzzle {
    val solutionGrid: Array<IntArray> = arrayOf(
        intArrayOf(5, 3, 4, 6, 7, 8, 9, 1, 2),
        intArrayOf(6, 7, 2, 1, 9, 5, 3, 4, 8),
        intArrayOf(1, 9, 8, 3, 4, 2, 5, 6, 7),
        intArrayOf(8, 5, 9, 7, 6, 1, 4, 2, 3),
        intArrayOf(4, 2, 6, 8, 5, 3, 7, 9, 1),
        intArrayOf(7, 1, 3, 9, 2, 4, 8, 5, 6),
        intArrayOf(9, 6, 1, 5, 3, 7, 2, 8, 4),
        intArrayOf(2, 8, 7, 4, 1, 9, 6, 3, 5),
        intArrayOf(3, 4, 5, 2, 8, 6, 1, 7, 9),
    )

    /** Cage sizes per row, left to right. Each row's sizes sum to 9, every size is 2-4. */
    private val rowCageSizes: List<List<Int>> = listOf(
        listOf(2, 3, 4),
        listOf(4, 2, 3),
        listOf(3, 3, 3),
        listOf(2, 2, 2, 3),
        listOf(4, 3, 2),
        listOf(3, 4, 2),
        listOf(2, 4, 3),
        listOf(3, 2, 4),
        listOf(2, 3, 2, 2),
    )

    val cageCellGroups: List<List<Coordinate>> = buildList {
        for (row in 0..8) {
            var column = 0
            for (size in rowCageSizes[row]) {
                add((column until column + size).map { Coordinate(row, it) })
                column += size
            }
        }
    }

    fun makeCages(): List<Cage> = cageCellGroups.mapIndexed { index, coordinates ->
        val sum = coordinates.sumOf { solutionGrid[it.row][it.column] }
        Cage(id = index, cells = coordinates, sum = sum)
    }

    fun makeBoard(): Board = Board.blank(makeCages())
}
