import SwiftData

/// Loads/saves the single in-progress puzzle (see [[SavedPuzzle]]'s doc comment). Undo/redo
/// history is never part of what's saved — a restored board always starts with a clean history.
@MainActor
public enum PuzzleStore {
    public static func load(context: ModelContext) -> Board? {
        guard let saved = try? context.fetch(FetchDescriptor<SavedPuzzle>()).first else { return nil }
        return try? saved.decodeBoard()
    }

    public static func save(_ board: Board, context: ModelContext) {
        if let existing = try? context.fetch(FetchDescriptor<SavedPuzzle>()).first {
            try? existing.update(with: board)
        } else if let saved = try? SavedPuzzle(board: board) {
            context.insert(saved)
        }
        try? context.save()
    }
}
