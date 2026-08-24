/// Bootstrap fixture data for the local dev build (issues #2/#3 in the v1 breakdown), standing
/// in for the real puzzle generator (ADR 0003 / issue #11) which doesn't exist yet.
///
/// `solutionGrid` is a known-valid completed Sudoku grid, used only to derive correct cage sums
/// below — the running `Board` never sees it. Cage groups are deliberately kept within single
/// rows so "no repeated digit in a cage" holds automatically (a Sudoku row is always all-distinct
/// digits), rather than risking a hand-picked irregular shape crossing rows/columns/boxes.
public enum DemoPuzzle {
    static let solutionGrid: [[Int]] = [
        [5, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        [1, 9, 8, 3, 4, 2, 5, 6, 7],
        [8, 5, 9, 7, 6, 1, 4, 2, 3],
        [4, 2, 6, 8, 5, 3, 7, 9, 1],
        [7, 1, 3, 9, 2, 4, 8, 5, 6],
        [9, 6, 1, 5, 3, 7, 2, 8, 4],
        [2, 8, 7, 4, 1, 9, 6, 3, 5],
        [3, 4, 5, 2, 8, 6, 1, 7, 9],
    ]

    /// Cage sizes per row, left to right. Each row's sizes sum to 9, every size is 2-4.
    static let rowCageSizes: [[Int]] = [
        [2, 3, 4],
        [4, 2, 3],
        [3, 3, 3],
        [2, 2, 2, 3],
        [4, 3, 2],
        [3, 4, 2],
        [2, 4, 3],
        [3, 2, 4],
        [2, 3, 2, 2],
    ]

    public static let cageCellGroups: [[Coordinate]] = {
        var groups: [[Coordinate]] = []
        for row in 0..<9 {
            var column = 0
            for size in rowCageSizes[row] {
                let group = (column..<(column + size)).map { Coordinate(row: row, column: $0) }
                groups.append(group)
                column += size
            }
        }
        return groups
    }()

    public static func makeCages() -> [Cage] {
        cageCellGroups.enumerated().map { index, coordinates in
            let sum = coordinates.reduce(0) { $0 + solutionGrid[$1.row][$1.column] }
            return Cage(id: index, cells: coordinates, sum: sum)
        }
    }

    public static func makeBoard() -> Board {
        Board(cages: makeCages())
    }
}
