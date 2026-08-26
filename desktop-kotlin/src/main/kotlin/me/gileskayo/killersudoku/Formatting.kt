package me.gileskayo.killersudoku

/** Shared by the timer display and stats popover so "mm:ss" only has one implementation. */
fun Double.formattedAsMinutesAndSeconds(): String {
    val totalSeconds = maxOf(0, this.toInt())
    return "%02d:%02d".format(totalSeconds / 60, totalSeconds % 60)
}
