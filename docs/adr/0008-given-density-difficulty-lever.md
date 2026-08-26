# 0008 — Classic-mode givens live inside normal cages and become the difficulty lever

## Status

Accepted (2026-08-25)

## Context

Player feedback on [[0006]]'s given baseline: a dedicated single-cell cage reads as an artificial
"box within a box" — a dashed square around one cell, showing a redundant sum label on top of a
digit that's already displayed. The requested fix was for a given digit to be scattered inside an
ordinary 2-4 cell cage instead — that cage keeps its normal size, sum, and border; one of its
cells just happens to already show its digit. This was checked against hybrid mode's existing
cage-exempt given mechanic (no box at all around the given) and confirmed to be a different,
new mechanic, not a reuse of hybrid's.

Implementing "reveal a digit but leave the cell as a normal cage member" surfaced a real bug risk:
[[PuzzleSolver]]'s `givens` parameter (used today by hybrid mode) hardcodes `cageIndex: -1` when
placing a given, since hybrid's givens are never part of any cage. Reusing it naively for a given
that *is* part of a cage would silently drop that digit's contribution to its cage's partial sum.
Fixed by looking up the given's real cage index instead of forcing -1, falling back to -1 only
when the coordinate genuinely isn't covered by any cage (hybrid's case, unaffected).

That fix turned out not to matter for classic mode's *uniqueness* check in the end (see below),
but is kept anyway as a correctness fix to a public API that accepted this input combination
without handling it properly.

With givens now structurally meaningful, the discussion extended further: rather than a small
flat baseline (constant across every non-Beginner tier, per [[0006]]'s explicit "not the
difficulty lever" position), given-density itself becomes classic mode's tier signal — Expert
sparse, Easy dense — deliberately reopening that position. This also removes [[0007]]'s
difficulty-matching retry loop (regenerate until `nodesVisited` happens to land in the requested
tier's bucket), which 0007 itself flagged as possibly needing "more attempts than uniqueness
alone" — confirmed in practice: the test suite's single `generate(difficulty: .easy)` call took
~18.5s. Given-density is decided directly at generation time, so a specific tier no longer needs
a lucky search-effort roll to hit.

A second bug surfaced by the test suite after implementation: the first version verified
uniqueness with cages *and* givens together (mirroring hybrid mode's pattern), which let a
genuinely ambiguous cage layout (two valid completions) slip through whenever the chosen givens
happened to rule out one of them — a real generated puzzle failed
`countSolutions(cages:, upTo: 2) == 1` (found 2) despite passing the cages+givens check. Unlike
hybrid mode — where givens sit outside the cage system and are load-bearing for uniqueness by
construction, since those cells have no cage constraint at all — classic mode's cage layout is
already 100% self-contained and should stand on its own as a real Killer Sudoku puzzle (solvable
by cage-sum logic alone); a given is a bonus reveal layered on top of an already-valid puzzle, not
something its validity should depend on. Fixed by checking uniqueness from the cage structure
alone, before givens are even chosen.

## Decision

Classic mode (Easy through Expert; Beginner is unaffected, still hybrid mode's cage-exempt
mechanic at a fixed 20 givens) generates a normal, fully cage-covered board — no single-cell
cages — then reveals a given-count drawn from a per-tier range, out of 81 cells:

| Tier   | Given cells | Approx. % |
|--------|-------------|-----------|
| Expert | 4-8         | 5-10%     |
| Hard   | 9-16        | 11-20%    |
| Medium | 17-24       | 21-30%    |
| Easy   | 25-40       | 31-49%    |

A given cell stays an ordinary member of its 2-4-cell cage. `CageLayoutGenerator`'s
`givensCount`/single-cell-cage seeding is deleted (dead once nothing calls it with a nonzero
count); `Cage`'s size precondition reverts to 2-4 cells, since size-1 cages no longer occur
anywhere in the system. `PuzzleSolver`'s given-placement now credits a given's real cage
membership rather than always treating it as cage-exempt (general correctness fix; not currently
exercised by any caller — see Context). `Difficulty.fromSearchEffort` and its [[0007]] role for
classic mode are removed — given-density, checked deterministically at generation time, is now
the sole classic-mode tier signal, with no retry-until-graded loop. Classic mode's uniqueness
check (`PuzzleSolver.verify(cages:upTo:)`, no givens) runs *before* givens are chosen, on the
cage structure alone.

## Consequences

Classic mode's difficulty is now a structural heuristic (given-density) — the exact approach
[[0006]] deliberately avoided in favor of technique-adjacent grading, and the exact approach
KDE ksudoku uses per [[0006]]'s own research into prior art. That tradeoff is made knowingly here,
in exchange for matching what a given should look like and for materially faster generation.
`DifficultyGrader` (the technique simulator) is untouched — still real, tested, still not used for
grading, same status [[0007]] already left it in.

The per-tier ranges above are a v1 starting point, not empirically calibrated — same caveat
[[0007]]'s original thresholds carried, and it needs the same kind of real-play revisit. Easy's
upper bound (40 of 81 cells, ~49%) sits close to Beginner/hybrid's fixed 20 givens (~25%) despite
being nearly double the percentage — worth watching whether Easy and Beginner end up feeling too
similar in practice even though the underlying given-representation mechanic differs (inside a
normal cage vs. cage-exempt).

Measured trade on generation speed: `generate(difficulty:)` (the New Puzzle flow) got dramatically
faster — no more retry-until-graded loop, ~18.5s down to ~3s for a real test call — since
given-density is chosen directly instead of discovered by chance. But the *ungraded* `generate()`
path (`KillerSudokuApp.swift`'s app-launch fallback, used only when there's no saved puzzle to
restore) got slower: [[0006]]'s single-cell given cages, baked directly into the cage array, gave
cage-alone uniqueness verification a free head start it no longer has now that givens are a
post-hoc reveal rather than part of the cage structure. Measured ~1.8s before this ADR, ~11s
after. This path runs synchronously in `KillerSudokuApp.init()` (unlike the New Puzzle flow, which
already generates off the main actor with a loading state) and is hit exactly once per install —
every later launch restores the saved board instead. Left as a known, documented tradeoff rather
than restructuring app launch to be async for a one-time cost; revisit if it turns out to matter
in practice (e.g. if first-launch freeze becomes a real complaint).
