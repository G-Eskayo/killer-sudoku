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
        // ADR 0012: SolveRecord was missing from this schema entirely -- StatsStore's
        // insert+save silently did nothing (no error, no crash, no data) for every solve ever
        // completed, since the container never knew SolveRecord existed.
        let container: ModelContainer
        do {
            container = try ModelContainer(for: SavedPuzzle.self, SolveRecord.self)
        } catch {
            container = try! ModelContainer(
                for: SavedPuzzle.self, SolveRecord.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }
        modelContainer = container

        let context = ModelContext(container)
        let restored = PuzzleStore.load(context: context)
        // ADR 0011: every puzzle gets a real difficulty tier, never "ungraded" — a solve on a
        // puzzle with no known tier had nowhere to record in StatsStore, which read as "nothing
        // logged" even after genuinely completing a puzzle.
        let difficulty = restored?.difficulty ?? .medium
        let board = restored?.board ?? PuzzleGenerator.generate(difficulty: difficulty)
        _game = StateObject(wrappedValue: GameState(board: board, difficulty: difficulty, modelContext: context))
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
