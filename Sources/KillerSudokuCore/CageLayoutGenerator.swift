/// Partitions a solved 9x9 grid into randomized Killer Sudoku cages: orthogonally-connected
/// groups of 2-4 cells, covering every cell exactly once, none containing a repeated digit
/// (per [[CONTEXT.md]]'s cage definition), plus an optional few size-1 "given" cages (ADR 0006).
/// Used by [[PuzzleGenerator]].
public enum CageLayoutGenerator {
    /// `givensCount` single-cell cages (ADR 0006's classic-mode given baseline) are seeded
    /// first, before the rest of the board is partitioned into normal 2-4 cell cages.
    ///
    /// Returns nil if no valid partition was found within the retry budget — for the full board
    /// this essentially never happens in practice, but a caller partitioning an irregular region
    /// (issue #3's hybrid mode, where some cells are excluded as givens) needs to handle it: an
    /// unlucky given selection can leave a cell fully boxed in by holes/edges with no possible
    /// cage-mate, which is a *structural* dead end no amount of retrying the same region fixes —
    /// only picking a fresh region (a caller-level concern) does.
    public static func generate(for grid: [[Int]], givensCount: Int = 0) -> [Cage]? {
        cages(for: grid, in: Set(Coordinate.all), startingID: 0, givensCount: givensCount)
    }

    /// Same algorithm restricted to an explicit cell region rather than the whole board — lets a
    /// caller (e.g. a test needing a partially hand-controlled layout, or hybrid mode excluding
    /// given cells) generate a realistic, well-scattered cage partition over just part of the
    /// board. `startingID` avoids id collisions when the caller combines this with cages built
    /// another way. `maxAttempts` bounds the retry loop — see the doc comment above on why an
    /// irregular region isn't guaranteed to ever succeed.
    static func cages(
        for grid: [[Int]], in region: Set<Coordinate>, startingID: Int,
        givensCount: Int = 0, maxAttempts: Int = 500
    ) -> [Cage]? {
        for _ in 0..<maxAttempts {
            if let groups = attempt(for: grid, in: region, givensCount: givensCount) {
                return groups.enumerated().map { index, cells in
                    let sum = cells.reduce(0) { $0 + grid[$1.row][$1.column] }
                    return Cage(id: startingID + index, cells: cells, sum: sum)
                }
            }
        }
        return nil
    }

    /// One randomized region-growing pass over `region`. Returns nil (caller retries from
    /// scratch) if a cell gets stranded alone with no unassigned neighbor and no adjacent
    /// already-built cage it can join without breaking the size or no-repeat-digit bounds —
    /// simpler and just as effective at this board size as backtracking within a single pass.
    private static func attempt(
        for grid: [[Int]], in region: Set<Coordinate>, givensCount: Int
    ) -> [[Coordinate]]? {
        var unassigned = region
        var cages: [[Coordinate]] = []

        // Seed the given-baseline single-cell cages first, before any normal growth claims
        // their would-be neighbors.
        for _ in 0..<givensCount {
            guard let seed = unassigned.randomElement() else { break }
            unassigned.remove(seed)
            cages.append([seed])
        }

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
            // Size-1 entries here are always given-baseline cages (the main growth loop only
            // ever appends cages of size 2+) — they must never absorb a stranded neighbor and
            // grow past size 1, or they'd stop being givens.
            cage.count >= 2 && cage.count < 4
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
}
