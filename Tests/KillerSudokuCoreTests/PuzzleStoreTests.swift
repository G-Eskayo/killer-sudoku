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

        PuzzleStore.save(board, difficulty: nil, context: context)
        let restored = PuzzleStore.load(context: context)

        #expect(restored?.board.cell(at: target).digit == 6)
    }

    @Test @MainActor func savingAgainReplacesTheSinglePuzzleRatherThanAddingAnother() throws {
        let context = Self.makeInMemoryContext()
        var board = Board(cages: BoardTests.makeTestCages())
        let target = Coordinate(row: 0, column: 0)
        board.setDigit(1, at: target)
        PuzzleStore.save(board, difficulty: nil, context: context)

        board.setDigit(9, at: target)
        PuzzleStore.save(board, difficulty: nil, context: context)

        #expect(try context.fetchCount(FetchDescriptor<SavedPuzzle>()) == 1)
        #expect(PuzzleStore.load(context: context)?.board.cell(at: target).digit == 9)
    }

    @Test @MainActor func savedDifficultyRoundTrips() {
        let context = Self.makeInMemoryContext()
        let board = Board(cages: BoardTests.makeTestCages())

        PuzzleStore.save(board, difficulty: .hard, context: context)

        #expect(PuzzleStore.load(context: context)?.difficulty == .hard)
    }

    @Test @MainActor func savedDifficultyIsNilWhenTheCurrentPuzzleHasNoKnownTier() {
        let context = Self.makeInMemoryContext()
        let board = Board(cages: BoardTests.makeTestCages())

        PuzzleStore.save(board, difficulty: nil, context: context)

        #expect(PuzzleStore.load(context: context)?.difficulty == nil)
    }

    @Test @MainActor func savingAgainReplacesTheStoredDifficultyToo() {
        let context = Self.makeInMemoryContext()
        let board = Board(cages: BoardTests.makeTestCages())
        PuzzleStore.save(board, difficulty: .easy, context: context)

        PuzzleStore.save(board, difficulty: .expert, context: context)

        #expect(PuzzleStore.load(context: context)?.difficulty == .expert)
    }
}
