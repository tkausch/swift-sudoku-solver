/// An algorithm that solves Sudoku puzzles of one type.
///
/// `Puzzle` is the primary associated type, so code can work with any solver
/// for a given puzzle type:
///
/// ```swift
/// func solveAll(_ puzzles: [Sudoku], with solver: some SudokuSolver<Sudoku>) -> [Sudoku?] {
///     puzzles.map(solver.solve)
/// }
///
/// let solver: any SudokuSolver<Sudoku> = DFSSolver()
/// ```
public protocol SudokuSolver<Puzzle> {
    /// The kind of puzzle this solver works on.
    associatedtype Puzzle: SolvableSudoku

    /// Solves a puzzle.
    ///
    /// - Parameter sudoku: The puzzle to solve. It is not modified.
    /// - Returns: A solved copy of `sudoku`, or `nil` if it has no solution.
    func solve(_ sudoku: Puzzle) -> Puzzle?
}
