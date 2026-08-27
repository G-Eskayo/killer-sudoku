package me.gileskayo.killersudoku

import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

/** Real Material icons rather than hand-drawn Canvas paths -- an earlier pass hand-drew these
 * (arcs and lines approximating each SF Symbol) and they read as visibly rough/asymmetric next to
 * the Swift original's crisp system glyphs. Standing in for: "arrow.uturn.backward" (undo),
 * "arrow.counterclockwise" (reset), "chart.bar" (stats), "pause.fill"/"play.fill" (timer),
 * "info.circle" (the hover-reveal help icon). */
private val glyphSize = 18.dp

@Composable
fun BarChartIcon(color: Color = textSecondary, modifier: Modifier = Modifier) {
    Icon(Icons.Filled.BarChart, contentDescription = "Stats", tint = color, modifier = modifier.size(glyphSize))
}

@Composable
fun UndoIcon(color: Color = textSecondary, modifier: Modifier = Modifier) {
    Icon(Icons.AutoMirrored.Filled.Undo, contentDescription = "Undo", tint = color, modifier = modifier.size(glyphSize))
}

@Composable
fun ResetIcon(color: Color = textSecondary, modifier: Modifier = Modifier) {
    Icon(Icons.Filled.Replay, contentDescription = "Reset", tint = color, modifier = modifier.size(glyphSize))
}

@Composable
fun PlayIcon(color: Color = textSecondary, modifier: Modifier = Modifier) {
    Icon(Icons.Filled.PlayArrow, contentDescription = "Resume timer", tint = color, modifier = modifier.size(glyphSize))
}

@Composable
fun PauseIcon(color: Color = textSecondary, modifier: Modifier = Modifier) {
    Icon(Icons.Filled.Pause, contentDescription = "Pause timer", tint = color, modifier = modifier.size(glyphSize))
}

@Composable
fun InfoIcon(color: Color = textSecondary, modifier: Modifier = Modifier) {
    Icon(Icons.Outlined.Info, contentDescription = "How to play", tint = color, modifier = modifier.size(glyphSize))
}
