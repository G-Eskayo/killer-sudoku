import Testing
import Foundation
@testable import KillerSudokuCore

@Suite struct BoardTests {
    static func makeTestCages() -> [Cage] {
        [
            Cage(id: 0, cells: [Coordinate(row: 0, column: 0), Coordinate(row: 0, column: 1)], sum: 8),
            Cage(id: 1, cells: [Coordinate(row: 1, column: 0), Coordinate(row: 1, column: 1)], sum: 10),
        ]
    }

    @Test func startsWithAllCellsEmpty() {
        let board = Board(cages: Self.makeTestCages())
        for row in 0..<9 {
            for column in 0..<9 {
                #expect(board.cell(at: Coordinate(row: row, column: column)).digit == nil)
            }
        }
    }

    @Test func setDigitUpdatesOnlyThatCell() {
        var board = Board(cages: Self.makeTestCages())
        let target = Coordinate(row: 3, column: 4)
        board.setDigit(7, at: target)

        #expect(board.cell(at: target).digit == 7)
        #expect(board.cell(at: Coordinate(row: 3, column: 5)).digit == nil)
    }

    @Test func setDigitNilClearsCell() {
        var board = Board(cages: Self.makeTestCages())
        let target = Coordinate(row: 2, column: 2)
        board.setDigit(5, at: target)
        board.setDigit(nil, at: target)

        #expect(board.cell(at: target).digit == nil)
    }

    @Test func togglePencilMarkAddsThenRemoves() {
        var board = Board(cages: Self.makeTestCages())
        let target = Coordinate(row: 0, column: 0)

        board.togglePencilMark(4, at: target)
        #expect(board.cell(at: target).pencilMarks == [4])

        board.togglePencilMark(4, at: target)
        #expect(board.cell(at: target).pencilMarks.isEmpty)
    }

    /// Regression test: a cell that already shows a digit has no visible room for a pencil mark
    /// (`BoardView.drawPencilMarks` only ever renders marks when `cell.digit == nil`) — toggling
    /// one anyway silently recorded it with no way to see or undo it, which is exactly what made
    /// Shift+digit look broken on any given or already-filled cell.
    @Test func togglePencilMarkIsANoOpWhenTheCellAlreadyHasADigit() {
        var board = Board(cages: Self.makeTestCages())
        let target = Coordinate(row: 0, column: 0)
        board.setDigit(7, at: target)

        board.togglePencilMark(4, at: target)
        #expect(board.cell(at: target).pencilMarks.isEmpty)

        // A true no-op shouldn't add its own undo entry either — undoing once should undo the
        // digit set, not a phantom pencil-mark toggle sitting on top of it.
        board.undo()
        #expect(board.cell(at: target).digit == nil)
    }

    /// A digit cleared later should still surface pencil marks the player made *before* filling
    /// the cell — clearing a digit must not have wiped them.
    @Test func pencilMarksMadeBeforeADigitSurviveClearingThatDigit() {
        var board = Board(cages: Self.makeTestCages())
        let target = Coordinate(row: 0, column: 0)

        board.togglePencilMark(4, at: target)
        board.setDigit(7, at: target)
        board.setDigit(nil, at: target)

        #expect(board.cell(at: target).pencilMarks == [4])
    }

    @Test func cageAtReturnsOwningCage() {
        let board = Board(cages: Self.makeTestCages())

        #expect(board.cage(at: Coordinate(row: 0, column: 0))?.id == 0)
        #expect(board.cage(at: Coordinate(row: 1, column: 1))?.id == 1)
        #expect(board.cage(at: Coordinate(row: 8, column: 8)) == nil)
    }

    @Test func completedDigitsIsEmptyOnAnEmptyBoard() {
        let board = Board(cages: Self.makeTestCages())
        #expect(board.completedDigits().isEmpty)
    }

    @Test func completedDigitsIncludesADigitPlacedInAllNineCells() {
        var board = Board(cages: Self.makeTestCages())
        for row in 0..<9 {
            board.setDigit(3, at: Coordinate(row: row, column: 0))
        }
        #expect(board.completedDigits() == [3])
    }

