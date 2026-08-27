package me.gileskayo.killersudoku

import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import me.gileskayo.killersudoku.core.PuzzleTimer

/** Visible, pausable per-puzzle timer. Re-reads [PuzzleTimer.elapsed] on a 1-second cadence so
 * the displayed time keeps advancing while running, without [GameState] needing to push updates
 * itself. Monospaced digits and a secondary (dimmed) color match the Swift original's
 * `.font(.system(size: 14, weight: .medium, design: .monospaced)).foregroundStyle(.secondary)`. */
@Composable
fun TimerDisplay(timer: PuzzleTimer, onToggle: () -> Unit) {
    var displayedSeconds by remember(timer) { mutableStateOf(timer.elapsed()) }
    LaunchedEffect(timer) {
        while (true) {
            displayedSeconds = timer.elapsed()
            delay(1000)
        }
    }

    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(
            displayedSeconds.formattedAsMinutesAndSeconds(),
            style = TextStyle(
                color = textSecondary, fontSize = 14.sp, fontWeight = FontWeight.Medium, fontFamily = FontFamily.Monospace,
            ),
        )
        Spacer(Modifier.width(8.dp))
        Box(
            modifier = Modifier
                .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null, onClick = onToggle)
                .padding(6.dp),
        ) {
            if (timer.isRunning) PauseIcon() else PlayIcon()
        }
    }
}
