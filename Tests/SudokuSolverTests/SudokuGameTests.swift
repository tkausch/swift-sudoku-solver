import Testing
@testable import SudokuSolver

struct SudokuGameTests {
    let puzzle = try! SudokuParser.parse(
        "53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79")

    @Test func startsWithBoardEqualToPuzzle() {
        let game = SudokuGame(puzzle: puzzle)
        #expect(game.board == puzzle)
        #expect(!game.isSolved)
    }

    @Test func givensAreTheFilledCellsOfThePuzzle() {
        let game = SudokuGame(puzzle: puzzle)
        #expect(game.isGiven(atRow: 0, col: 0))
        #expect(!game.isGiven(atRow: 0, col: 2))
    }

    @Test func enteringADigitInAnEmptyCellSucceeds() {
        var game = SudokuGame(puzzle: puzzle)
        let entered = game.set(4, atRow: 0, col: 2)
        #expect(entered)
        #expect(game.board[0, 2] == 4)
        #expect(!game.isGiven(atRow: 0, col: 2))
    }

    @Test func givensCannotBeChanged() {
        var game = SudokuGame(puzzle: puzzle)
        let entered = game.set(1, atRow: 0, col: 0)
        #expect(!entered)
        #expect(game.board[0, 0] == 5)
        let cleared = game.set(Sudoku.empty, atRow: 0, col: 0)
        #expect(!cleared)
        #expect(game.board[0, 0] == 5)
    }

    @Test func entriesCanBeCleared() {
        var game = SudokuGame(puzzle: puzzle)
        game.set(4, atRow: 0, col: 2)
        game.set(Sudoku.empty, atRow: 0, col: 2)
        #expect(game.board == puzzle)
    }

    @Test func conflictingEntriesAreAllowedButNotSolved() {
        var game = SudokuGame(puzzle: puzzle)
        game.set(5, atRow: 0, col: 2)   // 5 is already in row 0
        #expect(game.board[0, 2] == 5)
        #expect(!game.board.isValidSudoku())
    }

    @Test func fillingInTheSolutionSolvesTheGame() throws {
        let solution = try #require(DFSSolver().solve(puzzle))
        var game = SudokuGame(puzzle: puzzle)
        for row in 0..<Sudoku.size {
            for col in 0..<Sudoku.size where !game.isGiven(atRow: row, col: col) {
                game.set(solution[row, col], atRow: row, col: col)
            }
        }
        #expect(game.isSolved)
        #expect(game.board == solution)
        #expect(game.puzzle == puzzle)
    }
}
