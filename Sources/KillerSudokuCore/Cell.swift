public struct Cell: Sendable, Codable {
    public var digit: Int?
    public var pencilMarks: Set<Int> = []

    public init(digit: Int? = nil) {
        self.digit = digit
    }
}
