import SwiftUI

/// How-to-play help, tucked behind a hover instead of sitting on screen at all times -- the
/// board's own micro-interactions (highlights, animations, the given/entered digit distinction)
/// are meant to teach most of this by feel, so the full explanation only needs to be a beat away,
/// not a permanent fixture. Mirrors the Kotlin port's identical delayed-hover treatment.
struct InfoHoverIcon: View {
    @State private var isHovering = false
    @State private var showTooltip = false

    var body: some View {
        Image(systemName: "info.circle")
            .foregroundStyle(.secondary)
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    // Reveal only after the pointer lingers -- a brief pass-over shouldn't pop a
                    // tooltip, only a deliberate hover. `isHovering` is re-checked when the delay
                    // fires since the pointer may have already left by then.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        if isHovering { showTooltip = true }
                    }
                } else {
                    showTooltip = false
                }
            }
            .popover(isPresented: $showTooltip, arrowEdge: .top) {
                Text("Click a cell, then type 1-9. Shift+1-9 toggles a pencil mark instead. Delete clears. Arrow keys move.")
                    .font(.caption)
                    .padding()
                    .frame(maxWidth: 280)
            }
    }
}
