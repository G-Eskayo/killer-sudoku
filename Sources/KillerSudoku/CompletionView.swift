import SwiftUI
import KillerSudokuCore

/// Follow-up to issue #10's board-level completion flourish: that animation is easy to miss
/// entirely at a glance, and there was no explicit moment confirming the puzzle actually ended,
/// what got logged, or what to do next. Shown once per solve via `ContentView`'s
/// `.onChange(of: game.board.isSolved)`, using a snapshot captured at that instant rather than
/// live-reading `game` — the sheet's content shouldn't shift under the player while it's open.
struct CompletionSnapshot: Identifiable {
    let id = UUID()
    let difficulty: Difficulty
    let elapsedSeconds: Double
    let bestTime: Double?
    let solveCount: Int

    /// True when this solve's own time *is* the best on record for its tier — `bestTime` is read
    /// after `StatsStore.record` already ran, so an exact match means this solve set it.
    var isNewBest: Bool {
        guard let bestTime else { return true }
        return elapsedSeconds <= bestTime
    }
}

struct CompletionView: View {
    let snapshot: CompletionSnapshot
    let onNewPuzzle: (Difficulty) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("Solved!")
                    .font(.largeTitle.weight(.bold))
                Text(snapshot.elapsedSeconds.formattedAsMinutesAndSeconds)
                    .font(.system(.title2, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 4) {
                Text("\(snapshot.difficulty.displayName) — \(snapshot.solveCount) solved")
                    .font(.subheadline)
                if snapshot.isNewBest {
                    Text("New best time")
                        .font(.subheadline.weight(.semibold))
                }
            }

            VStack(spacing: 10) {
                Text("New Puzzle").font(.headline)
                ForEach(Difficulty.allCases, id: \.self) { tier in
                    Button {
                        onNewPuzzle(tier)
                        dismiss()
                    } label: {
                        Text(tier.displayName).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(28)
        .frame(width: 260)
    }
}
