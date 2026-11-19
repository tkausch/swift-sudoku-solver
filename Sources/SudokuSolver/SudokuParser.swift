/// Parses Sudoku puzzles from text, and formats them back to text.
///
/// Puzzles are written as ``Sudoku/cellCount`` characters in row-major order:
/// a digit `1...Sudoku.size` for a clue, `0` or `.` for an empty cell.
/// Whitespace between characters is ignored, so a puzzle can be split across
/// lines.
///
/// ```swift
/// let sudoku = try SudokuParser.parse("""
///     53..7....
///     6..195...
///     .98....6.
///     8...6...3
///     4..8.3..1
///     7...2...6
///     .6....28.
///     ...419..5
///     ....8..79
///     """)
/// print(SudokuParser.string(for: sudoku))   // 53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79
/// ```
public struct SudokuParser {

    /// Parses a puzzle from text.
    ///
    /// - Parameter input: ``Sudoku/cellCount`` characters in row-major order:
    ///   a digit `1...Sudoku.size` for a clue, `0` or `.` for an empty cell.
    ///   Whitespace is ignored.
    /// - Returns: The parsed puzzle.
    /// - Throws: ``SudokuError/wrongLength(_:)`` if `input` doesn't have
    ///   exactly ``Sudoku/cellCount`` cells, ``SudokuError/invalidCharacter(_:)``
    ///   for a character that isn't a digit, `.`, or whitespace, or
    ///   ``SudokuError/conflictingDigits`` if the same digit appears twice in
    ///   a row, column, or box.
    public static func parse(_ input: String) throws -> Sudoku {
        var board: [Int] = []
        board.reserveCapacity(Sudoku.cellCount)
        for ch in input where !ch.isWhitespace {
            switch ch {
            case ".": board.append(0)
            case "0"..."9": board.append(Int(String(ch))!)
            default: throw SudokuError.invalidCharacter(ch)
            }
        }

        guard board.count == Sudoku.cellCount else {
            throw SudokuError.wrongLength(board.count)
        }

        guard let sudoku = Sudoku(board: board) else {
            throw SudokuError.conflictingDigits
        }
        return sudoku
    }

    /// Formats a puzzle as a single line of text.
    ///
    /// - Parameter sudoku: The puzzle to format.
    /// - Returns: ``Sudoku/cellCount`` characters in row-major order: a digit
    ///   `1...Sudoku.size` for a clue, `.` for an empty cell.
    public static func string(for sudoku: Sudoku) -> String {
        sudoku.board.map { $0 == 0 ? "." : String($0) }.joined()
    }
}
