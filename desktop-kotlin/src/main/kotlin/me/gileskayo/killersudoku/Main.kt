package me.gileskayo.killersudoku

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.darkColorScheme
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import me.gileskayo.killersudoku.core.Difficulty
import me.gileskayo.killersudoku.core.PuzzleGenerator
import me.gileskayo.killersudoku.core.PuzzleStore

private val windowBackground = Color(0xFF1C1C1E)

/** Restores an in-progress puzzle when there is one, otherwise starts fresh -- always at a real
 * difficulty tier, never an ungraded blank board (mirrors the Swift port's launch behavior).
 * Forces a dark theme rather than following the system setting: [BoardCanvas] draws every line,
 * digit, and highlight in white at various opacities (matching the Swift app, which only reads
 * correctly against a dark window), so a light-mode host would wash the whole board out to
 * near-invisible -- as it in fact did before this was pinned down. */
fun main() {
    val restored = PuzzleStore.load()
    val (initialBoard, initialDifficulty) = restored ?: (PuzzleGenerator.generate(Difficulty.MEDIUM) to Difficulty.MEDIUM)
    val game = GameState(initialBoard, initialDifficulty ?: Difficulty.MEDIUM)

    application {
        Window(onCloseRequest = ::exitApplication, title = "Killer Sudoku") {
            MaterialTheme(colorScheme = darkColorScheme(background = windowBackground, surface = windowBackground)) {
                Surface(color = windowBackground) {
                    App(game)
                }
            }
        }
    }
}
