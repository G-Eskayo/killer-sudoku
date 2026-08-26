/// Resolves a physical digit-row key press (1-9) into its digit, independent of whether Shift is
/// held. `KeyPress.key.character` (SwiftUI) is *not* the unshifted base key as it might appear —
/// on a US keyboard, Shift+3 delivers `"#"`, the shifted symbol, not `"3"`. A caller must resolve
/// through this shifted-symbol table when Shift is held, and parse the character directly
/// otherwise.
public enum DigitKeyInput {
    /// US keyboard's Shift+digit row: `!@#$%^&*(` for 1-9. Not locale-independent — fine for a
    /// v1 that only targets US keyboard layouts; revisit if non-US layout support is ever needed.
    private static let shiftedSymbols: [Character: Int] = [
        "!": 1, "@": 2, "#": 3, "$": 4, "%": 5, "^": 6, "&": 7, "*": 8, "(": 9,
    ]

    /// `character` is the key's own reported character (already shift-processed by the system
    /// when `shiftHeld` is true) — not a base/unshifted value to look up unconditionally.
    public static func resolve(character: Character, shiftHeld: Bool) -> Int? {
        if shiftHeld {
            return shiftedSymbols[character]
        }
        guard let digit = character.wholeNumberValue, (1...9).contains(digit) else { return nil }
        return digit
    }
}
