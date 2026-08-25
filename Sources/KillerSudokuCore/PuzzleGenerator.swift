/// Generates a fresh, on-device Killer Sudoku puzzle. Classic mode (ADR 0003) is a random solved
/// grid partitioned into cages with a small constant given baseline (ADR 0006), retried until
/// [[PuzzleSolver]] confirms exactly one solution; hybrid mode (issue #3, Beginner only) instead
/// pre-fills a substantially larger set of givens outside the cage system entirely, per
/// [[CONTEXT.md]]'s classic/hybrid split. This is the app's single public entry point for puzzle
/// generation — everything else in this file's sibling types is implementation detail.
public enum PuzzleGenerator {
    /// ADR 0006's given baseline: 2-4 single-cell cages, constant across every classic-mode
    /// difficulty tier — cage shape/size and required techniques are what actually differentiate
    /// tiers, not how many givens there are.
    private static let classicGivensRange = 2...4

    /// Hybrid mode's given count (issue #3): "substantially more" than classic mode's baseline
    /// per CONTEXT.md, while still leaving most of the grid (61 of 81 cells) as real cage-based
    /// killer sudoku play rather than a plain Sudoku with decorative cages.
    private static let hybridGivensCount = 20

    public static func generate() -> Board {
        while true {
            if let board = attemptClassic(requiring: nil) {
                return board
            }
        }
    }

    /// Regenerates until a candidate matches the requested tier. `.beginner` always produces a
    /// hybrid-mode puzzle (issue #3); every other tier is classic mode, regenerated until it both
    /// verifies as uniquely solvable *and* grades at the requested difficulty (ADR 0007's
    /// search-effort signal) — the "New Puzzle" flow (issue #2).
    public static func generate(difficulty: Difficulty) -> Board {
        while true {
            let board = difficulty == .beginner ? attemptHybrid() : attemptClassic(requiring: difficulty)
            if let board { return board }
        }
    }

    /// One classic-mode candidate. Returns nil if cage generation didn't converge, the layout is
    /// non-unique, verification was inconclusive within the solver's node budget, or (when
    /// `difficulty` is given) it doesn't land in the requested tier — any of which just means the
    /// caller's retry loop tries a fresh instance.
    private static func attemptClassic(requiring difficulty: Difficulty?) -> Board? {
        let grid = SudokuGridGenerator.generate()
        guard let cages = CageLayoutGenerator.generate(for: grid, givensCount: Int.random(in: classicGivensRange)) else {
            return nil
        }
        let result = PuzzleSolver.verify(cages: cages, upTo: 2)
        guard result.solutionCount == 1 else { return nil }
        if let difficulty, Difficulty.fromSearchEffort(nodesVisited: result.nodesVisited) != difficulty {
            return nil
        }
        return classicBoard(for: cages)
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
        return hybridBoard(for: cages, givens: givens)
    }

    /// Pre-fills every size-1 (given) cage's digit directly into the initial cell grid — a
    /// size-1 cage's sum *is* that cell's digit, unambiguous by construction — rather than going
    /// through `Board.setDigit`, which would record each as an undoable player edit. Givens
    /// aren't a player action; they shouldn't be undoable.
    private static func classicBoard(for cages: [Cage]) -> Board {
        var cells = Array(repeating: Array(repeating: Cell(), count: 9), count: 9)
        for cage in cages where cage.cells.count == 1 {
            let coordinate = cage.cells[0]
            cells[coordinate.row][coordinate.column] = Cell(digit: cage.sum)
        }
        return Board(cages: cages, cells: cells)
    }

    private static func hybridBoard(for cages: [Cage], givens: [Coordinate: Int]) -> Board {
        var cells = Array(repeating: Array(repeating: Cell(), count: 9), count: 9)
        for (coordinate, digit) in givens {
            cells[coordinate.row][coordinate.column] = Cell(digit: digit)
        }
        return Board(cages: cages, cells: cells)
    }
}
