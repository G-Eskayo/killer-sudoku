import SwiftUI
import KillerSudokuCore

struct ContentView: View {
    @EnvironmentObject private var game: GameState
    @State private var selected: Coordinate? = Coordinate(row: 0, column: 0)
    @State private var showingStats = false
    @State private var completionSnapshot: CompletionSnapshot?
    @State private var showingResetConfirmation = false
    @FocusState private var isFocused: Bool

    private let cellSize: CGFloat = 56

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Text("Killer Sudoku")
                    .font(.title2.weight(.semibold))
                HStack {
                    NewPuzzleMenu(isGenerating: game.isGeneratingNewPuzzle) { difficulty in
                        game.startNewPuzzle(difficulty: difficulty)
                    }
                    if let currentDifficulty = game.currentDifficulty {
                        Text(currentDifficulty.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        game.board.undo()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .disabled(!game.board.canUndo)
                    .help("Undo last move")
                    Button {
                        showingResetConfirmation = true
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Reset puzzle")
                    .confirmationDialog(
                        "Reset this puzzle?", isPresented: $showingResetConfirmation, titleVisibility: .visible
                    ) {
                        Button("Reset", role: .destructive) { game.resetPuzzle() }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This clears every digit and note you've entered. The puzzle itself stays the same.")
                    }
                    TimerView(timer: game.timer) { game.toggleTimer() }
                    Button {
                        showingStats = true
                    } label: {
                        Image(systemName: "chart.bar")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .popover(isPresented: $showingStats) {
                        StatsView(game: game)
                    }
                }
            }

            BoardView(board: game.board, selected: selected, cellSize: cellSize)
                .gesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            let column = Int(value.location.x / cellSize)
                            let row = Int(value.location.y / cellSize)
                            guard (0..<9).contains(row), (0..<9).contains(column) else { return }
                            selected = Coordinate(row: row, column: column)
                        }
                )
                .focusable()
                .focused($isFocused)
                .onKeyPress(action: handle(keyPress:))

            CompletionLegendView(completedDigits: game.board.completedDigits())

            Text("Click a cell, then type 1-9. Shift+1-9 toggles a pencil mark instead. Delete clears. Arrow keys move.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .onAppear { isFocused = true }
        .onChange(of: game.board.isSolved) { _, isSolved in
            // Fires only on a genuine false->true transition while this view is live, not for
            // an already-solved puzzle restored at launch (SwiftUI's default `onChange` doesn't
            // fire for the initial value) — same guarantee `GameState.hasRecordedSolve` and
            // `BoardView`'s completion flourish already rely on.
            guard isSolved, let difficulty = game.currentDifficulty else { return }
            let stats = game.stats(for: difficulty)
            completionSnapshot = CompletionSnapshot(
                difficulty: difficulty, elapsedSeconds: game.timer.elapsed(),
                bestTime: stats.bestTime, solveCount: stats.solveCount
            )
        }
        .sheet(item: $completionSnapshot) { snapshot in
            CompletionView(snapshot: snapshot) { tier in
                game.startNewPuzzle(difficulty: tier)
            }
        }
        // The only way out is picking a New Puzzle tier — no Escape-key or click-outside
        // dismissal back to a "finished" board (which `Board`'s own solved-lock now also
        // refuses to let you edit further anyway; this keeps the UI consistent with that).
        .interactiveDismissDisabled(completionSnapshot != nil)
    }

    private func handle(keyPress: KeyPress) -> KeyPress.Result {
        guard let selected, !game.isGeneratingNewPuzzle else { return .ignored }

        if isDelete(keyPress) {
            // Pausing the timer should mean pausing the game — editing the board while paused
            // let you keep solving on a clock that isn't counting it, which defeats the point
            // of a pausable timer. Arrow-key navigation below stays allowed even while paused;
            // only actions that change the board are blocked.
            guard game.timer.isRunning else { return .handled }
            if game.board.cell(at: selected).digit != nil {
                game.board.setDigit(nil, at: selected)
            } else {
                game.board.clearPencilMarks(at: selected)
            }
            return .handled
        }

        let shiftHeld = keyPress.modifiers.contains(.shift)
        // `key.character` is *not* the unshifted base key despite its name — on a US keyboard,
        // Shift+3 delivers "#", not "3". `DigitKeyInput` resolves either case correctly.
        if let digit = DigitKeyInput.resolve(character: keyPress.key.character, shiftHeld: shiftHeld) {
            guard game.timer.isRunning else { return .handled }
            if shiftHeld {
                game.board.togglePencilMark(digit, at: selected)
            } else {
                game.board.setDigit(digit, at: selected)
            }
            return .handled
        }

        switch keyPress.key {
        case .upArrow:
            move(rowDelta: -1, columnDelta: 0)
            return .handled
        case .downArrow:
            move(rowDelta: 1, columnDelta: 0)
            return .handled
        case .leftArrow:
            move(rowDelta: 0, columnDelta: -1)
            return .handled
        case .rightArrow:
            move(rowDelta: 0, columnDelta: 1)
            return .handled
        default:
            return .ignored
        }
    }

    /// `KeyEquivalent.delete`/`.deleteForward` don't reliably match the Mac Backspace key's
    /// actual runtime character (historically ambiguous between BS 0x08 and DEL 0x7F) - checking
    /// the raw character scalar directly is the fallback that actually works.
    private func isDelete(_ keyPress: KeyPress) -> Bool {
        if keyPress.key == .delete || keyPress.key == .deleteForward {
            return true
        }
        if let scalar = keyPress.characters.unicodeScalars.first {
            return scalar.value == 0x7F || scalar.value == 0x08
        }
        return false
    }

    private func move(rowDelta: Int, columnDelta: Int) {
        guard let selected else { return }
        let newRow = min(max(selected.row + rowDelta, 0), 8)
        let newColumn = min(max(selected.column + columnDelta, 0), 8)
        self.selected = Coordinate(row: newRow, column: newColumn)
    }
}
