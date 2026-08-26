# 0011 — Every puzzle gets a real difficulty tier; Difficulty's raw values are stable

## Status

Accepted (2026-08-26)

## Context

Player report: completed a puzzle, nothing showed up in the stats view. Two real, independent
bugs, both rooted in schema changes made earlier the same session:

1. `GameState.currentDifficulty` is `Difficulty?`, and `nil` represented "the app-launch puzzle,
   ungraded" (`PuzzleGenerator.generate()`, no-arg). `recordSolveIfNeeded` refuses to record a
   solve with no known tier — there's nowhere for it to go. Separately, `Cell` gained an `isGiven`
   field mid-session with no backward-compatible decoding; a `SavedPuzzle` encoded before that
   change fails to decode afterward, and `PuzzleStore.load()` swallows the failure (`try?`) and
   silently falls back to a fresh *ungraded* puzzle. A player who never explicitly picked "New
   Puzzle" after that point could complete a puzzle with no tier to record against at all.

2. Separately and more seriously: `SavedPuzzle.difficultyRawValue` and `SolveRecord`'s own field
   of the same name persist `Difficulty.rawValue` as a plain `Int` — [[SolveRecord]]'s doc comment
   already documented the intended contract: "keeps the persisted shape stable even if
   `Difficulty`'s case order... changes later." [[0009]] broke that contract without anyone
   noticing: removing `.beginner` with every case still on *implicit* (declaration-order) raw
   values shifted every remaining case's number down by one (easy 1→0, medium 2→1, hard 3→1,
   expert 4→3). A solve recorded before [[0009]] would silently decode to the *wrong* tier after
   it — not fail, just misattribute. Checking the "right" tier's stats would show nothing, because
   the record moved to a different one, with no error anywhere to point at why.

## Decision

Three fixes, addressing both the immediate symptom and its root causes:

- `Difficulty` now declares explicit raw values (`easy = 0, medium = 1, hard = 2, expert = 3` —
  the same numbers implicit declaration already produced today, so no data changes, only future
  case-list edits are protected). Adding, removing, or reordering a case can never again silently
  renumber another.
- `Cell.init(from:)` is now hand-written, decoding `isGiven` as absent-means-`false` rather than
  requiring the key. A future new field needs the same treatment to stay backward-compatible.
- The "ungraded puzzle" concept is removed entirely. `PuzzleGenerator.generate()` (no-arg) is
  deleted; `KillerSudokuApp.init()`'s app-launch fallback now calls
  `generate(difficulty: restored?.difficulty ?? .medium)` — every puzzle, restored or freshly
  generated, always has a real tier to record a solve against.

`SavedPuzzle.difficultyRawValue` and `GameState.currentDifficulty` stay `Optional` at the type
level rather than becoming non-optional — tightening those would ripple into SwiftData's
persisted model schema (`SavedPuzzle` is a `@Model` type) for no functional gain, on the same day
a schema-adjacent change (`Cell.isGiven`) already caused one of these two bugs. The *value* is
guaranteed non-nil at the one integration point that matters (`KillerSudokuApp.init`) instead.

## Consequences

Any solve recorded before this fix, under the renumbered scheme, is still filed under whatever
tier its raw value now maps to — this decision stops the corruption from continuing, it doesn't
retroactively repair already-misattributed records. Given how recently [[0009]] shipped in the
same session, this is judged not worth a one-off data migration.

The broader lesson, not just this specific fix: persisted raw values are a contract with past
data the moment anything real is saved, not an implementation detail — the same class of bug can
recur for any other `@Model`/`Codable` type in this project (`SavedPuzzle` itself, `SolveRecord`)
if a future case list, field, or shape change doesn't consider what's already on disk.
