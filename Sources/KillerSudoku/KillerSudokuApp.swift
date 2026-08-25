import SwiftData
import SwiftUI
import KillerSudokuCore

@main
struct KillerSudokuApp: App {
    private let modelContainer: ModelContainer
    @StateObject private var game: GameState

    init() {
        // Falls back to an in-memory store if the on-disk container can't be created (e.g. a
        // corrupted store from an earlier schema) rather than crashing on launch — the player
        // just loses their saved puzzle for this run instead of being locked out entirely.
        let container: ModelContainer
        do {
            container = try ModelContainer(for: SavedPuzzle.self)
        } catch {
            container = try! ModelContainer(
                for: SavedPuzzle.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }
        modelContainer = container

        let context = ModelContext(container)
        let board = PuzzleStore.load(context: context) ?? PuzzleGenerator.generate()
        _game = StateObject(wrappedValue: GameState(board: board, modelContext: context))
    }

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
