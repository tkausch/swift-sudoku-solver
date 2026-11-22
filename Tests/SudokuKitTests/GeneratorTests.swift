import Testing
@testable import SudokuKit

struct GeneratorTests {
    func easyPuzzle(seed: UInt64, minimumClues: Int = 36) -> Sudoku {
        var rng = SplitMix64(seed: seed)
        return SudokuGenerator().generate(minimumClues: minimumClues, using: &rng)
    }

    func clues(_ sudoku: Sudoku) -> Int {
        sudoku.grid.filter { $0 != 0 }.count
    }

    @Test(arguments: 1...10 as ClosedRange<UInt64>)
    func easyPuzzleIsSolvableWithNakedSingles(seed: UInt64) {
        let puzzle = easyPuzzle(seed: seed)
        #expect(puzzle.isValidSudoku())
        #expect(!puzzle.isComplete)
        #expect(NakedSingleSolver().solve(puzzle) != nil)
    }

    @Test(arguments: 1...10 as ClosedRange<UInt64>)
    func easyPuzzleHasExactlyOneSolution(seed: UInt64) {
        #expect(DFSSolver().countSolutions(easyPuzzle(seed: seed)) == 1)
    }

    @Test(arguments: 1...10 as ClosedRange<UInt64>)
    func easyPuzzleRespectsMinimumClues(seed: UInt64) {
        let count = clues(easyPuzzle(seed: seed))
        #expect(count >= 36)
        #expect(count <= 37)   // for these seeds digging reaches the target (one pair = 2 cells)
    }

    @Test func lowerMinimumGivesFewerClues() {
        let count = clues(easyPuzzle(seed: 7, minimumClues: 25))
        #expect(count >= 25)
        #expect(count < 36)
    }

    @Test func emptyCellsAreSymmetric() {
        let board = easyPuzzle(seed: 3).grid
        for i in board.indices {
            #expect((board[i] == 0) == (board[80 - i] == 0))
        }
    }

    @Test func sameSeedGivesSamePuzzle() {
        #expect(easyPuzzle(seed: 42) == easyPuzzle(seed: 42))
    }

    @Test func differentSeedsGiveDifferentPuzzles() {
        #expect(easyPuzzle(seed: 1) != easyPuzzle(seed: 2))
    }

    @Test func givensMatchTheSolution() throws {
        let puzzle = easyPuzzle(seed: 5)
        let solution = try #require(DFSSolver().solve(puzzle))
        #expect(solution.isValidSudoku())
        for i in puzzle.grid.indices where puzzle.grid[i] != 0 {
            #expect(solution.grid[i] == puzzle.grid[i])
        }
    }

    @Test func systemRandomGeneratorWorks() {
        let puzzle = SudokuGenerator().generate()
        #expect(NakedSingleSolver().solve(puzzle) != nil)
    }
}

struct SplitMix64Tests {
    @Test func sameSeedGivesSameSequence() {
        var a = SplitMix64(seed: 42), b = SplitMix64(seed: 42)
        #expect((0..<10).map { _ in a.next() } == (0..<10).map { _ in b.next() })
    }

    @Test func differentSeedsGiveDifferentSequences() {
        var a = SplitMix64(seed: 1), b = SplitMix64(seed: 2)
        #expect(a.next() != b.next())
    }
}
