package me.gileskayo.killersudoku.core

import kotlinx.serialization.Serializable
import kotlinx.serialization.Transient

/**
 * One undoable player edit. Pencil-mark toggles are their own inverse, so undoing/redoing one
 * just re-toggles it; digit edits need the prior value recorded since null (cleared) is itself a
 * valid "next" state. [DigitEdit.eliminatedPeers] are the row/column/box peers that had this same
 * digit auto-removed from their pencil marks as a side effect -- undo/redo needs to
 * restore/reapply that removal too, in the same step as the digit itself.
 */
internal sealed class Edit {
    data class DigitEdit(
        val coordinate: Coordinate, val previous: Int?, val next: Int?, val eliminatedPeers: Set<Coordinate>,
    ) : Edit()

    data class PencilMarkEdit(val coordinate: Coordinate, val mark: Int) : Edit()
    data class ClearedPencilMarksEdit(val coordinate: Coordinate, val previous: Set<Int>) : Edit()
}

/**
 * Immutable board state -- every mutating call (`setDigit`, `undo`, ...) returns a *new* `Board`
 * rather than mutating in place, mirroring the Swift original's value-type semantics (a
 * `mutating func` on a Swift struct looks, from the caller's side, exactly like "produces a new
 * value"). This also composes naturally with Compose's snapshot state: a `mutableStateOf<Board>`
 * recomposes on reassignment the same way SwiftUI's `@Published var board: Board` does.
 */
