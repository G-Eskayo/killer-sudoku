package me.gileskayo.killersudoku

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
import me.gileskayo.killersudoku.core.PuzzleTimer

/** Visible, pausable per-puzzle timer. Re-reads [PuzzleTimer.elapsed] on a 1-second cadence so
 * the displayed time keeps advancing while running, without [GameState] needing to push updates
 * itself. Play/pause is a plain text glyph rather than an icon -- avoids pulling in a whole
 * Material Icons dependency for two symbols. */
@Composable
fun TimerDisplay(timer: PuzzleTimer, onToggle: () -> Unit) {
    var displayedSeconds by remember(timer) { mutableStateOf(timer.elapsed()) }
    LaunchedEffect(timer) {
        while (true) {
            displayedSeconds = timer.elapsed()
            delay(1000)
        }
    }

    Row {
        Text(displayedSeconds.formattedAsMinutesAndSeconds())
        Spacer(Modifier.width(8.dp))
        TextButton(onClick = onToggle) {
            Text(if (timer.isRunning) "⏸" else "▶")
        }
    }
}
