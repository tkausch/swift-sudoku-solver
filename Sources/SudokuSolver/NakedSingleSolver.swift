/// Solves Sudoku puzzles using only naked singles: it never guesses.
///
/// A *naked single* is an empty cell with exactly one candidate. The solver
/// fills such cells until the grid is complete or none are left. Puzzles that
/// can be finished this way are the easiest kind for a human, so the solver
/// also works as a difficulty check:
///
/// ```swift
/// var grid = puzzle
/// switch NakedSingleSolver().fillNakedSingles(&grid) {
/// case .solved:        print("easy")
/// case .stuck:         print("needs more than naked singles")
/// case .contradiction: print("no solution")
/// }
/// ```
///
/// Every digit it places is forced, so it never backtracks. The solver has no
/// stored state, so one instance can be shared and used from several threads at once.
public struct NakedSingleSolver<Puzzle: SolvableSudoku>: SudokuSolver, Sendable {

    /// How far ``fillNakedSingles(_:)`` got.
    public enum Outcome: Equatable, Sendable {
        /// Every cell is filled.
        case solved
        /// Every empty cell has two or more candidates: a stronger technique is needed.
        case stuck
        /// An empty cell has no candidates, so the puzzle has no solution.
        case contradiction
    }

    /// Creates a solver.
    public init() {}

    /// Solves a puzzle if naked singles alone are enough.
    ///
    /// - Parameter sudoku: The puzzle to solve. It is not modified.
    /// - Returns: A solved copy of `sudoku`, or `nil` if it gets stuck or has no solution.
    public func solve(_ sudoku: Puzzle) -> Puzzle? {
        var sudoku = sudoku
        return fillNakedSingles(&sudoku) == .solved ? sudoku : nil
    }

    /// Fills naked singles until none are left.
    ///
    /// Each pass places every cell that has exactly one candidate. This is safe
    /// because placing a digit only removes candidates elsewhere; a resulting
    /// conflict shows up as a cell with no candidates on the next pass.
    ///
    /// - Parameter sudoku: The grid to fill. It keeps every digit placed, also
    ///   when the result is ``Outcome/stuck``.
    /// - Returns: Whether the grid was solved, got stuck, or hit a contradiction.
    public func fillNakedSingles(_ sudoku: inout Puzzle) -> Outcome {
        while true {
            var foundEmpty = false
            var placed = false
            for row in 0..<Puzzle.size {
                for col in 0..<Puzzle.size where sudoku.isEmpty(atRow: row, col: col) {
                    foundEmpty = true
                    let candidates = sudoku.candidates(atRow: row, col: col)
                    if candidates.isEmpty { return .contradiction }
                    if candidates.count == 1 {
                        sudoku[row, col] = candidates[0]
                        placed = true
                    }
                }
            }
            if !foundEmpty { return .solved }
            if !placed { return .stuck }
        }
    }
}
