package me.gileskayo.killersudoku

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import me.gileskayo.killersudoku.core.Difficulty

/** A snapshot captured at the instant of completion rather than live-reading [GameState] -- the
 * dialog's content shouldn't shift under the player while it's open. */
data class CompletionSnapshot(
    val difficulty: Difficulty,
    val elapsedSeconds: Double,
    val bestTime: Double?,
    val solveCount: Int,
) {
    /** True when this solve's own time *is* the best on record for its tier -- bestTime is read
     * after StatsStore.record already ran, so an exact match means this solve set it. */
    val isNewBest: Boolean get() = bestTime == null || elapsedSeconds <= bestTime
}

/** The only way out is picking a New Puzzle tier -- [DialogProperties] disables both the Escape
 * key and outside-click dismissal, mirroring the Swift port's `.interactiveDismissDisabled(true)`.
 * This is also why the board itself is separately locked once solved (see `Board.setDigit`). */
@Composable
fun CompletionDialog(snapshot: CompletionSnapshot, onNewPuzzle: (Difficulty) -> Unit) {
    Dialog(
        onDismissRequest = {},
        properties = DialogProperties(dismissOnBackPress = false, dismissOnClickOutside = false),
    ) {
        Surface(shape = MaterialTheme.shapes.large, color = windowBackground) {
            Column(
                modifier = Modifier.padding(28.dp).width(260.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(24.dp),
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(
                        "Solved!",
                        style = TextStyle(color = textPrimary, fontSize = 34.sp, fontWeight = FontWeight.Bold, fontFamily = FontFamily.SansSerif),
                    )
                    Text(
                        snapshot.elapsedSeconds.formattedAsMinutesAndSeconds(),
                        style = TextStyle(color = textSecondary, fontSize = 22.sp, fontFamily = FontFamily.Monospace),
                    )
                }

                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(
                        "${snapshot.difficulty.displayName} — ${snapshot.solveCount} solved",
                        style = TextStyle(color = textPrimary, fontSize = 13.sp, fontFamily = FontFamily.SansSerif),
                    )
                    if (snapshot.isNewBest) {
                        Text(
                            "New best time",
                            style = TextStyle(
                                color = textPrimary, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, fontFamily = FontFamily.SansSerif,
                            ),
                        )
                    }
                }

                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        "New Puzzle",
                        style = TextStyle(
                            color = textPrimary, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, fontFamily = FontFamily.SansSerif,
                        ),
                    )
                    for (difficulty in Difficulty.entries) {
                        OutlinedButton(onClick = { onNewPuzzle(difficulty) }, modifier = Modifier.fillMaxWidth()) {
                            Text(difficulty.displayName, color = textPrimary)
                        }
                    }
                }
            }
        }
    }
}
