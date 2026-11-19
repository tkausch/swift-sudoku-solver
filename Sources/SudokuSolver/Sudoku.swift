/// A 9×9 Sudoku grid.
///
/// The grid has 9 rows, 9 columns and 9 boxes of 3×3 cells. Each cell is either
/// empty (`0`) or holds a digit `1...9`. Rows and columns are numbered from `0`.
///
/// A `Sudoku` can only be created from a board without conflicting digits, so
/// every instance starts out valid:
///
/// ```swift
/// let cells = Array(repeating: Sudoku.empty, count: Sudoku.cellCount)
/// var sudoku = Sudoku(board: cells)!
/// sudoku[0, 0] = 5
/// print(sudoku.candidates(atRow: 0, col: 1))   // [1, 2, 3, 4, 6, 7, 8, 9]
/// ```
public struct Sudoku: Equatable, Sendable, CustomStringConvertible {

    /// The number of rows and columns, which is also the number of boxes and of distinct digits (`9`).
    public static let size = 9

    /// The number of rows and columns in one box (`3`).
    public static let boxSize = 3

    /// The total number of cells on the board (`81`).
    public static let cellCount = size * size

    /// The values a cell may hold: `0` for an empty cell, or a digit `1...size`.
    public static let allowedValues = 0...size

    /// Returns whether a value may be stored in a cell.
    ///
    /// - Parameter value: The value to check.
    /// - Returns: `true` if `value` is in ``allowedValues``.
    public static func isAllowedValue(_ value: Int) -> Bool {
        allowedValues.contains(value)
    }

    /// All ``cellCount`` cells in row-major order.
    ///
    /// The cell at `row`, `col` is `board[row * size + col]`; `0` marks an empty cell.
    /// Use ``subscript(_:_:)`` to change cells.
    public private(set) var board: [Int]

    /// Creates a grid from a list of cell values.
    ///
    /// - Parameter board: ``cellCount`` values in row-major order: `0` for an
    ///   empty cell, `1...size` for a given digit.
    /// - Returns: `nil` if `board` doesn't have ``cellCount`` values, contains
    ///   a value outside ``allowedValues``, or has the same digit twice in a row,
    ///   column or box.
    public init?(board: [Int]) {
        guard board.count == Self.cellCount, board.allSatisfy(Self.isAllowedValue) else { return nil }
        self.board = board
        guard isValidSudoku() else { return nil }
    }

    /// Returns whether the grid follows the Sudoku rules so far.
    ///
    /// Empty cells are ignored, so a partially filled grid can be valid. A valid
    /// grid isn't necessarily solvable.
    ///
    /// - Returns: `true` if no row, column or box contains the same digit twice.
    public func isValidSudoku() -> Bool {
        let size = Self.size, boxSize = Self.boxSize
        let boxOrigins = stride(from: 0, to: size, by: boxSize)

        return (0..<size).allSatisfy { isValidRow($0) }
            && (0..<size).allSatisfy { isValidColumn($0) }
            && boxOrigins.allSatisfy { i in boxOrigins.allSatisfy { j in isValidBox(r: i, c: j) } }
    }

    /// Reads or writes the cell at a given row and column.
    ///
    /// Writing `0` empties the cell. Writing does not look for duplicate digits:
    /// call ``isValidSudoku()`` afterwards if needed.
    ///
    /// - Precondition: `row` and `col` are in `0..<size`; a written value is in
    ///   ``allowedValues``. Violating either stops the program.
    ///
    /// - Parameters:
    ///   - row: The row, `0..<size`.
    ///   - col: The column, `0..<size`.
    /// - Returns: The cell's value: `0` if empty, otherwise a digit `1...size`.
    public subscript(row: Int, col: Int) -> Int {
        get {
            return board[Self.checkedIndex(row, col)]
        }
        set {
            precondition(Self.isAllowedValue(newValue), "Value \(newValue) is outside \(Self.allowedValues)")
            board[Self.checkedIndex(row, col)] = newValue
        }
    }

    /// Whether every cell is filled, i.e. no cell is ``empty``.
    ///
    /// This doesn't check validity: combine it with ``isValidSudoku()`` to tell
    /// whether the grid is solved.
    public var isComplete: Bool { !board.contains(Self.empty) }

