import Testing
@testable import SudokuKit

struct SudokuTests {
    let puzzle = "530070000600195000098000060800060003400803001700020006060000280000419005000080079"
    let solution = "534678912672195348198342567859761423426853791713924856961537284287419635345286179"

    func board(_ string: String) -> [Int] {
        string.compactMap(\.wholeNumberValue)
    }

    @Test func parsesBoardIntoRows() throws {
        let sudoku = try #require(Sudoku(grid: board(puzzle)))
        #expect(sudoku.grid.count == Sudoku.gridSize)
        #expect(sudoku.grid == board(puzzle))
        #expect(sudoku[1, 3] == 1)   // row-major: index 1 * 9 + 3 = 12
        #expect(sudoku[0, 0] == 5)
        #expect(sudoku[0, 2] == 0)
        #expect(sudoku[8, 8] == 9)
        #expect(!sudoku.isComplete)
    }

    @Test func rejectsWrongLength() {
        #expect(Sudoku(grid: [1, 2, 3]) == nil)
    }

    @Test(arguments: [-1, 10, 42, Int.min, Int.max])
    func rejectsOutOfRangeValues(value: Int) {
        var cells = Array(repeating: 0, count: 81)
        cells[40] = value
        #expect(Sudoku(grid: cells) == nil)
    }

