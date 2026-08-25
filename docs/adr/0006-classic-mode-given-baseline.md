# 0006 — Classic mode gets a small constant given baseline, not zero givens

## Status

Accepted (2026-08-25)

## Context

Building issue #2 (difficulty-graded New Puzzle flow) surfaced that CONTEXT.md's original
"classic mode = no givens at all" commitment, combined with [[0003]]'s solving-technique
grading, doesn't actually work: every randomly generated classic-mode puzzle graded Expert,
with zero spread across difficulty tiers, even after adding two real, textbook-standard
techniques (cage-line/pointing-pair elimination, and the "Rule of 45"/innies-and-outies —
comparing a row/column/box's fixed total of 45 against the cage sums overlapping it). Neither
technique addition moved the needle at all on real generated puzzles.

Investigation why: a maximally-constraining 2-cell cage (an extreme sum with only one valid
digit pair) still narrows its two cells to 2 candidates each, never 1 — a true naked single is
structurally impossible as the very first move on a truly blank grid, regardless of how many
more advanced techniques get added. Rule of 45 needs cages that are *fully contained* within a
row/column/box to leave a clean remainder; this project's `CageLayoutGenerator` grows cages via
unbiased orthogonal expansion with no preference for staying inside a single row/column/box, so
that alignment rarely happens by chance.

Researched how real Killer Sudoku implementations handle this (see the issue #2 discussion for
the full trail): a toy project just bundles a handful of hand-made puzzle files (no generation
at all); an unfinished WIP acknowledges its brute-force solver "runs indefinitely" on some
inputs; one uses cage-size as an explicit difficulty proxy. The most informative reference,
KDE's ksudoku (`CageGenerator`, `MathdokuGenerator`) — mature, real, shipped software — settled
the question: it hardcodes `mMinSingles = 2, mMaxSingles = 4` (2-4 single-cell cages, which are
just givens under a different name) into *every* generated puzzle regardless of difficulty, and
its actual difficulty parameter is `maxSize` (max cage size grows with difficulty) — a pure
structural heuristic, with no post-hoc verification the result is actually the intended
difficulty. No implementation found actually does zero-given, procedurally-graded classic-mode
generation — this project set out to solve a harder problem than established prior art
attempts.

Three paths considered:

- **Match KDE's structural-heuristic approach**: drop technique-simulation grading, keep zero
  givens, use max cage size as the difficulty proxy. Matches what's proven to ship, but throws
  away [[CONTEXT.md]]'s explicit "not a structural heuristic" requirement and this project's own
  (already-working) grader.
- **Small constant given baseline, keep real grading**: add 2-4 single-cell cages (matching
  KDE's baseline) to classic mode, keep the existing solving-technique grader — which is already
  a genuine improvement over KDE's own heuristic-only approach. Costs the "purist, zero-given"
  framing from the original grilling session.
- **Keep pushing zero-given + real grading**: no prior art solves this combination; continuing
  would mean open-ended, unproven work (multi-region 45-rule combinations spanning bands/stacks,
  more technique classes) with no evidence it converges — the same shape of dead end hit twice
  already in this issue.

## Decision

Classic mode gets a small constant given baseline: 2-4 single-cell cages, generated the same way
regardless of difficulty tier (Easy through Expert) — mirroring KDE ksudoku's baseline. The rest
of the grid stays 100% covered by cages sized 2-4, exactly as before. Difficulty grading stays
real solving-technique simulation ([[0003]], unchanged design), now running against a board that
includes this baseline rather than a literally blank one.

## Consequences

Classic mode is no longer the fully given-less "purist" form CONTEXT.md originally described —
that framing is retired in favor of what's actually achievable with real difficulty grading. The
given baseline is *constant* across tiers (not difficulty-scaled), so it doesn't become the
difficulty lever itself — cage shape, size, and which techniques are required to finish still do
that work, keeping faith with "not a structural heuristic" for the part that actually
differentiates Easy from Expert. Classic and hybrid mode are now points on the same
givens-quantity spectrum (few vs. many) rather than a binary givens/no-givens split, which also
simplifies how issue #3 (hybrid mode) can reuse this same mechanism at a larger given count. This
needs re-validating empirically (does grading real generated puzzles now actually produce a
difficulty spread?) before the rest of issue #2 (difficulty-driven generation retry, New Puzzle
UI) is built on top of it.
