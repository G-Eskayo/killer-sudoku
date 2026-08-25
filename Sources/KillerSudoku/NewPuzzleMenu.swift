import SwiftUI
import KillerSudokuCore

/// The New Puzzle flow (issue #2): a difficulty picker that starts a fresh classic-mode puzzle,
/// replacing whatever was in progress. Shows a spinner instead of the menu while generating,
/// since a request can take anywhere from well under a second to tens of seconds (ADR 0007).
struct NewPuzzleMenu: View {
    let isGenerating: Bool
    let onSelect: (Difficulty) -> Void

    var body: some View {
        if isGenerating {
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Generating…").font(.caption).foregroundStyle(.secondary)
            }
        } else {
            Menu("New Puzzle") {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    Button(label(for: difficulty)) { onSelect(difficulty) }
                }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }

    private func label(for difficulty: Difficulty) -> String {
        switch difficulty {
        case .beginner: return "Beginner"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }
}
