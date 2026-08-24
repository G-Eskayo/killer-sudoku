public struct Coordinate: Hashable, Sendable {
    public let row: Int
    public let column: Int

    public init(row: Int, column: Int) {
        precondition((0..<9).contains(row) && (0..<9).contains(column), "Coordinate out of range")
        self.row = row
        self.column = column
    }

    public var boxIndex: Int { (row / 3) * 3 + (column / 3) }
}
