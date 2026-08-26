# 0014 — Ship and measure release builds, not debug

## Status

Accepted (2026-08-26)

## Context

Player question: would rewriting the generator/solver in C++ help hit the 3-second goal
[[0013]] fell short of? Before considering a language rewrite — real interop complexity, a second
toolchain, and one that wouldn't even address [[0013]]'s actual bottleneck, which is the
*probability* a random cage layout is uniquely solvable, not raw per-node speed — a much more
basic question needed checking first: what build configuration was actually being measured.

`scripts/run-app.sh` defaulted to `CONFIG="${1:-debug}"`, and every invocation all session passed
no argument. `swift test` also defaults to debug with no flag. Every profiling number in [[0010]]
and [[0013]] — and the actual running app the player had been testing this entire session — was
an unoptimized debug build: no compiler optimizations, full bounds checking and ARC overhead on
every array access and reference count in the solver's hot inner loop.

Measured the identical code in release: `swift test -c release` over the same 24-run sample
[[0013]] used dropped average generation time from ~3-4s to ~1.0s, with 23/24 runs under 3 seconds
(the one miss at 3.07s) — without changing a single line of the generator or solver.

## Decision

`scripts/run-app.sh` now defaults to `CONFIG="${1:-release}"`. Debug stays available by passing
`debug` explicitly, for faster compile times while iterating on something other than performance.

## Consequences

[[0013]]'s "roughly 60-75% of generations complete within 3 seconds, average around 3-4 seconds"
finding was accurate for debug builds but never represented what a player running the real app
would experience once packaged in release — which was already close to [[0013]]'s original goal
without any of that ADR's parallelism/cancellation work being strictly necessary to *reach* the
3-second target, though it still measurably helps get closer to consistently *always* landing
under it. No ADR gets edited to reflect this after the fact; this one stands as the correction.

The broader lesson: any future performance work on this project must state which build
configuration it measured, and default to measuring release unless debug-specific behavior
(e.g. a debug logging path) is what's actually being investigated. A debug-vs-release gap this
large going unnoticed for two ADRs' worth of tuning is itself worth remembering.
