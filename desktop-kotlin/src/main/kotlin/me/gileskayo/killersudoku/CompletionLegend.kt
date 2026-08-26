package me.gileskayo.killersudoku

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Small, non-interactive 1-9 readout. Dims a digit once [completedDigits] reports it complete.
 * Never touches pencil marks anywhere on the board -- that's the whole point of it existing as a
 * separate readout. */
@Composable
fun CompletionLegend(completedDigits: Set<Int>) {
    Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
        for (digit in 1..9) {
            Text(
                "$digit",
                fontSize = 15.sp,
                fontWeight = FontWeight.Medium,
                color = if (digit in completedDigits) Color.White.copy(alpha = 0.35f) else Color.White,
            )
        }
    }
}
