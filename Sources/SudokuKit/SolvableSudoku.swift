/// The operations a ``SudokuSolver`` needs from a Sudoku grid.
///
/// A grid is `size`×`size` cells addressed by zero-based `row` and `col`.
/// Empty cells hold `0`; filled cells hold a digit `1...size`.
///
/// Adopt this protocol to solve your own grid type, for example a 4×4 or 16×16
/// variant, with any ``SudokuSolver`` such as ``DFSSolver``.
public protocol SolvableSudoku {
    /// The number of rows and columns, which is also the highest digit.
    static var size: Int { get }

    /// Reads or writes the cell at a given row and column.
    ///
    /// Solvers write a digit to try it and write `0` to undo it.
    ///
    /// - Parameters:
    ///   - row: The row, `0..<size`.
    ///   - col: The column, `0..<size`.
    /// - Returns: The cell's value: `0` if empty, otherwise a digit `1...size`.
    subscript(row: Int, col: Int) -> Int { get set }

    /// Returns the digits that can be placed in a cell without breaking the rules.
    ///
    /// - Parameters:
    ///   - row: The cell's row, `0..<size`.
    ///   - col: The cell's column, `0..<size`.
    /// - Returns: The possible digits, in no particular order. Empty if the cell
    ///   is already filled or no digit fits.
    func candidates(atRow row: Int, col: Int) -> Set<Int>
}

extension SolvableSudoku {
    /// The value of an empty cell (`0`).
    public static var empty: Int { 0 }

    /// Returns whether a cell is empty.
    ///
    /// - Parameters:
    ///   - row: The row, `0..<size`.
    ///   - col: The column, `0..<size`.
    /// - Returns: `true` if the cell holds ``empty``.
    public func isEmpty(atRow row: Int, col: Int) -> Bool {
        self[row, col] == Self.empty
    }
}
