package me.gileskayo.killersudoku

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.darkColorScheme
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.WindowPosition
import androidx.compose.ui.window.application
import androidx.compose.ui.window.rememberWindowState
import me.gileskayo.killersudoku.core.Difficulty
import me.gileskayo.killersudoku.core.PuzzleGenerator
import me.gileskayo.killersudoku.core.PuzzleStore

/** Restores an in-progress puzzle when there is one, otherwise starts fresh -- always at a real
 * difficulty tier, never an ungraded blank board (mirrors the Swift port's launch behavior).
 * Forces a dark theme rather than following the system setting: [BoardCanvas] draws every line,
 * digit, and highlight in white at various opacities (matching the Swift app, which only reads
 * correctly against a dark window), so a light-mode host would wash the whole board out to
 * near-invisible -- as it in fact did before this was pinned down. */
fun main() {
    // The macOS dark-title-bar / transparent-title-bar flags live in build.gradle.kts's jvmArgs,
    // not here -- AWT's Cocoa bridge reads them at native launch time, before the JVM reaches
    // this function, so setting them via System.setProperty at this point is too late to have
    // any effect (confirmed: had no visible effect when tried here).
    val restored = PuzzleStore.load()
    val (initialBoard, initialDifficulty) = restored ?: (PuzzleGenerator.generate(Difficulty.MEDIUM) to Difficulty.MEDIUM)
    val game = GameState(initialBoard, initialDifficulty ?: Difficulty.MEDIUM)

    application {
        val windowState = rememberWindowState(
            position = WindowPosition.Aligned(androidx.compose.ui.Alignment.Center),
            // Matches the Swift app's actual on-screen proportions (~900x680pt) rather than
            // fitting tightly around the board -- Swift's header row has a flexible spacer
            // pushing its icon cluster to the far right edge, so its window ends up much wider
            // than the board itself with generous margins on both sides.
            size = DpSize(900.dp, 730.dp),
        )
        Window(
            onCloseRequest = ::exitApplication, title = "Killer Sudoku", state = windowState, resizable = false,
        ) {
            MaterialTheme(colorScheme = darkColorScheme(background = windowBackground, surface = windowBackground)) {
                // fillMaxSize is load-bearing: without it, Surface sizes to its content (the
                // Column), and any leftover window space below/around that content shows the
                // window's own raw (light) background instead of windowBackground -- the "white
                // bar at the bottom" bug.
                Surface(color = windowBackground, modifier = Modifier.fillMaxSize()) {
                    App(game)
                }
            }
        }
    }
}
