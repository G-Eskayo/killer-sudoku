package me.gileskayo.killersudoku.core

/** A pausable stopwatch for the current puzzle. Immutable value type -- no wall-clock side
 * effects of its own -- so callers decide when to re-read [elapsed] rather than this type
 * pushing updates. [nowEpochMillis] is injectable everywhere for deterministic tests. */
data class PuzzleTimer(
    private val accumulatedSeconds: Double = 0.0,
    private val runningSinceEpochMillis: Long? = null,
) {
    val isRunning: Boolean get() = runningSinceEpochMillis != null

    fun start(nowEpochMillis: Long = System.currentTimeMillis()): PuzzleTimer =
        if (runningSinceEpochMillis != null) this else copy(runningSinceEpochMillis = nowEpochMillis)

    fun pause(nowEpochMillis: Long = System.currentTimeMillis()): PuzzleTimer {
        val since = runningSinceEpochMillis ?: return this
        return copy(accumulatedSeconds = accumulatedSeconds + (nowEpochMillis - since) / 1000.0, runningSinceEpochMillis = null)
    }

    fun reset(): PuzzleTimer = PuzzleTimer()

    fun elapsed(nowEpochMillis: Long = System.currentTimeMillis()): Double {
        val since = runningSinceEpochMillis ?: return accumulatedSeconds
        return accumulatedSeconds + (nowEpochMillis - since) / 1000.0
    }
}
