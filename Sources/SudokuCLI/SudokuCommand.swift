import ArgumentParser
import SudokuSolver

@main
struct SudokuCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sudoku",
        abstract: "Solve or generate a 9x9 Sudoku.",
        discussion: """
            Without a puzzle, one of \(ClassicPuzzles.all.count) built-in puzzles is picked at random.
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
        if let sample, !ClassicPuzzles.all.indices.contains(sample - 1) {
            throw ValidationError("--sample must be between 1 and \(ClassicPuzzles.all.count).")
        }
    }

    fileprivate func printTime(_ elapsed: ContinuousClock.Instant.Duration) {
        let ms = Double(elapsed.components.seconds) * 1_000
        + Double(elapsed.components.attoseconds) / 1e15
        print("\nSolved in \(Double(Int(ms * 10)) / 10) ms:\n")
    }
    
    func run() throws {
        if list {
            for (i, sample) in ClassicPuzzles.all.enumerated() {
                print("\(i + 1). \(sample.name)")
            }
            return
        }

        let puzzle: Sudoku
        if generate {
            puzzle = SudokuGenerator().generateEasy(minimumClues: clues ?? Self.defaultMinimumClues)
            let clueCount = puzzle.board.filter { $0 != Sudoku.empty }.count
            print("Generated easy puzzle with \(clueCount) clues:")
            print(SudokuParser.string(for: puzzle) + "\n")
        } else if let cells {
            puzzle = try SudokuParser.parse(cells)
        } else {
            let sample = sample.map { ClassicPuzzles.all[$0 - 1] } ?? ClassicPuzzles.all.randomElement()!
            print("Puzzle: \(sample.name)\n")
            puzzle = try SudokuParser.parse(sample.cells)
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
}
