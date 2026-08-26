# 0010 — Generate candidate puzzles in parallel batches

## Status

Accepted (2026-08-26)

## Context

Player feedback: puzzle generation still felt slow at every tier, even after [[0008]] removed the
search-effort-matching retry loop. Profiled with a throwaway harness (grid generation, cage
generation, and solver verification timed separately across real attempts): grid and cage
generation are both negligible (tens of milliseconds across dozens of attempts combined). Nearly
all wall-clock time is [[PuzzleSolver]].verify — a random cage layout is non-unique roughly
85-95% of the time, and *each failed attempt* still costs a real search, typically landing near
the full 20,000-node budget before giving up.

Tried lowering `nodeBudget` (e.g. to 3,000) to make each failure cheaper — measured *worse*
overall: many attempts that would have resolved (unique or proven non-unique) within the larger
budget instead hit the smaller cap inconclusively, forcing far more retries. Proving or
disproving uniqueness for these cage layouts often genuinely needs more than a few thousand
nodes; a smaller budget doesn't make individual attempts faster in aggregate, it just discards
more of them.

Each attempt (fresh grid, fresh cage partition, fresh verify) is fully independent — no shared
state, no dependency between attempts. That makes them embarrassingly parallel: instead of trying
attempts one at a time, a whole batch can run at once across CPU cores, turning serial retry cost
into parallel retry cost.

## Decision

`PuzzleGenerator.generate()`/`generate(difficulty:)` now run a batch of attempts concurrently via
`DispatchQueue.concurrentPerform`, sized to `ProcessInfo.processInfo.activeProcessorCount`, and
take the first successful result from the batch — repeating with a fresh batch if none succeed.
`attemptClassic` itself and its downstream calls (`SudokuGridGenerator`, `CageLayoutGenerator`,
`PuzzleSolver.verify`) are unchanged; this only changes how many run at once. Both public
generation functions keep their existing synchronous signatures — no caller (`KillerSudokuApp`'s
synchronous app-launch path, `GameState`'s already-`Task.detached`-wrapped New Puzzle flow) needed
to change.

`DispatchQueue.concurrentPerform` blocks until every iteration in the batch finishes, even after
one has already succeeded — `attemptClassic` isn't structured to check a cancellation flag
mid-search, so there's nothing to cancel into early anyway, and adding that would couple the
solver's inner loop to a concurrency concern for uncertain benefit. `ResultBox` (a small
`NSLock`-protected slot) just records whichever attempt in the batch finishes successfully first.

## Consequences

Measured improvement on an 8-core machine: typical generation time dropped from roughly 10-38s to
2-4s across all four tiers; occasional 8-10s outliers remain when an entire batch happens to be
unlucky (all `activeProcessorCount` parallel attempts land on slow failures), which is expected
and much rarer than a single slow failure was before. This trades CPU utilization for wall-clock
time — generation now briefly saturates all cores instead of one, which is the right trade for a
short, user-facing, one-shot operation (New Puzzle), not a background or continuous one.

Because the batch always runs to completion, the *best-case* attempt in a batch doesn't return
early — wall-clock time for a successful batch is bounded by its *slowest* member, not its
fastest. A true early-cancellation design (e.g. solver-level cooperative cancellation checks)
could improve on this further, but wasn't pursued here given the scope of change required for
uncertain additional gain over the batching win already measured.
