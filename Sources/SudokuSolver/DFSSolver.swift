/// Solves Sudoku puzzles with depth-first search (backtracking).
///
/// The search repeatedly picks the empty cell with the fewest candidates, tries
/// each candidate in turn, and backs up when it reaches a cell with none.
/// Choosing the most constrained cell finds dead ends early and fills cells
/// with a single candidate without guessing.
///
/// ```swift
/// let solver = DFSSolver<Sudoku>()
/// if let solution = solver.solve(puzzle) {
///     print(solution)
/// }
/// ```
///
/// The solver has no stored state, so one instance can be shared and used
/// from several threads at once.
public struct DFSSolver<Puzzle: SolvableSudoku>: SudokuSolver, Sendable {
    /// Creates a solver.
    ///
    /// The puzzle type is usually inferred from the first call, so
    /// `DFSSolver().solve(sudoku)` works without writing `<Sudoku>`.
    public init() {}

    /// Solves a puzzle.
    ///
    /// If the puzzle has several solutions, the first one found is returned.
    ///
    /// - Parameter sudoku: The puzzle to solve. It is not modified.
    /// - Returns: A solved copy of `sudoku`, or `nil` if it has no solution.
    public func solve(_ sudoku: Puzzle) -> Puzzle? {
        solveCountingPositions(sudoku).solution
    }

    /// Solves a puzzle like ``solve(_:)`` and also reports how much searching it took.
    ///
    /// A board position is one state of the grid examined by the search: the
    /// starting grid plus every grid reached by placing a digit, including those
    /// later abandoned by backtracking. A puzzle with `n` empty cells needs at
    /// least `n + 1` positions; more means the search had to backtrack.
    ///
    /// ```swift
    /// let (solution, positions) = DFSSolver().solveCountingPositions(puzzle)
    /// ```
    ///
    /// - Parameter sudoku: The puzzle to solve. It is not modified.
    /// - Returns: A tuple with the solved copy of `sudoku` (or `nil` if it has
    ///   no solution) and the number of board positions visited.
    public func solveCountingPositions(_ sudoku: Puzzle) -> (solution: Puzzle?, positions: Int) {
        var sudoku = sudoku
        var positions = 0
        let solved = search(&sudoku, positions: &positions)
        return (solved ? sudoku : nil, positions)
    }

    /// Counts the solutions of a puzzle, stopping once `limit` is reached.
    ///
    /// Use the default limit of 2 to check that a puzzle has exactly one solution:
    ///
    /// ```swift
    /// let isUnique = DFSSolver().countSolutions(puzzle) == 1
    /// ```
    ///
    /// - Parameters:
    ///   - sudoku: The puzzle to examine. It is not modified.
    ///   - limit: The search stops after finding this many solutions. Must be at least 1.
    /// - Returns: The number of solutions, at most `limit`: `0` if there is none.
    public func countSolutions(_ sudoku: Puzzle, limit: Int = 2) -> Int {
        precondition(limit >= 1, "limit must be at least 1")
        var sudoku = sudoku
        var count = 0
        countSolutions(&sudoku, limit: limit, count: &count)
        return count
    }
    
    /// Depth-first search: fills one empty cell with each of its candidates in turn
    /// and recurses; undoes the move when a branch leads to a dead end.
    ///
    /// Always branches on the empty cell with the fewest candidates. This finds
    /// dead ends (a cell with no candidates) early and keeps the search tree small.
    ///
    /// - Parameter positions: Incremented once for every board position visited.
    /// - Returns: `true` once `sudoku` is completely and validly filled.
    private func search(_ sudoku: inout Puzzle, positions: inout Int) -> Bool {
        positions += 1

        guard let (row, col, candidates) = mostConstrainedCell(in: sudoku) else {
            return true   // no empty cell left: solved
        }

        for digit in candidates {
            sudoku[row, col] = digit
            if search(&sudoku, positions: &positions) { return true }
        }
        sudoku[row, col] = Puzzle.empty   // backtrack
        return false
    }

    /// Depth-first search like ``search(_:positions:)``, but instead of stopping at the first
    /// solution it counts solutions until `count` reaches `limit`.
    private func countSolutions(_ sudoku: inout Puzzle, limit: Int, count: inout Int) {
        guard let (row, col, candidates) = mostConstrainedCell(in: sudoku) else {
            count += 1   // no empty cell left: one more solution
            return
        }
        for digit in candidates {
            sudoku[row, col] = digit
            countSolutions(&sudoku, limit: limit, count: &count)
            if count >= limit { break }
        }
        sudoku[row, col] = Puzzle.empty   // backtrack
    }

    /// Returns the empty cell with the fewest candidates, or `nil` if every cell is filled.
    /// Stops early on a cell with zero or one candidate, since none can be better.
    private func mostConstrainedCell(in sudoku: Puzzle) -> (row: Int, col: Int, candidates: [Int])? {
        var best: (row: Int, col: Int, candidates: [Int])?

        for row in 0..<Puzzle.size {
            for col in 0..<Puzzle.size where sudoku.isEmpty(atRow: row, col: col) {
                let candidates = sudoku.candidates(atRow: row, col: col)
                if candidates.count <= 1 { return (row, col, candidates) }
                if best == nil || candidates.count < best!.candidates.count {
                    best = (row, col, candidates)
                }
            }
        }
        return best
    }
}
