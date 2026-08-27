package me.gileskayo.killersudoku

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.hoverable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Popup
import kotlinx.coroutines.delay

/** How-to-play help, tucked behind a hover instead of sitting on screen at all times -- the
 * board's own micro-interactions (highlights, animations, the given/entered digit distinction)
 * are meant to teach most of this by feel, so the full explanation only needs to be a beat away,
 * not a permanent fixture. Mirrors the Swift app's identical `info.circle` + delayed popover. */
@Composable
fun InfoHoverIcon() {
    val interactionSource = remember { MutableInteractionSource() }
    val isHovered by interactionSource.collectIsHoveredAsState()
    var showTooltip by remember { mutableStateOf(false) }

    LaunchedEffectHoverDelay(isHovered) { showTooltip = it }

    Box {
        Box(modifier = Modifier.hoverable(interactionSource).padding(6.dp)) {
            InfoIcon()
        }
        if (showTooltip) {
            Popup(alignment = Alignment.BottomStart, offset = IntOffset(0, -44)) {
                Surface(
                    color = windowBackground,
                    border = BorderStroke(1.dp, textSecondary.copy(alpha = 0.25f)),
                    shape = MaterialTheme.shapes.medium,
                    shadowElevation = 8.dp,
                ) {
                    Text(
                        "Click a cell, then type 1-9. Shift+1-9 toggles a pencil mark instead. Delete clears. Arrow keys move.",
                        style = TextStyle(color = textPrimary, fontSize = 12.sp, fontFamily = FontFamily.SansSerif),
                        modifier = Modifier.padding(12.dp).widthIn(max = 260.dp),
                    )
                }
            }
        }
    }
}

/** Reveal only after the pointer lingers -- a brief pass-over shouldn't pop a tooltip, only a
 * deliberate hover. Hides immediately on leaving, no matching delay needed there. */
@Composable
private fun LaunchedEffectHoverDelay(isHovered: Boolean, onShouldShow: (Boolean) -> Unit) {
    androidx.compose.runtime.LaunchedEffect(isHovered) {
        if (isHovered) {
            delay(600)
            onShouldShow(true)
        } else {
            onShouldShow(false)
        }
    }
}
