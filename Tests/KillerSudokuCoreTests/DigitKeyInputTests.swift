import Testing
@testable import KillerSudokuCore

@Suite struct DigitKeyInputTests {
    @Test func unshiftedDigitCharactersResolveDirectly() {
        for digit in 1...9 {
            let character = Character("\(digit)")
            #expect(DigitKeyInput.resolve(character: character, shiftHeld: false) == digit)
        }
    }

    /// Regression test: a real captured key event for Shift+3 delivered `"#"` as `key.character`,
    /// not `"3"` — this is the exact bug that made Shift+digit pencil-mark entry silently do
    /// nothing, since `"#".wholeNumberValue` is nil.
    @Test func shiftedSymbolsResolveToTheirDigit() {
        let expected: [Character: Int] = [
            "!": 1, "@": 2, "#": 3, "$": 4, "%": 5, "^": 6, "&": 7, "*": 8, "(": 9,
        ]
        for (symbol, digit) in expected {
            #expect(DigitKeyInput.resolve(character: symbol, shiftHeld: true) == digit)
        }
    }

    @Test func unshiftedDigitCharacterWithShiftHeldDoesNotResolve() {
        // If shift is held, the system already delivered the shifted symbol, not the raw digit —
        // resolving a raw digit character while shiftHeld is true would be an inconsistent state
        // that should never actually occur, but must not silently succeed if it did.
        #expect(DigitKeyInput.resolve(character: "3", shiftHeld: true) == nil)
    }

    @Test func nonDigitNonShiftedSymbolCharactersDoNotResolve() {
        #expect(DigitKeyInput.resolve(character: "a", shiftHeld: false) == nil)
        #expect(DigitKeyInput.resolve(character: "0", shiftHeld: false) == nil)
        #expect(DigitKeyInput.resolve(character: ")", shiftHeld: true) == nil)
    }
}
