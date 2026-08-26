# Killer Sudoku — Context Glossary

**App name**: Killer Sudoku (working title, also the app's actual name).

Domain terms only. No implementation details — see `docs/adr/` for decisions and rationale.

## Puzzle structure

- **Cell**: one of the 81 squares in the 9x9 grid. Holds either a **digit** (1-9) or is empty.
- **Cage**: a group of orthogonally-connected cells, outlined on the board, that must together
  sum to its **cage sum** and contain no repeated digit among its own cells. Cages are the
  defining mechanic of Killer Sudoku, layered on top of standard Sudoku's row/column/3x3-box
  uniqueness rules.
- **Cage sum**: the target total shown in the top-left corner of a cage, which the digits placed
  in that cage's cells must add up to exactly once the cage is fully filled.
- **Given**: a digit pre-filled by the puzzle before the player starts, exactly as in standard
  Sudoku. In classic mode a given is an ordinary member of its normal 2-4 cell cage — the cage's
  size, sum, and border are unaffected, one of its cells just already shows its digit. In hybrid
  mode givens sit outside the cage system entirely, pre-filled directly like a normal Sudoku clue
  — a different mechanic, not a smaller version of classic mode's. See [[0008]] for why classic
  mode has givens at all and why they're no longer single-cell cages ([[0006]], superseded).

## Modes

- **Classic mode**: 100% of the grid is covered by cages sized 2-4 — no single-cell cages. A
  given-count is drawn from a per-tier range ([[0008]]) and revealed inside whatever cage those
  cells already belong to. Given-density *is* the difficulty lever for classic mode (sparse at
  Expert, dense at Easy) — see Difficulty below.
- **Hybrid mode**: substantially more givens are pre-filled (like standard Sudoku) alongside
  cages covering the rest of the grid, making the puzzle meaningfully more approachable than
  classic mode. Used for the Beginner difficulty tier only, at a fixed given-count independent of
  the other tiers' scaling.

## Difficulty

- **Difficulty tier**: one of Beginner, Easy, Medium, Hard, Expert — five tiers total, Expert is
  the single top tier ([[0005]]). Beginner is hybrid mode; every tier above it is classic mode.
- **Given-density difficulty signal**: classic mode's active difficulty signal ([[0008]]) — how
  many of the 81 cells are revealed as givens, scaled by tier (Expert sparsest, Easy densest).
  Decided directly at generation time, not discovered by retrying and re-checking. Supersedes two
  earlier attempts: solving-technique simulation ([[0003]]) and solver search effort ([[0007]]),
  neither of which is used for classic-mode grading anymore — see [[0008]] for why.
- **Solving-technique grading**: originally meant determining which solving techniques a puzzle
  *requires* (basic cage-sum arithmetic and single candidates for low tiers, advanced cage-
  combination deduction for high tiers) rather than a structural heuristic like cage count or
  size — [[0003]]. In practice this never differentiated real classic-mode puzzles at all (every
  one graded hardest-tier regardless of actual difficulty). The technique simulator
  (`DifficultyGrader`) itself is still real, tested code; it's just never been what classic mode's
  New Puzzle flow actually uses for grading.

## Play-state indicators

- **Digit completion state**: once all 9 instances of a digit are correctly placed on the
  board, that digit is "complete." Completion is reflected in the completion legend (below)
  but never auto-removes that digit from pencil marks anywhere on the board — the player keeps
  full manual control of their own notes regardless of a digit's completion state. (Deliberately
  fixes a specific annoyance from another app, where completing a digit force-cleared it from
  notes the player hadn't gotten to yet.)
- **Completion legend**: a small, non-interactive 1-9 readout (not a number pad — entry stays
  keyboard-first) that dims a digit once it reaches its completion state. Purely a status
  readout, not an input method.
- **Same-digit highlight**: selecting a cell that contains a digit highlights every other cell
  on the board that currently contains that same digit. Only ever reflects digits the player
  has actually placed — it must never expose information about unfilled cells (e.g. must not
  hint at where a digit *should* go, only echo where it visibly already *is*).

## Visual language

- Cages are dashed borders + a sum label only — no background color tint. (Originally tints
  were planned, but seeing them on the actual bootstrap build — where the placeholder demo
  puzzle's cages happen to all be single-row strips — showed a flat "rainbow stripes" problem;
  dropped rather than risk the same busy read on real irregular cage shapes later.)
- Since color carries no cage-identity meaning, every play-state cue (mistake, same-digit
  highlight, selection, completion) is conveyed with non-color cues — outlines, glow,
  brightness — which was already the plan for those states and remains colorblind-safe by
  construction.
- The app follows the system light/dark setting (no in-app theme toggle).