    @Test func completedDigitsExcludesADigitPlacedFewerThanNineTimes() {
        var board = Board(cages: Self.makeTestCages())
        board.setDigit(5, at: Coordinate(row: 0, column: 0))
        #expect(board.completedDigits().isEmpty)
    }

    @Test func mistakenCoordinatesIsEmptyOnAnEmptyBoard() {
        let board = Board(cages: Self.makeTestCages())
        #expect(board.mistakenCoordinates().isEmpty)
    }

    @Test func duplicateDigitInSameRowIsMistaken() {
        var board = Board(cages: Self.makeTestCages())
        let a = Coordinate(row: 4, column: 0)
        let b = Coordinate(row: 4, column: 5)
        board.setDigit(7, at: a)
        board.setDigit(7, at: b)

        #expect(board.mistakenCoordinates() == [a, b])
    }

    @Test func duplicateDigitInSameColumnIsMistaken() {
        var board = Board(cages: Self.makeTestCages())
        let a = Coordinate(row: 2, column: 6)
        let b = Coordinate(row: 7, column: 6)
        board.setDigit(3, at: a)
        board.setDigit(3, at: b)

        #expect(board.mistakenCoordinates() == [a, b])
    }

    @Test func duplicateDigitInSameBoxIsMistaken() {
        var board = Board(cages: Self.makeTestCages())
        let a = Coordinate(row: 3, column: 3)
        let b = Coordinate(row: 5, column: 5)
        board.setDigit(9, at: a)
        board.setDigit(9, at: b)

        #expect(board.mistakenCoordinates() == [a, b])
    }

    @Test func duplicateDigitInSameCageIsMistaken() {
        var board = Board(cages: Self.makeTestCages())
        let a = Coordinate(row: 0, column: 0)
        let b = Coordinate(row: 0, column: 1)
        board.setDigit(4, at: a)
        board.setDigit(4, at: b)

        #expect(board.mistakenCoordinates() == [a, b])
    }

    @Test func nonDuplicateValidPlacementIsNotMistaken() {
        // Row 3 isn't covered by either test cage, so this only exercises row/column/box rules.
        var board = Board(cages: Self.makeTestCages())
        board.setDigit(1, at: Coordinate(row: 3, column: 0))
        board.setDigit(2, at: Coordinate(row: 3, column: 1))

        #expect(board.mistakenCoordinates().isEmpty)
    }

    @Test func cageSumAlreadyExceededIsMistakenBeforeCageIsFull() {
        // Cage 0 sums to 8 across 2 cells; placing 9 alone already exceeds it.
        var board = Board(cages: Self.makeTestCages())
        let a = Coordinate(row: 0, column: 0)
        board.setDigit(9, at: a)

        #expect(board.mistakenCoordinates() == [a])
    }

    @Test func fullyFilledCageWithWrongSumIsMistaken() {
        // Cage 0 sums to 8 across 2 cells; 3 + 4 = 7, not 8.
        var board = Board(cages: Self.makeTestCages())
        let a = Coordinate(row: 0, column: 0)
        let b = Coordinate(row: 0, column: 1)
        board.setDigit(3, at: a)
        board.setDigit(4, at: b)

        #expect(board.mistakenCoordinates() == [a, b])
    }

    @Test func fullyFilledCageWithCorrectSumIsNotMistaken() {
        // Cage 0 sums to 8 across 2 cells; 3 + 5 = 8.
        var board = Board(cages: Self.makeTestCages())
        board.setDigit(3, at: Coordinate(row: 0, column: 0))
        board.setDigit(5, at: Coordinate(row: 0, column: 1))

        #expect(board.mistakenCoordinates().isEmpty)
    }

    @Test func clearingTheDuplicateDigitResolvesTheMistake() {
        var board = Board(cages: Self.makeTestCages())
        let a = Coordinate(row: 4, column: 0)
        let b = Coordinate(row: 4, column: 5)
        board.setDigit(7, at: a)
        board.setDigit(7, at: b)
        #expect(!board.mistakenCoordinates().isEmpty)

        board.setDigit(nil, at: b)
        #expect(board.mistakenCoordinates().isEmpty)
    }

