/// Generates a fresh, on-device Killer Sudoku puzzle: a random solved grid (ADR 0003), fully
/// partitioned into normal 2-4 cell cages, with a per-tier count of cells revealed as givens
/// inside whatever cage they already belong to (ADR 0008) — given-density *is* the difficulty
/// lever. Hybrid/Beginner mode (issue #3) was removed in ADR 0009: this is now the only mode.
/// This is the app's single public entry point for puzzle generation — everything else in this
/// file's sibling types is implementation detail.
public enum PuzzleGenerator {
    /// ADR 0008's per-tier given-count ranges, out of 81 cells. The ungraded app-launch puzzle
    /// (`generate()`, no tier requested) falls back to `.medium`'s range as a reasonable default.
    private static let classicGivensRanges: [Difficulty: ClosedRange<Int>] = [
        .easy: 25...40,
        .medium: 17...24,
        .hard: 9...16,
        .expert: 4...8,
    ]

    public static func generate() -> Board {
        while true {
            if let board = attemptClassic(requiring: nil) {
                return board
            }
        }
    }

    /// Regenerates until [[PuzzleSolver]] confirms exactly one solution — the "New Puzzle" flow
    /// (issue #2). Given-density is chosen directly from the requested tier's range, not
    /// discovered after the fact, so this never needs a second retry condition for the tier
    /// itself (ADR 0008).
    public static func generate(difficulty: Difficulty) -> Board {
        while true {
            if let board = attemptClassic(requiring: difficulty) {
                return board
            }
        }
    }

    /// One candidate. Returns nil if cage generation didn't converge or the cage layout alone
    /// isn't uniquely solvable — either just means the caller's retry loop tries a fresh
    /// instance. Uniqueness is checked from the cage structure alone, *before* givens are chosen:
    /// a real Killer Sudoku puzzle is solvable by cage-sum logic on its own, and a given is a
    /// bonus reveal layered on top, not something the puzzle's validity should depend on.
    /// Checking cage+givens together here would let a genuinely ambiguous cage layout slip
    /// through whenever the chosen givens happened to rule out its other solutions.
    private static func attemptClassic(requiring difficulty: Difficulty?) -> Board? {
        let grid = SudokuGridGenerator.generate()
        guard let cages = CageLayoutGenerator.generate(for: grid) else { return nil }
        guard PuzzleSolver.verify(cages: cages, upTo: 2).solutionCount == 1 else { return nil }

        let givenCount = Int.random(in: classicGivensRanges[difficulty ?? .medium]!)
        let givenCoordinates = Set(Coordinate.all.shuffled().prefix(givenCount))
        let givens = Dictionary(uniqueKeysWithValues: givenCoordinates.map { ($0, grid[$0.row][$0.column]) })
        return board(for: cages, givens: givens)
    }

    /// Pre-fills every given's digit directly into the initial cell grid, as a normal member of
    /// its cage (ADR 0008) — rather than through `Board.setDigit`, which would record each as an
    /// undoable player edit. Givens aren't a player action; they shouldn't be undoable.
    private static func board(for cages: [Cage], givens: [Coordinate: Int]) -> Board {
        var cells = Array(repeating: Array(repeating: Cell(), count: 9), count: 9)
        for (coordinate, digit) in givens {
            cells[coordinate.row][coordinate.column] = Cell(digit: digit)
        }
        return Board(cages: cages, cells: cells)
    }
}
