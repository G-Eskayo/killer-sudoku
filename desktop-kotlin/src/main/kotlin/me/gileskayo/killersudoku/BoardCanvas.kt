package me.gileskayo.killersudoku

import androidx.compose.foundation.Canvas
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameMillis
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.foundation.layout.size
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.TextUnitType
import androidx.compose.ui.unit.dp
import me.gileskayo.killersudoku.core.Board
import me.gileskayo.killersudoku.core.Cage
import me.gileskayo.killersudoku.core.Coordinate
import kotlin.math.pow

/** Issue #10's micro-interaction animations, ported from the Swift board's `TimelineView`
 * approach: a continuously-updating "now" (via [withFrameMillis]-driven recomposition) plus a
 * per-trigger start-timestamp map, diffed against the *previous* frame's completion sets so an
 * animation only starts on a genuine transition, not every recomposition of a still-true state. */
@Composable
fun BoardCanvas(board: Board, selected: Coordinate?, cellSizeDp: Dp, modifier: Modifier = Modifier) {
    val textMeasurer = rememberTextMeasurer()
    var now by remember { mutableLongStateOf(System.currentTimeMillis()) }
    LaunchedEffect(Unit) {
        while (true) {
            withFrameMillis { now = it }
        }
    }

    val mistakePulseStarts = remember { mutableStateOf(mapOf<Coordinate, Long>()) }
    val cagePulseStarts = remember { mutableStateOf(mapOf<Int, Long>()) }
    val rowPulseStarts = remember { mutableStateOf(mapOf<Int, Long>()) }
    val columnPulseStarts = remember { mutableStateOf(mapOf<Int, Long>()) }
    val boxPulseStarts = remember { mutableStateOf(mapOf<Int, Long>()) }
    var completionFlourishStart by remember { mutableStateOf<Long?>(null) }

    val mistaken = remember(board) { board.mistakenCoordinates() }
    val completedCages = remember(board) { board.correctlyCompletedCageIds() }
    val completedRows = remember(board) { board.correctlyCompletedRowIndices() }
    val completedColumns = remember(board) { board.correctlyCompletedColumnIndices() }
    val completedBoxes = remember(board) { board.correctlyCompletedBoxIndices() }
    val isSolved = remember(board) { board.isSolved }

    LaunchedEffect(mistaken) {
        val fresh = System.currentTimeMillis()
        mistakePulseStarts.value = mistakePulseStarts.value + mistaken.filter { it !in mistakePulseStarts.value }.associateWith { fresh }
    }
    LaunchedEffect(completedCages) {
        val fresh = System.currentTimeMillis()
        val newOnes = completedCages.filter { it !in cagePulseStarts.value }
        cagePulseStarts.value = cagePulseStarts.value + newOnes.associateWith { fresh }
    }
    LaunchedEffect(completedRows) {
        val fresh = System.currentTimeMillis()
        val newOnes = completedRows.filter { it !in rowPulseStarts.value }
        rowPulseStarts.value = rowPulseStarts.value + newOnes.associateWith { fresh }
    }
    LaunchedEffect(completedColumns) {
        val fresh = System.currentTimeMillis()
        val newOnes = completedColumns.filter { it !in columnPulseStarts.value }
        columnPulseStarts.value = columnPulseStarts.value + newOnes.associateWith { fresh }
    }
    LaunchedEffect(completedBoxes) {
        val fresh = System.currentTimeMillis()
        val newOnes = completedBoxes.filter { it !in boxPulseStarts.value }
        boxPulseStarts.value = boxPulseStarts.value + newOnes.associateWith { fresh }
    }
    LaunchedEffect(isSolved) {
        if (isSolved) completionFlourishStart = System.currentTimeMillis()
    }

    Canvas(modifier = modifier.size(cellSizeDp * 9)) {
        val cellSize = cellSizeDp.toPx()
        val boardSize = cellSize * 9

        fun cellRect(row: Int, column: Int) =
            Rect(Offset(column * cellSize, row * cellSize), Size(cellSize, cellSize))

        fun pulseProgress(start: Long?, durationMillis: Long): Float {
            if (start == null) return 0f
            val elapsed = now - start
            if (elapsed < 0 || elapsed >= durationMillis) return 0f
            val t = elapsed.toFloat() / durationMillis
            return (1 - t).pow(2)
        }

        drawSameDigitHighlight(board, selected, ::cellRect)
        drawRowColumnCelebrations(rowPulseStarts.value, columnPulseStarts.value, boardSize, cellSize, ::pulseProgress)
        drawSelection(selected, ::cellRect)
        drawGridLines(boardSize, cellSize)
        drawCageBorders(board)
        drawCageCelebrations(board, cagePulseStarts.value, ::cellRect, ::pulseProgress)
        drawCageSums(board, textMeasurer, ::cellRect)
        drawBoxCelebrations(boxPulseStarts.value, cellSize, ::pulseProgress)
        drawMistakes(mistaken, mistakePulseStarts.value, now, ::cellRect)
        drawDigits(board, textMeasurer, cellSize, ::cellRect)
        drawPencilMarks(board, textMeasurer, cellSize, ::cellRect)
        drawCompletionFlourish(completionFlourishStart, boardSize, ::pulseProgress)
    }
}

