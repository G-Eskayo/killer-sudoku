# Killer Sudoku — v1 Scope

Concrete feature scope for the first buildable version, resolved via a grilling session on
2026-08-24. Domain terms are defined in `CONTEXT.md`; architectural decisions with real
trade-offs are in `docs/adr/`. This doc is the "what" — the requirements — not the "why."

## Platform & distribution

- Native macOS app, SwiftUI + `Canvas` for the board ([[0001]]).
- Local-only, notarized build. No Mac App Store, no App Sandbox entitlements ([[0002]]).
- Local persistence via SwiftData (puzzle state, solve history, best times).
- **Hard requirement**: no ads, no in-app purchases, no nags of any kind, ever.

## Puzzle engine

- On-device puzzle generator, not a bundled set ([[0003]]).
- Difficulty graded by solving-technique simulation (what techniques a human would need,
  not structural heuristics).
- Difficulty tiers: Beginner (hybrid mode — many givens), Easy, Medium, Hard, Expert (classic
  mode — a small constant baseline of 2-4 givens at every tier, rest of the grid 100% cage
  coverage; see [[0006]]). Five tiers total; Expert is the single top tier (decided 2026-08-24 —
  see [[0005]] — rather than splitting it into Expert *and* Extreme).
- Single active puzzle at a time, auto-saved continuously. Starting a new puzzle replaces the
  in-progress one — no multi-puzzle library in v1.

## Board interaction

- Keyboard-first: arrow keys / click to select a cell, type 1-9 to fill it, a modifier toggles
  pencil-mark (notes) entry mode.
- Pencil marks are manual only — no auto-candidate computation or "fill all candidates" assist.
- Live, subtle mistake highlighting: any rule violation (duplicate digit in row/column/box/
  cage, or a cage sum already impossible to hit) flags immediately via outline/glow, not a
  popup or sound.
- Same-digit highlight: selecting a cell highlights every other cell currently holding the same
  digit. Must only reflect digits already placed by the player — never expose information about
  unfilled cells.
- Digit completion state: once a digit's 9 instances are all correctly placed, it shows as
  complete in the completion legend (a small, non-interactive 1-9 readout) — but this never
  auto-clears that digit from pencil marks anywhere on the board. Player notes are always
  under full manual control, regardless of completion state.
- No hints of any kind in v1.
- Full undo/redo history for the whole puzzle (Cmd+Z / Cmd+Shift+Z).

## Visual design

- Cages: dashed borders + cage sum labeled in the cage's top-left cell — no per-cage color
  tint (dropped after the bootstrap build showed a "rainbow stripes" problem on regular cage
  shapes; see CONTEXT.md's Visual language section).
- Since color carries no cage-identity meaning, every UI state (mistake, highlight, selection,
  completion) uses non-color cues (outline, glow, brightness), colorblind-safe by construction.
- Follows system light/dark appearance automatically; cage tint palette is a deliberately
  separate, hand-tuned set per appearance mode (not auto-derived from one palette).
- Animation level: subtle micro-interactions only (mistake pulse, cage-complete fade/scale,
  brief full-puzzle-completion flourish) — nothing that slows down solving or feels gimmicky.

## Stats

- Visible, pausable per-puzzle timer.
- Persisted best time and solve history per difficulty tier, stored locally via SwiftData.

## Accessibility

- Full keyboard playability (falls out of the keyboard-first input model).
- No dedicated VoiceOver support in v1 — explicitly deferred, not an oversight.

## Explicitly out of scope for v1

- Mac App Store distribution / App Sandbox.
- Hints of any kind.
- Auto-computed pencil marks / candidates.
- Multiple simultaneous saved in-progress puzzles.
- In-app theme toggle independent of system appearance.
- VoiceOver / deep accessibility work.
