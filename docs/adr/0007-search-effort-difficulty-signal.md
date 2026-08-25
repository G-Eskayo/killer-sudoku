# 0007 — Classic-mode difficulty uses solver search effort, not technique simulation

## Status

Accepted (2026-08-25)

## Context

[[0006]] added a small given baseline to classic mode, hoping it would let `DifficultyGrader`'s
solving-technique simulation (naked/hidden singles, Rule of 45, cage-line elimination, naked
pairs) actually differentiate real generated puzzles. It didn't: across three real interventions
(cage-line elimination, Rule of 45, and the given baseline itself), every one of 22+ real
generated classic-mode puzzles graded Expert. Zero spread, no matter what was tried.

[[PuzzleSolver]] already computes something else during its existing uniqueness-verification
pass: how many search-tree nodes it takes to fully prove a puzzle has exactly one solution. That
number was exposed (`PuzzleSolver.verify` returns `nodesVisited` alongside the solution count)
and measured across 10 real generated, accepted puzzles: 352, 1114, 2044, 3000, 4442, 5990, 5995,
7807, 13123, 13808 — roughly a 40x spread, log-scale distributed, no clustering. A puzzle that
takes a brute-force solver more search effort to crack does, in practice, correlate with how hard
it is for a person to crack too, even though the number itself doesn't name which technique a
human would use.

This directly trades away CONTEXT.md's original "not a structural heuristic" framing for
solving-technique grading — search-effort is a computed, not a named-technique, signal. It's a
deliberate, considered trade rather than an accidental drift: technique simulation was tried in
good faith with three real additions and never worked in practice, while this signal empirically
does, and reuses a solve the generator already has to do (no extra verification cost).

## Decision

Classic-mode difficulty (Easy/Medium/Hard/Expert) is assigned from `nodesVisited` — the same
uniqueness-verification search [[PuzzleGenerator]] already runs — via calibrated thresholds
(`Difficulty.fromSearchEffort`), not `DifficultyGrader`'s technique simulation.

`DifficultyGrader` itself is not deleted: it's real, tested, working code, and CONTEXT.md's
technique catalog documentation (naked single, Rule of 45, cage-line, naked pair) remains
accurate as a description of what it does — it's just not the active mechanism gating classic-
mode's New Puzzle flow. It may be revisited for hybrid mode (issue #3), where substantially more
givens might let it actually differentiate, unlike classic mode's small baseline.

## Consequences

Threshold boundaries (`..<1500` easy, `1500..<4500` medium, `4500..<8500` hard, `8500...`
expert) are calibrated from a 10-puzzle sample — a reasonable v1 starting point, not a precise
calibration. They should be revisited if real play data suggests puzzles labeled "Easy" don't
feel easy, or "Expert" puzzles are inconsistently hard.

Requesting a *specific* difficulty tier means retrying until both uniqueness *and* the tier
match, which can need more attempts than uniqueness alone — worth measuring end-to-end before
shipping the New Puzzle UI, the same way [[PuzzleGenerator]]'s own generation latency was
measured and documented honestly in issue #1 rather than assumed.
