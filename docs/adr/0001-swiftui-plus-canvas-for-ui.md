# 0001 — Build the app in SwiftUI, with Canvas for custom board/cage drawing

## Status

Accepted (2026-08-24)

## Context

The app's whole reason for existing is UI/UX quality — the user is explicitly tired of
ad-laden, buggy Sudoku apps and wants a top-tier native experience. That put real weight on
getting animations, dark mode, and interaction polish right with minimal hand-rolled plumbing.

Two real alternatives were considered:

- **AppKit**: gives the finest-grained control over custom drawing and interaction, which
  matters for a fussy, precise grid UI (cage borders, cage-sum labels, per-cell highlight
  states). But it means manually building things SwiftUI provides for free — dark mode
  theming, standard animations, VoiceOver wiring — which works against the "top-tier polish,
  no cut corners" goal within a reasonable build effort.
- **AppKit view hosted in a SwiftUI shell** (`NSViewRepresentable`): SwiftUI for chrome/menus/
  settings, hand-drawn Core Graphics for the board itself. Maximum drawing control, but adds
  real complexity — worth it only if SwiftUI's own `Canvas` view turns out to be insufficient
  for cage rendering.

## Decision

Build the app in SwiftUI throughout, using SwiftUI's `Canvas` view for the custom board and
cage drawing (cage borders, cage-sum labels, cell fills) rather than relying solely on stock
SwiftUI shapes or dropping to AppKit.

## Consequences

Gets dark mode, standard animations, and a chunk of accessibility support close to free, and
keeps the codebase in one UI paradigm. The risk this doesn't resolve: if `Canvas`-based
rendering turns out to be too limiting or too slow for smooth cage/board animations at scale,
falling back to an AppKit-hosted board (the third option above) is the escape hatch — revisit
this ADR if that happens rather than fighting `Canvas` indefinitely.