@Serializable
@ConsistentCopyVisibility
data class Board internal constructor(
    val cages: List<Cage>,
    private val cells: List<List<Cell>>,
    @Transient private val undoStack: List<Edit> = emptyList(),
    @Transient private val redoStack: List<Edit> = emptyList(),
) {
    companion object {
        fun blank(cages: List<Cage>): Board =
            Board(cages, List(9) { List(9) { Cell() } })
    }

    private val cageIndexByCoordinate: Map<Coordinate, Int> by lazy {
        buildMap {
            cages.forEachIndexed { cageIndex, cage ->
                cage.cells.forEach { coordinate -> put(coordinate, cageIndex) }
            }
        }
    }

    fun cellAt(coordinate: Coordinate): Cell = cells[coordinate.row][coordinate.column]

    fun cageAt(coordinate: Coordinate): Cage? = cageIndexByCoordinate[coordinate]?.let { cages[it] }

    val canUndo: Boolean get() = undoStack.isNotEmpty()
    val canRedo: Boolean get() = redoStack.isNotEmpty()

    /**
     * A no-op once the board is solved: a finished puzzle is frozen, not just "given cells are
     * protected" -- without this, clearing and retyping a cell's digit could flip `isSolved`
     * false->true again and re-trigger the completion flow as if it were a fresh solve. Also a
     * no-op on a given cell or when the new value matches what's already there. Placing a real
     * digit (not clearing one) also auto-eliminates that same digit from every row/column/box
     * peer's pencil marks, recorded as part of this same edit so undo/redo moves both together.
     */
    fun setDigit(digit: Int?, at: Coordinate): Board {
        if (isSolved) return this
        val current = cellAt(at)
        if (current.isGiven) return this
        if (current.digit == digit) return this

        var newCells = cells.withCell(at) { it.copy(digit = digit) }
        val eliminatedPeers = mutableSetOf<Coordinate>()
        if (digit != null) {
            for (peer in peerCoordinates(at)) {
                val peerRow = newCells[peer.row]
                val peerCell = peerRow[peer.column]
                if (digit in peerCell.pencilMarks) {
                    eliminatedPeers.add(peer)
                    newCells = newCells.withCell(peer) { it.copy(pencilMarks = it.pencilMarks - digit) }
                }
            }
        }

        val edit = Edit.DigitEdit(at, current.digit, digit, eliminatedPeers)
        return copy(cells = newCells, undoStack = undoStack + edit, redoStack = emptyList())
    }

    /** A no-op when the cell already holds a digit: the board only ever renders pencil marks on
     * an empty cell, so recording one on a filled cell would silently do nothing visible -- and
     * worse, add its own undo entry on top of whatever set that digit. */
    fun togglePencilMark(mark: Int, at: Coordinate): Board {
        val current = cellAt(at)
        if (current.digit != null) return this
        val newCells = applyPencilMarkToggle(cells, mark, at)
        return copy(cells = newCells, undoStack = undoStack + Edit.PencilMarkEdit(at, mark), redoStack = emptyList())
    }

    /** Clears every pencil mark in one cell as a single undoable step -- e.g. Delete on a cell
     * that has notes but no digit. A no-op (no undo entry) when there's nothing to clear. */
    fun clearPencilMarks(at: Coordinate): Board {
        val previous = cellAt(at).pencilMarks
        if (previous.isEmpty()) return this
        val newCells = cells.withCell(at) { it.copy(pencilMarks = emptySet()) }
        return copy(
            cells = newCells, undoStack = undoStack + Edit.ClearedPencilMarksEdit(at, previous), redoStack = emptyList(),
        )
    }

    /** Clears every player-entered digit and pencil mark, keeping the same cage layout and
     * givens exactly as generated -- restarting this puzzle from scratch rather than replacing
     * it with a fresh one. Not itself undoable: the undo/redo history is discarded along with
     * the progress it describes, the same way starting a genuinely new puzzle also begins with
     * a clean history. */
    fun reset(): Board {
        val newCells = cells.map { row -> row.map { cell -> if (cell.isGiven) cell else Cell() } }
        return copy(cells = newCells, undoStack = emptyList(), redoStack = emptyList())
    }

    /** Undoes the most recent edit, walking back through the full session history one step at a
     * time. A no-op with nothing left to undo, or once the board is solved -- undoing the move
     * that completed it would unsolve the board and reopen `setDigit`'s lock, letting the player
     * edit a "finished" puzzle again through the back door. */
    fun undo(): Board {
        if (isSolved) return this
        val edit = undoStack.lastOrNull() ?: return this
        val newCells = applyUndo(cells, edit)
        return copy(
            cells = newCells, undoStack = undoStack.dropLast(1), redoStack = redoStack + edit,
        )
    }

    /** Redoes the most recently undone edit. A new edit made after an undo truncates this stack
     * (standard undo/redo semantics), and this is also a no-op once the board is solved -- a
     * stale redo entry from before a completing edit must not reach back in and mutate a
     * now-finished board. */
    fun redo(): Board {
        if (isSolved) return this
        val edit = redoStack.lastOrNull() ?: return this
        val newCells = applyRedo(cells, edit)
        return copy(
            cells = newCells, undoStack = undoStack + edit, redoStack = redoStack.dropLast(1),
        )
    }

    private fun applyUndo(source: List<List<Cell>>, edit: Edit): List<List<Cell>> = when (edit) {
        is Edit.DigitEdit -> {
            var result = source.withCell(edit.coordinate) { it.copy(digit = edit.previous) }
            if (edit.next != null) {
                for (peer in edit.eliminatedPeers) {
                    result = result.withCell(peer) { it.copy(pencilMarks = it.pencilMarks + edit.next) }
                }
            }
            result
        }
        is Edit.PencilMarkEdit -> applyPencilMarkToggle(source, edit.mark, edit.coordinate)
        is Edit.ClearedPencilMarksEdit -> source.withCell(edit.coordinate) { it.copy(pencilMarks = edit.previous) }
    }

    private fun applyRedo(source: List<List<Cell>>, edit: Edit): List<List<Cell>> = when (edit) {
        is Edit.DigitEdit -> {
            var result = source.withCell(edit.coordinate) { it.copy(digit = edit.next) }
            if (edit.next != null) {
                for (peer in edit.eliminatedPeers) {
                    result = result.withCell(peer) { it.copy(pencilMarks = it.pencilMarks - edit.next) }
                }
            }
            result
        }
        is Edit.PencilMarkEdit -> applyPencilMarkToggle(source, edit.mark, edit.coordinate)
        is Edit.ClearedPencilMarksEdit -> source.withCell(edit.coordinate) { it.copy(pencilMarks = emptySet()) }
    }

    private fun applyPencilMarkToggle(source: List<List<Cell>>, mark: Int, at: Coordinate): List<List<Cell>> =
        source.withCell(at) { cell ->
            if (mark in cell.pencilMarks) cell.copy(pencilMarks = cell.pencilMarks - mark)
            else cell.copy(pencilMarks = cell.pencilMarks + mark)
        }

    /** Every other cell sharing this coordinate's row, column, or 3x3 box -- the standard Sudoku
     * "peer" set used for pencil-mark auto-elimination. */
    private fun peerCoordinates(coordinate: Coordinate): Set<Coordinate> {
        val peers = mutableSetOf<Coordinate>()
        for (column in 0..8) if (column != coordinate.column) peers.add(Coordinate(coordinate.row, column))
        for (row in 0..8) if (row != coordinate.row) peers.add(Coordinate(row, coordinate.column))
        peers.addAll(boxCoordinates(coordinate.boxIndex))
        peers.remove(coordinate)
        return peers
    }

    /** Digits currently placed in exactly 9 cells on the board -- a naive count-based proxy for
     * digit completion. Doesn't account for rule violations (a duplicate digit still counts
     * toward "9 placed"). */
    fun completedDigits(): Set<Int> {
        val counts = mutableMapOf<Int, Int>()
        for (row in cells) for (cell in row) {
            val digit = cell.digit ?: continue
            counts[digit] = (counts[digit] ?: 0) + 1
        }
        return counts.filterValues { it == 9 }.keys
    }

    /** Cells currently in violation of a Killer Sudoku rule: a duplicate digit in the same row,
     * column, box, or cage, or a cage whose placed digits already make its target sum
     * unreachable. Only ever reflects digits the player has placed -- never hints at what's
     * missing. */
    fun mistakenCoordinates(): Set<Coordinate> {
        val mistaken = mutableSetOf<Coordinate>()
        for (row in 0..8) addDuplicates((0..8).map { Coordinate(row, it) }, mistaken)
        for (column in 0..8) addDuplicates((0..8).map { Coordinate(it, column) }, mistaken)
        for (boxIndex in 0..8) addDuplicates(boxCoordinates(boxIndex), mistaken)
        for (cage in cages) {
            addDuplicates(cage.cells, mistaken)
            if (cageSumIsImpossible(cage)) {
                mistaken.addAll(cage.cells.filter { cellAt(it).digit != null })
            }
        }
        return mistaken
    }

    private fun addDuplicates(coordinates: List<Coordinate>, mistaken: MutableSet<Coordinate>) {
        val firstSeenAt = mutableMapOf<Int, Coordinate>()
        for (coordinate in coordinates) {
            val digit = cellAt(coordinate).digit ?: continue
            val earlier = firstSeenAt[digit]
            if (earlier != null) {
                mistaken.add(coordinate)
                mistaken.add(earlier)
            } else {
                firstSeenAt[digit] = coordinate
            }
        }
    }

    private fun cageSumIsImpossible(cage: Cage): Boolean {
        val placedDigits = cage.cells.mapNotNull { cellAt(it).digit }
        val partialSum = placedDigits.sum()
        val remainingCount = cage.cells.size - placedDigits.size

        if (remainingCount <= 0) return partialSum != cage.sum
        if (partialSum >= cage.sum) return true

        val available = ((1..9).toSet() - placedDigits.toSet()).sorted()
        if (available.size < remainingCount) return true

        val minPossible = partialSum + available.take(remainingCount).sum()
        val maxPossible = partialSum + available.takeLast(remainingCount).sum()
        return cage.sum !in minPossible..maxPossible
    }

    /** Every cell filled and no rule violations -- the puzzle is genuinely finished, not just
     * full. */
    val isSolved: Boolean
        get() {
            for (row in cells) for (cell in row) if (cell.digit == null) return false
            return mistakenCoordinates().isEmpty()
        }

    /** Every other cell currently holding the same digit as [coordinate]. Only ever reflects
     * digits the player has actually placed -- an empty cell has no digit to match against, so
     * it always returns empty rather than hinting at where that digit belongs. */
    fun sameDigitCoordinates(as_: Coordinate): Set<Coordinate> {
        val digit = cellAt(as_).digit ?: return emptySet()
        val matches = mutableSetOf<Coordinate>()
        for (row in 0..8) for (column in 0..8) {
            val candidate = Coordinate(row, column)
            if (candidate != as_ && cellAt(candidate).digit == digit) matches.add(candidate)
        }
        return matches
    }

    /** Cage IDs fully filled with a valid (correct-sum, no-repeat) set of digits right now -- a
     * pure snapshot, not a transition. The UI diffs this against its previous value itself to
     * trigger a one-time completion animation per cage. */
    fun correctlyCompletedCageIds(): Set<Int> {
        val completed = mutableSetOf<Int>()
        for (cage in cages) {
            val digits = cage.cells.mapNotNull { cellAt(it).digit }
            if (digits.size == cage.cells.size && digits.toSet().size == digits.size && digits.sum() == cage.sum) {
                completed.add(cage.id)
            }
        }
        return completed
    }

    fun correctlyCompletedRowIndices(): Set<Int> =
        (0..8).filter { row ->
            val digits = (0..8).mapNotNull { cellAt(Coordinate(row, it)).digit }
            digits.size == 9 && digits.toSet().size == 9
        }.toSet()

    fun correctlyCompletedColumnIndices(): Set<Int> =
        (0..8).filter { column ->
            val digits = (0..8).mapNotNull { cellAt(Coordinate(it, column)).digit }
            digits.size == 9 && digits.toSet().size == 9
        }.toSet()

    fun correctlyCompletedBoxIndices(): Set<Int> =
        (0..8).filter { boxIndex ->
            val digits = boxCoordinates(boxIndex).mapNotNull { cellAt(it).digit }
            digits.size == 9 && digits.toSet().size == 9
        }.toSet()

    private fun boxCoordinates(boxIndex: Int): List<Coordinate> {
        val startRow = (boxIndex / 3) * 3
        val startColumn = (boxIndex % 3) * 3
        return buildList {
            for (row in startRow until startRow + 3) {
                for (column in startColumn until startColumn + 3) {
                    add(Coordinate(row, column))
                }
            }
        }
    }
}

/** Returns a new 9x9 grid with just one cell transformed -- avoids repeating the nested-map
 * boilerplate every call site needs for an immutable 2D grid update. */
private fun List<List<Cell>>.withCell(coordinate: Coordinate, transform: (Cell) -> Cell): List<List<Cell>> =
    mapIndexed { r, row ->
        if (r != coordinate.row) row
        else row.mapIndexed { c, cell -> if (c != coordinate.column) cell else transform(cell) }
    }
