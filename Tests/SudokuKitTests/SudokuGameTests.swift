import Testing
@testable import SudokuKit

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

    @Test(arguments: [-1, 10, 42])
    func digitsOutOfRangeAreRefused(digit: Int) {
        var game = SudokuGame(puzzle: puzzle)
        let entered = game.set(digit, atRow: 0, col: 2)
        #expect(!entered)
        #expect(game.board == puzzle)
        #expect(!game.canUndo)
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

    // MARK: - Undo

    @Test func newGameHasNothingToUndo() {
        var game = SudokuGame(puzzle: puzzle)
        #expect(!game.canUndo)
        let undone = game.undo()
        #expect(!undone)
        #expect(game.board == puzzle)
    }

    @Test func undoTakesBackAnEntry() {
        var game = SudokuGame(puzzle: puzzle)
        game.set(4, atRow: 0, col: 2)
        #expect(game.canUndo)
        let undone = game.undo()
        #expect(undone)
        #expect(game.board == puzzle)
        #expect(!game.canUndo)
    }

    @Test func undoRestoresOverwrittenAndClearedDigits() {
        var game = SudokuGame(puzzle: puzzle)
        game.set(4, atRow: 0, col: 2)
        game.set(1, atRow: 0, col: 2)
        game.set(Sudoku.empty, atRow: 0, col: 2)

        game.undo()
        #expect(game.board[0, 2] == 1)
        game.undo()
        #expect(game.board[0, 2] == 4)
        game.undo()
        #expect(game.board[0, 2] == Sudoku.empty)
        #expect(!game.canUndo)
    }

    @Test func undoGoesBackInReverseOrderAcrossCells() {
        var game = SudokuGame(puzzle: puzzle)
        game.set(4, atRow: 0, col: 2)
        game.set(2, atRow: 0, col: 3)
        game.undo()
        #expect(game.board[0, 3] == Sudoku.empty)
        #expect(game.board[0, 2] == 4)
    }

    @Test func refusedAndUnchangedMovesAreNotRecorded() {
        var game = SudokuGame(puzzle: puzzle)
        game.set(1, atRow: 0, col: 0)              // given: refused
        game.set(Sudoku.empty, atRow: 0, col: 2)   // already empty: no change
        #expect(!game.canUndo)

        game.set(4, atRow: 0, col: 2)
        game.set(4, atRow: 0, col: 2)              // same digit again: no change
        game.undo()
        #expect(!game.canUndo)
        #expect(game.board == puzzle)
    }

    @Test func undoAfterSolvingUnsolvesTheGame() throws {
        let solution = try #require(DFSSolver().solve(puzzle))
        var game = SudokuGame(puzzle: puzzle)
        for row in 0..<Sudoku.size {
            for col in 0..<Sudoku.size where !game.isGiven(atRow: row, col: col) {
                game.set(solution[row, col], atRow: row, col: col)
            }
        }
        #expect(game.isSolved)
        game.undo()
        #expect(!game.isSolved)
        #expect(game.board[8, 6] == Sudoku.empty)   // last empty cell filled
    }

    // MARK: Solution

    @Test func solutionIsComputedOnFirstAccessOnly() throws {
        var game = SudokuGame(puzzle: puzzle)
        #expect(game._solution == nil)
        let solution = game.solution
        #expect(game._solution == solution)
        #expect(solution == DFSSolver().solve(puzzle))
        #expect(game.hint(forRow: 0, col: 2) == solution[0, 2])
    }

    @Test func storedSolutionSurvivesMovesAndCopies() throws {
        var game = SudokuGame(puzzle: puzzle)
        _ = game.solution
        game.set(4, atRow: 0, col: 2)               // moves don't affect the solution
        let copy = game
        #expect(copy._solution != nil)
    }

    @Test func storedSolutionDoesNotAffectEquality() {
        var solved = SudokuGame(puzzle: puzzle)
        _ = solved.solution
        #expect(solved == SudokuGame(puzzle: puzzle))
    }
}

struct SudokuGameIdentityTests {
    @Test func idDependsOnPuzzleOnly() throws {
        let puzzle = try SudokuParser.parse(SudokuPuzzle.all[0].cells)
        var game = SudokuGame(puzzle: puzzle)
        let fresh = game
        game.set(4, atRow: 0, col: 2)
        #expect(game.id == fresh.id)
        #expect(game != fresh)
        #expect(game.id == SudokuPuzzle.all[0].cells)
    }
}
