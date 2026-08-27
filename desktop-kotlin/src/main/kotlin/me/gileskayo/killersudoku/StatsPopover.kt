package me.gileskayo.killersudoku

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import me.gileskayo.killersudoku.core.Difficulty

/** Best time and solve count per difficulty tier. Deliberately plain -- polish not required for
 * this surface, per the Swift original's `StatsView`. */
@Composable
fun StatsPopover(game: GameState) {
    Column(modifier = Modifier.padding(16.dp).widthIn(min = 260.dp)) {
        Text(
            "Stats",
            style = TextStyle(color = textPrimary, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, fontFamily = FontFamily.SansSerif),
        )
        Spacer(Modifier.height(10.dp))
        for (difficulty in Difficulty.entries) {
            val (bestTime, solveCount) = game.stats(difficulty)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    difficulty.displayName,
                    style = TextStyle(color = textPrimary, fontSize = 14.sp, fontFamily = FontFamily.SansSerif),
                    modifier = Modifier.width(72.dp),
                )
                Text(
                    if (solveCount == 0) "No solves yet" else "$solveCount solved",
                    style = TextStyle(color = textSecondary, fontSize = 12.sp, fontFamily = FontFamily.SansSerif),
                )
                Spacer(Modifier.width(12.dp))
                Text(
                    bestTime?.formattedAsMinutesAndSeconds() ?: "—",
                    style = TextStyle(color = textPrimary, fontSize = 14.sp, fontFamily = FontFamily.Monospace),
                )
            }
        }
    }
}
