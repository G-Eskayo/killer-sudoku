import Testing
import Foundation
@testable import KillerSudokuCore

@Suite struct CellTests {
    /// Regression test (ADR 0011): a `Cell` encoded before `isGiven` existed has no `isGiven` key
    /// at all. Decoding it must default to `false`, not fail — a failed decode silently discarded
    /// the player's whole saved puzzle via `PuzzleStore.load()`'s `try?`.
    @Test func decodingWithoutAnIsGivenKeyDefaultsToFalse() throws {
        let json = #"{"digit": 7, "pencilMarks": [1, 2]}"#.data(using: .utf8)!
        let cell = try JSONDecoder().decode(Cell.self, from: json)

        #expect(cell.digit == 7)
        #expect(cell.pencilMarks == [1, 2])
        #expect(cell.isGiven == false)
    }

    @Test func decodingWithAnExplicitIsGivenKeyRoundTrips() throws {
        let json = #"{"digit": 3, "pencilMarks": [], "isGiven": true}"#.data(using: .utf8)!
        let cell = try JSONDecoder().decode(Cell.self, from: json)

        #expect(cell.isGiven == true)
    }

    @Test func encodingAndDecodingRoundTripsIsGiven() throws {
        let original = Cell(digit: 5, isGiven: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Cell.self, from: data)

        #expect(decoded.isGiven == true)
    }
}
