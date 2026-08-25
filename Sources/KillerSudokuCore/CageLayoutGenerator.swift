/// Partitions a solved 9x9 grid into randomized Killer Sudoku cages: orthogonally-connected
/// groups of 2-4 cells, covering every cell exactly once, none containing a repeated digit
/// (per [[CONTEXT.md]]'s cage definition). Used by [[PuzzleGenerator]].
public enum CageLayoutGenerator {
    public static func generate(for grid: [[Int]]) -> [Cage] {
        cages(for: grid, in: allCoordinates(), startingID: 0)
    }

    /// Same algorithm restricted to an explicit cell region rather than the whole board — lets a
    /// caller (e.g. a test needing a partially hand-controlled layout) generate a realistic,
    /// well-scattered cage partition over just part of the board. `startingID` avoids id
    /// collisions when the caller combines this with cages built another way.
    static func cages(for grid: [[Int]], in region: Set<Coordinate>, startingID: Int) -> [Cage] {
        while true {
            if let groups = attempt(for: grid, in: region) {
                return groups.enumerated().map { index, cells in
                    let sum = cells.reduce(0) { $0 + grid[$1.row][$1.column] }
                    return Cage(id: startingID + index, cells: cells, sum: sum)
                }
            }
        }
    }

    /// One randomized region-growing pass over `region`. Returns nil (caller retries from
    /// scratch) if a cell gets stranded alone with no unassigned neighbor and no adjacent
    /// already-built cage it can join without breaking the size or no-repeat-digit bounds —
    /// simpler and just as effective at this board size as backtracking within a single pass.
    private static func attempt(for grid: [[Int]], in region: Set<Coordinate>) -> [[Coordinate]]? {
        var unassigned = region
        var cages: [[Coordinate]] = []

        while let seed = unassigned.randomElement() {
            unassigned.remove(seed)
            var cageCells = [seed]
            var digitsUsed: Set<Int> = [grid[seed.row][seed.column]]
            // Weighted toward smaller cages (2-3 over 4): fewer cells per cage means fewer
            // possible digit combinations per cage sum on average, which verifies faster and
            // makes a unique solution more likely on a given attempt — see PuzzleSolver's node
            // budget doc comment for why verification cost matters this much here.
            let targetSize = [2, 2, 2, 3, 3, 4].randomElement()!

            while cageCells.count < targetSize {
                let candidates = cageCells
                    .flatMap { orthogonalNeighbors(of: $0, in: region) }
                    .filter { unassigned.contains($0) && !digitsUsed.contains(grid[$0.row][$0.column]) }
                guard let next = candidates.randomElement() else { break }
                cageCells.append(next)
                unassigned.remove(next)
                digitsUsed.insert(grid[next.row][next.column])
            }

            if cageCells.count >= 2 {
                cages.append(cageCells)
            } else if let mergeIndex = adjacentCageIndex(for: seed, in: cages, grid: grid, region: region) {
                cages[mergeIndex].append(seed)
            } else {
                return nil
            }
        }

        return cages
    }

    private static func adjacentCageIndex(
        for coordinate: Coordinate, in cages: [[Coordinate]], grid: [[Int]], region: Set<Coordinate>
    ) -> Int? {
        let neighborSet = Set(orthogonalNeighbors(of: coordinate, in: region))
        let digit = grid[coordinate.row][coordinate.column]
        return cages.firstIndex { cage in
            cage.count < 4
                && cage.contains(where: neighborSet.contains)
                && !cage.contains(where: { grid[$0.row][$0.column] == digit })
        }
    }

    private static func orthogonalNeighbors(of coordinate: Coordinate, in region: Set<Coordinate>) -> [Coordinate] {
        [(-1, 0), (1, 0), (0, -1), (0, 1)].compactMap { rowDelta, columnDelta in
            let row = coordinate.row + rowDelta
            let column = coordinate.column + columnDelta
            guard (0..<9).contains(row), (0..<9).contains(column) else { return nil }
            let candidate = Coordinate(row: row, column: column)
            return region.contains(candidate) ? candidate : nil
        }
    }

    private static func allCoordinates() -> Set<Coordinate> {
        var coordinates: Set<Coordinate> = []
        for row in 0..<9 {
            for column in 0..<9 {
                coordinates.insert(Coordinate(row: row, column: column))
            }
        }
        return coordinates
    }
}
