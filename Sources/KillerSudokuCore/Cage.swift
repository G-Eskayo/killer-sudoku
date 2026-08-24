public struct Cage: Identifiable, Sendable {
    public let id: Int
    public let cells: [Coordinate]
    public let sum: Int

    public init(id: Int, cells: [Coordinate], sum: Int) {
        precondition(cells.count >= 2 && cells.count <= 4, "Cage must have 2-4 cells")
        self.id = id
        self.cells = cells
        self.sum = sum
    }
}
