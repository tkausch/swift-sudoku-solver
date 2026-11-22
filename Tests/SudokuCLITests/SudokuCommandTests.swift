import Testing
import SudokuKit
@testable import SudokuCLI

struct SudokuCommandTests {
    @Test(arguments: [
        ["--difficulty", "easy"],
        ["--seed", "7"],
        ["--generate", "--difficulty", "hard", "--clues", "30"],
        ["--clues", "30"],
        ["--generate", "--sample", "1"],
        ["--difficulty", "impossible", "--generate"],
    ])
    func rejectsInvalidCombinations(arguments: [String]) {
        #expect(throws: (any Error).self) { try SudokuCommand.parse(arguments) }
    }

    @Test(arguments: [
        ["--generate"],
        ["--generate", "--difficulty", "medium"],
        ["-g", "-d", "hard", "--seed", "7"],
        ["--generate", "--clues", "30", "--seed", "1"],
        ["--sample", "2"],
    ])
    func acceptsValidCombinations(arguments: [String]) throws {
        _ = try SudokuCommand.parse(arguments)
    }

    @Test func sameSeedGeneratesSamePuzzle() throws {
        let command = try SudokuCommand.parse(["--generate", "--difficulty", "hard", "--seed", "7"])
        var first = SplitMix64(seed: 7)
        var second = SplitMix64(seed: 7)
        #expect(command.generatePuzzle(using: &first) == command.generatePuzzle(using: &second))
    }

    @Test func difficultyControlsClues() throws {
        let command = try SudokuCommand.parse(["--generate", "--difficulty", "easy"])
        var rng = SplitMix64(seed: 1)
        let puzzle = command.generatePuzzle(using: &rng)
        #expect(puzzle.grid.filter { $0 != Sudoku.empty }.count >= SudokuDifficulty.easy.minimumClues)
    }

    @Test func rejectsPuzzleWithSeveralSolutions() throws {
        let command = try SudokuCommand.parse([])
        #expect(throws: (any Error).self) {
            try command.parseUserPuzzle("1" + String(repeating: ".", count: 80))
        }
    }
}
