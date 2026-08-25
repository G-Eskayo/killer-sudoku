/// Produces a random, fully-solved, valid 9x9 Sudoku grid (every row, column, and 3x3 box a
/// permutation of 1-9) via randomized backtracking. Used as the seed grid for cage-based puzzle
/// generation ([[PuzzleGenerator]]) — the running `Board` never sees this grid directly.
public enum SudokuGridGenerator {
    public static func generate() -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        let filled = fill(&grid, at: 0)
        precondition(filled, "backtracking search must always find a solution for an empty grid")
        return grid
    }

    private static func fill(_ grid: inout [[Int]], at position: Int) -> Bool {
        guard position < 81 else { return true }
        let row = position / 9
        let column = position % 9

        for digit in (1...9).shuffled() where SudokuRules.canPlace(digit, at: row, column, in: grid) {
            grid[row][column] = digit
            if fill(&grid, at: position + 1) { return true }
            grid[row][column] = 0
        }
        return false
    }
}
