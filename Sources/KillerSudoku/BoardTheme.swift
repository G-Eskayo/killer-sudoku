import SwiftUI

/// Cage tint palettes, deliberately hand-tuned per appearance rather than derived from one
/// palette (see CONTEXT.md's "Visual language" section). Placeholder set — a real design pass
/// comes later; this just needs to be distinct and legible in both modes for now.
enum BoardTheme {
    static let lightCageTints: [Color] = [
        Color(red: 0.90, green: 0.93, blue: 0.99),
        Color(red: 0.90, green: 0.97, blue: 0.90),
        Color(red: 0.99, green: 0.94, blue: 0.88),
        Color(red: 0.97, green: 0.90, blue: 0.97),
        Color(red: 0.89, green: 0.97, blue: 0.97),
        Color(red: 0.99, green: 0.97, blue: 0.86),
    ]

    static let darkCageTints: [Color] = [
        Color(red: 0.16, green: 0.20, blue: 0.30),
        Color(red: 0.15, green: 0.24, blue: 0.17),
        Color(red: 0.30, green: 0.22, blue: 0.14),
        Color(red: 0.27, green: 0.16, blue: 0.27),
        Color(red: 0.13, green: 0.26, blue: 0.26),
        Color(red: 0.29, green: 0.27, blue: 0.12),
    ]

    static func cageTint(for cageID: Int, colorScheme: ColorScheme) -> Color {
        let palette = colorScheme == .dark ? darkCageTints : lightCageTints
        return palette[cageID % palette.count]
    }
}
