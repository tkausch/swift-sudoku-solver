/// Generates new Sudoku puzzles.
///
/// ```swift
/// let puzzle = SudokuGenerator().generate()
/// print(puzzle)
/// ```
///
/// Pass your own random number generator to get reproducible puzzles:
///
/// ```swift
/// var rng = SplitMix64(seed: 42)
/// let puzzle = SudokuGenerator().generate(using: &rng)
/// ```
public struct SudokuGenerator: Sendable {
    /// Creates a generator.
    public init() {}

    /// Generates an easy puzzle: one that can be solved with naked singles alone.
    ///
    /// The generator fills a random complete grid, then empties cells in random
    /// order, in pairs that are symmetric around the center. A pair stays empty
    /// only if ``NakedSingleSolver`` can still solve the puzzle. That also
    /// guarantees exactly one solution, since every digit is forced.
    ///
    /// - Parameters:
    ///   - minimumClues: Digging stops before the puzzle would have fewer clues
    ///     than this. Lower values make bigger, slower puzzles, but they stay
    ///     solvable with naked singles. Must be in `17...81`.
    ///   - rng: The source of randomness.
    /// - Returns: An easy puzzle with at least `minimumClues` clues.
    public func generate<R: RandomNumberGenerator>(minimumClues: Int = 36, using rng: inout R) -> Sudoku {
        precondition((17...Sudoku.gridSize).contains(minimumClues), "minimumClues must be in 17...\(Sudoku.gridSize)")

        var sudoku = randomFilledSudoku(using: &rng)
        var clues = Sudoku.gridSize
        let solver = NakedSingleSolver<Sudoku>()

        for pair in symmetricPairs().shuffled(using: &rng) {
            guard clues - pair.count >= minimumClues else { continue }

            let candidate = emptying(pair, in: sudoku)
            if solver.solve(candidate) != nil {   // still easy: keep the cells empty
                sudoku = candidate
                clues -= pair.count
            }
        }
        return sudoku
    }

    /// Generates an easy puzzle using the system's random number generator.
    ///
    /// - Parameter minimumClues: See ``generate(minimumClues:using:)``.
    public func generate(minimumClues: Int = 36) -> Sudoku {
        var rng = SystemRandomNumberGenerator()
        return generate(minimumClues: minimumClues, using: &rng)
    }

    @available(*, deprecated, renamed: "generate(minimumClues:)")
    public func generateEasy(minimumClues: Int = 36) -> Sudoku {
        generate(minimumClues: minimumClues)
    }

    /// Generates a puzzle of the given difficulty.
    ///
    /// - Parameters:
    ///   - difficulty: How many clues the puzzle keeps; see ``SudokuDifficulty``.
    ///   - rng: The source of randomness.
    public func generate<R: RandomNumberGenerator>(_ difficulty: SudokuDifficulty, using rng: inout R) -> Sudoku {
        generate(minimumClues: difficulty.minimumClues, using: &rng)
    }

    /// Generates a puzzle of the given difficulty using the system's random number generator.
    public func generate(_ difficulty: SudokuDifficulty) -> Sudoku {
        var rng = SystemRandomNumberGenerator()
        return generate(difficulty, using: &rng)
    }

    /// A cell position on the grid.
    private typealias Index = (row: Int, col: Int)

    /// All pairs of cells that mirror each other through the center:
    /// (r, c) and (8 - r, 8 - c). The center cell is its own mirror, so its "pair" has one cell.
    private func symmetricPairs() -> [[Index]] {
        let last = Sudoku.size - 1
        return (0...(Sudoku.gridSize / 2)).map { index in
            let cell: Index = (index / Sudoku.size, index % Sudoku.size)
            let mirror: Index = (last - cell.row, last - cell.col)
            return cell == mirror ? [cell] : [cell, mirror]
        }
    }

    /// Returns a copy of `sudoku` with the given cells emptied.
    private func emptying(_ cells: [Index], in sudoku: Sudoku) -> Sudoku {
        var copy = sudoku
        for cell in cells { copy[cell.row, cell.col] = Sudoku.empty }
        return copy
    }

    /// Returns a random complete, valid grid.
    private func randomFilledSudoku<R: RandomNumberGenerator>(using rng: inout R) -> Sudoku {
        var grid = Sudoku(grid: Array(repeating: Sudoku.empty, count: Sudoku.gridSize))!
        let filled = fillRandom(&grid, from: 0, using: &rng)
        assert(filled, "an empty grid always has a solution")
        return grid
    }

    /// Fills the cells from `index` onward in row-major order, trying each
    /// cell's candidates in random order and backtracking on dead ends.
    private func fillRandom<R: RandomNumberGenerator>(_ grid: inout Sudoku, from index: Int, using rng: inout R) -> Bool {
        guard index < Sudoku.gridSize else { return true }
        let row = index / Sudoku.size, col = index % Sudoku.size

        for digit in grid.candidates(atRow: row, col: col).shuffled(using: &rng) {
            grid[row, col] = digit
            if fillRandom(&grid, from: index + 1, using: &rng) { return true }
        }
        grid[row, col] = Sudoku.empty
        return false
    }
}
