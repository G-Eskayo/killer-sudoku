public struct Coordinate: Hashable, Sendable, Codable {
    public let row: Int
    public let column: Int

    public init(row: Int, column: Int) {
        precondition((0..<9).contains(row) && (0..<9).contains(column), "Coordinate out of range")
        self.row = row
        self.column = column
    }

    public var boxIndex: Int { (row / 3) * 3 + (column / 3) }

    /// Every cell on the board, once each. Shared by anything that needs to enumerate or
    /// partition the whole 9x9 grid.
    public static let all: [Coordinate] = {
        var coordinates: [Coordinate] = []
        for row in 0..<9 {
            for column in 0..<9 {
                coordinates.append(Coordinate(row: row, column: column))
            }
        }
        return coordinates
    }()
}
