import SwiftUI
import KillerSudokuCore

/// Best time and solve count per difficulty tier (issue #9). Deliberately plain — per
/// v1-scope.md's acceptance criteria, "polish not required" for this surface.
struct StatsView: View {
    @ObservedObject var game: GameState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Stats").font(.headline)
            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                let stats = game.stats(for: difficulty)
                HStack {
                    Text(difficulty.displayName)
                        .frame(width: 72, alignment: .leading)
                    Text(stats.solveCount == 0 ? "No solves yet" : "\(stats.solveCount) solved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(stats.bestTime?.formattedAsMinutesAndSeconds ?? "—")
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .padding(16)
        .frame(width: 260)
    }
}
