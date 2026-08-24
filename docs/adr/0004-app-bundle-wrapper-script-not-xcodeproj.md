# 0004 — Package local dev builds as a hand-rolled .app bundle, not a full Xcode project

## Status

Accepted (2026-08-24)

## Context

The first local build was launched with `swift run`, which runs the built executable as a bare
Unix process. In practice this meant the window never behaved like a real macOS app: it wasn't
independent of the launching terminal, and keyboard/click interaction didn't work reliably —
because a bare SPM executable has no `Info.plist`, no bundle identifier, and never gets proper
`NSApplication` activation/focus from macOS the way a real `.app` does.

Two ways to fix that were available:

- **Full Xcode project** (`.xcodeproj`): the standard path for a "real" native Mac app —
  proper target settings, asset catalogs, signing identity picker, and the natural home for
  future notarization work ([[0002]]). But hand-authoring/maintaining a `.pbxproj` outside
  Xcode's GUI is painful, and generating one requires either using Xcode's GUI directly or a
  third-party generator tool not currently installed.
- **Hand-rolled `.app` bundle wrapper around the SPM build**: a small script
  (`scripts/run-app.sh`) builds via `swift build`, assembles a minimal `Contents/MacOS` +
  `Info.plist` bundle around the binary, ad-hoc code-signs it, and launches it via `open`. Keeps
  the existing SPM package structure (and its already-working `swift test` loop) untouched.

## Decision

Use the hand-rolled `.app` bundle wrapper script for local dev builds, not a full Xcode
project, for now.

## Consequences

Fixes the actual bug (no real app activation → broken interaction) with a small, scriptable,
version-controlled build step, and keeps `swift test`/`swift build` as the fast local iteration
loop. The gap this leaves: no asset catalog (app icon, etc.), no signing-identity management
beyond ad-hoc signing, and no path to real notarization ([[0002]] calls for a notarized build) —
ad-hoc signing is only good for running locally on this machine, not for distributing the app
elsewhere. Revisit this ADR (likely moving to a real Xcode project) once app-icon work or actual
notarized distribution becomes the next real task, rather than continuing to extend the script.
