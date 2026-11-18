<p align="center">
  <img src="assets/banner.svg" alt="Swift Sudoku Solver: a 9×9 grid mid-solve next to a depth-first search tree" width="100%">
</p>

# Swift Sudoku Solver

[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0%2B-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-macOS%2013%2B%20%7C%20iOS%2016%2B-lightgrey)](#requirements)
[![Swift Package Manager](https://img.shields.io/badge/SwiftPM-compatible-brightgreen)](https://swift.org/package-manager/)
[![Latest tag](https://img.shields.io/github/v/tag/tkausch/swift-sudoku-solver?sort=semver)](https://github.com/tkausch/swift-sudoku-solver/tags)
[![Last commit](https://img.shields.io/github/last-commit/tkausch/swift-sudoku-solver)](https://github.com/tkausch/swift-sudoku-solver/commits/main)

A 9×9 Sudoku library and command-line tool in Swift. Puzzles are solved with
depth-first search (backtracking) that always branches on the most constrained cell.

## Requirements

- Swift 6.0 or later
- macOS 13+ / iOS 16+ (the library has no other dependencies)

The command-line tool uses [Swift Argument Parser](https://github.com/apple/swift-argument-parser).

## Command-line tool

```sh
swift build -c release
.build/release/sudoku            # solve a random built-in puzzle
```

```
USAGE: sudoku [<puzzle>] [--list] [--sample <n>]

ARGUMENTS:
  <puzzle>                81 cells row by row: digits 1-9, 0 or . for empty.

OPTIONS:
  -l, --list              List the built-in puzzles and exit.
  -s, --sample <n>        Solve built-in puzzle number <n> (see --list) instead
                          of a random one.
  -h, --help              Show help information.
```

Examples:

```sh
.build/release/sudoku --list
.build/release/sudoku --sample 12
.build/release/sudoku 53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79
```

Output:

```
5 3 . | . 7 . | . . .
6 . . | 1 9 5 | . . .
. 9 8 | . . . | . 6 .
------+-------+------
...

Board positions visited: 52

Solved in 0.3 ms:

5 3 4 | 6 7 8 | 9 1 2
6 7 2 | 1 9 5 | 3 4 8
1 9 8 | 3 4 2 | 5 6 7
------+-------+------
...
```

Invalid input exits with status 64 and a message; a puzzle without a solution exits with status 1.

## Library

Add the package as a dependency and import `SudokuSolver`:

```swift
import SudokuSolver

let cells = "53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79"
    .map { $0 == "." ? 0 : $0.wholeNumberValue! }

guard let puzzle = Sudoku(board: cells) else { fatalError("invalid puzzle") }

let solver = DFSSolver<Sudoku>()
if let solution = solver.solve(puzzle) {
    print(solution)
}

// With statistics:
let (solution, positions) = solver.solveCountingPositions(puzzle)
```

### Types

| Type | Purpose |
|---|---|
| `Sudoku` | A 9×9 grid stored as 81 values in row-major order (`0` = empty). Creation fails for wrong cell counts, values outside `0...9`, or duplicate digits. Provides `subscript(row:col:)`, `isValidSudoku()`, `isComplete`, `candidates(atRow:col:)`. |
| `SolvableSudoku` | Protocol with what a solver needs: `size`, a read/write subscript and `candidates(atRow:col:)`. `Sudoku` conforms. |
| `SudokuSolver<Puzzle>` | Protocol for solving algorithms: `solve(_:) -> Puzzle?`. Usable as `some SudokuSolver<Sudoku>` or `any SudokuSolver<Sudoku>`. |
| `DFSSolver<Puzzle>` | Depth-first search solver conforming to `SudokuSolver`. |

### How `DFSSolver` works

1. Find the empty cell with the fewest candidates (stop early at 0 or 1).
2. If there is no empty cell, the puzzle is solved.
3. Otherwise try each candidate digit in that cell and recurse.
4. If no candidate leads to a solution, clear the cell and backtrack.

Choosing the most constrained cell finds dead ends early and makes cells with
a single candidate get filled without guessing.

A *board position* is one grid state examined by the search: the start plus
every grid reached by placing a digit, including abandoned ones. A puzzle with
`n` empty cells needs at least `n + 1` positions; anything above that is backtracking.

## Results

All built-in puzzles have exactly one solution. Release build, median of 5 runs,
Apple M3 Pro, macOS 26.7, Swift 6.4.

| # | Puzzle | Clues | Board positions | Time (ms) |
|--:|---|--:|--:|--:|
| 1 | Wikipedia example (easy) | 30 | 52 | 0.3 |
| 2 | Project Euler #96, grid 01 (easy) | 32 | 50 | 0.3 |
| 3 | Project Euler #96, grid 02 (medium) | 30 | 62 | 0.4 |
| 4 | Peter Norvig, grid 2 (hard) | 17 | 719 | 8.8 |
| 5 | Arto Inkala, "world's hardest" (very hard) | 21 | 13,811 | 129.9 |
| 6 | Easter Monster (very hard) | 21 | 6,274 | 40.9 |
| 7 | Golden Nugget (very hard) | 21 | 14,713 | 103.2 |
| 8 | AI Escargot, Arto Inkala 2006 (very hard) | 23 | 220 | 1.6 |
| 9 | Peter Norvig, hardest.txt #1 (very hard) | 22 | 4,876 | 37.2 |
| 10 | Peter Norvig, hardest.txt #2 (very hard) | 23 | 654 | 4.8 |
| 11 | Peter Norvig, hardest.txt #4 (very hard) | 24 | 1,517 | 13.0 |
| 12 | Wikipedia, designed against brute force (very hard) | 17 | 58,234 | 511.8 |

Observations:

- The easy puzzles never backtrack: puzzle 1 has 51 empty cells and needs exactly 52 positions.
- Difficulty for humans and for the solver differ: AI Escargot is famously hard to
  solve by hand but needs only 220 positions.
- Puzzle 12 was built to defeat simple backtracking and is the slowest by far.
- Each position costs roughly 7–9 µs, mostly spent allocating arrays and a `Set`
  in `candidates(atRow:col:)`. Bitmask-based candidate tracking would make each
  position much cheaper.

Positions are deterministic; times vary between runs and machines. To reproduce:

```sh
swift build -c release
for i in $(seq 1 12); do .build/release/sudoku -s $i | grep -E "positions|Solved"; done
```

## Development

```sh
swift build
swift test
```

```
assets/
  banner.svg             README header image
Sources/
  SudokuSolver/          library
    Sudoku.swift           grid type, validation, candidates
    SolvableSudoku.swift   protocol used by solvers
    SudokuSolver.swift     solver protocol
    DFSSolver.swift        depth-first search solver
  SudokuCLI/             command-line tool
    SudokuCommand.swift    argument parsing and output
    SamplePuzzles.swift    built-in puzzles
Tests/
  SudokuSolverTests/
    SudokuTests.swift      grid tests
    SolverTests.swift      solver tests
```
