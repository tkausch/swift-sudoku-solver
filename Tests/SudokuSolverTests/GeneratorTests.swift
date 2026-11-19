import Testing
@testable import SudokuSolver

/// A small seeded random number generator, so generated puzzles are reproducible.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

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
        let puzzle = SudokuGenerator().generateEasy()
        #expect(NakedSingleSolver().solve(puzzle) != nil)
    }
}
