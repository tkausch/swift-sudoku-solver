import ArgumentParser
import SudokuSolver

@main
struct SudokuCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sudoku",
        abstract: "Solve or generate a 9x9 Sudoku.",
        discussion: """
            Without a puzzle, one of \(samplePuzzles.count) built-in puzzles is picked at random.
            With --generate, a new easy puzzle is generated and solved instead.
            """
    )

    @Argument(help: ArgumentHelp(
        "\(Sudoku.cellCount) cells row by row: digits 1-\(Sudoku.size), 0 or . for empty.",
        valueName: "puzzle"))
    var cells: String?

    @Flag(name: .shortAndLong, help: "List the built-in puzzles and exit.")
    var list = false

    @Option(name: .shortAndLong,
            help: ArgumentHelp("Solve built-in puzzle number <n> (see --list) instead of a random one.",
                               valueName: "n"))
    var sample: Int?

    @Flag(name: .shortAndLong,
          help: "Generate a new easy puzzle (solvable with naked singles) and solve it.")
    var generate = false

    @Option(help: ArgumentHelp("With --generate: the minimum number of clues (\(minimumClueRange.lowerBound)-\(minimumClueRange.upperBound), default \(defaultMinimumClues)).",
                               valueName: "n"))
    var clues: Int?

    static let minimumClueRange = 17...Sudoku.cellCount
    static let defaultMinimumClues = 36

    mutating func validate() throws {
        if cells != nil && sample != nil {
            throw ValidationError("Pass either a puzzle or --sample, not both.")
        }
        if generate && (cells != nil || sample != nil) {
            throw ValidationError("--generate can't be combined with a puzzle or --sample.")
        }
        if clues != nil && !generate {
            throw ValidationError("--clues only works together with --generate.")
        }
        if let clues, !Self.minimumClueRange.contains(clues) {
            throw ValidationError("--clues must be between \(Self.minimumClueRange.lowerBound) and \(Self.minimumClueRange.upperBound).")
        }
        if let sample, !samplePuzzles.indices.contains(sample - 1) {
            throw ValidationError("--sample must be between 1 and \(samplePuzzles.count).")
        }
    }

    fileprivate func printTime(_ elapsed: ContinuousClock.Instant.Duration) {
        let ms = Double(elapsed.components.seconds) * 1_000
        + Double(elapsed.components.attoseconds) / 1e15
        print("\nSolved in \(Double(Int(ms * 10)) / 10) ms:\n")
    }
    
    func run() throws {
        if list {
            for (i, sample) in samplePuzzles.enumerated() {
                print("\(i + 1). \(sample.name)")
            }
            return
        }

        let puzzle: Sudoku
        if generate {
            puzzle = SudokuGenerator().generateEasy(minimumClues: clues ?? Self.defaultMinimumClues)
            let clueCount = puzzle.board.filter { $0 != 0 }.count
            print("Generated easy puzzle with \(clueCount) clues:")
            print(puzzle.board.map { $0 == 0 ? "." : String($0) }.joined() + "\n")
        } else if let cells {
            puzzle = try Self.parsePuzzle(cells)
        } else {
            let sample = sample.map { samplePuzzles[$0 - 1] } ?? samplePuzzles.randomElement()!
            print("Puzzle: \(sample.name)\n")
            puzzle = try Self.parsePuzzle(sample.cells)
        }

        print(puzzle)

        let clock = ContinuousClock()
        var solution: Sudoku?
        var positions = 0
        let elapsed = clock.measure {
            (solution, positions) = DFSSolver().solveCountingPositions(puzzle)
        }
        print("\nBoard positions visited: \(positions)")

        guard let solution else {
            print("\nNo solution found.")
            throw ExitCode.failure
        }

        printTime(elapsed)
        print(solution)
    }

    /// Parses `cellCount` cells (digits 0-9, `.` for empty, whitespace ignored).
    static func parsePuzzle(_ input: String) throws -> Sudoku {
        var board: [Int] = []
        for ch in input where !ch.isWhitespace {
            switch ch {
            case ".": board.append(0)
            case "0"..."9": board.append(Int(String(ch))!)
            default:
                throw ValidationError("Invalid character '\(ch)': only digits 0-9 (or . for empty) are allowed.")
            }
        }

        guard board.count == Sudoku.cellCount else {
            throw ValidationError("Invalid puzzle: expected exactly \(Sudoku.cellCount) cells, got \(board.count).")
        }

        guard let sudoku = Sudoku(board: board) else {
            throw ValidationError("Invalid puzzle: duplicate digits in a row, column or box.")
        }
        return sudoku
    }
}
