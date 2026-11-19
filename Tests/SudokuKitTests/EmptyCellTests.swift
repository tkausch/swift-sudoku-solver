import Testing
@testable import SudokuKit

struct EmptyCellTests {
    let puzzle = "53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79"

    @Test func emptyIsZero() {
        #expect(Sudoku.empty == 0)
    }

    @Test func isEmptyMatchesCells() throws {
        let sudoku = try SudokuParser.parse(puzzle)
        #expect(!sudoku.isEmpty(atRow: 0, col: 0))
        #expect(sudoku.isEmpty(atRow: 0, col: 2))
    }

    @Test func clearingACellMakesItEmpty() throws {
        var sudoku = try SudokuParser.parse(puzzle)
        sudoku[0, 0] = Sudoku.empty
        #expect(sudoku.isEmpty(atRow: 0, col: 0))
    }
}
