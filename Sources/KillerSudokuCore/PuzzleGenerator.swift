/// Generates a fresh, on-device classic-mode Killer Sudoku puzzle (ADR 0003): a random solved
/// grid, partitioned into cages, retried until [[PuzzleSolver]] confirms the cage layout alone
/// (no givens) has exactly one solution. This is the app's single public entry point for puzzle
/// generation — everything else in this file's sibling types is implementation detail.
public enum PuzzleGenerator {
    public static func generate() -> Board {
        while true {
            let grid = SudokuGridGenerator.generate()
            let cages = CageLayoutGenerator.generate(for: grid)
            // countSolutions returns nil when verification is inconclusive within its node
            // budget (some random layouts are genuinely expensive to prove either way) — treated
            // the same as a confirmed non-unique layout: discard and try a fresh instance rather
            // than fight one hard candidate to the end.
            if PuzzleSolver.countSolutions(cages: cages, upTo: 2) == 1 {
                return Board(cages: cages)
            }
        }
    }
}
