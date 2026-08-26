import Foundation
import SwiftData

/// The single in-progress puzzle, persisted locally. Per v1-scope.md there's only ever one
/// active puzzle at a time — starting a new puzzle replaces this record rather than adding
/// another, so [[PuzzleStore]] never lets more than one exist.
@Model
public final class SavedPuzzle {
    public var boardData: Data
    public var updatedAt: Date
    /// The tier this puzzle was requested at via "New Puzzle" (issue #2/#9) — kept alongside the
    /// board so a puzzle restored after relaunch still records to the right tier in [[StatsStore]]
    /// on completion. Stored as a raw `Int` rather than `Difficulty` directly for the same reason
    /// [[SolveRecord]] does (see its doc comment) — and ADR 0011 is the reason that reason
    /// actually matters: an implicit raw value silently reinterprets as a *different* tier if the
    /// case list ever changes, rather than failing to decode. Optional only for old records
    /// predating ADR 0011's "always a real tier" guarantee; `PuzzleStore`/`KillerSudokuApp`
    /// default a nil read to `.medium` rather than ever passing nil onward.
    public var difficultyRawValue: Int?

    public init(board: Board, difficulty: Difficulty?) throws {
        self.boardData = try JSONEncoder().encode(board)
        self.updatedAt = Date()
        self.difficultyRawValue = difficulty?.rawValue
    }

    public func update(with board: Board, difficulty: Difficulty?) throws {
        self.boardData = try JSONEncoder().encode(board)
        self.updatedAt = Date()
        self.difficultyRawValue = difficulty?.rawValue
    }

    public func decodeBoard() throws -> Board {
        try JSONDecoder().decode(Board.self, from: boardData)
    }

    public var difficulty: Difficulty? {
        difficultyRawValue.flatMap { Difficulty(rawValue: $0) }
    }
}
