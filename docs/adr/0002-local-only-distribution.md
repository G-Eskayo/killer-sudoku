# 0002 — Distribute as a local, notarized build — not through the Mac App Store

## Status

Accepted (2026-08-24)

## Context

The app was scoped as a personal, ad-free Sudoku app for the user's own laptop, not as a
product meant for wide discovery. Two paths were considered:

- **Mac App Store**: requires an Apple Developer account, App Sandbox entitlements, and a
  review pass for every release. Buys discoverability and painless install/update across
  Macs, but for a single-player offline game with no server component, sandboxing buys little
  and review overhead buys nothing the user asked for.
- **Local-only, notarized**: build and notarize the app directly, install it without going
  through the Store. No sandbox entitlement constraints, no review cycles, fastest path to
  shipping something that's "just mine."

## Decision

Distribute as a local, notarized `.app` build outside the Mac App Store. No App Sandbox
entitlements are required by this choice.

## Consequences

Faster iteration (no review cycle) and no sandboxing constraints to design around. The gap
this leaves: if the project later gets released more broadly (e.g. as a portfolio piece others
install), moving to the App Store means retrofitting App Sandbox entitlements and possibly
adjusting how local data (puzzle progress, stats) is stored — revisit this ADR if that need
arises rather than assuming today's file-access patterns port over unchanged.
