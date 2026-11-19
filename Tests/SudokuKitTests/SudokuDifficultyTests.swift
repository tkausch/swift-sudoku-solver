import Testing
@testable import SudokuKit

struct SudokuDifficultyTests {
    func clues(_ sudoku: Sudoku) -> Int {
        sudoku.grid.filter { $0 != 0 }.count
    }

    @Test func harderMeansFewerMinimumClues() {
        #expect(SudokuDifficulty.easy.minimumClues > SudokuDifficulty.medium.minimumClues)
        #expect(SudokuDifficulty.medium.minimumClues > SudokuDifficulty.hard.minimumClues)
    }

    @Test func titleIsCapitalized() {
        #expect(SudokuDifficulty.allCases.map(\.title) == ["Easy", "Medium", "Hard"])
    }

    @Test(arguments: SudokuDifficulty.allCases)
    func generatedPuzzleRespectsMinimumAndIsSolvable(difficulty: SudokuDifficulty) {
        var rng = SplitMix64(seed: 3)
        let puzzle = SudokuGenerator().generate(difficulty, using: &rng)
        #expect(clues(puzzle) >= difficulty.minimumClues)
        #expect(NakedSingleSolver<Sudoku>().solve(puzzle) != nil)
    }
}