private val primary = Color.White
private val secondary = Color.White.copy(alpha = 0.6f)

private fun DrawScope.drawSameDigitHighlight(board: Board, selected: Coordinate?, cellRect: (Int, Int) -> Rect) {
    if (selected == null) return
    for (coordinate in board.sameDigitCoordinates(as_ = selected)) {
        val rect = cellRect(coordinate.row, coordinate.column)
        drawRect(primary.copy(alpha = 0.12f), topLeft = rect.topLeft, size = rect.size)
    }
}

private fun DrawScope.drawRowColumnCelebrations(
    rowStarts: Map<Int, Long>, columnStarts: Map<Int, Long>, boardSize: Float, cellSize: Float,
    pulseProgress: (Long?, Long) -> Float,
) {
    for (row in 0..8) {
        val progress = pulseProgress(rowStarts[row], 900)
        if (progress <= 0f) continue
        drawRect(primary.copy(alpha = 0.24f * progress), Offset(0f, row * cellSize), Size(boardSize, cellSize))
    }
    for (column in 0..8) {
        val progress = pulseProgress(columnStarts[column], 900)
        if (progress <= 0f) continue
        drawRect(primary.copy(alpha = 0.24f * progress), Offset(column * cellSize, 0f), Size(cellSize, boardSize))
    }
}

private fun DrawScope.drawSelection(selected: Coordinate?, cellRect: (Int, Int) -> Rect) {
    if (selected == null) return
    val rect = cellRect(selected.row, selected.column).deflate(2f)
    drawRect(Color(0xFF3B82F6), rect.topLeft, rect.size, style = Stroke(width = 3f))
}

private fun DrawScope.drawGridLines(boardSize: Float, cellSize: Float) {
    for (i in 0..9) {
        val isBoxLine = i % 3 == 0
        val width = if (isBoxLine) 2.5f else 1f
        val color = primary.copy(alpha = if (isBoxLine) 0.8f else 0.3f)
        drawLine(color, Offset(i * cellSize, 0f), Offset(i * cellSize, boardSize), strokeWidth = width)
        drawLine(color, Offset(0f, i * cellSize), Offset(boardSize, i * cellSize), strokeWidth = width)
    }
}

private fun cageBorderPath(board: Board, cage: Cage, cellSize: Float, inset: Float): androidx.compose.ui.graphics.Path {
    val path = androidx.compose.ui.graphics.Path()
    fun cellRect(row: Int, column: Int) = Rect(Offset(column * cellSize, row * cellSize), Size(cellSize, cellSize)).deflate(inset)
    for (coordinate in cage.cells) {
        val row = coordinate.row
        val column = coordinate.column
        val rect = cellRect(row, column)

        fun isSameCage(other: Coordinate?): Boolean =
            other != null && board.cageAt(other)?.id == cage.id

        if (!isSameCage(if (row > 0) Coordinate(row - 1, column) else null)) {
            path.moveTo(rect.left, rect.top); path.lineTo(rect.right, rect.top)
        }
        if (!isSameCage(if (row < 8) Coordinate(row + 1, column) else null)) {
            path.moveTo(rect.left, rect.bottom); path.lineTo(rect.right, rect.bottom)
        }
        if (!isSameCage(if (column > 0) Coordinate(row, column - 1) else null)) {
            path.moveTo(rect.left, rect.top); path.lineTo(rect.left, rect.bottom)
        }
        if (!isSameCage(if (column < 8) Coordinate(row, column + 1) else null)) {
            path.moveTo(rect.right, rect.top); path.lineTo(rect.right, rect.bottom)
        }
    }
    return path
}

private fun DrawScope.drawCageBorders(board: Board) {
    val cellSize = size.width / 9
    val dashStyle = Stroke(width = 1.5f, pathEffect = PathEffect.dashPathEffect(floatArrayOf(4f, 3f)))
    for (cage in board.cages) {
        drawPath(cageBorderPath(board, cage, cellSize, 4f), primary.copy(alpha = 0.55f), style = dashStyle)
    }
}

private fun DrawScope.drawCageCelebrations(
    board: Board, cageStarts: Map<Int, Long>, cellRect: (Int, Int) -> Rect, pulseProgress: (Long?, Long) -> Float,
) {
    val cellSize = size.width / 9
    for (cage in board.cages) {
        val progress = pulseProgress(cageStarts[cage.id], 700)
        if (progress <= 0f) continue
        val rects = cage.cells.map { cellRect(it.row, it.column) }
        val centroid = Offset(rects.map { it.center.x }.average().toFloat(), rects.map { it.center.y }.average().toFloat())
        val scale = 1 + 0.1f * progress
        val path = cageBorderPath(board, cage, cellSize, 4f)
        scale(scale, pivot = centroid) {
            drawPath(path, primary.copy(alpha = 0.8f * progress), style = Stroke(width = 3f))
        }
    }
}

