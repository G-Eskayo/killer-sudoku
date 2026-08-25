public struct Cage: Identifiable, Sendable, Codable {
    public let id: Int
    public let cells: [Coordinate]
    public let sum: Int

    public init(id: Int, cells: [Coordinate], sum: Int) {
        // Size 1 is a given (ADR 0006) — its "sum" is just that one cell's digit, unambiguous
        // by construction. Every other cage is 2-4 cells, same as before.
        precondition(cells.count >= 1 && cells.count <= 4, "Cage must have 1-4 cells")
        self.id = id
        self.cells = cells
        self.sum = sum
    }
}
