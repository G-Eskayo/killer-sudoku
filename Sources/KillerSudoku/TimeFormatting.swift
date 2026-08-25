import Foundation

/// Shared by `TimerView` and `StatsView` so "mm:ss" only has one implementation.
extension TimeInterval {
    var formattedAsMinutesAndSeconds: String {
        let totalSeconds = max(0, Int(self))
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}
