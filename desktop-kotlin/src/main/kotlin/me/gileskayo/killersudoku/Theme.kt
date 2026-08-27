package me.gileskayo.killersudoku

import androidx.compose.ui.graphics.Color

/** Every color the UI uses, centralized so nothing falls back to Material3's default purple/blue
 * accent scheme -- the Swift original never uses tinted color for UI chrome (CONTEXT.md reserves
 * color for nothing in this app), just white/gray at different opacities. Mirrors SwiftUI's
 * `.primary` / `.secondary` / `.tertiary` foreground styles in dark mode. */
/** Sampled directly from the Swift app's own rendered window (RGB 37,41,43) rather than guessed --
 * SwiftUI's default window background in dark mode isn't a flat "black", it has a faint cool
 * (blue-gray) tint. */
val windowBackground = Color(0xFF25292B)
val textPrimary = Color.White
val textSecondary = Color.White.copy(alpha = 0.6f)
val textTertiary = Color.White.copy(alpha = 0.35f)

/** Matches the Swift app's `.accentColor` selection outline (macOS's default system blue). */
val accentColor = Color(0xFF3B82F6)
