import Foundation

/// A pausable stopwatch for the current puzzle. Pure value type — no wall-clock side effects of
/// its own — so callers (a SwiftUI `TimelineView`, say) decide when to re-read `elapsed()`
/// rather than this type pushing updates. `now` is injectable everywhere for deterministic tests.
public struct PuzzleTimer: Sendable {
    private var accumulated: TimeInterval = 0
    private var runningSince: Date?

    public init() {}

    public var isRunning: Bool { runningSince != nil }

    public mutating func start(now: Date = Date()) {
        guard runningSince == nil else { return }
        runningSince = now
    }

    public mutating func pause(now: Date = Date()) {
        guard let since = runningSince else { return }
        accumulated += now.timeIntervalSince(since)
        runningSince = nil
    }

    public mutating func reset() {
        accumulated = 0
        runningSince = nil
    }

    public func elapsed(now: Date = Date()) -> TimeInterval {
        guard let since = runningSince else { return accumulated }
        return accumulated + now.timeIntervalSince(since)
    }
}
