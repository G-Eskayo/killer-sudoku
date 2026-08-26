package me.gileskayo.killersudoku

import androidx.compose.foundation.focusable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.isShiftPressed
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.input.pointer.PointerInputScope
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Popup
import kotlinx.coroutines.launch
import me.gileskayo.killersudoku.core.Coordinate
import me.gileskayo.killersudoku.core.Difficulty

private val cellSize = 56.dp

@Composable
fun App(game: GameState) {
    var selected by remember { mutableStateOf<Coordinate?>(Coordinate(0, 0)) }
    var showingStats by remember { mutableStateOf(false) }
    var showingResetConfirmation by remember { mutableStateOf(false) }
    var completionSnapshot by remember { mutableStateOf<CompletionSnapshot?>(null) }
    val focusRequester = remember { FocusRequester() }
    val scope = rememberCoroutineScope()

    // Fires only on a genuine false->true transition, not for an already-solved puzzle restored
    // at launch: `previousIsSolved` starts equal to the initial `isSolved`, so the first firing
    // (which LaunchedEffect always runs once, unlike SwiftUI's onChange) always finds no change.
    val isSolved = game.board.isSolved
    var previousIsSolved by remember { mutableStateOf(isSolved) }
    LaunchedEffect(isSolved) {
        if (isSolved && !previousIsSolved) {
            val (bestTime, solveCount) = game.stats(game.currentDifficulty)
            completionSnapshot = CompletionSnapshot(game.currentDifficulty, game.timer.elapsed(), bestTime, solveCount)
        }
        previousIsSolved = isSolved
    }

    LaunchedEffect(Unit) { focusRequester.requestFocus() }

    fun move(rowDelta: Int, columnDelta: Int) {
        val current = selected ?: return
        val newRow = (current.row + rowDelta).coerceIn(0, 8)
        val newColumn = (current.column + columnDelta).coerceIn(0, 8)
        selected = Coordinate(newRow, newColumn)
    }

    Column(modifier = Modifier.padding(24.dp)) {
        Text("Killer Sudoku", style = MaterialTheme.typography.titleLarge)
        Spacer(Modifier.width(8.dp))

        Row(verticalAlignment = Alignment.CenterVertically) {
            NewPuzzleMenu(isGenerating = game.isGeneratingNewPuzzle) { difficulty ->
                scope.launch { game.startNewPuzzle(difficulty) }
            }
            Spacer(Modifier.width(6.dp))
            Text(game.currentDifficulty.displayName, style = MaterialTheme.typography.bodySmall)
            Spacer(Modifier.width(24.dp))
            TextButton(onClick = { game.updateBoard(game.board.undo()) }, enabled = game.board.canUndo) {
                Text("Undo")
            }
            TextButton(onClick = { showingResetConfirmation = true }) {
                Text("Reset")
            }
            Spacer(Modifier.width(16.dp))
            TimerDisplay(timer = game.timer, onToggle = { game.toggleTimer() })
            Spacer(Modifier.width(16.dp))
            Box {
                TextButton(onClick = { showingStats = true }) { Text("Stats") }
                if (showingStats) {
                    Popup(onDismissRequest = { showingStats = false }) {
                        Surface(shadowElevation = 8.dp) { StatsPopover(game) }
                    }
                }
            }
        }

        Spacer(Modifier.width(16.dp))

        Box(
            modifier = Modifier
                .focusRequester(focusRequester)
                .focusable()
                .onPreviewKeyEvent { event ->
                    if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
                    handleKeyEvent(event, game, selected, onMove = ::move)
                }
                .pointerInput(Unit) {
                    detectCellTap(cellSize) { coordinate -> selected = coordinate }
                },
        ) {
            BoardCanvas(board = game.board, selected = selected, cellSizeDp = cellSize)
        }

        Spacer(Modifier.width(16.dp))
        CompletionLegend(completedDigits = game.board.completedDigits())
        Text(
            "Click a cell, then type 1-9. Shift+1-9 toggles a pencil mark instead. Delete clears. Arrow keys move.",
            style = MaterialTheme.typography.bodySmall,
        )
    }

    if (showingResetConfirmation) {
        AlertDialog(
            onDismissRequest = { showingResetConfirmation = false },
            title = { Text("Reset this puzzle?") },
            text = { Text("This clears every digit and note you've entered. The puzzle itself stays the same.") },
            confirmButton = {
                TextButton(onClick = {
                    showingResetConfirmation = false
                    game.resetPuzzle()
                }) { Text("Reset") }
            },
            dismissButton = {
                TextButton(onClick = { showingResetConfirmation = false }) { Text("Cancel") }
            },
        )
    }

    completionSnapshot?.let { snapshot ->
        CompletionDialog(snapshot) { difficulty ->
            completionSnapshot = null
            scope.launch { game.startNewPuzzle(difficulty) }
        }
    }
}

/** Maps a raw tap position to the cell beneath it -- the board is always drawn at exactly
 * `cellSize * 9` square, so this is a plain divide-and-clamp, no hit-testing needed. */
private suspend fun PointerInputScope.detectCellTap(cellSize: Dp, onTap: (Coordinate) -> Unit) {
    detectTapGestures { offset ->
        val cellPx = cellSize.toPx()
        val column = (offset.x / cellPx).toInt().coerceIn(0, 8)
        val row = (offset.y / cellPx).toInt().coerceIn(0, 8)
        onTap(Coordinate(row, column))
    }
}

/** `key.character` isn't a concept Compose Desktop's key events use at all -- unlike SwiftUI,
 * where the "Shift+3 delivers '#', not '3'" bug forced a whole reverse-mapping workaround
 * (`DigitKeyInput` on the Swift port), Compose's [Key] constants are physical-key based
 * (`Key.One`..`Key.Nine` name the number-row keys themselves, independent of what character
 * Shift would produce), so the digit and the Shift state are just two independent, correct
 * signals from the start. */
private fun handleKeyEvent(event: KeyEvent, game: GameState, selected: Coordinate?, onMove: (Int, Int) -> Unit): Boolean {
    if (selected == null || game.isGeneratingNewPuzzle) return false

    if (event.key == Key.Delete || event.key == Key.Backspace) {
        if (!game.timer.isRunning) return true
        val cell = game.board.cellAt(selected)
        if (cell.digit != null) game.updateBoard(game.board.setDigit(null, at = selected))
        else game.updateBoard(game.board.clearPencilMarks(at = selected))
        return true
    }

    val digit = digitFromKey(event.key)
    if (digit != null) {
        if (!game.timer.isRunning) return true
        if (event.isShiftPressed) game.updateBoard(game.board.togglePencilMark(digit, at = selected))
        else game.updateBoard(game.board.setDigit(digit, at = selected))
        return true
    }

    when (event.key) {
        Key.DirectionUp -> onMove(-1, 0)
        Key.DirectionDown -> onMove(1, 0)
        Key.DirectionLeft -> onMove(0, -1)
        Key.DirectionRight -> onMove(0, 1)
        else -> return false
    }
    return true
}

private fun digitFromKey(key: Key): Int? = when (key) {
    Key.One -> 1
    Key.Two -> 2
    Key.Three -> 3
    Key.Four -> 4
    Key.Five -> 5
    Key.Six -> 6
    Key.Seven -> 7
    Key.Eight -> 8
    Key.Nine -> 9
    else -> null
}
