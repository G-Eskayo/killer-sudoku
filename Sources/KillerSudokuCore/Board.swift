public struct Board: Sendable {
    private var cells: [[Cell]]
    public let cages: [Cage]
    private let cageIndexByCoordinate: [Coordinate: Int]

    public init(cages: [Cage]) {
        self.cells = Array(repeating: Array(repeating: Cell(), count: 9), count: 9)
        self.cages = cages
        var index: [Coordinate: Int] = [:]
        for (cageIndex, cage) in cages.enumerated() {
            for coordinate in cage.cells {
                index[coordinate] = cageIndex
            }
        }
        self.cageIndexByCoordinate = index
    }

    public func cell(at coordinate: Coordinate) -> Cell {
        cells[coordinate.row][coordinate.column]
    }

    public func cage(at coordinate: Coordinate) -> Cage? {
        cageIndexByCoordinate[coordinate].map { cages[$0] }
    }

    public mutating func setDigit(_ digit: Int?, at coordinate: Coordinate) {
        cells[coordinate.row][coordinate.column].digit = digit
    }

    public mutating func togglePencilMark(_ mark: Int, at coordinate: Coordinate) {
        var cell = cells[coordinate.row][coordinate.column]
        if cell.pencilMarks.contains(mark) {
            cell.pencilMarks.remove(mark)
        } else {
            cell.pencilMarks.insert(mark)
        }
        cells[coordinate.row][coordinate.column] = cell
    }
}