private fun DrawScope.drawBoxCelebrations(boxStarts: Map<Int, Long>, cellSize: Float, pulseProgress: (Long?, Long) -> Float) {
    for (boxIndex in 0..8) {
        val progress = pulseProgress(boxStarts[boxIndex], 900)
        if (progress <= 0f) continue
        val startRow = (boxIndex / 3) * 3
        val startColumn = (boxIndex % 3) * 3
        val rect = Rect(
            Offset(startColumn * cellSize, startRow * cellSize), Size(cellSize * 3, cellSize * 3),
        ).deflate(2f)
        drawRect(primary.copy(alpha = 0.62f * progress), rect.topLeft, rect.size, style = Stroke(width = 3.5f))
    }
}

private fun DrawScope.drawMistakes(
    mistaken: Set<Coordinate>, mistakeStarts: Map<Coordinate, Long>, now: Long, cellRect: (Int, Int) -> Rect,
) {
    for (coordinate in mistaken) {
        val rect = cellRect(coordinate.row, coordinate.column).deflate(2f)
        val start = mistakeStarts[coordinate]
        val elapsed = if (start != null) now - start else Long.MAX_VALUE
        // A brief extra-thick stroke right when a mistake newly appears, settling back to a
        // steady-state outline for as long as it stays mistaken (no blur/glow filter, unlike the
        // Swift original -- Compose's DrawScope has no direct shadow primitive; a thicker,
        // brighter stroke conveys the same "this is wrong" cue).
        val width = if (elapsed in 0..800) 2.5f + 4f * (1 - elapsed / 800f) else 2.5f
        drawRect(primary.copy(alpha = 0.9f), rect.topLeft, rect.size, style = Stroke(width = width))
    }
}

private fun DrawScope.drawCageSums(board: Board, textMeasurer: TextMeasurer, cellRect: (Int, Int) -> Rect) {
    for (cage in board.cages) {
        val topLeft = cage.cells.minByOrNull { it.row * 9 + it.column } ?: continue
        val rect = cellRect(topLeft.row, topLeft.column)
        drawText(
            textMeasurer, "${cage.sum}",
            topLeft = Offset(rect.left + 6, rect.top + 3),
            style = TextStyle(color = secondary, fontSize = TextUnit(10f, TextUnitType.Sp), fontWeight = FontWeight.Medium),
        )
    }
}

/** A given draws bold at full brightness, reading as fixed/"printed"; a player-entered digit
 * draws at regular weight and a touch of transparency -- the two are visually distinguishable
 * without relying on color, matching Board.setDigit's refusal to let a given be changed. */
private fun DrawScope.drawDigits(board: Board, textMeasurer: TextMeasurer, cellSize: Float, cellRect: (Int, Int) -> Rect) {
    for (row in 0..8) for (column in 0..8) {
        val cell = board.cellAt(Coordinate(row, column))
        val digit = cell.digit ?: continue
        val rect = cellRect(row, column)
        val style = TextStyle(
            color = if (cell.isGiven) primary else primary.copy(alpha = 0.78f),
            fontSize = TextUnit(cellSize * 0.5f, TextUnitType.Sp),
            fontWeight = if (cell.isGiven) FontWeight.SemiBold else FontWeight.Normal,
        )
        val layout = textMeasurer.measure("$digit", style)
        drawText(layout, topLeft = Offset(rect.center.x - layout.size.width / 2f, rect.center.y - layout.size.height / 2f))
    }
}

/** The whole 3x3 mark grid is inset from the cell edges -- not just made smaller -- so its
 * top-left slot (digit 1) clears the cage-sum label, which always sits in the cell's top-left
 * corner. */
private fun DrawScope.drawPencilMarks(board: Board, textMeasurer: TextMeasurer, cellSize: Float, cellRect: (Int, Int) -> Rect) {
    val inset = 12f
    for (row in 0..8) for (column in 0..8) {
        val cell = board.cellAt(Coordinate(row, column))
        if (cell.digit != null || cell.pencilMarks.isEmpty()) continue
        val rect = cellRect(row, column).deflate(inset)
        val subCell = rect.width / 3

        for (mark in cell.pencilMarks) {
            val slot = mark - 1
            val subRow = slot / 3
            val subColumn = slot % 3
            val style = TextStyle(color = secondary, fontSize = TextUnit(subCell * 0.65f, TextUnitType.Sp))
            val layout = textMeasurer.measure("$mark", style)
            val center = Offset(rect.left + subCell * (subColumn + 0.5f), rect.top + subCell * (subRow + 0.5f))
            drawText(layout, topLeft = Offset(center.x - layout.size.width / 2f, center.y - layout.size.height / 2f))
        }
    }
}

private fun DrawScope.drawCompletionFlourish(start: Long?, boardSize: Float, pulseProgress: (Long?, Long) -> Float) {
    val progress = pulseProgress(start, 1600)
    if (progress <= 0f) return
    val rect = Rect(Offset.Zero, Size(boardSize, boardSize)).deflate(2f)
    drawRect(primary.copy(alpha = 0.9f * progress), rect.topLeft, rect.size, style = Stroke(width = 5f))
}
