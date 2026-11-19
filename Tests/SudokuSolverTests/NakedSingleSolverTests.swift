import Testing
@testable import SudokuSolver

struct NakedSingleSolverTests {
    func sudoku(_ string: String) throws -> Sudoku {
        try #require(Sudoku(grid: string.compactMap(\.wholeNumberValue)))
    }

    let easy = "530070000600195000098000060800060003400803001700020006060000280000419005000080079"
    let easySolution = "534678912672195348198342567859761423426853791713924856961537284287419635345286179"
    /// "World's hardest Sudoku" by Arto Inkala: has no naked single at the start.
    let hard = "800000000003600000070090200050007000000045700000100030001000068008500010090000400"
    /// Cell (0, 8) has no candidate: row 0 holds 1-8 and column 8 already holds 9.
    let deadEnd = "123456780" + "000000009" + String(repeating: "0", count: 63)

    @Test func solvesEasyPuzzle() throws {
        var grid = try sudoku(easy)
        let outcome = NakedSingleSolver().fillNakedSingles(&grid)
        let expected = try sudoku(easySolution)
        #expect(outcome == .solved)
        #expect(grid == expected)
    }

    @Test func agreesWithDFSSolver() throws {
        let puzzle = try sudoku(easy)
        let solved = try #require(NakedSingleSolver().solve(puzzle))
        #expect(solved == DFSSolver().solve(puzzle))
    }

    @Test func getsStuckOnHardPuzzle() throws {
        let puzzle = try sudoku(hard)
        var grid = puzzle
        #expect(NakedSingleSolver().fillNakedSingles(&grid) == .stuck)
        #expect(NakedSingleSolver().solve(puzzle) == nil)
    }

    /// Project Euler #96, grid 02: one naked single, then stuck. The placed
    /// digit stays in the grid and matches the real solution.
    @Test func stuckGridKeepsPlacedDigits() throws {
        let puzzle = try sudoku("200080300060070084030500209000105408000000000402706000301007040720040060004010003")
        let solution = try #require(DFSSolver().solve(puzzle))
        var grid = puzzle
        #expect(NakedSingleSolver().fillNakedSingles(&grid) == .stuck)
        #expect(grid.grid.filter { $0 == 0 }.count == puzzle.grid.filter { $0 == 0 }.count - 1)
        for i in grid.grid.indices where grid.grid[i] != 0 {
            #expect(grid.grid[i] == solution.grid[i])   // givens kept, placed digit correct
        }
    }

    @Test func reportsContradiction() throws {
        let puzzle = try sudoku(deadEnd)
        var grid = puzzle
        #expect(NakedSingleSolver().fillNakedSingles(&grid) == .contradiction)
        #expect(NakedSingleSolver().solve(puzzle) == nil)
    }

    @Test func solvedGridIsReturnedUnchanged() throws {
        let solution = try sudoku(easySolution)
        var grid = solution
        #expect(NakedSingleSolver().fillNakedSingles(&grid) == .solved)
        #expect(grid == solution)
    }

    /// One blank cell per row of a solved grid: each is a naked single.
    @Test func fillsSingleBlanks() throws {
        let solution = try sudoku(easySolution)
        var cells = solution.grid
        for row in 0..<9 { cells[row * 9 + row] = 0 }
        let puzzle = try #require(Sudoku(grid: cells))
        #expect(NakedSingleSolver().solve(puzzle) == solution)
    }

    @Test func worksForAnyGridConformingToProtocol() throws {
        let puzzle = MiniSudoku(cells: [1, 0, 3, 4,
                                        3, 4, 1, 2,
                                        2, 1, 4, 0,
                                        4, 3, 2, 1])
        let solved = try #require(NakedSingleSolver().solve(puzzle))
        #expect(solved.cells == [1, 2, 3, 4,
                                 3, 4, 1, 2,
                                 2, 1, 4, 3,
                                 4, 3, 2, 1])
    }
}
