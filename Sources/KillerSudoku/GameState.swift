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
    /// Per issue #8: visible, pausable, resets on a new puzzle — deliberately not persisted
    /// itself (unlike `board`), so it always starts fresh at app launch regardless of whether
    /// the puzzle was restored. A future stats slice (#9) reads `elapsed()` on completion; it
    /// doesn't own storage here.
    @Published var timer = PuzzleTimer()
    /// True while a New Puzzle request (issue #2) is generating in the background — generation
    /// can take anywhere from well under a second to tens of seconds (ADR 0007), so the UI needs
    /// a loading state rather than freezing on the main thread for an explicit user action.
    @Published private(set) var isGeneratingNewPuzzle = false
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
        timer.start()
    }

    func toggleTimer() {
        if timer.isRunning {
            timer.pause()
        } else {
            timer.start()
        }
    }

    /// Starts a fresh puzzle at the requested difficulty (issue #2), replacing whatever was in
    /// progress — the single-active-puzzle model from v1-scope.md. Generation runs off the main
    /// actor so the UI stays responsive; `isGeneratingNewPuzzle` lets the view show that. A new
    /// `Board` value naturally starts with empty undo/redo history (nothing to carry over), and
    /// the timer restarts per issue #8's "resets when a new puzzle starts".
    func startNewPuzzle(difficulty: Difficulty) {
        guard !isGeneratingNewPuzzle else { return }
        isGeneratingNewPuzzle = true
        Task {
            let newBoard = await Task.detached(priority: .userInitiated) {
                PuzzleGenerator.generate(difficulty: difficulty)
            }.value
            board = newBoard
            timer.reset()
            timer.start()
            isGeneratingNewPuzzle = false
        }
    }
}
