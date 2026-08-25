import Testing
@testable import KillerSudokuCore

@Suite struct CageLayoutGeneratorTests {
    @Test func everyCellIsCoveredExactlyOnce() {
        let cages = CageLayoutGenerator.generate(for: DemoPuzzle.solutionGrid)

        var seen: Set<Coordinate> = []
        for cage in cages {
            for coordinate in cage.cells {
                #expect(!seen.contains(coordinate), "duplicate coverage at \(coordinate)")
                seen.insert(coordinate)
            }
        }
        #expect(seen.count == 81)
    }

    @Test func everyCageSizeIsWithinBounds() {
        let cages = CageLayoutGenerator.generate(for: DemoPuzzle.solutionGrid)
        for cage in cages {
            #expect((2...4).contains(cage.cells.count))
        }
    }

    @Test func noCageHasARepeatedDigit() {
        let cages = CageLayoutGenerator.generate(for: DemoPuzzle.solutionGrid)
        for cage in cages {
            let digits = cage.cells.map { DemoPuzzle.solutionGrid[$0.row][$0.column] }
            #expect(Set(digits).count == digits.count)
        }
    }

    @Test func everyCageIsOrthogonallyConnected() {
        let cages = CageLayoutGenerator.generate(for: DemoPuzzle.solutionGrid)
        for cage in cages {
            #expect(isOrthogonallyConnected(cage.cells), "cage \(cage.id) is not connected: \(cage.cells)")
        }
    }

    @Test func givensCountProducesThatManySingleCellCages() {
        let cages = CageLayoutGenerator.generate(for: DemoPuzzle.solutionGrid, givensCount: 3)
        let singleCellCages = cages.filter { $0.cells.count == 1 }
        #expect(singleCellCages.count == 3)
    }

    @Test func givensStillCoverEveryCellExactlyOnceWithNonGivenCagesWithinBounds() {
        let cages = CageLayoutGenerator.generate(for: DemoPuzzle.solutionGrid, givensCount: 3)

        var seen: Set<Coordinate> = []
        for cage in cages {
            for coordinate in cage.cells {
                #expect(!seen.contains(coordinate), "duplicate coverage at \(coordinate)")
                seen.insert(coordinate)
            }
            #expect((1...4).contains(cage.cells.count))
        }
        #expect(seen.count == 81)
    }

    private func isOrthogonallyConnected(_ cells: [Coordinate]) -> Bool {
        guard let first = cells.first else { return true }
        var reached: Set<Coordinate> = [first]
        var frontier = [first]
        let cellSet = Set(cells)

        while let current = frontier.popLast() {
            let neighbors = [(-1, 0), (1, 0), (0, -1), (0, 1)].compactMap { rowDelta, columnDelta -> Coordinate? in
                let row = current.row + rowDelta
                let column = current.column + columnDelta
                guard (0..<9).contains(row), (0..<9).contains(column) else { return nil }
                return Coordinate(row: row, column: column)
            }
            for neighbor in neighbors where cellSet.contains(neighbor) && !reached.contains(neighbor) {
                reached.insert(neighbor)
                frontier.append(neighbor)
            }
        }
        return reached.count == cells.count
    }
}