    @Test func sameDigitCoordinatesIsEmptyWhenSelectedCellIsEmpty() {
        let board = Board(cages: Self.makeTestCages())
        #expect(board.sameDigitCoordinates(as: Coordinate(row: 0, column: 0)).isEmpty)
    }

    @Test func sameDigitCoordinatesIsEmptyWhenDigitHasNoOtherMatches() {
        var board = Board(cages: Self.makeTestCages())
        board.setDigit(6, at: Coordinate(row: 0, column: 0))
        #expect(board.sameDigitCoordinates(as: Coordinate(row: 0, column: 0)).isEmpty)
    }

    @Test func sameDigitCoordinatesFindsOtherCellsWithTheSameDigitButNotItself() {
        var board = Board(cages: Self.makeTestCages())
        let selected = Coordinate(row: 0, column: 0)
        let match = Coordinate(row: 8, column: 8)
        board.setDigit(6, at: selected)
        board.setDigit(6, at: match)

        #expect(board.sameDigitCoordinates(as: selected) == [match])
    }

    @Test func undoingASetDigitRestoresThePreviousValue() {
        var board = Board(cages: Self.makeTestCages())
        let target = Coordinate(row: 3, column: 4)
        board.setDigit(7, at: target)

        board.undo()

        #expect(board.cell(at: target).digit == nil)
    }

    @Test func redoingReappliesTheUndoneDigit() {
        var board = Board(cages: Self.makeTestCages())
        let target = Coordinate(row: 3, column: 4)
        board.setDigit(7, at: target)
        board.undo()

        board.redo()

        #expect(board.cell(at: target).digit == 7)
    }

    @Test func undoWalksBackThroughMultipleEditsNotJustTheLastOne() {
        var board = Board(cages: Self.makeTestCages())
        let target = Coordinate(row: 3, column: 4)
        board.setDigit(1, at: target)
        board.setDigit(2, at: target)
        board.setDigit(3, at: target)

        board.undo()
        #expect(board.cell(at: target).digit == 2)
        board.undo()
        #expect(board.cell(at: target).digit == 1)
        board.undo()
        #expect(board.cell(at: target).digit == nil)
    }

    @Test func newEditAfterUndoTruncatesTheRedoStack() {
        var board = Board(cages: Self.makeTestCages())
        let target = Coordinate(row: 3, column: 4)
        board.setDigit(1, at: target)
        board.undo()
        #expect(board.canRedo)

        board.setDigit(9, at: target)

        #expect(!board.canRedo)
        board.redo()
        #expect(board.cell(at: target).digit == 9)
    }

    @Test func undoingAPencilMarkToggleReTogglesIt() {
        var board = Board(cages: Self.makeTestCages())
        let target = Coordinate(row: 0, column: 0)
        board.togglePencilMark(4, at: target)
        #expect(board.cell(at: target).pencilMarks == [4])

        board.undo()

        #expect(board.cell(at: target).pencilMarks.isEmpty)
    }

    @Test func undoWithNothingToUndoIsANoOp() {
        var board = Board(cages: Self.makeTestCages())
        #expect(!board.canUndo)
        board.undo()
        #expect(board.mistakenCoordinates().isEmpty)
    }

    @Test func settingTheSameDigitAgainDoesNotAddAnUndoStep() {
        var board = Board(cages: Self.makeTestCages())
        let target = Coordinate(row: 3, column: 4)
        board.setDigit(5, at: target)
        board.setDigit(5, at: target)

        board.undo()

        #expect(board.cell(at: target).digit == nil)
        #expect(!board.canUndo)
    }

    @Test func encodingAndDecodingRoundTripsCagesAndCellContents() throws {
        var board = Board(cages: Self.makeTestCages())
        let target = Coordinate(row: 0, column: 0)
        board.setDigit(6, at: target)
        board.togglePencilMark(3, at: Coordinate(row: 1, column: 0))

        let data = try JSONEncoder().encode(board)
        let restored = try JSONDecoder().decode(Board.self, from: data)

        #expect(restored.cages.map(\.id) == board.cages.map(\.id))
        #expect(restored.cell(at: target).digit == 6)
        #expect(restored.cell(at: Coordinate(row: 1, column: 0)).pencilMarks == [3])
    }

