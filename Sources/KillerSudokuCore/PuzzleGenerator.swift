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
            let grid = SudokuGridGenerator.generate()
            let cages = CageLayoutGenerator.generate(for: grid, givensCount: Int.random(in: givensRange))
            // countSolutions returns nil when verification is inconclusive within its node
            // budget (some random layouts are genuinely expensive to prove either way) — treated
            // the same as a confirmed non-unique layout: discard and try a fresh instance rather
            // than fight one hard candidate to the end.
            if PuzzleSolver.countSolutions(cages: cages, upTo: 2) == 1 {
                return board(for: cages)
            }
        }
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
