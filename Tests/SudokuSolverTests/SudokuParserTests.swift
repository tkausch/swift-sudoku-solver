import Testing
@testable import SudokuSolver

struct SudokuParserTests {
    let puzzle = "53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79"

    @Test func parsesPuzzle() throws {
        let sudoku = try SudokuParser.parse(puzzle)
        #expect(sudoku[0, 0] == 5)
        #expect(sudoku[0, 2] == 0)
        #expect(sudoku[8, 8] == 9)
    }

    @Test func ignoresWhitespaceAndNewlines() throws {
        let spaced = puzzle.map { String($0) }.joined(separator: " ")
        let sudoku = try SudokuParser.parse(spaced)
        #expect(sudoku.board == (try SudokuParser.parse(puzzle)).board)
    }

    @Test func treatsZeroAndDotAsEmpty() throws {
        let withZeros = puzzle.replacingOccurrences(of: ".", with: "0")
        let sudoku = try SudokuParser.parse(withZeros)
        #expect(sudoku.board == (try SudokuParser.parse(puzzle)).board)
    }

    @Test func rejectsWrongLength() {
        #expect(throws: SudokuError.wrongLength(3)) {
            try SudokuParser.parse("123")
        }
    }

    @Test func rejectsInvalidCharacter() {
        #expect(throws: SudokuError.invalidCharacter("x")) {
            try SudokuParser.parse(String(repeating: "x", count: Sudoku.cellCount))
        }
    }

    @Test func rejectsConflictingDigits() {
        var cells = Array(repeating: "0", count: Sudoku.cellCount)
        cells[0] = "5"
        cells[8] = "5"
        #expect(throws: SudokuError.conflictingDigits) {
            try SudokuParser.parse(cells.joined())
        }
    }

    @Test func formatsPuzzleBackToText() throws {
        let sudoku = try SudokuParser.parse(puzzle)
        #expect(SudokuParser.string(for: sudoku) == puzzle)
    }

    @Test func roundTripsThroughParseAndFormat() throws {
        let sudoku = try SudokuParser.parse(puzzle)
        let formatted = SudokuParser.string(for: sudoku)
        #expect(try SudokuParser.parse(formatted) == sudoku)
    }
}
