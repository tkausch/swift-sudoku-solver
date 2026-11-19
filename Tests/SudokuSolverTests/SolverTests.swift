import Testing
@testable import SudokuSolver

struct SolverTests {
    func sudoku(_ string: String) throws -> Sudoku {
        try #require(Sudoku(grid: string.compactMap(\.wholeNumberValue)))
    }

    @Test func solvesEasyPuzzle() throws {
        let puzzle = try sudoku("530070000600195000098000060800060003400803001700020006060000280000419005000080079")
        let solution = try sudoku("534678912672195348198342567859761423426853791713924856961537284287419635345286179")
        #expect(DFSSolver().solve(puzzle) == solution)
    }

    /// "World's hardest Sudoku" by Arto Inkala; needs real backtracking.
    @Test func solvesHardPuzzle() throws {
        let puzzle = try sudoku("800000000003600000070090200050007000000045700000100030001000068008500010090000400")
        let solved = try #require(DFSSolver().solve(puzzle))
        #expect(solved.isComplete)
        #expect(solved.isValidSudoku())
        let expected = try sudoku("812753649943682175675491283154237896369845721287169534521974368438526917796318452")
        #expect(solved == expected)
    }

    @Test func keepsGivens() throws {
        let puzzle = try sudoku("800000000003600000070090200050007000000045700000100030001000068008500010090000400")
        let solved = try #require(DFSSolver().solve(puzzle))
        for i in puzzle.grid.indices where puzzle.grid[i] != 0 {
            #expect(solved.grid[i] == puzzle.grid[i])
        }
    }

    @Test func solvesEmptyGrid() throws {
        let solved = try #require(DFSSolver().solve(try sudoku(String(repeating: "0", count: 81))))
        #expect(solved.isComplete)
        #expect(solved.isValidSudoku())
    }

    @Test func returnsSolvedGridUnchanged() throws {
        let solution = try sudoku("534678912672195348198342567859761423426853791713924856961537284287419635345286179")
        #expect(DFSSolver().solve(solution) == solution)
    }

    /// Givens don't conflict, but cell (0, 8) has no candidate: row 0 holds 1-8
    /// and column 8 already holds 9.
    @Test func returnsNilWhenUnsolvable() throws {
        let puzzle = try sudoku("123456780" + "000000009" + String(repeating: "0", count: 63))
        #expect(DFSSolver().solve(puzzle) == nil)
    }

