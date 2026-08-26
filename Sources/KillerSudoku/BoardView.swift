import SwiftUI
import KillerSudokuCore

struct BoardView: View {
    let board: Board
    let selected: Coordinate?
    let cellSize: CGFloat

    /// Trigger timestamps for issue #10's micro-interaction animations, keyed by whatever just
    /// transitioned into that state (a coordinate newly mistaken, a cage/row/column/box newly
    /// completed). Populated by the `onChange` handlers below, which diff against the *previous*
    /// value so an animation only starts on a genuine transition, not every time `body` re-runs
    /// with the same still-true state.
    @State private var mistakePulseStarts: [Coordinate: Date] = [:]
    @State private var cagePulseStarts: [Int: Date] = [:]
    @State private var rowPulseStarts: [Int: Date] = [:]
    @State private var columnPulseStarts: [Int: Date] = [:]
    @State private var boxPulseStarts: [Int: Date] = [:]
    @State private var completionFlourishStart: Date?

    // Widened from the original pass per feedback that the animations read as too subtle to
    // notice at a glance.
    private static let mistakePulseDuration: TimeInterval = 0.8
    private static let cageCelebrationDuration: TimeInterval = 0.7
    private static let lineCelebrationDuration: TimeInterval = 0.9
    private static let completionFlourishDuration: TimeInterval = 1.6

