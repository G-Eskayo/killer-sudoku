# 0005 — One top difficulty tier (Expert), not Expert and Extreme split

## Status

Accepted (2026-08-24)

## Context

[[0003]] deferred exactly how many difficulty tiers exist above Hard: a single top tier, or
splitting it into Expert *and* Extreme as two separately-graded tiers. This was blocking issue
#2 (difficulty-graded New Puzzle flow) from being fully specified — the generator's
solving-technique grading logic needs a concrete tier list to grade against, not an open
question.

Two paths:

- **Single top tier (Expert)**: five tiers total — Beginner, Easy, Medium, Hard, Expert.
  Simpler grading logic (one fewer boundary to define and tune), and Extreme-tier Killer Sudoku
  difficulty grading (distinguishing "very hard" from "hardest possible") is a genuinely fuzzy,
  hard-to-validate line even for experienced solvers.
- **Two top tiers (Expert and Extreme)**: six tiers, more granularity for advanced players, but
  needs a second grading boundary above Hard defined well enough that generated puzzles land in
  the right one — real additional design and testing work for a v1.

## Decision

Five difficulty tiers total: Beginner, Easy, Medium, Hard, Expert. No separate Extreme tier in
v1.

## Consequences

Issue #2's solving-technique grading logic has a concrete, closed tier list to build against.
A second, more granular top tier (Extreme) remains a plausible v2 addition once real solve-time
data across players exists to calibrate where that boundary should actually sit — attempting to
define it now, without that data, would be guessing.
