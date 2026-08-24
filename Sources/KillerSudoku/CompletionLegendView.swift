import SwiftUI
import KillerSudokuCore

/// Small, non-interactive 1-9 readout — CONTEXT.md's "Completion legend". Dims a digit once
/// `Board.completedDigits()` reports it complete. Never touches pencil marks anywhere on the
/// board (that's the whole point of it existing as a separate readout).
struct CompletionLegendView: View {
    let completedDigits: Set<Int>

    var body: some View {
        HStack(spacing: 14) {
            ForEach(1...9, id: \.self) { digit in
                Text("\(digit)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(completedDigits.contains(digit) ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.primary))
            }
        }
    }
}
