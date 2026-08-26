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

    private enum CodingKeys: String, CodingKey {
        case digit, pencilMarks, isGiven
    }

    /// Decodes `isGiven` as absent-means-false (ADR 0011) rather than requiring the key, so a
    /// saved puzzle encoded before this field existed still decodes instead of silently failing
    /// and discarding the player's in-progress puzzle. `encode(to:)` stays compiler-synthesized —
    /// only decoding needs this tolerance.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        digit = try container.decodeIfPresent(Int.self, forKey: .digit)
        pencilMarks = try container.decodeIfPresent(Set<Int>.self, forKey: .pencilMarks) ?? []
        isGiven = try container.decodeIfPresent(Bool.self, forKey: .isGiven) ?? false
    }
}
