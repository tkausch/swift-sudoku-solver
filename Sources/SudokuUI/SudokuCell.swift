#if canImport(SwiftUI)

/// The position of one cell on the board, used as the selection in ``SudokuBoardView``.
public struct SudokuCell: Hashable, Sendable {
    /// The row, `0..<Sudoku.size`.
    public var row: Int
    /// The column, `0..<Sudoku.size`.
    public var col: Int

    /// Creates a cell position.
    public init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }

    /// Whether the other cell is in the same row, column or 3×3 box.
    func sharesUnit(with other: SudokuCell, boxSize: Int) -> Bool {
        row == other.row
            || col == other.col
            || (row / boxSize == other.row / boxSize && col / boxSize == other.col / boxSize)
    }
}

#endif
