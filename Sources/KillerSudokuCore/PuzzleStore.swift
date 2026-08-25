import SwiftData

/// Loads/saves the single in-progress puzzle (see [[SavedPuzzle]]'s doc comment). Undo/redo
/// history is never part of what's saved — a restored board always starts with a clean history.
@MainActor
public enum PuzzleStore {
    public static func load(context: ModelContext) -> (board: Board, difficulty: Difficulty?)? {
        guard let saved = try? context.fetch(FetchDescriptor<SavedPuzzle>()).first else { return nil }
        guard let board = try? saved.decodeBoard() else { return nil }
        return (board, saved.difficulty)
    }

    public static func save(_ board: Board, difficulty: Difficulty?, context: ModelContext) {
        if let existing = try? context.fetch(FetchDescriptor<SavedPuzzle>()).first {
            try? existing.update(with: board, difficulty: difficulty)
        } else if let saved = try? SavedPuzzle(board: board, difficulty: difficulty) {
            context.insert(saved)
        }
        try? context.save()
    }
}
