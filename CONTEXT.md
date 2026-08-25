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
  Sudoku. In classic mode a given is always represented as a **single-cell cage** (a cage of
  size 1 — its "sum" is just that one cell's digit, so it's unambiguous by construction); in
  hybrid mode givens sit outside the cage system entirely, pre-filled directly like a normal
  Sudoku clue. See [[0006]] for why classic mode has givens at all.

## Modes

- **Classic mode**: a small, constant baseline of givens (2-4 single-cell cages) at every
  non-Beginner tier, with the rest of the grid 100% covered by cages sized 2-4 — not the fully
  given-less "purist" form originally envisioned. [[0006]] documents why: real-world Killer
  Sudoku generators (researched during issue #2) don't attempt zero-given, procedurally-graded
  classic puzzles either — they all lean on a small constant given baseline to make the grid
  breakable at all, independent of difficulty tier. The baseline stays constant across Easy
  through Expert; only cage shape/size and what techniques are required change with difficulty.
- **Hybrid mode**: substantially more givens are pre-filled (like standard Sudoku) alongside
  cages covering the rest of the grid, making the puzzle meaningfully more approachable than
  classic mode's small baseline. Used for the Beginner difficulty tier only — the more
  pre-filled, more onboarding-friendly end of the same givens spectrum classic mode's baseline
  sits at the other end of, not a separate mechanic.

## Difficulty

- **Difficulty tier**: one of Beginner, Easy, Medium, Hard, Expert/Extreme (exact top-tier
  naming/count still open). Beginner is hybrid mode; every tier above it is classic mode.
- **Solving-technique grading**: how the generator assigns a puzzle to a difficulty tier — by
  determining which solving techniques are *required* to crack it without guessing (basic
  cage-sum arithmetic and single candidates for low tiers, advanced cage-combination deduction
  for high tiers), not by a structural heuristic like cage count or size. See [[0003]] and
  [[0006]] — grading runs against the board including its constant given baseline (classic mode)
  or full given set (hybrid mode), not a literally blank grid.

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
