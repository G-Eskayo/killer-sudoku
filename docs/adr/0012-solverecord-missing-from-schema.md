# 0012 — Register SolveRecord in the app's ModelContainer schema

## Status

Accepted (2026-08-26)

## Context

Player report: completed a puzzle, nothing showed up in stats. [[0011]] fixed two real bugs in
how a completed puzzle finds its difficulty tier, but the player then completed another puzzle
under a build with both of those fixes in place and still saw nothing recorded.

Screenshot of the finished board showed a fully valid Sudoku grid (every row, column, and 3x3 box
a correct 1-9 permutation) with no mistake indicator anywhere. Temporary logging in
`GameState.recordSolveIfNeeded` confirmed `board.isSolved` really was `true` and
`currentDifficulty` really was `.medium` — the domain logic and [[0011]]'s fixes were both working
correctly. `StatsStore.record(...)` should have run.

Querying the actual on-disk store directly (`sqlite3 default.store ".tables"`) found no
`ZSOLVERECORD` table at all — only `ZSAVEDPUZZLE`. `KillerSudokuApp.init()`'s `ModelContainer` was
constructed as `ModelContainer(for: SavedPuzzle.self)` — `SolveRecord.self` was never included in
the schema. `StatsStore.record`'s `context.insert(SolveRecord(...))` followed by `try? context
.save()` had been silently doing nothing, for every solve ever completed, since issue #9 first
shipped this feature. Not something introduced today — a pre-existing gap, just never surfaced
until someone actually looked at the champion board expecting to see something in it.

`StatsStoreTests` never caught this because it builds its own isolated `ModelContainer(for:
SolveRecord.self, ...)` for each test — correctly scoped for unit-testing `StatsStore`'s query
logic in isolation, but with no connection to the real app's container, so a schema gap in
`KillerSudokuApp.swift` had no test surface that could ever exercise it.

## Decision

`ModelContainer(for: SavedPuzzle.self, SolveRecord.self)` — both persisted model types registered
in the one real container the app actually uses, for both the on-disk and in-memory-fallback
configurations.

## Consequences

Every solve completed before this fix was never actually persisted anywhere — there's no data to
recover, only a silent no-op each time. Going forward, solves record correctly.

The class of bug (a model type that compiles fine, has working query/store logic, and passing
unit tests, but was never actually wired into the app's real persistence container) has no unit
test that can catch it by construction — the fix needs an integration-level check if this project
ever wants automated coverage here: something that constructs the *actual* `KillerSudokuApp`
container configuration (not a test's own hand-rolled one) and round-trips a real record through
it. Not built here, given the scope of what prompted this ADR; worth revisiting if this class of
gap recurs for a future model type.
