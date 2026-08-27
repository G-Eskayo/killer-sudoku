package me.gileskayo.killersudoku

import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.width
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import me.gileskayo.killersudoku.core.Difficulty

/** The New Puzzle flow: a difficulty picker that starts a fresh puzzle, replacing whatever was
 * in progress. Shows a spinner instead of the menu while generating. Plain clickable text, not a
 * Material `TextButton` -- the Swift original's `Menu("New Puzzle")` reads as plain white text
 * with no button fill or accent tint. */
@Composable
fun NewPuzzleMenu(isGenerating: Boolean, onSelect: (Difficulty) -> Unit) {
    if (isGenerating) {
        Row {
            CircularProgressIndicator(modifier = Modifier.width(14.dp), color = textSecondary)
            Spacer(Modifier.width(6.dp))
            Text("Generating...", style = TextStyle(color = textSecondary, fontSize = 12.sp, fontFamily = FontFamily.SansSerif))
        }
        return
    }

    var expanded by remember { mutableStateOf(false) }
    Text(
        "New Puzzle ⌄",
        style = TextStyle(color = textPrimary, fontSize = 14.sp, fontFamily = FontFamily.SansSerif),
        modifier = Modifier.clickable(
            interactionSource = remember { MutableInteractionSource() }, indication = null,
        ) { expanded = true },
    )
    DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
        for (difficulty in Difficulty.entries) {
            DropdownMenuItem(text = { Text(difficulty.displayName) }, onClick = {
                expanded = false
                onSelect(difficulty)
            })
        }
    }
}