    /// The grid as text, one row per line.
    ///
    /// Empty cells are shown as `.`, and boxes are separated by `|` and `-+-` lines:
    ///
    /// ```
    /// 5 3 . | . 7 . | . . .
    /// 6 . . | 1 9 5 | . . .
    /// . 9 8 | . . . | . 6 .
    /// ------+-------+------
    /// ```
    public var description: String {
        let size = Self.size, boxSize = Self.boxSize
        let boxSegment = String(repeating: "-", count: boxSize * 2 - 1)
        let separator = Array(repeating: boxSegment, count: boxSize).joined(separator: "-+-")

        var lines: [String] = []
        for row in 0..<size {
            if row > 0 && row % boxSize == 0 { lines.append(separator) }
            var line = ""
            for col in 0..<size {
                if col > 0 && col % boxSize == 0 { line += "| " }
                let v = self[row, col]
                line += (v == Self.empty ? "." : String(v)) + " "
            }
            lines.append(String(line.dropLast()))
        }
        return lines.joined(separator: "\n")
    }
    
    /// Returns `true` if row `i` contains no digit twice.
    private func isValidRow(_ i: Int) -> Bool {
        return Self.isValidUnit(rowUnit(atRow: i))
    }
    
    /// Returns `true` if column `j` contains no digit twice.
    private func isValidColumn(_ j: Int) -> Bool {
        Self.isValidUnit(colUnit(atCol: j))
    }

    /// Returns `true` if the box containing cell (`r`, `c`) contains no digit twice.
    private func isValidBox(r: Int, c: Int) -> Bool {
        return Self.isValidUnit(boxUnit(atRow: r, col: c))
    }

    private func boxUnit(atRow r: Int, col c: Int) -> [Int] {
        let boxSize = Self.boxSize
        let startRow = (r / boxSize) * boxSize
        let startCol = (c / boxSize) * boxSize
        let box = (startRow..<startRow + boxSize).flatMap { row in
            board[Self.index(row, startCol)..<Self.index(row, startCol + boxSize)]
        }
        return box
    }
    
    private func colUnit(atCol col: Int) -> [Int] {
        return (0..<Self.size).map { board[Self.index($0, col)] }
    }
    
    private func rowUnit(atRow row: Int) -> [Int] {
        let start = Self.index(row,0)
        return Array(board[start..<start + Self.size])
    }
    
    /// Returns the position in `board` of the cell at `row`, `col`.
    @inline(__always)
    private static func index(_ row: Int, _ col: Int) -> Int {
        row * size + col
    }

    /// Like ``index(_:_:)``, but stops the program if `row` or `col` is outside `0..<size`.
    @inline(__always)
    private static func checkedIndex(_ row: Int, _ col: Int) -> Int {
        precondition((0..<size).contains(row) && (0..<size).contains(col),
                     "Cell (\(row), \(col)) is outside the \(size)×\(size) grid")
        return index(row, col)
    }
    

    /// Returns `true` if the non-empty digits of a unit (row, column or box) are unique.
    private static func isValidUnit<Unit: Collection<Int>>(_ unit: Unit) -> Bool {
        let digits = unit.filter { $0 != empty }
        return Set(digits).count == digits.count
    }
}

// MARK: - SolvableSudoku

/// `size` and the subscript come from the main declaration; this extension adds
/// `candidates(atRow:col:)`.
extension Sudoku: SolvableSudoku {

    /// Returns the digits that can be placed in a cell without repeating a digit
    /// in its row, column or box.
    ///
    /// - Parameters:
    ///   - row: The cell's row, `0..<size`.
    ///   - col: The cell's column, `0..<size`.
    /// - Returns: The possible digits in ascending order. Empty if the cell is
    ///   already filled, or if no digit fits (a dead end).
    public func candidates(atRow row: Int, col: Int) -> [Int] {
        guard isEmpty(atRow: row, col: col) else { return [] }

        let rowNums = rowUnit(atRow: row)
        let colNums = colUnit(atCol: col)
        let boxNums = boxUnit(atRow: row, col: col)
        let used = Set(rowNums + colNums + boxNums)

        return (1...Self.size).filter { !used.contains($0) }
    }
}
