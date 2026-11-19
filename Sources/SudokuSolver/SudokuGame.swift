/// A puzzle being played: the original clues plus the player's entries.
///
/// ``puzzle`` never changes, so it tells which cells are givens. ``board``
/// starts as a copy of it and holds the player's digits on top:
///
/// ```swift
/// var game = SudokuGame(puzzle: SudokuGenerator().generate(.medium))
/// game.isGiven(atRow: 0, col: 0)       // true if (0, 0) is a clue
/// game.set(4, atRow: 0, col: 1)        // false if (0, 1) is a given
/// game.set(Sudoku.empty, atRow: 0, col: 1)   // clears the entry
/// game.isSolved
/// ```
///
/// Entries aren't checked against the rules, so the board can hold conflicting
/// digits while the player works. Use ``Sudoku/isValidSudoku()`` on ``board`` to
/// find out.
public struct SudokuGame: Equatable, Sendable {
    /// The original puzzle: the givens only.
    public let puzzle: Sudoku

    /// The givens plus the player's entries.
    public private(set) var board: Sudoku

    /// Starts a game with no entries yet.
    ///
    /// - Parameter puzzle: The puzzle to play. Its filled cells become the givens.
    public init(puzzle: Sudoku) {
        self.puzzle = puzzle
        self.board = puzzle
    }

    /// Returns whether a cell was filled in the original puzzle.
    ///
    /// - Parameters:
    ///   - row: The row, `0..<Sudoku.size`.
    ///   - col: The column, `0..<Sudoku.size`.
    /// - Returns: `true` for a given, `false` for a cell the player may fill.
    public func isGiven(atRow row: Int, col: Int) -> Bool {
        !puzzle.isEmpty(atRow: row, col: col)
    }

    /// Enters or clears a digit in a cell that isn't a given.
    ///
    /// - Precondition: `row` and `col` are in `0..<Sudoku.size`, and `digit`
    ///   is in ``Sudoku/allowedValues``.
    ///
    /// - Parameters:
    ///   - digit: A digit `1...Sudoku.size`, or ``SolvableSudoku/empty`` to clear the cell.
    ///   - row: The row, `0..<Sudoku.size`.
    ///   - col: The column, `0..<Sudoku.size`.
    /// - Returns: `false` if the cell is a given and was left unchanged.
    @discardableResult
    public mutating func set(_ digit: Int, atRow row: Int, col: Int) -> Bool {
        guard !isGiven(atRow: row, col: col) else { return false }
        board[row, col] = digit
        return true
    }

    /// Whether every cell is filled and no row, column or box repeats a digit.
    public var isSolved: Bool {
        board.isComplete && board.isValidSudoku()
    }
}
