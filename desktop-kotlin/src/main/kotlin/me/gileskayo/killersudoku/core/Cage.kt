package me.gileskayo.killersudoku.core

import kotlinx.serialization.Serializable

@Serializable
data class Cage(val id: Int, val cells: List<Coordinate>, val sum: Int) {
    init {
        require(cells.size in 2..4) { "Cage must have 2-4 cells" }
    }
}
