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

    /// Digits currently placed in exactly 9 cells on the board. A naive count-based proxy for
    /// "Digit completion state" (CONTEXT.md) — it doesn't yet account for rule violations, since
    /// mistake detection doesn't exist yet (issue #5). Revisit once that lands.
    public func completedDigits() -> Set<Int> {
        var counts: [Int: Int] = [:]
        for row in cells {
            for cell in row {
                guard let digit = cell.digit else { continue }
                counts[digit, default: 0] += 1
            }
        }
        return Set(counts.filter { $0.value == 9 }.keys)
    }
}
