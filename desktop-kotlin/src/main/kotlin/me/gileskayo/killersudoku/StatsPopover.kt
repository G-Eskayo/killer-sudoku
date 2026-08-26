package me.gileskayo.killersudoku

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import me.gileskayo.killersudoku.core.Difficulty

/** Best time and solve count per difficulty tier. Deliberately plain -- polish not required for
 * this surface. */
@Composable
fun StatsPopover(game: GameState) {
    Column(modifier = Modifier.padding(16.dp).widthIn(min = 260.dp)) {
        Text("Stats", fontWeight = FontWeight.Bold)
        Spacer(Modifier.width(10.dp))
        for (difficulty in Difficulty.entries) {
            val (bestTime, solveCount) = game.stats(difficulty)
            Row {
                Text(difficulty.displayName, modifier = Modifier.width(72.dp))
                Text(
                    if (solveCount == 0) "No solves yet" else "$solveCount solved",
                    style = MaterialTheme.typography.bodySmall,
                )
                Spacer(Modifier.width(12.dp))
                Text(bestTime?.formattedAsMinutesAndSeconds() ?: "-")
            }
        }
    }
}
