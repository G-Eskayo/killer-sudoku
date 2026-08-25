import Testing
import Foundation
@testable import KillerSudokuCore

@Suite struct PuzzleTimerTests {
    @Test func startsAtZeroElapsed() {
        let timer = PuzzleTimer()
        #expect(timer.elapsed() == 0)
    }

    @Test func elapsedGrowsWhileRunning() {
        let t0 = Date()
        var timer = PuzzleTimer()
        timer.start(now: t0)

        #expect(timer.elapsed(now: t0.addingTimeInterval(5)) == 5)
    }

    @Test func isRunningReflectsState() {
        var timer = PuzzleTimer()
        #expect(!timer.isRunning)
        timer.start()
        #expect(timer.isRunning)
        timer.pause()
        #expect(!timer.isRunning)
    }

    @Test func pauseFreezesElapsedTime() {
        let t0 = Date()
        var timer = PuzzleTimer()
        timer.start(now: t0)
        timer.pause(now: t0.addingTimeInterval(5))

        #expect(timer.elapsed(now: t0.addingTimeInterval(50)) == 5)
    }

    @Test func resumingAfterPauseContinuesAccumulating() {
        let t0 = Date()
        var timer = PuzzleTimer()
        timer.start(now: t0)
        timer.pause(now: t0.addingTimeInterval(5))
        timer.start(now: t0.addingTimeInterval(20))

        #expect(timer.elapsed(now: t0.addingTimeInterval(23)) == 8)
    }

    @Test func resetZeroesElapsedAndStopsRunning() {
        let t0 = Date()
        var timer = PuzzleTimer()
        timer.start(now: t0)

        timer.reset()

        #expect(timer.elapsed(now: t0.addingTimeInterval(10)) == 0)
        #expect(!timer.isRunning)
    }

    @Test func startingWhileAlreadyRunningDoesNotResetTheClock() {
        let t0 = Date()
        var timer = PuzzleTimer()
        timer.start(now: t0)
        timer.start(now: t0.addingTimeInterval(3))

        #expect(timer.elapsed(now: t0.addingTimeInterval(5)) == 5)
    }
}
