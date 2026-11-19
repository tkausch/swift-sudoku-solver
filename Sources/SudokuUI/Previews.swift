#if canImport(SwiftUI) && DEBUG
import SwiftUI
import SudokuKit

/// Board and number pad wired together, for Xcode previews.
struct SudokuPreviewScreen: View {
    @State var game: SudokuGame
    @State var selection: SudokuCell?

    var body: some View {
        VStack(spacing: 16) {
            SudokuBoardView(game: game, selection: $selection)
            SudokuNumberPad(game: $game, selection: selection)
        }
        .padding()
    }

    /// The Wikipedia example puzzle with no entries.
    static var newGame: SudokuGame {
        SudokuGame(puzzle: try! SudokuParser.parse(SudokuPuzzle.all[0].cells))
    }
}

#Preview("Playing") {
    var game = SudokuPreviewScreen.newGame
    game.set(4, atRow: 0, col: 2)
    game.set(6, atRow: 0, col: 3)
    return SudokuPreviewScreen(game: game, selection: SudokuCell(row: 0, col: 3))
}

#Preview("Conflict") {
    var game = SudokuPreviewScreen.newGame
    game.set(5, atRow: 0, col: 2)   // 5 is already at (0, 0)
    return SudokuPreviewScreen(game: game, selection: SudokuCell(row: 0, col: 2))
}

#Preview("Solved") {
    var game = SudokuPreviewScreen.newGame
    let solution = DFSSolver().solve(game.puzzle)!
    for row in 0..<Sudoku.size {
        for col in 0..<Sudoku.size where !game.isGiven(atRow: row, col: col) {
            game.set(solution[row, col], atRow: row, col: col)
        }
    }
    return SudokuPreviewScreen(game: game, selection: nil)
}

#endif
