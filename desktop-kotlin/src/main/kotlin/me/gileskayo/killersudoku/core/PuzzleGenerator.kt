package me.gileskayo.killersudoku.core

import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicReference

/** Generates a fresh, on-device Killer Sudoku puzzle: a random solved grid, fully partitioned
 * into normal 2-4 cell cages, with a per-tier count of cells revealed as givens inside whatever
 * cage they already belong to -- given-density *is* the difficulty lever. This is the app's
 * single public entry point for puzzle generation. */
object PuzzleGenerator {
    private val classicGivensRanges: Map<Difficulty, IntRange> = mapOf(
        Difficulty.EASY to 25..40,
        Difficulty.MEDIUM to 17..24,
        Difficulty.HARD to 9..16,
        Difficulty.EXPERT to 4..8,
    )

    /** Regenerates until [PuzzleSolver] confirms exactly one solution. Given-density is chosen
     * directly from the requested tier's range, not discovered after the fact, so this never
     * needs a second retry condition for the tier itself. Blocking -- call from a background
     * dispatcher, not the UI thread. */
    fun generate(difficulty: Difficulty): Board = attemptClassicInParallel(difficulty)

    /** Profiling on the Swift port found ~85-95% of individual attempts fail (a random cage
     * layout is non-unique far more often than not), and each failure still costs a real solver
     * search (often near the full node budget) before giving up -- grid/cage generation
     * themselves are negligible by comparison. Attempts share no state, so a whole batch runs at
     * once across CPU cores, turning serial retry cost into parallel retry cost.
     *
     * A batch used to always wait for its *slowest* member even after another one had already
     * succeeded. [AtomicReference] doubles as the cancellation signal -- every attempt in the
     * batch polls whether a result already exists during its solver search, so the moment any
     * one succeeds, the rest abort within a bounded number of nodes instead of running to their
     * own natural conclusion regardless of the others.
     *
     * That still leaves the case where *every* attempt in a batch fails -- nothing to cancel
     * against. At a 5-15% per-attempt success rate, a batch sized to exactly the core count
     * fails outright well over half the time at the harder tiers. Oversubscribing to 2x core
     * count (matching the Swift port's own empirically-chosen multiplier) raises the odds that
     * at least one attempt somewhere in the batch succeeds, while a fixed-size thread pool
     * (sized to the actual core count) queues the excess and runs it as cores free up. */
    private fun attemptClassicInParallel(difficulty: Difficulty): Board {
        val coreCount = maxOf(1, Runtime.getRuntime().availableProcessors())
        val batchSize = coreCount * 2
        val executor = Executors.newFixedThreadPool(coreCount)
        try {
            while (true) {
                val result = AtomicReference<Board?>(null)
                val futures = (0 until batchSize).map {
                    executor.submit {
                        val board = attemptClassic(difficulty) { result.get() != null }
                        if (board != null) result.compareAndSet(null, board)
                    }
                }
                futures.forEach { it.get() }
                result.get()?.let { return it }
            }
        } finally {
            executor.shutdown()
        }
    }

    /** One candidate. Returns null if cage generation didn't converge, the cage layout alone
     * isn't uniquely solvable, or the search was cancelled (another attempt in the same batch
     * already succeeded) -- any of which just means the caller's retry loop tries a fresh
     * instance. Uniqueness is checked from the cage structure alone, *before* givens are chosen:
     * a real Killer Sudoku puzzle is solvable by cage-sum logic on its own, and a given is a
     * bonus reveal layered on top, not something the puzzle's validity should depend on.
     * Checking cage+givens together here would let a genuinely ambiguous cage layout slip
     * through whenever the chosen givens happened to rule out its other solutions. */
    private fun attemptClassic(difficulty: Difficulty, isCancelled: (() -> Boolean)? = null): Board? {
        if (isCancelled?.invoke() == true) return null
        val grid = SudokuGridGenerator.generate()
        val cages = CageLayoutGenerator.generate(grid) ?: return null
        val result = PuzzleSolver.verify(cages, cap = 2, isCancelled = isCancelled)
        if (result.solutionCount != 1) return null

        val givenCount = classicGivensRanges.getValue(difficulty).random()
        val givenCoordinates = Coordinate.all.shuffled().take(givenCount).toSet()
        val givens = givenCoordinates.associateWith { grid[it.row][it.column] }
        return board(cages, givens)
    }

    /** Pre-fills every given's digit directly into the initial cell grid, as a normal member of
     * its cage -- rather than through [Board.setDigit], which would record each as an undoable
     * player edit. Givens aren't a player action; they shouldn't be undoable. */
    private fun board(cages: List<Cage>, givens: Map<Coordinate, Int>): Board {
        val cells = List(9) { row ->
            List(9) { column ->
                val digit = givens[Coordinate(row, column)]
                if (digit != null) Cell(digit = digit, isGiven = true) else Cell()
            }
        }
        return Board(cages, cells)
    }
}
