/// Standard Sudoku row/column/3x3-box uniqueness check, shared by anything that needs to place a
/// digit into a partially-filled 9x9 grid: [[SudokuGridGenerator]] and [[PuzzleSolver]].
enum SudokuRules {
    static func canPlace(_ digit: Int, at row: Int, _ column: Int, in grid: [[Int]]) -> Bool {
        for otherColumn in 0..<9 where grid[row][otherColumn] == digit { return false }
        for otherRow in 0..<9 where grid[otherRow][column] == digit { return false }

        let boxRow = (row / 3) * 3
        let boxColumn = (column / 3) * 3
        for r in boxRow..<(boxRow + 3) {
            for c in boxColumn..<(boxColumn + 3) where grid[r][c] == digit { return false }
        }
        return true
    }
}
