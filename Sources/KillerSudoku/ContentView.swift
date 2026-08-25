import SwiftUI
import KillerSudokuCore

struct ContentView: View {
    @EnvironmentObject private var game: GameState
    @State private var selected: Coordinate? = Coordinate(row: 0, column: 0)
    @State private var showingStats = false
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
                    Spacer()
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
    }

    private func handle(keyPress: KeyPress) -> KeyPress.Result {
        guard let selected, !game.isGeneratingNewPuzzle else { return .ignored }

        if isDelete(keyPress) {
            game.board.setDigit(nil, at: selected)
            return .handled
        }

        // Use `key.character` (the unshifted base key) rather than `characters`, which reflects
        // shift-processed output (e.g. Shift+1 produces "!", not "1") and would break note entry.
        if let digit = keyPress.key.character.wholeNumberValue, (1...9).contains(digit) {
            if keyPress.modifiers.contains(.shift) {
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
