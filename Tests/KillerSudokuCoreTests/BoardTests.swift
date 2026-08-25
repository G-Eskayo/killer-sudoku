import Testing
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
}
