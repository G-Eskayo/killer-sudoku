# 0013 — Cooperative solver cancellation, oversubscribed batches

## Status

Accepted (2026-08-26)

## Context

Player ask: generate every puzzle within 3 seconds, ideally. [[0010]] already parallelized
generation into batches sized to CPU core count, but `DispatchQueue.concurrentPerform` always
waits for the *whole* batch even after one attempt succeeds — a straggler still burning through
its own search gets no signal that the answer is already found, so a batch's wall-clock time is
bounded by its slowest member, not its fastest.

Separately, profiling found the harder-hitting cost: at a measured 5-15% per-attempt success rate,
a batch sized to exactly the core count fails *outright* (every single attempt non-unique or
inconclusive) well over half the time — and when that happens, there's nothing for cancellation to
even help with, since no attempt succeeded to cancel the others against.

## Decision

Two changes, addressing each cause:

1. `PuzzleSolver.verify` gains an optional `isCancelled: (() -> Bool)?`, polled every 256 search
   nodes (and on the very first node, so a search cancelled before it even starts doesn't run
   256 nodes first) and treated the same as exceeding the node budget — inconclusive, not a
   definite answer. `PuzzleGenerator`'s `ResultBox` (the batch's "first one wins" slot) doubles as
   this signal: every attempt in a batch polls `box.hasResult`, so the moment any one succeeds,
   the rest abort within a bounded number of nodes instead of running to their own conclusion.

2. Batch size is oversubscribed to twice the CPU core count rather than exactly matching it,
   raising the odds that at least one attempt in a given round succeeds at all — GCD queues the
   excess and schedules it as cores free up, and cancellation (above) keeps the cost of the extra
   attempts low once a winner does appear, rather than multiplying worst-case cost by the
   oversubscription factor.

Multiplier chosen empirically: measured head-to-head against 1x (exactly core count) and 4x over
10 runs each. 2x had the best combination of average time and share of runs under 3 seconds, but
the measurement itself was noisy enough (likely sustained CPU load from this same session's own
heavy test activity) that this is the better of what was actually compared, not a precise optimum.

## Consequences

Measured combined result across tiers (24 runs, since tier doesn't actually affect this cost —
verification happens before givens are chosen, so difficulty has no bearing on generation time):
roughly 60-75% of generations complete within 3 seconds, average around 3-4 seconds, with an
occasional tail up to ~15-20 seconds when an unlucky run needs many more attempts than average to
find a uniquely-solvable cage layout at all.

"Always within 3 seconds" is not something this approach can guarantee. Success or failure per
attempt is genuinely probabilistic (a random cage partition either happens to be uniquely solvable
or it doesn't), and that distribution has a real tail — no amount of parallelism tuning changes the
*probability* of needing an unlucky number of attempts, only how cheaply those attempts run.
Meaningfully closing the gap further would mean attacking the *success rate itself* (e.g. biasing
`CageLayoutGenerator`'s cage-shape distribution toward layouts statistically more likely to be
uniquely solvable) rather than parallelizing around a fixed low rate — a real algorithmic question
with uncertain payoff, not pursued here.
