package me.gileskayo.killersudoku.core

import kotlinx.serialization.Serializable

@Serializable
data class Coordinate(val row: Int, val column: Int) {
    init {
        require(row in 0..8 && column in 0..8) { "Coordinate out of range" }
    }

    val boxIndex: Int get() = (row / 3) * 3 + (column / 3)

    companion object {
        /** Every cell on the board, once each. Shared by anything that needs to enumerate or
         * partition the whole 9x9 grid. */
        val all: List<Coordinate> = buildList {
            for (row in 0..8) {
                for (column in 0..8) {
                    add(Coordinate(row, column))
                }
            }
        }
    }
}