    @Test func acceptsEveryValueFromZeroToNine() {
        var cells = Array(repeating: 0, count: 81)
        cells[0..<10] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]   // 0 in row 0, 1...9 spread over rows 0-1
        #expect(Sudoku(grid: cells) != nil)
    }

    #if compiler(>=6.2)   // exit tests (#expect(processExitsWith:)) need Swift 6.2
    @Test(arguments: [-1, 10])
    func subscriptRejectsOutOfRangeValues(value: Int) async {
        await #expect(processExitsWith: .failure) { [value] in
            var sudoku = Sudoku(grid: Array(repeating: 0, count: 81))!
            sudoku[0, 0] = value
        }
    }
    #endif

    @Test func partialPuzzleIsValid() throws {
        let sudoku = try #require(Sudoku(grid: board(puzzle)))
        #expect(sudoku.isValidSudoku())
    }

    @Test func solvedGridIsValidAndComplete() throws {
        let sudoku = try #require(Sudoku(grid: board(solution)))
        #expect(sudoku.isComplete)
        #expect(sudoku.isValidSudoku())
    }

    // The initializer rejects boards with duplicate digits.
    @Test func rejectsDuplicateInRow() {
        var cells = Array(repeating: 0, count: 81)
        cells[0] = 5; cells[8] = 5
        #expect(Sudoku(grid: cells) == nil)
    }

    @Test func rejectsDuplicateInColumn() {
        var cells = Array(repeating: 0, count: 81)
        cells[0] = 5; cells[72] = 5
        #expect(Sudoku(grid: cells) == nil)
    }

    @Test func rejectsDuplicateInBox() {
        var cells = Array(repeating: 0, count: 81)
        cells[0] = 5; cells[20] = 5   // (0,0) and (2,2)
        #expect(Sudoku(grid: cells) == nil)
    }

    @Test func detectsDuplicateAfterEditing() throws {
        var sudoku = try #require(Sudoku(grid: Array(repeating: 0, count: 81)))
        sudoku[0, 0] = 5
        sudoku[0, 8] = 5
        #expect(!sudoku.isValidSudoku())
    }

    @Test func subscriptSetsValue() throws {
        var sudoku = try #require(Sudoku(grid: board(puzzle)))
        sudoku[0, 2] = 4
        #expect(sudoku[0, 2] == 4)
        #expect(sudoku.grid[2] == 4)
    }

    // MARK: - candidates

    @Test func candidatesExcludeRowColumnAndBox() throws {
        let sudoku = try #require(Sudoku(grid: board(puzzle)))
        // Cell (0, 2): row has 5 3 7, column has 8, box has 5 3 6 9 8 → 1 2 4 left.
        #expect(sudoku.candidates(atRow: 0, col: 2) == [1, 2, 4])
        // Cell (4, 4): row 4 8 3 1, column 7 9 6 2 1 8, box 6 8 3 2 → only 5.
        #expect(sudoku.candidates(atRow: 4, col: 4) == [5])
    }

    @Test func candidatesOfFilledCellAreEmpty() throws {
        let sudoku = try #require(Sudoku(grid: board(puzzle)))
        #expect(sudoku.candidates(atRow: 0, col: 0) == [])
    }

    @Test func emptyGridAllowsEveryDigit() throws {
        let sudoku = try #require(Sudoku(grid: Array(repeating: 0, count: Sudoku.gridSize)))
        #expect(sudoku.candidates(atRow: 4, col: 4) == Array(1...9))
    }

    // MARK: - hasConflict

    @Test func validPuzzleHasNoConflicts() throws {
        let sudoku = try #require(Sudoku(grid: board(puzzle)))
        for row in 0..<Sudoku.size {
            for col in 0..<Sudoku.size {
                #expect(!sudoku.hasConflict(atRow: row, col: col))
            }
        }
    }

    @Test func rowConflictMarksBothCells() throws {
        var sudoku = try #require(Sudoku(grid: board(puzzle)))
        sudoku[0, 2] = 5   // 5 is already at (0, 0)
        #expect(sudoku.hasConflict(atRow: 0, col: 2))
        #expect(sudoku.hasConflict(atRow: 0, col: 0))
        #expect(!sudoku.hasConflict(atRow: 0, col: 1))
    }

    @Test func columnConflict() throws {
        var sudoku = try #require(Sudoku(grid: board(puzzle)))
        sudoku[3, 1] = 9   // 9 is already at (2, 1); not in row 3 or the box
        #expect(sudoku.hasConflict(atRow: 3, col: 1))
        #expect(sudoku.hasConflict(atRow: 2, col: 1))
    }

    @Test func boxConflict() throws {
        var sudoku = try #require(Sudoku(grid: board(puzzle)))
        sudoku[1, 1] = 8   // 8 is already at (2, 2); not in row 1 or column 1
        #expect(sudoku.hasConflict(atRow: 1, col: 1))
        #expect(sudoku.hasConflict(atRow: 2, col: 2))
    }

    @Test func emptyCellHasNoConflict() throws {
        let sudoku = try #require(Sudoku(grid: board(puzzle)))
        #expect(!sudoku.hasConflict(atRow: 0, col: 2))
    }

    @Test func candidatesMatchSolution() throws {
        let sudoku = try #require(Sudoku(grid: board(puzzle)))
        let solved = try #require(Sudoku(grid: board(solution)))
        for row in 0..<Sudoku.size {
            for col in 0..<Sudoku.size where sudoku[row, col] == 0 {
                #expect(sudoku.candidates(atRow: row, col: col).contains(solved[row, col]))
            }
        }
    }

    @Test func lastCellMapsToLastIndex() throws {
        var sudoku = try #require(Sudoku(grid: board(puzzle)))
        sudoku[8, 7] = 0
        #expect(sudoku.grid[79] == 0)
        #expect(sudoku[8, 8] == 9)
        #expect(sudoku.grid[80] == 9)
    }

    #if compiler(>=6.2)   // exit tests (#expect(processExitsWith:)) need Swift 6.2
    @Test(arguments: [(0, 9), (9, 0), (-1, 0), (0, -1)])
    func subscriptRejectsOutOfBoundsCells(row: Int, col: Int) async {
        // Without a bounds check, (0, 9) would silently hit cell (1, 0).
        await #expect(processExitsWith: .failure) { [row, col] in
            let sudoku = Sudoku(grid: Array(repeating: 0, count: Sudoku.gridSize))!
            _ = sudoku[row, col]
        }
    }
    #endif
}
