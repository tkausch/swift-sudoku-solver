# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```sh
swift build                                   # build all targets
swift test                                    # run all tests (Swift Testing, not XCTest)
swift test --filter SolverTests               # one suite
swift test --filter SolverTests/solvesHardPuzzle   # one test
swift run sudoku --help                       # CLI; also --list, --sample <n>, --generate [--difficulty d | --clues n] [--seed n], or a puzzle string
swift run -c release sudoku --sample 5        # use release for timing numbers (README benchmarks are release builds)
```

CI (`.github/workflows/tests.yml`) runs only `swift build` and `swift test` on Linux in the `swift:6.0` container. Code must compile with Swift 6.0 (strict concurrency) and on Linux — avoid newer language features and Apple-only APIs in `SudokuKit` and `SudokuCLI`.

## Architecture

SwiftPM package (`Package.swift`) with three products:

- **SudokuKit** (library, no dependencies) — the core.
- **SudokuUI** (library) — SwiftUI views on top of `SudokuKit`.
- **sudoku** (executable, target `SudokuCLI`) — Swift Argument Parser front end in `SudokuCommand.swift`.

### SudokuKit layering

- `SolvableSudoku` is the protocol solvers depend on: `static size`, `subscript(row:col:)` get/set, `candidates(atRow:col:)`. Empty is `0`. Solvers are generic over it (`DFSSolver<Puzzle>`, `NakedSingleSolver<Puzzle>`) so they work on other grid sizes; tests use this for 4×4 variants. Don't hard-code 9 or 3 in solver code.
- `SudokuSolver<Puzzle>` is the algorithm protocol (`solve(_:) -> Puzzle?`, non-mutating input).
- `Sudoku` is the concrete 9×9 type. `init?(grid:)` rejects wrong length, out-of-range values and conflicts, so every instance starts valid; the subscript setter does **not** re-validate (solvers and `SudokuGame` rely on that). Use `Sudoku.size`, `boxSize`, `gridSize`, `empty` instead of literals.
- `SudokuParser` converts text ↔ `Sudoku` (81 chars, `0`/`.` empty, whitespace ignored) and throws `SudokuError`; `parsePlayable` additionally requires a unique solution (used by the CLI for user input).
- `DFSSolver` backtracks on the most-constrained cell (fewest candidates); also `solveCountingPositions` and `countSolutions(_:limit:)`.
- `NakedSingleSolver` fills forced cells only and reports `.solved` / `.stuck` / `.contradiction`.
- `SudokuGenerator` fills a random grid, then removes centrally symmetric cell pairs while `NakedSingleSolver` can still solve it — this is what guarantees a unique solution. `SudokuDifficulty` maps to a minimum clue count. Overloads take `using: inout RandomNumberGenerator` for reproducible output; use the public seeded `SplitMix64` (CLI `--seed`, tests).
- `SudokuGame` is the play-state value type: immutable `puzzle` (givens), `board` (givens + entries), undo history, and a lazily cached `solution` (via `DFSSolver`) used by `hint(forRow:col:)`. Entries are not rule-checked. `==` compares only `puzzle` and `board`; `id` (Identifiable) is the puzzle string, so it identifies the game across entries.
- `SudokuPuzzle.all` holds the built-in named puzzles used by the CLI and tests.

### SudokuUI

Every file is wrapped in `#if canImport(SwiftUI)` (Previews also `&& DEBUG`) so the target builds as an empty module on Linux — keep that guard on any new file. `SudokuBoardView` takes a `SudokuGame` value plus a `Binding<SudokuCell?>` selection and only displays; `SudokuNumberPad` takes a `Binding<SudokuGame>` and mutates it. `SudokuUITests` are guarded by `canImport(SwiftUI) && canImport(AppKit)` and render views with `ImageRenderer` to PNGs in the temp directory, so they only run on macOS.

## Conventions

- Public API has full DocC comments (`- Parameters:`, `- Returns:`, `- Precondition:`, double-backtick symbol links); match that style for new or changed APIs, and keep the README's type tables and examples in sync.
- Renamed public API keeps a `@available(*, deprecated, renamed:)` alias (e.g. `ClassicPuzzles`).
- CLI exit codes: 64 for invalid input or a puzzle with several solutions (`SudokuError` is rethrown as `ValidationError`), 1 for an unsolvable puzzle. `SudokuCLITests` tests the command via `SudokuCommand.parse([...])`.
