package me.gileskayo.killersudoku

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import me.gileskayo.killersudoku.core.Board
import me.gileskayo.killersudoku.core.Difficulty
import me.gileskayo.killersudoku.core.PuzzleGenerator
import me.gileskayo.killersudoku.core.PuzzleStore
import me.gileskayo.killersudoku.core.PuzzleTimer
import me.gileskayo.killersudoku.core.StatsStore

/** Shared app-level state, mirroring the Swift port's `GameState`. Also owns continuous
 * auto-save: every board change is persisted via [PuzzleStore], so there's no explicit "save"
 * action and no data loss on quit. */
class GameState(initialBoard: Board, initialDifficulty: Difficulty) {
    var board: Board by mutableStateOf(initialBoard)
        private set
    var timer: PuzzleTimer by mutableStateOf(PuzzleTimer())
        private set
    var isGeneratingNewPuzzle: Boolean by mutableStateOf(false)
        private set
    var currentDifficulty: Difficulty by mutableStateOf(initialDifficulty)
        private set

    /** Guards against recording the same completed puzzle twice -- every board change checks
     * for completion, so once a solve is recorded for this puzzle instance, further changes
     * (e.g. starting a fresh puzzle that happens to already be solved, unusual but possible)
     * must not record again. Reset whenever a new puzzle starts. */
    private var hasRecordedSolve = initialBoard.isSolved

    init {
        timer = timer.start()
        persistAndCheckSolve(initialBoard)
    }

    /** The single entry point every board mutation goes through -- auto-save and solve-detection
     * both need to see *every* change, the same way the Swift port's `$board.sink` fires on
     * every publish regardless of which call site triggered it. Named `updateBoard` rather than
     * `setBoard` -- the latter collides at the JVM level with the synthetic setter Kotlin
     * generates for the `board` property's `private set`. */
    fun updateBoard(newBoard: Board) {
        board = newBoard
        persistAndCheckSolve(newBoard)
    }

    private fun persistAndCheckSolve(board: Board) {
        PuzzleStore.save(board, currentDifficulty)
        recordSolveIfNeeded(board)
    }

    /** Pauses the timer *before* reading [PuzzleTimer.elapsed]: a finished puzzle shouldn't keep
     * ticking, and it keeps every later read of elapsed time consistent with exactly what got
     * persisted here. */
    private fun recordSolveIfNeeded(board: Board) {
        if (hasRecordedSolve || !board.isSolved) return
        hasRecordedSolve = true
        timer = timer.pause()
        StatsStore.record(currentDifficulty, timer.elapsed())
    }

    fun stats(difficulty: Difficulty): Pair<Double?, Int> =
        StatsStore.bestTime(difficulty) to StatsStore.solveCount(difficulty)

    fun toggleTimer() {
        timer = if (timer.isRunning) timer.pause() else timer.start()
    }

    /** Clears all player progress on the *current* puzzle (same cages, same givens) and restarts
     * its timer from zero -- a fresh attempt at the same puzzle, not a new one. */
    fun resetPuzzle() {
        updateBoard(board.reset())
        hasRecordedSolve = false
        timer = timer.reset().start()
    }

    /** Starts a fresh puzzle at the requested difficulty, replacing whatever was in progress.
     * Generation runs off the UI thread so it stays responsive; [isGeneratingNewPuzzle] lets the
     * UI show a loading state. */
    suspend fun startNewPuzzle(difficulty: Difficulty) {
        if (isGeneratingNewPuzzle) return
        isGeneratingNewPuzzle = true
        val newBoard = withContext(Dispatchers.Default) { PuzzleGenerator.generate(difficulty) }
        currentDifficulty = difficulty
        hasRecordedSolve = false
        updateBoard(newBoard)
        timer = timer.reset().start()
        isGeneratingNewPuzzle = false
    }
}
