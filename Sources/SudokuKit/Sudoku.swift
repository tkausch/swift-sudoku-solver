/// A 9×9 Sudoku grid.
///
/// The grid has 9 rows, 9 columns and 9 boxes of 3×3 cells. Each cell is either
/// empty (`0`) or holds a digit `1...9`. Rows and columns are numbered from `0`.
///
/// A `Sudoku` can only be created from a grid without conflicting digits, so
/// every instance starts out valid:
///
/// ```swift
/// let cells = Array(repeating: Sudoku.empty, count: Sudoku.gridSize)
/// var sudoku = Sudoku(grid: cells)!
/// sudoku[0, 0] = 5
/// print(sudoku.candidates(atRow: 0, col: 1).sorted())   // [1, 2, 3, 4, 6, 7, 8, 9]
/// ```
public struct Sudoku: Equatable, Sendable, CustomStringConvertible {

    /// The number of rows and columns, which is also the number of boxes and of distinct digits (`9`).
    public static let size = 9

    /// The number of rows and columns in one box (`3`).
    public static let boxSize = 3

    /// The total number of cells in the grid (`81`).
    public static let gridSize = size * size

    /// The values a cell may hold: `0` for an empty cell, or a digit `1...size`.
    public static let allowedDigits = 0...size

    // MARK: Lookup tables

    /// Every unit as the ``grid`` indices of its cells: the ``size`` rows first,
    /// then the columns, then the boxes (27 units of 9 cells).
    ///
    /// ```swift
    /// Sudoku.units[0]    // row 0:    [0, 1, 2, 3, 4, 5, 6, 7, 8]
    /// Sudoku.units[9]    // column 0: [0, 9, 18, 27, 36, 45, 54, 63, 72]
    /// Sudoku.units[18]   // box 0:    [0, 1, 2, 9, 10, 11, 18, 19, 20]
    /// ```
    public static let units: [[Int]] = {
        let rows = (0..<size).map { row in (0..<size).map { index(row, $0) } }
        let columns = (0..<size).map { col in (0..<size).map { index($0, col) } }
        let boxes = (0..<size).map { box in
            let top = box / boxSize * boxSize, left = box % boxSize * boxSize
            return (0..<size).map { i in index(top + i / boxSize, left + i % boxSize) }
        }
        return rows + columns + boxes
    }()

    /// The three units each cell belongs to, by ``grid`` index: its row, column
    /// and box, in that order, each as the cell indices from ``units``.
    public static let unitsOf: [[[Int]]] = (0..<gridSize).map { cell in
        units.filter { $0.contains(cell) }
    }

    /// The cells that share a row, column or box with each cell, by ``grid``
    /// index: 20 cells in ascending order, not including the cell itself.
    public static let peers: [[Int]] = (0..<gridSize).map { cell in
        Set(unitsOf[cell].joined()).subtracting([cell]).sorted()
    }

    /// Returns whether a digit may be stored in a cell.
    ///
    /// - Parameter digit: The digit to check.
    /// - Returns: `true` if `digit` is in ``allowedDigits``.
    public static func isAllowedDigit(_ digit: Int) -> Bool {
        allowedDigits.contains(digit)
    }

    /// All ``gridSize`` cells in row-major order.
    ///
    /// The cell at `row`, `col` is `grid[row * size + col]`; `0` marks an empty cell.
    /// Use ``subscript(_:_:)`` to change cells.
    public private(set) var grid: [Int]

    /// Creates a grid from a list of cell values.
    ///
    /// - Parameter grid: ``gridSize`` values in row-major order: `0` for an
    ///   empty cell, `1...size` for a given digit.
    /// - Returns: `nil` if `grid` doesn't have ``gridSize`` values, contains
    ///   a value outside ``allowedDigits``, or has the same digit twice in a row,
    ///   column or box.
    public init?(grid: [Int]) {
        guard grid.count == Self.gridSize, grid.allSatisfy(Self.isAllowedDigit) else { return nil }
        self.grid = grid
        guard isValidSudoku() else { return nil }
    }

    /// Returns whether the grid follows the Sudoku rules so far.
    ///
    /// Empty cells are ignored, so a partially filled grid can be valid. A valid
    /// grid isn't necessarily solvable.
    ///
    /// - Returns: `true` if no row, column or box contains the same digit twice.
    public func isValidSudoku() -> Bool {
        Self.units.allSatisfy { unit in Self.isValidUnit(unit.lazy.map { grid[$0] }) }
    }

    /// Reads or writes the cell at a given row and column.
    ///
    /// Writing `0` empties the cell. Writing does not look for duplicate digits:
    /// call ``isValidSudoku()`` afterwards if needed.
    ///
    /// - Precondition: `row` and `col` are in `0..<size`; a written value is in
    ///   ``allowedDigits``. Violating either stops the program.
    ///
    /// - Parameters:
    ///   - row: The row, `0..<size`.
    ///   - col: The column, `0..<size`.
    /// - Returns: The cell's value: `0` if empty, otherwise a digit `1...size`.
    public subscript(row: Int, col: Int) -> Int {
        get {
            return grid[Self.checkedIndex(row, col)]
        }
        set {
            precondition(Self.isAllowedDigit(newValue), "Value \(newValue) is outside \(Self.allowedDigits)")
            grid[Self.checkedIndex(row, col)] = newValue
        }
    }

    /// Whether every cell is filled, i.e. no cell is ``empty``.
    ///
    /// This doesn't check validity: combine it with ``isValidSudoku()`` to tell
    /// whether the grid is solved.
    public var isComplete: Bool { !grid.contains(Self.empty) }

    /// Returns whether a cell's digit also appears elsewhere in its row, column or box.
    ///
    /// Useful for highlighting mistakes while a puzzle is being played.
    ///
    /// - Parameters:
    ///   - row: The row, `0..<size`.
    ///   - col: The column, `0..<size`.
    /// - Returns: `false` for an empty cell, or if the digit is unique in all three units.
    public func hasConflict(atRow row: Int, col: Int) -> Bool {
        let digit = self[row, col]
        guard digit != Self.empty else { return false }
        return Self.peers[Self.index(row, col)].contains { grid[$0] == digit }
    }

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
    
    /// Returns the position in `grid` of the cell at `row`, `col`.
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
    /// - Returns: The possible digits. Empty if the cell is already filled, or if
    ///   no digit fits (a dead end). Sort the set if you need a fixed order.
    public func candidates(atRow row: Int, col: Int) -> Set<Int> {
        guard isEmpty(atRow: row, col: col) else { return [] }

        var candidates = Set(1...Self.size)
        for peer in Self.peers[Self.index(row, col)] {
            candidates.remove(grid[peer])
        }
        return candidates
    }
}
