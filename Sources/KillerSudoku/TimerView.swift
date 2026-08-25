import SwiftUI
import KillerSudokuCore

/// Visible, pausable per-puzzle timer (issue #8). `TimelineView` redraws this on a 1-second
/// cadence so the displayed elapsed time keeps advancing while running, without `GameState`
/// needing to push updates itself — `PuzzleTimer.elapsed()` is just read fresh each tick.
struct TimerView: View {
    let timer: PuzzleTimer
    let onToggle: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 8) {
                Text(timer.elapsed(now: context.date).formattedAsMinutesAndSeconds)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                Button(action: onToggle) {
                    Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
    }
}
