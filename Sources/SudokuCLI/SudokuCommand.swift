import ArgumentParser
import SudokuKit

extension SudokuDifficulty: ExpressibleByArgument {}

@main
struct SudokuCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sudoku",
        abstract: "Solve or generate a 9x9 Sudoku.",
        discussion: """
            Without a puzzle, one of \(SudokuPuzzle.all.count) built-in puzzles is picked at random.
            A puzzle you pass must have exactly one solution.
            With --generate, a new puzzle is generated and solved instead. Add --difficulty or
            --clues to control how many clues it keeps, and --seed to get the same puzzle again.
            """
    )

    @Argument(help: ArgumentHelp(
        "\(Sudoku.gridSize) cells row by row: digits 1-\(Sudoku.size), 0 or . for empty.",
        valueName: "puzzle"))
    var cells: String?

    @Flag(name: .shortAndLong, help: "List the built-in puzzles and exit.")
    var list = false

    @Option(name: .shortAndLong,
            help: ArgumentHelp("Solve built-in puzzle number <n> (see --list) instead of a random one.",
                               valueName: "n"))
    var sample: Int?

    @Flag(name: .shortAndLong,
          help: "Generate a new puzzle (solvable with naked singles) and solve it.")
    var generate = false

    @Option(name: .shortAndLong,
            help: ArgumentHelp("With --generate: how many clues to keep (\(SudokuDifficulty.allCases.map(\.rawValue).joined(separator: ", "))).",
                               valueName: "level"))
    var difficulty: SudokuDifficulty?

    @Option(help: ArgumentHelp("With --generate: the minimum number of clues (\(minimumClueRange.lowerBound)-\(minimumClueRange.upperBound), default \(defaultMinimumClues)).",
                               valueName: "n"))
    var clues: Int?

    @Option(help: ArgumentHelp("With --generate: a seed for the random number generator, to get the same puzzle again.",
                               valueName: "n"))
    var seed: UInt64?

    static let minimumClueRange = 17...Sudoku.gridSize
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
        if difficulty != nil && !generate {
            throw ValidationError("--difficulty only works together with --generate.")
        }
        if seed != nil && !generate {
            throw ValidationError("--seed only works together with --generate.")
        }
        if difficulty != nil && clues != nil {
            throw ValidationError("Pass either --difficulty or --clues, not both.")
        }
        if let clues, !Self.minimumClueRange.contains(clues) {
            throw ValidationError("--clues must be between \(Self.minimumClueRange.lowerBound) and \(Self.minimumClueRange.upperBound).")
        }
        if let sample, !SudokuPuzzle.all.indices.contains(sample - 1) {
            throw ValidationError("--sample must be between 1 and \(SudokuPuzzle.all.count).")
        }
    }

    fileprivate func printTime(_ elapsed: ContinuousClock.Instant.Duration) {
        let ms = Double(elapsed.components.seconds) * 1_000
        + Double(elapsed.components.attoseconds) / 1e15
        print("\nSolved in \(Double(Int(ms * 10)) / 10) ms:\n")
    }

    /// Generates a puzzle as requested by `--difficulty` or `--clues`.
    func generatePuzzle(using rng: inout some RandomNumberGenerator) -> Sudoku {
        let generator = SudokuGenerator()
        if let difficulty {
            return generator.generate(difficulty, using: &rng)
        }
        return generator.generate(minimumClues: clues ?? Self.defaultMinimumClues, using: &rng)
    }

    /// Parses a puzzle typed in by the user.
    ///
    /// Invalid input and puzzles with several solutions exit with status 64,
    /// like other usage errors; a puzzle without a solution exits with status 1.
    func parseUserPuzzle(_ cells: String) throws -> Sudoku {
        do {
            return try SudokuParser.parsePlayable(cells)
        } catch SudokuError.noSolution {
            print("No solution found.")
            throw ExitCode.failure
        } catch let error as SudokuError {
            throw ValidationError(error.localizedDescription)
        }
    }

    func run() throws {
        if list {
            for (i, sample) in SudokuPuzzle.all.enumerated() {
                print("\(i + 1). \(sample.name)")
            }
            return
        }

        let puzzle: Sudoku
        if generate {
            if let seed {
                var rng = SplitMix64(seed: seed)
                puzzle = generatePuzzle(using: &rng)
            } else {
                var rng = SystemRandomNumberGenerator()
                puzzle = generatePuzzle(using: &rng)
            }
            let clueCount = puzzle.grid.filter { $0 != Sudoku.empty }.count
            let level = difficulty?.rawValue ?? "easy"
            print("Generated \(level) puzzle with \(clueCount) clues:")
            print(SudokuParser.string(for: puzzle) + "\n")
        } else if let cells {
            puzzle = try parseUserPuzzle(cells)
        } else {
            let sample = sample.map { SudokuPuzzle.all[$0 - 1] } ?? SudokuPuzzle.all.randomElement()!
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