    private var boardSize: CGFloat { cellSize * 9 }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                draw(in: &context, size: size, now: timeline.date)
            }
        }
        .frame(width: boardSize, height: boardSize)
        .onChange(of: board.mistakenCoordinates()) { previous, current in
            let now = Date()
            for coordinate in current.subtracting(previous) { mistakePulseStarts[coordinate] = now }
        }
        .onChange(of: board.correctlyCompletedCageIDs()) { previous, current in
            let now = Date()
            for id in current.subtracting(previous) { cagePulseStarts[id] = now }
        }
        .onChange(of: board.correctlyCompletedRowIndices()) { previous, current in
            let now = Date()
            for row in current.subtracting(previous) { rowPulseStarts[row] = now }
        }
        .onChange(of: board.correctlyCompletedColumnIndices()) { previous, current in
            let now = Date()
            for column in current.subtracting(previous) { columnPulseStarts[column] = now }
        }
        .onChange(of: board.correctlyCompletedBoxIndices()) { previous, current in
            let now = Date()
            for box in current.subtracting(previous) { boxPulseStarts[box] = now }
        }
        .onChange(of: board.isSolved) { _, isSolved in
            if isSolved { completionFlourishStart = Date() }
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, now: Date) {
        drawSameDigitHighlight(in: &context)
        drawRowColumnCelebrations(in: &context, now: now)
        drawSelection(in: &context)
        drawGridLines(in: &context)
        drawCageBorders(in: &context)
        drawCageCelebrations(in: &context, now: now)
        drawCageSums(in: &context)
        drawBoxCelebrations(in: &context, now: now)
        drawMistakes(in: &context, now: now)
        drawDigits(in: &context)
        drawPencilMarks(in: &context)
        drawCompletionFlourish(in: &context, now: now)
    }

    /// 1 right at the trigger instant, easing out to 0 over `duration`. 0 (and skippable by the
    /// caller) once elapsed time is negative (shouldn't happen) or past `duration`.
    private func pulseProgress(since start: Date?, duration: TimeInterval, now: Date) -> CGFloat {
        guard let start else { return 0 }
        let elapsed = now.timeIntervalSince(start)
        guard elapsed >= 0, elapsed < duration else { return 0 }
        let t = CGFloat(elapsed / duration)
        return (1 - t) * (1 - t)
    }

    /// A subtle background fill (brightness, not color) on every other cell holding the same
    /// digit as the current selection — deliberately a different non-color treatment than
    /// `drawMistakes`'s outline+glow, so the two cues stay visually distinct at a glance even
    /// though neither uses hue.
    private func drawSameDigitHighlight(in context: inout GraphicsContext) {
        guard let selected else { return }
        for coordinate in board.sameDigitCoordinates(as: selected) {
            let rect = cellRect(row: coordinate.row, column: coordinate.column).insetBy(dx: 1, dy: 1)
            context.fill(Path(rect), with: .color(.primary.opacity(0.12)))
        }
    }

    private func drawSelection(in context: inout GraphicsContext) {
        guard let selected else { return }
        let rect = cellRect(row: selected.row, column: selected.column).insetBy(dx: 2, dy: 2)
        context.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(.accentColor), lineWidth: 3)
    }

    /// Issue #10: a brief brightness sweep across a row or column the instant it's completed
    /// correctly, fading out. Same fill-under-digits treatment as `drawSameDigitHighlight`, at a
    /// higher peak opacity since it's a one-shot celebration rather than a standing indicator.
    private func drawRowColumnCelebrations(in context: inout GraphicsContext, now: Date) {
        for row in 0..<9 {
            let progress = pulseProgress(since: rowPulseStarts[row], duration: Self.lineCelebrationDuration, now: now)
            guard progress > 0 else { continue }
            let rect = CGRect(x: 0, y: CGFloat(row) * cellSize, width: boardSize, height: cellSize).insetBy(dx: 1, dy: 1)
            context.fill(Path(rect), with: .color(.primary.opacity(0.24 * progress)))
        }
        for column in 0..<9 {
            let progress = pulseProgress(since: columnPulseStarts[column], duration: Self.lineCelebrationDuration, now: now)
            guard progress > 0 else { continue }
            let rect = CGRect(x: CGFloat(column) * cellSize, y: 0, width: cellSize, height: boardSize).insetBy(dx: 1, dy: 1)
            context.fill(Path(rect), with: .color(.primary.opacity(0.24 * progress)))
        }
    }

    /// Issue #10: a brief outline flash around a 3x3 box the instant it's completed correctly.
    /// An outline rather than a fill (unlike row/column) so it doesn't stack with those fills'
    /// opacity and read as over-emphasized when a box completes alongside a row or column.
    private func drawBoxCelebrations(in context: inout GraphicsContext, now: Date) {
        for boxIndex in 0..<9 {
            let progress = pulseProgress(since: boxPulseStarts[boxIndex], duration: Self.lineCelebrationDuration, now: now)
            guard progress > 0 else { continue }
            let startRow = (boxIndex / 3) * 3
            let startColumn = (boxIndex % 3) * 3
            let rect = CGRect(
                x: CGFloat(startColumn) * cellSize, y: CGFloat(startRow) * cellSize,
                width: cellSize * 3, height: cellSize * 3
            ).insetBy(dx: 2, dy: 2)
            context.stroke(
                Path(roundedRect: rect, cornerRadius: 4),
                with: .color(.primary.opacity(0.62 * progress)), lineWidth: 3.5
            )
        }
    }

    /// Outline + glow, deliberately no color (CONTEXT.md: color is reserved for nothing in this
    /// app since cage tints were dropped — every play-state cue must be colorblind-safe by
    /// construction). `.primary`-based stroke plus a soft shadow reads as "wrong" without relying
    /// on hue. Issue #10's mistake pulse briefly widens the glow right when a cell newly becomes
    /// mistaken, decaying back to this steady-state radius for as long as it stays mistaken.
    private func drawMistakes(in context: inout GraphicsContext, now: Date) {
        for coordinate in board.mistakenCoordinates() {
            let rect = cellRect(row: coordinate.row, column: coordinate.column).insetBy(dx: 2, dy: 2)
            let path = Path(roundedRect: rect, cornerRadius: 3)
            let pulse = pulseProgress(since: mistakePulseStarts[coordinate], duration: Self.mistakePulseDuration, now: now)
            context.drawLayer { layer in
                layer.addFilter(.shadow(color: .primary.opacity(0.9), radius: 4 + 16 * pulse))
                layer.stroke(path, with: .color(.primary.opacity(0.9)), lineWidth: 2.5)
            }
        }
    }

    private func drawGridLines(in context: inout GraphicsContext) {
        for i in 0...9 {
            let isBoxLine = i % 3 == 0
            let lineWidth: CGFloat = isBoxLine ? 2.5 : 1
            let color = Color.primary.opacity(isBoxLine ? 0.8 : 0.3)

            var vertical = Path()
            vertical.move(to: CGPoint(x: CGFloat(i) * cellSize, y: 0))
            vertical.addLine(to: CGPoint(x: CGFloat(i) * cellSize, y: boardSize))
            context.stroke(vertical, with: .color(color), lineWidth: lineWidth)

            var horizontal = Path()
            horizontal.move(to: CGPoint(x: 0, y: CGFloat(i) * cellSize))
            horizontal.addLine(to: CGPoint(x: boardSize, y: CGFloat(i) * cellSize))
            context.stroke(horizontal, with: .color(color), lineWidth: lineWidth)
        }
    }

    /// The dashed outline for one cage: a line segment along every edge of every one of its
    /// cells that *doesn't* border another cell of the same cage. Shared by the static border
    /// (`drawCageBorders`) and the completion echo (`drawCageCelebrations`), which draws this
    /// same shape again inside a scaled, fading layer.
    private func cageBorderPath(for cage: Cage, inset: CGFloat) -> Path {
        var path = Path()
        for coordinate in cage.cells {
            let row = coordinate.row
            let column = coordinate.column
            let rect = cellRect(row: row, column: column).insetBy(dx: inset, dy: inset)

            func isSameCage(_ other: Coordinate?) -> Bool {
                guard let other else { return false }
                return board.cage(at: other)?.id == cage.id
            }

            if !isSameCage(row > 0 ? Coordinate(row: row - 1, column: column) : nil) {
                path.move(to: CGPoint(x: rect.minX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            }
            if !isSameCage(row < 8 ? Coordinate(row: row + 1, column: column) : nil) {
                path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            }
            if !isSameCage(column > 0 ? Coordinate(row: row, column: column - 1) : nil) {
                path.move(to: CGPoint(x: rect.minX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            }
            if !isSameCage(column < 8 ? Coordinate(row: row, column: column + 1) : nil) {
                path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            }
        }
        return path
    }

    private func drawCageBorders(in context: inout GraphicsContext) {
        let dashStyle = StrokeStyle(lineWidth: 1.5, dash: [4, 3])
        for cage in board.cages {
            context.stroke(cageBorderPath(for: cage, inset: 4), with: .color(.primary.opacity(0.55)), style: dashStyle)
        }
    }

    /// Issue #10's cage-complete fade/scale: an echo of the cage's own border, scaled outward
    /// from its centroid and faded, playing once right when the cage becomes correctly filled.
    /// The static border from `drawCageBorders` is untouched underneath — this only adds a
    /// transient highlight on top of it.
    private func drawCageCelebrations(in context: inout GraphicsContext, now: Date) {
        for cage in board.cages {
            let progress = pulseProgress(since: cagePulseStarts[cage.id], duration: Self.cageCelebrationDuration, now: now)
            guard progress > 0 else { continue }

            let rects = cage.cells.map { cellRect(row: $0.row, column: $0.column) }
            let centroid = CGPoint(
                x: rects.map(\.midX).reduce(0, +) / CGFloat(rects.count),
                y: rects.map(\.midY).reduce(0, +) / CGFloat(rects.count)
            )
            let scale = 1 + 0.1 * progress
            let path = cageBorderPath(for: cage, inset: 4)

            context.drawLayer { layer in
                layer.translateBy(x: centroid.x, y: centroid.y)
                layer.scaleBy(x: scale, y: scale)
                layer.translateBy(x: -centroid.x, y: -centroid.y)
                layer.stroke(path, with: .color(.primary.opacity(0.8 * progress)), lineWidth: 3)
            }
        }
    }

    private func drawCageSums(in context: inout GraphicsContext) {
        for cage in board.cages {
            guard let topLeft = cage.cells.min(by: { ($0.row, $0.column) < ($1.row, $1.column) }) else { continue }
            let rect = cellRect(row: topLeft.row, column: topLeft.column)
            context.draw(
                Text("\(cage.sum)").font(.system(size: 10, weight: .medium)).foregroundColor(.secondary),
                at: CGPoint(x: rect.minX + 6, y: rect.minY + 3),
                anchor: .topLeading
            )
        }
    }

    /// A given (ADR 0008) draws bold at full `.primary` opacity, reading as fixed/"printed";
    /// a player-entered digit draws at regular weight and a touch of transparency, so the two
    /// are visually distinguishable without relying on color — matching `Board.setDigit`'s
    /// refusal to let a given be changed.
    private func drawDigits(in context: inout GraphicsContext) {
        for row in 0..<9 {
            for column in 0..<9 {
                let cell = board.cell(at: Coordinate(row: row, column: column))
                guard let digit = cell.digit else { continue }
                let rect = cellRect(row: row, column: column)
                let font = Font.system(size: cellSize * 0.5, weight: cell.isGiven ? .semibold : .regular)
                let text = cell.isGiven
                    ? Text("\(digit)").font(font)
                    : Text("\(digit)").font(font).foregroundColor(.primary.opacity(0.78))
                context.draw(text, at: CGPoint(x: rect.midX, y: rect.midY), anchor: .center)
            }
        }
    }

    /// The whole 3x3 mark grid is inset from the cell edges — not just made smaller — so its
    /// top-left slot (digit 1) clears `drawCageSums`'s label, which always sits in the cell's
    /// top-left corner. A uniform shrink alone would still leave slot 1 anchored at the same
    /// corner the sum label occupies.
    private static let pencilMarkInset: CGFloat = 12

    private func drawPencilMarks(in context: inout GraphicsContext) {
        for row in 0..<9 {
            for column in 0..<9 {
                let cell = board.cell(at: Coordinate(row: row, column: column))
                guard cell.digit == nil, !cell.pencilMarks.isEmpty else { continue }
                let rect = cellRect(row: row, column: column).insetBy(dx: Self.pencilMarkInset, dy: Self.pencilMarkInset)
                let subCell = rect.width / 3

                for mark in cell.pencilMarks {
                    let slot = mark - 1
                    let subRow = slot / 3
                    let subColumn = slot % 3
                    let point = CGPoint(
                        x: rect.minX + subCell * (CGFloat(subColumn) + 0.5),
                        y: rect.minY + subCell * (CGFloat(subRow) + 0.5)
                    )
                    context.draw(
                        Text("\(mark)").font(.system(size: subCell * 0.65)).foregroundColor(.secondary),
                        at: point,
                        anchor: .center
                    )
                }
            }
        }
    }

    /// Issue #10's full-puzzle-completion flourish: a glowing border around the entire board,
    /// strong right at the solve and fading out over a second. One-shot, triggered by
    /// `board.isSolved` transitioning to true.
    private func drawCompletionFlourish(in context: inout GraphicsContext, now: Date) {
        let progress = pulseProgress(since: completionFlourishStart, duration: Self.completionFlourishDuration, now: now)
        guard progress > 0 else { return }
        let rect = CGRect(x: 0, y: 0, width: boardSize, height: boardSize).insetBy(dx: 2, dy: 2)
        let path = Path(roundedRect: rect, cornerRadius: 6)
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: .primary.opacity(0.8), radius: 18 * progress))
            layer.stroke(path, with: .color(.primary.opacity(0.9 * progress)), lineWidth: 5)
        }
    }

    private func cellRect(row: Int, column: Int) -> CGRect {
        CGRect(x: CGFloat(column) * cellSize, y: CGFloat(row) * cellSize, width: cellSize, height: cellSize)
    }
}
