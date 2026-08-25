/// Generates a fresh, on-device classic-mode Killer Sudoku puzzle (ADR 0003): a random solved
/// grid, partitioned into cages (with a small constant given baseline — ADR 0006), retried until
/// [[PuzzleSolver]] confirms the cage layout has exactly one solution. This is the app's single
/// public entry point for puzzle generation — everything else in this file's sibling types is
/// implementation detail.
public enum PuzzleGenerator {
    /// ADR 0006's given baseline: 2-4 single-cell cages, constant across every classic-mode
    /// difficulty tier — cage shape/size and required techniques are what actually differentiate
    /// tiers, not how many givens there are.
    private static let givensRange = 2...4

    public static func generate() -> Board {
        while true {
            if let board = attempt(requiring: nil) {
                return board
            }
        }
    }

    /// Regenerates until a candidate both verifies as uniquely solvable *and* grades at the
    /// requested tier (ADR 0007's search-effort signal) — the "New Puzzle" flow (issue #2).
    public static func generate(difficulty: Difficulty) -> Board {
        while true {
            if let board = attempt(requiring: difficulty) {
                return board
            }
        }
    }

    /// One candidate puzzle. Returns nil if it's non-unique, inconclusive within the solver's
    /// node budget, or (when `difficulty` is given) doesn't land in the requested tier — any of
    /// which just means the caller's retry loop tries a fresh instance.
    private static func attempt(requiring difficulty: Difficulty?) -> Board? {
        let grid = SudokuGridGenerator.generate()
        let cages = CageLayoutGenerator.generate(for: grid, givensCount: Int.random(in: givensRange))
        let result = PuzzleSolver.verify(cages: cages, upTo: 2)
        guard result.solutionCount == 1 else { return nil }
        if let difficulty, Difficulty.fromSearchEffort(nodesVisited: result.nodesVisited) != difficulty {
            return nil
        }
        return board(for: cages)
    }

    /// Pre-fills every size-1 (given) cage's digit directly into the initial cell grid — a
    /// size-1 cage's sum *is* that cell's digit, unambiguous by construction — rather than going
    /// through `Board.setDigit`, which would record each as an undoable player edit. Givens
    /// aren't a player action; they shouldn't be undoable.
    private static func board(for cages: [Cage]) -> Board {
        var cells = Array(repeating: Array(repeating: Cell(), count: 9), count: 9)
        for cage in cages where cage.cells.count == 1 {
            let coordinate = cage.cells[0]
            cells[coordinate.row][coordinate.column] = Cell(digit: cage.sum)
        }
        return Board(cages: cages, cells: cells)
    }
}
