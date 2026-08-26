package me.gileskayo.killersudoku.core

/** Partitions a solved 9x9 grid into randomized Killer Sudoku cages: orthogonally-connected
 * groups of 2-4 cells, covering every cell exactly once, none containing a repeated digit.
 * Used by [PuzzleGenerator], which reveals some cells' digits as givens after the fact without
 * changing cage structure. */
object CageLayoutGenerator {
    /** Returns null if no valid partition was found within the retry budget -- for the full
     * board this essentially never happens in practice, but a caller partitioning an irregular
     * region needs to handle it: an unlucky region shape can leave a cell fully boxed in by
     * holes/edges with no possible cage-mate, which is a *structural* dead end no amount of
     * retrying the same region fixes -- only picking a fresh region (a caller-level concern)
     * does. */
    fun generate(grid: Array<IntArray>): List<Cage>? =
        cages(grid, Coordinate.all.toSet(), startingId = 0)

    /** Same algorithm restricted to an explicit cell region rather than the whole board -- lets
     * a caller (e.g. a test needing a partially hand-controlled layout) generate a realistic,
     * well-scattered cage partition over just part of the board. [startingId] avoids id
     * collisions when the caller combines this with cages built another way. [maxAttempts]
     * bounds the retry loop. */
    fun cages(grid: Array<IntArray>, region: Set<Coordinate>, startingId: Int, maxAttempts: Int = 500): List<Cage>? {
        repeat(maxAttempts) {
            val groups = attempt(grid, region)
            if (groups != null) {
                return groups.mapIndexed { index, cells ->
                    val sum = cells.sumOf { grid[it.row][it.column] }
                    Cage(id = startingId + index, cells = cells, sum = sum)
                }
            }
        }
        return null
    }

    /** One randomized region-growing pass over [region]. Returns null (caller retries from
     * scratch) if a cell gets stranded alone with no unassigned neighbor and no adjacent
     * already-built cage it can join without breaking the size or no-repeat-digit bounds --
     * simpler and just as effective at this board size as backtracking within a single pass. */
    private fun attempt(grid: Array<IntArray>, region: Set<Coordinate>): List<List<Coordinate>>? {
        val unassigned = region.toMutableSet()
        val cages = mutableListOf<MutableList<Coordinate>>()

        while (unassigned.isNotEmpty()) {
            val seed = unassigned.random()
            unassigned.remove(seed)
            val cageCells = mutableListOf(seed)
            val digitsUsed = mutableSetOf(grid[seed.row][seed.column])
            // Weighted toward smaller cages (2-3 over 4): fewer cells per cage means fewer
            // possible digit combinations per cage sum on average, which verifies faster and
            // makes a unique solution more likely on a given attempt.
            val targetSize = listOf(2, 2, 2, 3, 3, 4).random()

            while (cageCells.size < targetSize) {
                val candidates = cageCells
                    .flatMap { orthogonalNeighbors(it, region) }
                    .filter { it in unassigned && grid[it.row][it.column] !in digitsUsed }
                val next = candidates.randomOrNull() ?: break
                cageCells.add(next)
                unassigned.remove(next)
                digitsUsed.add(grid[next.row][next.column])
            }

            if (cageCells.size >= 2) {
                cages.add(cageCells)
            } else {
                val mergeIndex = adjacentCageIndex(seed, cages, grid, region)
                if (mergeIndex != null) {
                    cages[mergeIndex].add(seed)
                } else {
                    return null
                }
            }
        }

        return cages
    }

    private fun adjacentCageIndex(
        coordinate: Coordinate, cages: List<List<Coordinate>>, grid: Array<IntArray>, region: Set<Coordinate>,
    ): Int? {
        val neighborSet = orthogonalNeighbors(coordinate, region).toSet()
        val digit = grid[coordinate.row][coordinate.column]
        return cages.indexOfFirst { cage ->
            // Every cage here is already size 2+ (the growth loop only ever appends those) --
            // just needs room to grow without exceeding the 4-cell cap.
            cage.size < 4 &&
                cage.any { it in neighborSet } &&
                cage.none { grid[it.row][it.column] == digit }
        }.takeIf { it >= 0 }
    }

    private fun orthogonalNeighbors(coordinate: Coordinate, region: Set<Coordinate>): List<Coordinate> =
        listOf(-1 to 0, 1 to 0, 0 to -1, 0 to 1).mapNotNull { (rowDelta, columnDelta) ->
            val row = coordinate.row + rowDelta
            val column = coordinate.column + columnDelta
            if (row !in 0..8 || column !in 0..8) return@mapNotNull null
            val candidate = Coordinate(row, column)
            candidate.takeIf { it in region }
        }
}
