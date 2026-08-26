public struct Cell: Sendable, Codable {
    public var digit: Int?
    public var pencilMarks: Set<Int> = []
    /// True for a cell [[PuzzleGenerator]] pre-filled (ADR 0008) rather than one the player set —
    /// `Board.setDigit` refuses to change a given, matching standard Sudoku convention.
    public var isGiven: Bool = false

    public init(digit: Int? = nil, isGiven: Bool = false) {
        self.digit = digit
        self.isGiven = isGiven
    }
}
