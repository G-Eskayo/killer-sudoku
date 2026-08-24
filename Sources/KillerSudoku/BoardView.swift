import SwiftUI
import KillerSudokuCore

/// Static + selection rendering only (issue #2/#3 scope). Mistake highlighting, same-digit
/// highlight, and the completion legend are separate later slices (#5-#7) and deliberately not
/// implemented here yet.
struct BoardView: View {
    let board: Board
    let selected: Coordinate?
    let cellSize: CGFloat

    private var boardSize: CGFloat { cellSize * 9 }

    var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        }
        .frame(width: boardSize, height: boardSize)
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        drawSelection(in: &context)
        drawGridLines(in: &context)
        drawCageBorders(in: &context)
        drawCageSums(in: &context)
        drawDigits(in: &context)
        drawPencilMarks(in: &context)
    }

    private func drawSelection(in context: inout GraphicsContext) {
        guard let selected else { return }
        let rect = cellRect(row: selected.row, column: selected.column).insetBy(dx: 2, dy: 2)
        context.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(.accentColor), lineWidth: 3)
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

    private func drawCageBorders(in context: inout GraphicsContext) {
        let dashInset: CGFloat = 4
        let dashStyle = StrokeStyle(lineWidth: 1.5, dash: [4, 3])

        for row in 0..<9 {
            for column in 0..<9 {
                let coordinate = Coordinate(row: row, column: column)
                guard let cage = board.cage(at: coordinate) else { continue }
                let rect = cellRect(row: row, column: column).insetBy(dx: dashInset, dy: dashInset)

                func isSameCage(_ other: Coordinate?) -> Bool {
                    guard let other else { return false }
                    return board.cage(at: other)?.id == cage.id
                }

                var path = Path()
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
                context.stroke(path, with: .color(.primary.opacity(0.55)), style: dashStyle)
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

    private func drawDigits(in context: inout GraphicsContext) {
        for row in 0..<9 {
            for column in 0..<9 {
                guard let digit = board.cell(at: Coordinate(row: row, column: column)).digit else { continue }
                let rect = cellRect(row: row, column: column)
                context.draw(
                    Text("\(digit)").font(.system(size: cellSize * 0.5)),
                    at: CGPoint(x: rect.midX, y: rect.midY),
                    anchor: .center
                )
            }
        }
    }

    private func drawPencilMarks(in context: inout GraphicsContext) {
        for row in 0..<9 {
            for column in 0..<9 {
                let cell = board.cell(at: Coordinate(row: row, column: column))
                guard cell.digit == nil, !cell.pencilMarks.isEmpty else { continue }
                let rect = cellRect(row: row, column: column)
                let subCell = cellSize / 3

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

    private func cellRect(row: Int, column: Int) -> CGRect {
        CGRect(x: CGFloat(column) * cellSize, y: CGFloat(row) * cellSize, width: cellSize, height: cellSize)
    }
}
