import Testing
@testable import SudokuKit

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
        let expected = try SudokuParser.parse(puzzle)
        #expect(sudoku.grid == expected.grid)
    }

    @Test func treatsZeroAndDotAsEmpty() throws {
        let withZeros = puzzle.replacingOccurrences(of: ".", with: "0")
        let sudoku = try SudokuParser.parse(withZeros)
        let expected = try SudokuParser.parse(puzzle)
        #expect(sudoku.grid == expected.grid)
    }

    @Test func rejectsWrongLength() {
        #expect(throws: SudokuError.wrongLength(3)) {
            try SudokuParser.parse("123")
        }
    }

    @Test func rejectsInvalidCharacter() {
        #expect(throws: SudokuError.invalidCharacter("x")) {
            try SudokuParser.parse(String(repeating: "x", count: Sudoku.gridSize))
        }
    }

    @Test func rejectsConflictingDigits() {
        var cells = Array(repeating: "0", count: Sudoku.gridSize)
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
        let reparsed = try SudokuParser.parse(formatted)
        #expect(reparsed == sudoku)
    }

    @Test func parsePlayableAcceptsUniquePuzzle() throws {
        #expect(try SudokuParser.parsePlayable(puzzle) == SudokuParser.parse(puzzle))
    }

    @Test func parsePlayableRejectsPuzzleWithSeveralSolutions() {
        #expect(throws: SudokuError.multipleSolutions) {
            try SudokuParser.parsePlayable("12345678" + String(repeating: ".", count: 73))
        }
    }

    /// Cell (0, 8) has no candidate: row 0 holds 1–8 and column 8 holds the 9.
    @Test func parsePlayableRejectsPuzzleWithoutSolution() {
        let cells = "12345678." + "........9" + String(repeating: ".", count: 63)
        #expect(throws: SudokuError.noSolution) {
            try SudokuParser.parsePlayable(cells)
        }
    }

    @Test func parsePlayableReportsFormatErrors() {
        #expect(throws: SudokuError.wrongLength(3)) {
            try SudokuParser.parsePlayable("123")
        }
    }
}
