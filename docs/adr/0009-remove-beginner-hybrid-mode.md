# 0009 — Remove Beginner/hybrid mode; Easy is the entry tier

## Status

Accepted (2026-08-26)

## Context

[[0008]] pushed classic mode's Easy tier up to a 25-40 given range (~31-49% of the board) so that
given-density could meaningfully differentiate all four classic tiers. That range now sits close
to hybrid mode's fixed 20 givens (~25%) — confirmed by testing, where Beginner and Easy started
reading as near-duplicates of each other despite using genuinely different mechanics (hybrid's
givens sit outside the cage system entirely; classic's now live inside a normal cage per [[0008]]).

Rather than re-tune Easy's range down to create artificial separation from Beginner, the simpler
call: hybrid mode was a separate mechanic built for exactly one purpose (an easier on-ramp before
classic mode's real difficulty spread existed as a lever at all). Now that given-density itself
scales smoothly across all of classic mode ([[0008]]), that on-ramp role is already covered by
Easy — hybrid mode duplicates it rather than complementing it.

## Decision

Hybrid mode is removed entirely. `Difficulty` drops `.beginner` (four tiers: Easy, Medium, Hard,
Expert). `PuzzleGenerator.attemptHybrid` and its fixed 20-given, cage-exempt mechanic are deleted;
`generate(difficulty:)` now always uses the classic-mode path. `PuzzleSolver`'s `givens` parameter
is also removed — hybrid mode was its only real caller anywhere in the app, and classic mode's own
uniqueness check runs on cage structure alone before givens are ever chosen ([[0008]]), so nothing
combines cages and givens in a single verification call anymore.

`CageLayoutGenerator`'s region-restricted partitioning (`cages(for:in:startingID:)`) is kept as-is
despite hybrid mode being its only real caller: it's still directly exercised by real tests (the
structurally-isolated-cell regression test, and a solver test fixture combining hand-built and
generated cages), which is enough standing justification on its own, separate from any
application-level caller.

## Consequences

Killer Sudoku now has a single puzzle mode with one continuous difficulty spectrum (given-density,
[[0008]]), rather than two mechanics that happened to overlap. Loses the "plain Sudoku clue,
zero cage logic needed" onboarding style hybrid mode offered — Easy's givens still require reading
cage sums, just with more of them revealed. Issue #3 (Beginner hybrid-mode generation) is now
obsolete and closed rather than left open against removed functionality.