    @Test func isNotSolvedOnAFreshBoard() {
        let board = Board(cages: Self.makeTestCages())
        #expect(!board.isSolved)
    }

    @Test func isSolvedWhenFullyAndCorrectlyFilled() {
        var board = Board(cages: DemoPuzzle.makeCages())
        for row in 0..<9 {
            for column in 0..<9 {
                board.setDigit(DemoPuzzle.solutionGrid[row][column], at: Coordinate(row: row, column: column))
            }
        }
        #expect(board.isSolved)
    }

    @Test func isNotSolvedWhenOneCellIsStillEmpty() {
        var board = Board(cages: DemoPuzzle.makeCages())
        for row in 0..<9 {
            for column in 0..<9 where !(row == 0 && column == 0) {
                board.setDigit(DemoPuzzle.solutionGrid[row][column], at: Coordinate(row: row, column: column))
            }
        }
        #expect(!board.isSolved)
    }

    @Test func setDigitIsANoOpOnAGivenCellRegardlessOfNewValue() {
        let target = Coordinate(row: 0, column: 0)
        var cells = Array(repeating: Array(repeating: Cell(), count: 9), count: 9)
        cells[target.row][target.column] = Cell(digit: 5, isGiven: true)
        var board = Board(cages: Self.makeTestCages(), cells: cells)

        board.setDigit(9, at: target)
        #expect(board.cell(at: target).digit == 5)

        board.setDigit(nil, at: target)
        #expect(board.cell(at: target).digit == 5)
        #expect(!board.canUndo)
    }

    /// Placing a digit removes that same digit from pencil marks in every row/column/box peer —
    /// standard "auto-eliminate" behavior. Row 3 isn't covered by either test cage, keeping this
    /// isolated to row/column/box rules.
    @Test func settingADigitEliminatesMatchingPencilMarksFromRowColumnAndBoxPeers() {
        var board = Board(cages: Self.makeTestCages())
        let target = Coordinate(row: 3, column: 3)
        let rowPeer = Coordinate(row: 3, column: 8)
        let columnPeer = Coordinate(row: 8, column: 3)
        let boxPeer = Coordinate(row: 4, column: 4)
        let unrelated = Coordinate(row: 6, column: 6)

        for coordinate in [rowPeer, columnPeer, boxPeer, unrelated] {
            board.togglePencilMark(7, at: coordinate)
        }

        board.setDigit(7, at: target)

        #expect(board.cell(at: rowPeer).pencilMarks.isEmpty)
        #expect(board.cell(at: columnPeer).pencilMarks.isEmpty)
        #expect(board.cell(at: boxPeer).pencilMarks.isEmpty)
        #expect(board.cell(at: unrelated).pencilMarks == [7])
    }

    @Test func settingADigitDoesNotEliminateNonMatchingPencilMarksFromPeers() {
        var board = Board(cages: Self.makeTestCages())
        let target = Coordinate(row: 3, column: 3)
        let peer = Coordinate(row: 3, column: 8)
        board.togglePencilMark(2, at: peer)

        board.setDigit(7, at: target)

        #expect(board.cell(at: peer).pencilMarks == [2])
    }

    @Test func undoingADigitSetRestoresEliminatedPencilMarks() {
        var board = Board(cages: Self.makeTestCages())
        let target = Coordinate(row: 3, column: 3)
        let peer = Coordinate(row: 3, column: 8)
        board.togglePencilMark(7, at: peer)
        board.setDigit(7, at: target)

        board.undo()

        #expect(board.cell(at: target).digit == nil)
        #expect(board.cell(at: peer).pencilMarks == [7])
    }

    @Test func redoingADigitSetReEliminatesPencilMarks() {
        var board = Board(cages: Self.makeTestCages())
        let target = Coordinate(row: 3, column: 3)
        let peer = Coordinate(row: 3, column: 8)
        board.togglePencilMark(7, at: peer)
        board.setDigit(7, at: target)
        board.undo()

        board.redo()

        #expect(board.cell(at: target).digit == 7)
        #expect(board.cell(at: peer).pencilMarks.isEmpty)
    }

