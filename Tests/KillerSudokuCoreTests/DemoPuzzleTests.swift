import Testing
@testable import KillerSudokuCore

@Suite struct DemoPuzzleTests {
    @Test func cageGroupsCoverEveryCellExactlyOnce() {
        var seen: Set<Coordinate> = []
        for group in DemoPuzzle.cageCellGroups {
            for coordinate in group {
                #expect(!seen.contains(coordinate), "duplicate coverage at \(coordinate)")
                seen.insert(coordinate)
            }
        }
        #expect(seen.count == 81)
    }

    @Test func everyCageSizeIsWithinBounds() {
        for group in DemoPuzzle.cageCellGroups {
            #expect((2...4).contains(group.count))
        }
    }

    @Test func noCageHasARepeatedDigit() {
        for group in DemoPuzzle.cageCellGroups {
            let digits = group.map { DemoPuzzle.solutionGrid[$0.row][$0.column] }
            #expect(Set(digits).count == digits.count)
        }
    }

    @Test func allCageSumsArePositive() {
        for cage in DemoPuzzle.makeCages() {
            #expect(cage.sum > 0)
        }
    }

    @Test func totalOfAllCageSumsMatchesFullGridTotal() {
        let total = DemoPuzzle.makeCages().reduce(0) { $0 + $1.sum }
        #expect(total == 405) // 9 rows x (1+2+...+9)
    }
}
