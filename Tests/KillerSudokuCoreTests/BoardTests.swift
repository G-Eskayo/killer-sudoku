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
}
