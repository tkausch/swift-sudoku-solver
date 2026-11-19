/// A well-known puzzle with exactly one solution.
public struct SudokuPuzzles: Identifiable, Sendable {
    public let name: String
    public let cells: String
    public var id: String { cells }

    /// Puzzles from the swift-sudoku-solver collection, easy to extremely hard.
    public static let all: [SudokuPuzzles] = [
        .init(name: "Wikipedia example", cells: "53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79"),
        .init(name: "Project Euler #96, grid 01", cells: "..3.2.6..9..3.5..1..18.64....81.29..7.......8..67.82....26.95..8..2.3..9..5.1.3.."),
        .init(name: "Project Euler #96, grid 02", cells: "2...8.3...6..7..84.3.5..2.9...1.54.8.........4.27.6...3.1..7.4.72..4..6...4.1...3"),
        .init(name: "Peter Norvig, grid 2", cells: "4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......"),
        .init(name: "Arto Inkala, \u{201C}world's hardest\u{201D}", cells: "8..........36......7..9.2...5...7.......457.....1...3...1....68..85...1..9....4.."),
        .init(name: "Easter Monster", cells: "1.......2.9.4...5...6...7...5.9.3.......7.......85..4.7.....6...3...9.8...2.....1"),
        .init(name: "Golden Nugget", cells: ".......39.....1..5..3.5.8....8.9...6.7...2...1..4.......9.8..5..2....6..4..7....."),
        .init(name: "AI Escargot", cells: "1....7.9..3..2...8..96..5....53..9...1..8...26....4...3......1..4......7..7...3.."),
    ]
}
