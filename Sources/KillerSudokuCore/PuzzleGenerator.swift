/// Generates a fresh, on-device Killer Sudoku puzzle. Classic mode (ADR 0003) is a random solved
/// grid, fully partitioned into normal 2-4 cell cages, with a per-tier count of cells revealed as
/// givens inside whatever cage they already belong to (ADR 0008) — given-density *is* classic
/// mode's difficulty lever. Hybrid mode (issue #3, Beginner only) instead pre-fills a
/// substantially larger, fixed set of givens outside the cage system entirely, per
/// [[CONTEXT.md]]'s classic/hybrid split. This is the app's single public entry point for puzzle
/// generation — everything else in this file's sibling types is implementation detail.
public enum PuzzleGenerator {
    /// ADR 0008's per-tier given-count ranges, out of 81 cells. `.beginner` never appears here —
    /// it always routes to `attemptHybrid` instead. The ungraded app-launch puzzle
    /// (`generate()`, no tier requested) falls back to `.medium`'s range as a reasonable default.
    private static let classicGivensRanges: [Difficulty: ClosedRange<Int>] = [
        .easy: 25...40,
        .medium: 17...24,
        .hard: 9...16,
        .expert: 4...8,
    ]

    /// Hybrid mode's given count (issue #3): "substantially more" than classic mode's densest
    /// tier per CONTEXT.md, while still leaving most of the grid (61 of 81 cells) as real
    /// cage-based killer sudoku play rather than a plain Sudoku with decorative cages.
    private static let hybridGivensCount = 20

    public static func generate() -> Board {
        while true {
            if let board = attemptClassic(requiring: nil) {
                return board
            }
        }
    }

    /// Regenerates until a candidate matches the requested tier. `.beginner` always produces a
    /// hybrid-mode puzzle (issue #3); every other tier is classic mode, regenerated until
    /// [[PuzzleSolver]] confirms exactly one solution — the "New Puzzle" flow (issue #2). Unlike
    /// before ADR 0008, this no longer needs a second retry condition for the tier itself: given-
    /// density is chosen directly from the requested tier's range, not discovered after the fact.
    public static func generate(difficulty: Difficulty) -> Board {
        while true {
            let board = difficulty == .beginner ? attemptHybrid() : attemptClassic(requiring: difficulty)
            if let board { return board }
        }
    }

    /// One classic-mode candidate. Returns nil if cage generation didn't converge or the cage
    /// layout alone isn't uniquely solvable — either just means the caller's retry loop tries a
    /// fresh instance. Uniqueness is checked from the cage structure alone, *before* givens are
    /// chosen: a real Killer Sudoku puzzle is solvable by cage-sum logic on its own, and a given
    /// is a bonus reveal layered on top, not something the puzzle's validity should depend on
    /// (unlike hybrid mode, where givens sit outside the cage system and are load-bearing for
    /// uniqueness by construction — see `attemptHybrid`). Checking cage+givens together here
    /// would let a genuinely ambiguous cage layout slip through whenever the chosen givens
    /// happened to rule out its other solutions.
    private static func attemptClassic(requiring difficulty: Difficulty?) -> Board? {
        let grid = SudokuGridGenerator.generate()
        guard let cages = CageLayoutGenerator.generate(for: grid) else { return nil }
        guard PuzzleSolver.verify(cages: cages, upTo: 2).solutionCount == 1 else { return nil }

        let givenCount = Int.random(in: classicGivensRanges[difficulty ?? .medium]!)
        let givenCoordinates = Set(Coordinate.all.shuffled().prefix(givenCount))
        let givens = Dictionary(uniqueKeysWithValues: givenCoordinates.map { ($0, grid[$0.row][$0.column]) })
        return board(for: cages, givens: givens)
    }

    /// One hybrid-mode candidate: `hybridGivensCount` random cells become givens (outside the
    /// cage system), and the rest of the grid is cage-partitioned exactly as in classic mode.
    /// Beginner isn't graded — any uniquely solvable result is accepted.
    ///
    /// A random given selection can isolate a cell (boxed in by holes/edges with no possible
    /// cage-mate) — a structural dead end for *that* region no amount of retrying fixes, so
    /// `CageLayoutGenerator` giving up (nil) is treated the same as any other failed attempt:
    /// discard everything, including the given selection, and try a fresh one.
    private static func attemptHybrid() -> Board? {
        let grid = SudokuGridGenerator.generate()
        let givenCoordinates = Set(Coordinate.all.shuffled().prefix(hybridGivensCount))
        var region = Set(Coordinate.all)
        region.subtract(givenCoordinates)
        guard let cages = CageLayoutGenerator.cages(for: grid, in: region, startingID: 0) else {
            return nil
        }
        let givens = Dictionary(uniqueKeysWithValues: givenCoordinates.map { ($0, grid[$0.row][$0.column]) })

        let result = PuzzleSolver.verify(cages: cages, givens: givens, upTo: 2)
        guard result.solutionCount == 1 else { return nil }
        return board(for: cages, givens: givens)
    }

    /// Pre-fills every given's digit directly into the initial cell grid — classic mode's givens
    /// (ADR 0008) stay members of their normal cage; hybrid mode's sit outside the cage system —
    /// either way this goes straight into `cells` rather than through `Board.setDigit`, which
    /// would record each as an undoable player edit. Givens aren't a player action; they
    /// shouldn't be undoable.
    private static func board(for cages: [Cage], givens: [Coordinate: Int]) -> Board {
        var cells = Array(repeating: Array(repeating: Cell(), count: 9), count: 9)
        for (coordinate, digit) in givens {
            cells[coordinate.row][coordinate.column] = Cell(digit: digit)
        }
        return Board(cages: cages, cells: cells)
    }
}
