import SwiftUI
import KillerSudokuCore

/// Shared app-level state so the App scene's `.commands` (Edit menu Undo/Redo, wired to the
/// system keyboard shortcuts Cmd+Z / Cmd+Shift+Z) and `ContentView` operate on the same board.
/// A plain `@State` in `ContentView` alone can't be reached from `.commands`, which lives on the
/// `Scene`, not the view tree.
@MainActor
final class GameState: ObservableObject {
    @Published var board: Board

    init(board: Board) {
        self.board = board
    }
}
