import Testing
import SwiftData
@testable import KillerSudokuCore

@Suite struct PuzzleStoreTests {
    private static func makeInMemoryContext() -> ModelContext {
        let container = try! ModelContainer(
            for: SavedPuzzle.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test @MainActor func loadReturnsNilWhenNothingSavedYet() {
        let context = Self.makeInMemoryContext()
        #expect(PuzzleStore.load(context: context) == nil)
    }

    @Test @MainActor func savedBoardRoundTripsWithCellContentsIntact() {
        let context = Self.makeInMemoryContext()
        var board = Board(cages: BoardTests.makeTestCages())
        let target = Coordinate(row: 0, column: 0)
        board.setDigit(6, at: target)

        PuzzleStore.save(board, context: context)
        let restored = PuzzleStore.load(context: context)

        #expect(restored?.cell(at: target).digit == 6)
    }

    @Test @MainActor func savingAgainReplacesTheSinglePuzzleRatherThanAddingAnother() throws {
        let context = Self.makeInMemoryContext()
        var board = Board(cages: BoardTests.makeTestCages())
        let target = Coordinate(row: 0, column: 0)
        board.setDigit(1, at: target)
        PuzzleStore.save(board, context: context)

        board.setDigit(9, at: target)
        PuzzleStore.save(board, context: context)

        #expect(try context.fetchCount(FetchDescriptor<SavedPuzzle>()) == 1)
        #expect(PuzzleStore.load(context: context)?.cell(at: target).digit == 9)
    }
}
