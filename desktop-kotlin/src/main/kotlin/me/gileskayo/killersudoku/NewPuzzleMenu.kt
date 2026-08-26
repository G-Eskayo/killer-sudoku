package me.gileskayo.killersudoku

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.width
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import me.gileskayo.killersudoku.core.Difficulty

/** The New Puzzle flow: a difficulty picker that starts a fresh puzzle, replacing whatever was
 * in progress. Shows a spinner instead of the menu while generating. */
@Composable
fun NewPuzzleMenu(isGenerating: Boolean, onSelect: (Difficulty) -> Unit) {
    if (isGenerating) {
        Row {
            CircularProgressIndicator(modifier = Modifier.width(14.dp))
            Spacer(Modifier.width(6.dp))
            Text("Generating...", style = MaterialTheme.typography.bodySmall)
        }
        return
    }

    var expanded by remember { mutableStateOf(false) }
    TextButton(onClick = { expanded = true }) {
        Text("New Puzzle ▾")
    }
    DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
        for (difficulty in Difficulty.entries) {
            DropdownMenuItem(text = { Text(difficulty.displayName) }, onClick = {
                expanded = false
                onSelect(difficulty)
            })
        }
    }
}
