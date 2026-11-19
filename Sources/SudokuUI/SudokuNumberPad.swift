#if canImport(SwiftUI)
import SwiftUI
import SudokuKit

/// Buttons for entering digits into the selected cell of a ``SudokuKit/SudokuGame``,
/// plus Erase and Undo.
///
/// Digits and Erase are disabled while no cell is selected or the selected cell is a given.
/// Undo is disabled when there is nothing to undo. See ``SudokuBoardView`` for a full example.
public struct SudokuNumberPad: View {
    @Binding private var game: SudokuGame
    private let selection: SudokuCell?

    /// Creates a number pad.
    ///
    /// - Parameters:
    ///   - game: The game to change.
    ///   - selection: The cell that digits are entered into.
    public init(game: Binding<SudokuGame>, selection: SudokuCell?) {
        self._game = game
        self.selection = selection
    }

    public var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(1...Sudoku.size, id: \.self) { digit in
                    Button {
                        enter(digit)
                    } label: {
                        Text(String(digit))
                            .font(.system(.title2, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .accessibilityLabel("Enter \(digit)")
                }
            }
            .disabled(!canEdit)

            HStack(spacing: 6) {
                Button {
                    enter(Sudoku.empty)
                } label: {
                    Label("Erase", systemImage: "delete.left")
                        .frame(maxWidth: .infinity, minHeight: 28)
                }
                .disabled(!canEdit)

                Button {
                    game.undo()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .frame(maxWidth: .infinity, minHeight: 28)
                }
                .disabled(!game.canUndo)
            }
        }
        .buttonStyle(.bordered)
    }

    /// Whether the selected cell can be changed.
    private var canEdit: Bool {
        guard let selection else { return false }
        return !game.isGiven(atRow: selection.row, col: selection.col)
    }

    private func enter(_ digit: Int) {
        guard let selection else { return }
        game.set(digit, atRow: selection.row, col: selection.col)
    }
}

#endif
