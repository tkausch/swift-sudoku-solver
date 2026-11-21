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
/// game.undo()                          // puts the 4 back
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

    /// One change to a cell, kept so it can be undone.
    private struct Move: Equatable, Sendable {
        let row: Int
        let col: Int
        let previous: Int
    }

    /// Changes made by ``set(_:atRow:col:)``, oldest first.
    private var history: [Move] = []

    /// ``solution`` once it has been computed, `nil` until then.
    var _solution: Sudoku?

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
    /// Each change can be taken back with ``undo()``. Writing the digit a cell
    /// already holds changes nothing and isn't recorded.
    ///
    /// - Precondition: `row` and `col` are in `0..<Sudoku.size`.
    ///
    /// - Parameters:
    ///   - digit: A digit `1...Sudoku.size`, or ``SolvableSudoku/empty`` to clear the cell.
    ///   - row: The row, `0..<Sudoku.size`.
    ///   - col: The column, `0..<Sudoku.size`.
    /// - Returns: `false` if `digit` is outside ``Sudoku/allowedDigits`` or the
    ///   cell is a given. The board is left unchanged in both cases.
    @discardableResult
    public mutating func set(_ digit: Int, atRow row: Int, col: Int) -> Bool {
        guard Sudoku.isAllowedDigit(digit), !isGiven(atRow: row, col: col) else { return false }
        let previous = board[row, col]
        guard digit != previous else { return true }
        board[row, col] = digit
        history.append(Move(row: row, col: col, previous: previous))
        return true
    }

    /// Whether there is a change that ``undo()`` can take back.
    public var canUndo: Bool { !history.isEmpty }

    /// Takes back the most recent change made with ``set(_:atRow:col:)``.
    ///
    /// Call it repeatedly to step back to the original puzzle.
    ///
    /// - Returns: `false` if there was nothing to undo.
    @discardableResult
    public mutating func undo() -> Bool {
        guard let move = history.popLast() else { return false }
        board[move.row, move.col] = move.previous
        return true
    }

    /// Whether every cell is filled and no row, column or box repeats a digit.
    public var isSolved: Bool {
        board.isComplete && board.isValidSudoku()
    }

    /// The puzzle's solution.
    ///
    /// The first access solves ``puzzle`` and stores the result; later accesses
    /// return it. Copies made afterwards keep it.
    ///
    /// - Precondition: ``puzzle`` has a solution. Puzzles from ``SudokuGenerator``
    ///   always do; check others with ``DFSSolver/countSolutions(_:limit:)``.
    public var solution: Sudoku {
        mutating get {
            if let _solution { return _solution }
            guard let solution = DFSSolver().solve(puzzle) else {
                preconditionFailure("The puzzle has no solution")
            }
            _solution = solution
            return solution
        }
    }

    /// The digit that belongs in a cell.
    ///
    /// - Parameters:
    ///   - row: The row, `0..<Sudoku.size`.
    ///   - col: The column, `0..<Sudoku.size`.
    /// - Precondition: ``puzzle`` has a solution, as for ``solution``.
    /// - Returns: The cell's digit in ``solution``.
    public mutating func hint(forRow row: Int, col: Int) -> Int {
        solution[row, col]
    }
}

// MARK: - Equatable

extension SudokuGame {
    /// Games are equal if they have the same puzzle, board and undo history.
    /// Whether ``solution`` has been computed yet doesn't matter.
    public static func == (lhs: SudokuGame, rhs: SudokuGame) -> Bool {
        lhs.puzzle == rhs.puzzle && lhs.board == rhs.board
    }
}
