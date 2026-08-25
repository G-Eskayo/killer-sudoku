import SwiftUI
import KillerSudokuCore

@main
struct KillerSudokuApp: App {
    @StateObject private var game = GameState(board: PuzzleGenerator.generate())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") { game.board.undo() }
                    .keyboardShortcut("z", modifiers: .command)
                    .disabled(!game.board.canUndo)
                Button("Redo") { game.board.redo() }
                    .keyboardShortcut("z", modifiers: [.command, .shift])
                    .disabled(!game.board.canRedo)
            }
        }
    }
}
