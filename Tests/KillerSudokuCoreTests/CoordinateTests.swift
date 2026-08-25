import Testing
@testable import KillerSudokuCore

@Suite struct CoordinateTests {
    @Test func allCoversEveryCellOnceWithNoDuplicates() {
        let all = Coordinate.all
        #expect(Set(all).count == 81)
        #expect(all.count == 81)
    }
}
