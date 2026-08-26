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
    /// usually takes a few seconds even with ADR 0010's parallel batching, so the UI needs a
    /// loading state rather than freezing on the main thread for an explicit user action.
    @Published private(set) var isGeneratingNewPuzzle = false
    /// The tier the current puzzle was requested at. Always a real tier since ADR 0011 — there's
    /// no more "ungraded" puzzle that can't record a solve anywhere. Persisted alongside the
    /// board (issue #9) so a restored puzzle still records to the right tier on completion.
    @Published private(set) var currentDifficulty: Difficulty?
    /// Guards against recording the same completed puzzle twice — `$board` publishes on every
    /// edit, so once a solve is recorded for this puzzle instance, further edits (e.g. an undo
    /// that re-triggers completion) must not record again. Reset whenever a new puzzle starts.
    private var hasRecordedSolve = false
    private let modelContext: ModelContext
    private var saveSubscription: AnyCancellable?

    init(board: Board, difficulty: Difficulty?, modelContext: ModelContext) {
        self.board = board
        self.currentDifficulty = difficulty
        self.modelContext = modelContext
        // A restored board that's already solved (unusual, but possible) shouldn't be recorded
        // as a fresh completion the moment the app launches.
        self.hasRecordedSolve = board.isSolved
        // No `.dropFirst()`: a freshly generated (or freshly loaded) board is saved immediately,
        // so "restores the exact in-progress puzzle" holds even before the player's first edit.
        saveSubscription = $board
            .sink { [weak self] board in
                guard let self else { return }
                PuzzleStore.save(board, difficulty: currentDifficulty, context: modelContext)
                recordSolveIfNeeded(board)
            }
        timer.start()
    }

    /// Records a completed solve exactly once per puzzle instance (issue #9) — only when the
    /// current puzzle has a known difficulty tier, since an ungraded puzzle (the app-launch
    /// case) has nowhere meaningful to record against.
    private func recordSolveIfNeeded(_ board: Board) {
        guard !hasRecordedSolve, board.isSolved, let currentDifficulty else { return }
        hasRecordedSolve = true
        StatsStore.record(difficulty: currentDifficulty, elapsedSeconds: timer.elapsed(), context: modelContext)
    }

    /// Best time and solve count for one tier (issue #9's `StatsView`).
    func stats(for difficulty: Difficulty) -> (bestTime: Double?, solveCount: Int) {
        (StatsStore.bestTime(for: difficulty, context: modelContext), StatsStore.solveCount(for: difficulty, context: modelContext))
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
            currentDifficulty = difficulty
            hasRecordedSolve = false
            board = newBoard
            timer.reset()
            timer.start()
            isGeneratingNewPuzzle = false
        }
    }
}
