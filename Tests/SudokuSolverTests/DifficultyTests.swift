import Testing
@testable import SudokuSolver

struct DifficultyTests {
    func clues(_ sudoku: Sudoku) -> Int {
        sudoku.board.filter { $0 != 0 }.count
    }

    @Test func harderMeansFewerMinimumClues() {
        #expect(Difficulty.easy.minimumClues > Difficulty.medium.minimumClues)
        #expect(Difficulty.medium.minimumClues > Difficulty.hard.minimumClues)
    }

    @Test func titleIsCapitalized() {
        #expect(Difficulty.allCases.map(\.title) == ["Easy", "Medium", "Hard"])
    }

    @Test(arguments: Difficulty.allCases)
    func generatedPuzzleRespectsMinimumAndIsSolvable(difficulty: Difficulty) {
        var rng = SplitMix64(seed: 3)
        let puzzle = SudokuGenerator().generate(difficulty, using: &rng)
        #expect(clues(puzzle) >= difficulty.minimumClues)
        #expect(NakedSingleSolver<Sudoku>().solve(puzzle) != nil)
    }
}
