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
    /// retry cost into parallel retry cost.
    ///
    /// ADR 0013: a batch used to always wait for its *slowest* member even after another one had
    /// already succeeded, since nothing told the stragglers to stop. `ResultBox` now doubles as
    /// the cancellation signal — every attempt in the batch polls `box.hasResult` during its
    /// solver search (see `PuzzleSolver.verify`'s `isCancelled`), so the moment any one succeeds,
    /// the rest abort within a bounded number of nodes instead of running to their own natural
    /// conclusion regardless of the others.
    ///
    /// That still leaves the case where *every* attempt in a batch fails — nothing to cancel
    /// against, so the round costs close to a full node budget regardless. At a 5-15% per-attempt
    /// success rate, a batch sized to exactly the core count fails outright well over half the
    /// time at the harder tiers. Oversubscribing past core count raises the odds that at least
    /// one attempt somewhere in the (larger) batch succeeds — GCD queues the excess and runs it
    /// as cores free up — while cancellation keeps the cost of doing so low once any attempt
    /// anywhere in the batch does succeed. Measured head-to-head against 1x and 4x (ADR 0013):
    /// 2x was the best balance found, though the measurement itself was noisy enough that this
    /// isn't a precise optimum, just the better of what was actually compared.
    private static func attemptClassicInParallel(requiring difficulty: Difficulty) -> Board {
        let batchSize = max(1, ProcessInfo.processInfo.activeProcessorCount) * 2
        while true {
            let box = ResultBox()
            DispatchQueue.concurrentPerform(iterations: batchSize) { _ in
                if let board = attemptClassic(requiring: difficulty, isCancelled: box.hasResult) {
                    box.setIfEmpty(board)
                }
            }
            if let board = box.get() { return board }
        }
    }

    /// One candidate. Returns nil if cage generation didn't converge, the cage layout alone
    /// isn't uniquely solvable, or the search was cancelled (another attempt in the same batch
    /// already succeeded) — any of which just means the caller's retry loop tries a fresh
    /// instance. Uniqueness is checked from the cage structure alone, *before* givens are chosen:
    /// a real Killer Sudoku puzzle is solvable by cage-sum logic on its own, and a given is a
    /// bonus reveal layered on top, not something the puzzle's validity should depend on.
    /// Checking cage+givens together here would let a genuinely ambiguous cage layout slip
    /// through whenever the chosen givens happened to rule out its other solutions.
    private static func attemptClassic(requiring difficulty: Difficulty, isCancelled: (() -> Bool)? = nil) -> Board? {
        if isCancelled?() == true { return nil }
        let grid = SudokuGridGenerator.generate()
        guard let cages = CageLayoutGenerator.generate(for: grid) else { return nil }
        guard PuzzleSolver.verify(cages: cages, upTo: 2, isCancelled: isCancelled).solutionCount == 1 else { return nil }

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

/// Thread-safe "first one wins" slot for `attemptClassicInParallel`'s concurrent batch — also
/// doubles as the batch's cancellation signal (ADR 0013): `hasResult` is passed to every other
/// attempt in the batch as its `isCancelled` poll, so the moment one succeeds, the rest notice
/// and abort instead of running their own search to its natural conclusion regardless.
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

    func hasResult() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return value != nil
    }
}
