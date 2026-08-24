# 0003 — Generate puzzles on-device rather than shipping a bundled set

## Status

Accepted (2026-08-24)

## Context

Puzzle supply is a core part of the app's value — a Sudoku app the user actually wants to keep
using long-term needs puzzles that don't run out. Three paths were considered:

- **Bundled puzzle set**: ship a curated, pre-verified set of puzzles per difficulty. Simple to
  build, difficulty is easy to guarantee by hand-verification, but the supply is finite and
  growing it means shipping new content/updates.
- **On-device generator**: algorithmically produce a fresh, unique-solution puzzle (cage
  layout + cage sums, respecting [[CONTEXT.md]]'s classic/hybrid mode split) at each difficulty
  on demand. Effectively unlimited puzzles and no content pipeline, at the cost of building a
  real generator plus a solver capable of grading difficulty.
- **Bundled now, generator later**: ship the simple version first, defer the harder engineering
  problem to a v2. Lowest v1 risk, but the generator work still has to happen eventually if the
  goal is a puzzle supply that doesn't run out.

## Decision

Build an on-device puzzle generator from the start rather than shipping (or starting with) a
bundled puzzle set.

## Consequences

Unlocks unlimited puzzles across every difficulty with no content-shipping pipeline, which
matters for an app meant to replace the user's daily Sudoku habit. The cost: the generator plus
a solver that can both verify unique solvability and grade difficulty is real, non-trivial
engineering, and is now on the critical path before the app is playable at all (there is no
"ship the easy version first" fallback once this path is chosen). This decision doesn't resolve
how difficulty is actually measured or how many difficulty tiers exist — that's a separate
open question to grill next.
