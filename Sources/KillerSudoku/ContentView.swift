import SwiftUI
import KillerSudokuCore

struct ContentView: View {
    @State private var board = DemoPuzzle.makeBoard()
    @State private var selected: Coordinate? = Coordinate(row: 0, column: 0)
    @FocusState private var isFocused: Bool

    private let cellSize: CGFloat = 56

    var body: some View {
        VStack(spacing: 16) {
            Text("Killer Sudoku")
                .font(.title2.weight(.semibold))

            BoardView(board: board, selected: selected, cellSize: cellSize)
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

            Text("Click a cell, then type 1-9. Delete clears. Arrow keys move.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .onAppear { isFocused = true }
    }

    private func handle(keyPress: KeyPress) -> KeyPress.Result {
        guard let selected else { return .ignored }

        if let character = keyPress.characters.first,
           let digit = character.wholeNumberValue,
           (1...9).contains(digit) {
            board.setDigit(digit, at: selected)
            return .handled
        }

        switch keyPress.key {
        case .delete, .deleteForward:
            board.setDigit(nil, at: selected)
            return .handled
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

    private func move(rowDelta: Int, columnDelta: Int) {
        guard let selected else { return }
        let newRow = min(max(selected.row + rowDelta, 0), 8)
        let newColumn = min(max(selected.column + columnDelta, 0), 8)
        self.selected = Coordinate(row: newRow, column: newColumn)
    }
}
