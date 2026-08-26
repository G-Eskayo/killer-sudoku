package me.gileskayo.killersudoku.core

import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class BoardTest {
    private fun testCages(): List<Cage> = listOf(
        Cage(id = 0, cells = listOf(Coordinate(0, 0), Coordinate(0, 1)), sum = 8),
        Cage(id = 1, cells = listOf(Coordinate(1, 0), Coordinate(1, 1)), sum = 10),
    )

    @Test
    fun startsWithAllCellsEmpty() {
        val board = Board.blank(testCages())
        for (row in 0..8) for (column in 0..8) {
            assertEquals(null, board.cellAt(Coordinate(row, column)).digit)
        }
    }

    @Test
    fun setDigitUpdatesOnlyThatCell() {
        val board = Board.blank(testCages()).setDigit(7, at = Coordinate(3, 4))
        assertEquals(7, board.cellAt(Coordinate(3, 4)).digit)
        assertEquals(null, board.cellAt(Coordinate(3, 5)).digit)
    }

    @Test
    fun setDigitNilClearsCell() {
        val board = Board.blank(testCages()).setDigit(5, at = Coordinate(2, 2)).setDigit(null, at = Coordinate(2, 2))
        assertEquals(null, board.cellAt(Coordinate(2, 2)).digit)
    }

    @Test
    fun setDigitIsANoOpOnAGivenCellRegardlessOfNewValue() {
        val target = Coordinate(0, 0)
        val cells = List(9) { r -> List(9) { c -> if (r == target.row && c == target.column) Cell(digit = 5, isGiven = true) else Cell() } }
        val board = Board(testCages(), cells)

        val afterOverwrite = board.setDigit(9, at = target)
        assertEquals(5, afterOverwrite.cellAt(target).digit)

        val afterClear = afterOverwrite.setDigit(null, at = target)
        assertEquals(5, afterClear.cellAt(target).digit)
        assertFalse(afterClear.canUndo)
    }

    @Test
    fun settingADigitEliminatesMatchingPencilMarksFromRowColumnAndBoxPeers() {
        val target = Coordinate(3, 3)
        val rowPeer = Coordinate(3, 8)
        val columnPeer = Coordinate(8, 3)
        val boxPeer = Coordinate(4, 4)
        val unrelated = Coordinate(6, 6)

        var board = Board.blank(testCages())
        for (coordinate in listOf(rowPeer, columnPeer, boxPeer, unrelated)) {
            board = board.togglePencilMark(7, at = coordinate)
        }
        board = board.setDigit(7, at = target)

        assertTrue(board.cellAt(rowPeer).pencilMarks.isEmpty())
        assertTrue(board.cellAt(columnPeer).pencilMarks.isEmpty())
        assertTrue(board.cellAt(boxPeer).pencilMarks.isEmpty())
        assertEquals(setOf(7), board.cellAt(unrelated).pencilMarks)
    }

    @Test
    fun undoingADigitSetRestoresEliminatedPencilMarks() {
        val target = Coordinate(3, 3)
        val peer = Coordinate(3, 8)
        var board = Board.blank(testCages()).togglePencilMark(7, at = peer).setDigit(7, at = target)

        board = board.undo()

        assertEquals(null, board.cellAt(target).digit)
        assertEquals(setOf(7), board.cellAt(peer).pencilMarks)
    }

    @Test
    fun togglePencilMarkAddsThenRemoves() {
        val target = Coordinate(0, 0)
        var board = Board.blank(testCages()).togglePencilMark(4, at = target)
        assertEquals(setOf(4), board.cellAt(target).pencilMarks)

        board = board.togglePencilMark(4, at = target)
        assertTrue(board.cellAt(target).pencilMarks.isEmpty())
    }

    @Test
    fun togglePencilMarkIsANoOpWhenTheCellAlreadyHasADigit() {
        val target = Coordinate(0, 0)
        var board = Board.blank(testCages()).setDigit(7, at = target)
        board = board.togglePencilMark(4, at = target)
        assertTrue(board.cellAt(target).pencilMarks.isEmpty())

        board = board.undo()
        assertEquals(null, board.cellAt(target).digit)
    }

    @Test
    fun pencilMarksMadeBeforeADigitSurviveClearingThatDigit() {
        val target = Coordinate(0, 0)
        val board = Board.blank(testCages())
            .togglePencilMark(4, at = target)
            .setDigit(7, at = target)
            .setDigit(null, at = target)
        assertEquals(setOf(4), board.cellAt(target).pencilMarks)
    }

    @Test
    fun clearPencilMarksRemovesEveryMarkInOneCell() {
        val target = Coordinate(0, 0)
        val board = Board.blank(testCages()).togglePencilMark(2, at = target).togglePencilMark(5, at = target)
            .clearPencilMarks(at = target)
        assertTrue(board.cellAt(target).pencilMarks.isEmpty())
    }

    @Test
    fun undoingClearPencilMarksRestoresThem() {
        val target = Coordinate(0, 0)
        var board = Board.blank(testCages()).togglePencilMark(2, at = target).togglePencilMark(5, at = target)
        board = board.clearPencilMarks(at = target)
        board = board.undo()
        assertEquals(setOf(2, 5), board.cellAt(target).pencilMarks)
    }

    @Test
    fun cageAtReturnsOwningCage() {
        val board = Board.blank(testCages())
        assertEquals(0, board.cageAt(Coordinate(0, 0))?.id)
        assertEquals(1, board.cageAt(Coordinate(1, 1))?.id)
        assertEquals(null, board.cageAt(Coordinate(8, 8)))
    }

    @Test
    fun duplicateDigitInSameRowIsMistaken() {
        val a = Coordinate(4, 0)
        val b = Coordinate(4, 5)
        val board = Board.blank(testCages()).setDigit(7, at = a).setDigit(7, at = b)
        assertEquals(setOf(a, b), board.mistakenCoordinates())
    }

    @Test
    fun duplicateDigitInSameCageIsMistaken() {
        val a = Coordinate(0, 0)
        val b = Coordinate(0, 1)
        val board = Board.blank(testCages()).setDigit(4, at = a).setDigit(4, at = b)
        assertEquals(setOf(a, b), board.mistakenCoordinates())
    }

    @Test
    fun cageSumAlreadyExceededIsMistakenBeforeCageIsFull() {
        val a = Coordinate(0, 0)
        val board = Board.blank(testCages()).setDigit(9, at = a)
        assertEquals(setOf(a), board.mistakenCoordinates())
    }

    @Test
    fun fullyFilledCageWithCorrectSumIsNotMistaken() {
        val board = Board.blank(testCages()).setDigit(3, at = Coordinate(0, 0)).setDigit(5, at = Coordinate(0, 1))
        assertTrue(board.mistakenCoordinates().isEmpty())
    }

    @Test
    fun undoWalksBackThroughMultipleEditsNotJustTheLastOne() {
        val target = Coordinate(3, 4)
        var board = Board.blank(testCages()).setDigit(1, at = target).setDigit(2, at = target).setDigit(3, at = target)

        board = board.undo()
        assertEquals(2, board.cellAt(target).digit)
        board = board.undo()
        assertEquals(1, board.cellAt(target).digit)
        board = board.undo()
        assertEquals(null, board.cellAt(target).digit)
    }

    @Test
    fun newEditAfterUndoTruncatesTheRedoStack() {
        val target = Coordinate(3, 4)
        var board = Board.blank(testCages()).setDigit(1, at = target)
        board = board.undo()
        assertTrue(board.canRedo)

        board = board.setDigit(9, at = target)
        assertFalse(board.canRedo)
    }

    @Test
    fun settingTheSameDigitAgainDoesNotAddAnUndoStep() {
        val target = Coordinate(3, 4)
        var board = Board.blank(testCages()).setDigit(5, at = target).setDigit(5, at = target)
        board = board.undo()
        assertEquals(null, board.cellAt(target).digit)
        assertFalse(board.canUndo)
    }

    @Test
    fun isSolvedWhenFullyAndCorrectlyFilled() {
        var board = DemoPuzzle.makeBoard()
        for (row in 0..8) for (column in 0..8) {
            board = board.setDigit(DemoPuzzle.solutionGrid[row][column], at = Coordinate(row, column))
        }
        assertTrue(board.isSolved)
    }

    @Test
    fun isNotSolvedWhenOneCellIsStillEmpty() {
        var board = DemoPuzzle.makeBoard()
        for (row in 0..8) for (column in 0..8) {
            if (row == 0 && column == 0) continue
            board = board.setDigit(DemoPuzzle.solutionGrid[row][column], at = Coordinate(row, column))
        }
        assertFalse(board.isSolved)
    }

    @Test
    fun isNotSolvedWhenFullyFilledButWithAMistake() {
        // Fills everything except (0,1) with the correct solution, then fills (0,1) with a
        // duplicate of (0,0) instead of its own value -- reaching "fully filled but mistaken"
        // without ever passing through a genuinely solved intermediate state, which setDigit
        // refuses to edit further.
        var board = DemoPuzzle.makeBoard()
        val duplicateTarget = Coordinate(0, 1)
        for (row in 0..8) for (column in 0..8) {
            val coordinate = Coordinate(row, column)
            if (coordinate == duplicateTarget) continue
            board = board.setDigit(DemoPuzzle.solutionGrid[row][column], at = coordinate)
        }
        board = board.setDigit(DemoPuzzle.solutionGrid[0][0], at = duplicateTarget)
        assertFalse(board.isSolved)
    }

    @Test
    fun setDigitIsANoOpOnceTheBoardIsSolved() {
        var board = DemoPuzzle.makeBoard()
        for (row in 0..8) for (column in 0..8) {
            board = board.setDigit(DemoPuzzle.solutionGrid[row][column], at = Coordinate(row, column))
        }
        assertTrue(board.isSolved)

        val target = Coordinate(0, 0)
        board = board.setDigit(null, at = target)
        assertEquals(DemoPuzzle.solutionGrid[0][0], board.cellAt(target).digit)
        assertTrue(board.isSolved)
    }

    @Test
    fun undoIsANoOpOnceTheBoardIsSolved() {
        var board = DemoPuzzle.makeBoard()
        for (row in 0..8) for (column in 0..8) {
            board = board.setDigit(DemoPuzzle.solutionGrid[row][column], at = Coordinate(row, column))
        }
        assertTrue(board.isSolved)

        board = board.undo()
        assertTrue(board.isSolved)
        assertEquals(DemoPuzzle.solutionGrid[8][8], board.cellAt(Coordinate(8, 8)).digit)
    }

    @Test
    fun resetClearsPlayerDigitsAndPencilMarksButKeepsGivens() {
        val given = Coordinate(0, 0)
        val cells = List(9) { r -> List(9) { c -> if (r == given.row && c == given.column) Cell(digit = 5, isGiven = true) else Cell() } }
        var board = Board(testCages(), cells)
        val playerCell = Coordinate(3, 4)
        val noteCell = Coordinate(5, 5)
        board = board.setDigit(7, at = playerCell).togglePencilMark(2, at = noteCell)

        board = board.reset()

        assertEquals(5, board.cellAt(given).digit)
        assertEquals(null, board.cellAt(playerCell).digit)
        assertTrue(board.cellAt(noteCell).pencilMarks.isEmpty())
    }

    @Test
    fun resetClearsUndoAndRedoHistory() {
        var board = Board.blank(testCages()).setDigit(7, at = Coordinate(3, 4))
        board = board.undo()
        assertTrue(board.canRedo)

        board = board.reset()
        assertFalse(board.canUndo)
        assertFalse(board.canRedo)
    }

    @Test
    fun correctlyCompletedCageIdsIncludesAFullyAndCorrectlyFilledCage() {
        val board = Board.blank(testCages()).setDigit(3, at = Coordinate(0, 0)).setDigit(5, at = Coordinate(0, 1))
        assertEquals(setOf(0), board.correctlyCompletedCageIds())
    }

    @Test
    fun correctlyCompletedRowIndicesIncludesARowOfNineDistinctDigits() {
        var board = DemoPuzzle.makeBoard()
        for (column in 0..8) {
            board = board.setDigit(DemoPuzzle.solutionGrid[0][column], at = Coordinate(0, column))
        }
        assertEquals(setOf(0), board.correctlyCompletedRowIndices())
    }

    @Test
    fun encodingAndDecodingRoundTripsCagesAndCellContentsButNotUndoHistory() {
        val target = Coordinate(0, 0)
        var board = Board.blank(testCages()).setDigit(6, at = target).togglePencilMark(3, at = Coordinate(1, 0))
        assertTrue(board.canUndo)

        val json = Json.encodeToString(board)
        val restored = Json.decodeFromString<Board>(json)

        assertEquals(board.cages.map { it.id }, restored.cages.map { it.id })
        assertEquals(6, restored.cellAt(target).digit)
        assertEquals(setOf(3), restored.cellAt(Coordinate(1, 0)).pencilMarks)
        assertFalse(restored.canUndo)
    }

    @Test
    fun correctlyCompletedBoxIndicesIncludesABoxOfNineDistinctDigits() {
        var board = DemoPuzzle.makeBoard()
        for (row in 0..2) for (column in 0..2) {
            board = board.setDigit(DemoPuzzle.solutionGrid[row][column], at = Coordinate(row, column))
        }
        assertEquals(setOf(0), board.correctlyCompletedBoxIndices())
    }
}
