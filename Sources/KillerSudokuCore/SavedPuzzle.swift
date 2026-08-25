import Foundation
import SwiftData

/// The single in-progress puzzle, persisted locally. Per v1-scope.md there's only ever one
/// active puzzle at a time — starting a new puzzle replaces this record rather than adding
/// another, so [[PuzzleStore]] never lets more than one exist.
@Model
public final class SavedPuzzle {
    public var boardData: Data
    public var updatedAt: Date

    public init(board: Board) throws {
        self.boardData = try JSONEncoder().encode(board)
        self.updatedAt = Date()
    }

    public func update(with board: Board) throws {
        self.boardData = try JSONEncoder().encode(board)
        self.updatedAt = Date()
    }

    public func decodeBoard() throws -> Board {
        try JSONDecoder().decode(Board.self, from: boardData)
    }
}
