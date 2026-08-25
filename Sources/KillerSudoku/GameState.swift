import Combine
import SwiftData
import SwiftUI
import KillerSudokuCore

/// Shared app-level state so the App scene's `.commands` (Edit menu Undo/Redo, wired to the
/// system keyboard shortcuts Cmd+Z / Cmd+Shift+Z) and `ContentView` operate on the same board.
/// A plain `@State` in `ContentView` alone can't be reached from `.commands`, which lives on the
/// `Scene`, not the view tree.
///
/// Also owns continuous auto-save: every published board change is persisted via
/// `PuzzleStore` (issue #7), so there's no explicit "save" action and no data loss on quit.
@MainActor
final class GameState: ObservableObject {
    @Published var board: Board
    private let modelContext: ModelContext
    private var saveSubscription: AnyCancellable?

    init(board: Board, modelContext: ModelContext) {
        self.board = board
        self.modelContext = modelContext
        // No `.dropFirst()`: a freshly generated (or freshly loaded) board is saved immediately,
        // so "restores the exact in-progress puzzle" holds even before the player's first edit.
        saveSubscription = $board
            .sink { [modelContext] board in
                PuzzleStore.save(board, context: modelContext)
            }
    }
}
