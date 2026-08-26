import Foundation

/// Generates a fresh, on-device Killer Sudoku puzzle: a random solved grid (ADR 0003), fully
/// partitioned into normal 2-4 cell cages, with a per-tier count of cells revealed as givens
/// inside whatever cage they already belong to (ADR 0008) — given-density *is* the difficulty
/// lever. Hybrid/Beginner mode (issue #3) was removed in ADR 0009: this is now the only mode.
/// This is the app's single public entry point for puzzle generation — everything else in this
/// file's sibling types is implementation detail.
public enum PuzzleGenerator {
    /// ADR 0008's per-tier given-count ranges, out of 81 cells. ADR 0011: every puzzle gets a
    /// real tier now — there's no more "ungraded" case to fall back for.
    private static let classicGivensRanges: [Difficulty: ClosedRange<Int>] = [
        .easy: 25...40,
        .medium: 17...24,
        .hard: 9...16,
        .expert: 4...8,
    ]

    /// Regenerates until [[PuzzleSolver]] confirms exactly one solution — the "New Puzzle" flow
    /// (issue #2), and also the app-launch fallback when there's no saved puzzle to restore
    /// (ADR 0011: always at an explicit tier, never ungraded). Given-density is chosen directly
    /// from the requested tier's range, not discovered after the fact, so this never needs a
    /// second retry condition for the tier itself (ADR 0008).
    public static func generate(difficulty: Difficulty) -> Board {
        attemptClassicInParallel(requiring: difficulty)
    }

    /// ADR 0010: profiling found ~85-95% of individual attempts fail (a random cage layout is
    /// non-unique far more often than not), and each failure still costs a real solver search
    /// (often near the full node budget) before giving up — grid/cage generation themselves are
    /// negligible by comparison. Attempts share no state and don't get faster with a smaller
    /// node budget (measured: it just forces more retries, net slower), but they're fully
    /// independent of each other, so running a whole batch at once across CPU cores turns serial
    /// retry cost into parallel retry cost. Waits for the *whole* batch even after one succeeds
    /// (see `ResultBox`'s doc comment for why) rather than cancelling in-flight attempts early.
    private static func attemptClassicInParallel(requiring difficulty: Difficulty) -> Board {
        let batchSize = max(1, ProcessInfo.processInfo.activeProcessorCount)
        while true {
            let box = ResultBox()
            DispatchQueue.concurrentPerform(iterations: batchSize) { _ in
                if let board = attemptClassic(requiring: difficulty) {
                    box.setIfEmpty(board)
                }
            }
            if let board = box.get() { return board }
        }
    }

    /// One candidate. Returns nil if cage generation didn't converge or the cage layout alone
    /// isn't uniquely solvable — either just means the caller's retry loop tries a fresh
    /// instance. Uniqueness is checked from the cage structure alone, *before* givens are chosen:
    /// a real Killer Sudoku puzzle is solvable by cage-sum logic on its own, and a given is a
    /// bonus reveal layered on top, not something the puzzle's validity should depend on.
    /// Checking cage+givens together here would let a genuinely ambiguous cage layout slip
    /// through whenever the chosen givens happened to rule out its other solutions.
    private static func attemptClassic(requiring difficulty: Difficulty) -> Board? {
        let grid = SudokuGridGenerator.generate()
        guard let cages = CageLayoutGenerator.generate(for: grid) else { return nil }
        guard PuzzleSolver.verify(cages: cages, upTo: 2).solutionCount == 1 else { return nil }

        let givenCount = Int.random(in: classicGivensRanges[difficulty]!)
        let givenCoordinates = Set(Coordinate.all.shuffled().prefix(givenCount))
        let givens = Dictionary(uniqueKeysWithValues: givenCoordinates.map { ($0, grid[$0.row][$0.column]) })
        return board(for: cages, givens: givens)
    }

    /// Pre-fills every given's digit directly into the initial cell grid, as a normal member of
    /// its cage (ADR 0008) — rather than through `Board.setDigit`, which would record each as an
    /// undoable player edit. Givens aren't a player action; they shouldn't be undoable.
    private static func board(for cages: [Cage], givens: [Coordinate: Int]) -> Board {
        var cells = Array(repeating: Array(repeating: Cell(), count: 9), count: 9)
        for (coordinate, digit) in givens {
            cells[coordinate.row][coordinate.column] = Cell(digit: digit, isGiven: true)
        }
        return Board(cages: cages, cells: cells)
    }
}

/// Thread-safe "first one wins" slot for `attemptClassicInParallel`'s concurrent batch.
/// `DispatchQueue.concurrentPerform` has no built-in way to cancel the other iterations once one
/// succeeds (and `attemptClassic` isn't structured to check a cancellation flag mid-search, so
/// there'd be nothing to cancel into anyway) — every iteration in a batch runs to completion
/// regardless, and this just records whichever succeeds first among them.
private final class ResultBox: @unchecked Sendable {
    private var value: Board?
    private let lock = NSLock()

    func setIfEmpty(_ board: Board) {
        lock.lock()
        defer { lock.unlock() }
        if value == nil { value = board }
    }

    func get() -> Board? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}