    @Test func solvesAnyGridConformingToProtocol() throws {
        let puzzle = MiniSudoku(cells: [1, 0, 0, 0,
                                        0, 0, 3, 0,
                                        0, 4, 0, 0,
                                        0, 0, 0, 2])
        let solved = try #require(DFSSolver().solve(puzzle))
        #expect(solved.cells == [1, 3, 2, 4,
                                 4, 2, 3, 1,
                                 2, 4, 1, 3,
                                 3, 1, 4, 2])
    }

    // MARK: - Board positions

    @Test func solvedGridVisitsOnePosition() throws {
        let solution = try sudoku("534678912672195348198342567859761423426853791713924856961537284287419635345286179")
        let result = DFSSolver().solveCountingPositions(solution)
        #expect(result.solution == solution)
        #expect(result.positions == 1)
    }

    @Test func singleEmptyCellVisitsTwoPositions() throws {
        let puzzle = try sudoku("034678912672195348198342567859761423426853791713924856961537284287419635345286179")
        #expect(DFSSolver().solveCountingPositions(puzzle).positions == 2)
    }

    /// Every empty cell must be filled once, so at least `empty + 1` positions are visited.
    @Test func positionsAreAtLeastEmptyCellsPlusOne() throws {
        let puzzle = try sudoku("800000000003600000070090200050007000000045700000100030001000068008500010090000400")
        let empty = puzzle.grid.filter { $0 == 0 }.count
        let result = DFSSolver().solveCountingPositions(puzzle)
        #expect(result.solution != nil)
        #expect(result.positions > empty + 1)   // this hard puzzle needs backtracking
    }

    @Test func countingDoesNotChangeSolution() throws {
        let puzzle = try sudoku("530070000600195000098000060800060003400803001700020006060000280000419005000080079")
        #expect(DFSSolver().solveCountingPositions(puzzle).solution == DFSSolver().solve(puzzle))
    }

    @Test func unsolvablePuzzleStillReportsPositions() throws {
        let puzzle = try sudoku("123456780" + "000000009" + String(repeating: "0", count: 63))
        let result = DFSSolver().solveCountingPositions(puzzle)
        #expect(result.solution == nil)
        #expect(result.positions == 1)   // cell (0, 8) has no candidates: dead end at the start
    }

    // MARK: - Counting solutions

    @Test func uniquePuzzlesHaveOneSolution() throws {
        let easy = try sudoku("530070000600195000098000060800060003400803001700020006060000280000419005000080079")
        let hard = try sudoku("800000000003600000070090200050007000000045700000100030001000068008500010090000400")
        #expect(DFSSolver().countSolutions(easy) == 1)
        #expect(DFSSolver().countSolutions(hard) == 1)
    }

    @Test func solvedGridHasOneSolution() throws {
        let solution = try sudoku("534678912672195348198342567859761423426853791713924856961537284287419635345286179")
        #expect(DFSSolver().countSolutions(solution) == 1)
    }

    @Test func emptyGridStopsAtLimit() throws {
        let empty = try sudoku(String(repeating: "0", count: 81))
        #expect(DFSSolver().countSolutions(empty) == 2)
        #expect(DFSSolver().countSolutions(empty, limit: 5) == 5)
        #expect(DFSSolver().countSolutions(empty, limit: 1) == 1)
    }

    /// Blanks cells (0, 3), (0, 4), (3, 3), (3, 4) of a solved grid. They hold
    /// 6 7 / 7 6, so swapping the pairs gives a second valid grid.
    @Test func deadlyRectangleHasTwoSolutions() throws {
        var cells = try sudoku("534678912672195348198342567859761423426853791713924856961537284287419635345286179").grid
        for i in [3, 4, 30, 31] { cells[i] = 0 }
        let puzzle = try #require(Sudoku(grid: cells))
        #expect(DFSSolver().countSolutions(puzzle) == 2)
        #expect(DFSSolver().countSolutions(puzzle, limit: 10) == 2)
    }

    @Test func unsolvablePuzzleHasNoSolution() throws {
        let puzzle = try sudoku("123456780" + "000000009" + String(repeating: "0", count: 63))
        #expect(DFSSolver().countSolutions(puzzle) == 0)
    }

    @Test func countingSolutionsKeepsInput() throws {
        let puzzle = try sudoku("530070000600195000098000060800060003400803001700020006060000280000419005000080079")
        let copy = puzzle
        _ = DFSSolver().countSolutions(puzzle)
        #expect(puzzle == copy)
    }

    @Test func countsSolutionsOfAnyGridConformingToProtocol() {
        let empty = MiniSudoku(cells: Array(repeating: 0, count: 16))
        #expect(DFSSolver().countSolutions(empty, limit: 1000) == 288)   // all 4×4 Sudoku grids
    }

    // MARK: - SudokuSolver protocol

    /// Code written against the protocol works with any solver for `Sudoku`.
    func solveAll(_ puzzles: [Sudoku], with solver: some SudokuSolver<Sudoku>) -> [Sudoku?] {
        puzzles.map(solver.solve)
    }

    @Test func usableAsOpaqueSolver() throws {
        let puzzle = try sudoku("530070000600195000098000060800060003400803001700020006060000280000419005000080079")
        let solutions = solveAll([puzzle], with: DFSSolver())
        #expect(solutions.first??.isComplete == true)
    }

    @Test func usableAsExistentialSolver() throws {
        let solver: any SudokuSolver<Sudoku> = DFSSolver()
        let puzzle = try sudoku("530070000600195000098000060800060003400803001700020006060000280000419005000080079")
        let solved = try #require(solver.solve(puzzle))
        #expect(solved.isValidSudoku())
    }
}

/// A minimal 4x4 grid (2x2 boxes) showing that `DFSSolver` only depends on `SolvableSudoku`.
struct MiniSudoku: SolvableSudoku {
    static let size = 4
    var cells: [Int]

    subscript(row: Int, col: Int) -> Int {
        get { cells[row * 4 + col] }
        set { cells[row * 4 + col] = newValue }
    }

    func candidates(atRow row: Int, col: Int) -> [Int] {
        guard self[row, col] == 0 else { return [] }
        let boxRow = row / 2 * 2, boxCol = col / 2 * 2
        var used = Set<Int>()
        for i in 0..<4 {
            used.insert(self[row, i])
            used.insert(self[i, col])
            used.insert(self[boxRow + i / 2, boxCol + i % 2])
        }
        return (1...4).filter { !used.contains($0) }
    }
}
