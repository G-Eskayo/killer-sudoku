import Testing
@testable import KillerSudokuCore

@Suite struct SudokuGridGeneratorTests {
    @Test func everyRowIsAPermutationOfOneToNine() {
        let grid = SudokuGridGenerator.generate()
        for row in grid {
            #expect(Set(row) == Set(1...9))
        }
    }

    @Test func everyColumnIsAPermutationOfOneToNine() {
        let grid = SudokuGridGenerator.generate()
        for column in 0..<9 {
            #expect(Set(grid.map { $0[column] }) == Set(1...9))
        }
    }

    @Test func everyBoxIsAPermutationOfOneToNine() {
        let grid = SudokuGridGenerator.generate()
        for boxRow in stride(from: 0, to: 9, by: 3) {
            for boxColumn in stride(from: 0, to: 9, by: 3) {
                var digits: [Int] = []
                for row in boxRow..<(boxRow + 3) {
                    for column in boxColumn..<(boxColumn + 3) {
                        digits.append(grid[row][column])
                    }
                }
                #expect(Set(digits) == Set(1...9))
            }
        }
    }
}