    @Test func clearPencilMarksRemovesEveryMarkInOneCell() {
        var board = Board(cages: Self.makeTestCages())
        let target = Coordinate(row: 0, column: 0)
        board.togglePencilMark(2, at: target)
        board.togglePencilMark(5, at: target)

        board.clearPencilMarks(at: target)

        #expect(board.cell(at: target).pencilMarks.isEmpty)
    }

    @Test func clearPencilMarksIsANoOpWhenAlreadyEmpty() {
        var board = Board(cages: Self.makeTestCages())
        board.clearPencilMarks(at: Coordinate(row: 0, column: 0))
        #expect(!board.canUndo)
    }

    @Test func undoingClearPencilMarksRestoresThem() {
        var board = Board(cages: Self.makeTestCages())
        let target = Coordinate(row: 0, column: 0)
        board.togglePencilMark(2, at: target)
        board.togglePencilMark(5, at: target)
        board.clearPencilMarks(at: target)

        board.undo()

        #expect(board.cell(at: target).pencilMarks == [2, 5])
    }

    @Test func correctlyCompletedCageIDsIncludesAFullyAndCorrectlyFilledCage() {
        var board = Board(cages: Self.makeTestCages())
        board.setDigit(3, at: Coordinate(row: 0, column: 0))
        board.setDigit(5, at: Coordinate(row: 0, column: 1))

        #expect(board.correctlyCompletedCageIDs() == [0])
    }

    @Test func correctlyCompletedCageIDsExcludesAPartiallyFilledCage() {
        var board = Board(cages: Self.makeTestCages())
        board.setDigit(3, at: Coordinate(row: 0, column: 0))

        #expect(board.correctlyCompletedCageIDs().isEmpty)
    }

    @Test func correctlyCompletedCageIDsExcludesAFullCageWithTheWrongSum() {
        var board = Board(cages: Self.makeTestCages())
        board.setDigit(1, at: Coordinate(row: 0, column: 0))
        board.setDigit(2, at: Coordinate(row: 0, column: 1))

        #expect(board.correctlyCompletedCageIDs().isEmpty)
    }

    @Test func correctlyCompletedRowIndicesIncludesARowOfNineDistinctDigits() {
        var board = Board(cages: DemoPuzzle.makeCages())
        for column in 0..<9 {
            board.setDigit(DemoPuzzle.solutionGrid[0][column], at: Coordinate(row: 0, column: column))
        }

        #expect(board.correctlyCompletedRowIndices() == [0])
    }

    @Test func correctlyCompletedRowIndicesExcludesAnIncompleteRow() {
        var board = Board(cages: DemoPuzzle.makeCages())
        for column in 0..<8 {
            board.setDigit(DemoPuzzle.solutionGrid[0][column], at: Coordinate(row: 0, column: column))
        }

        #expect(board.correctlyCompletedRowIndices().isEmpty)
    }

    @Test func correctlyCompletedColumnIndicesIncludesAColumnOfNineDistinctDigits() {
        var board = Board(cages: DemoPuzzle.makeCages())
        for row in 0..<9 {
            board.setDigit(DemoPuzzle.solutionGrid[row][0], at: Coordinate(row: row, column: 0))
        }

        #expect(board.correctlyCompletedColumnIndices() == [0])
    }

    @Test func correctlyCompletedBoxIndicesIncludesABoxOfNineDistinctDigits() {
        var board = Board(cages: DemoPuzzle.makeCages())
        for row in 0..<3 {
            for column in 0..<3 {
                board.setDigit(DemoPuzzle.solutionGrid[row][column], at: Coordinate(row: row, column: column))
            }
        }

        #expect(board.correctlyCompletedBoxIndices() == [0])
    }

    @Test func isNotSolvedWhenFullyFilledButWithAMistake() {
        var board = Board(cages: DemoPuzzle.makeCages())
        for row in 0..<9 {
            for column in 0..<9 {
                board.setDigit(DemoPuzzle.solutionGrid[row][column], at: Coordinate(row: row, column: column))
            }
        }
        // Swap two digits within row 0 so the row still has all 9 cells filled but now has a
        // duplicate (a real mistake, not just "different from the known solution").
        board.setDigit(DemoPuzzle.solutionGrid[0][0], at: Coordinate(row: 0, column: 1))

        #expect(!board.isSolved)
    }
}
