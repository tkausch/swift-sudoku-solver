#if canImport(SwiftUI)
import SwiftUI
import SudokuKit

/// A 9×9 Sudoku board that shows a ``SudokuKit/SudokuGame`` and lets the player select cells.
///
/// The board only displays the game. Pair it with ``SudokuNumberPad``, or your own controls,
/// to enter digits:
///
/// ```swift
/// struct GameScreen: View {
///     @State private var game = SudokuGame(puzzle: SudokuGenerator().generate(.medium))
///     @State private var selection: SudokuCell?
///
///     var body: some View {
///         VStack {
///             SudokuBoardView(game: game, selection: $selection)
///             SudokuNumberPad(game: $game, selection: selection)
///         }
///         .padding()
///     }
/// }
/// ```
///
/// - Givens are bold; the player's entries use the tint colour.
/// - Digits that clash with another cell in their row, column or box are red.
/// - The selected cell is highlighted, along with its row, column and box, and every cell
///   holding the same digit.
///
/// The board is square and fills the largest square that fits. Colours follow the
/// environment's tint and adapt to dark mode.
public struct SudokuBoardView: View {
    private let game: SudokuGame
    @Binding private var selection: SudokuCell?

    /// Creates a board.
    ///
    /// - Parameters:
    ///   - game: The game to show.
    ///   - selection: The selected cell. Tapping a cell selects it; tapping it again clears the selection.
    public init(game: SudokuGame, selection: Binding<SudokuCell?>) {
        self.game = game
        self._selection = selection
    }

    public var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let cellSide = side / CGFloat(Sudoku.size)

            ZStack {
                VStack(spacing: 0) {
                    ForEach(0..<Sudoku.size, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<Sudoku.size, id: \.self) { col in
                                cell(SudokuCell(row: row, col: col), side: cellSide)
                            }
                        }
                    }
                }
                GridLines(divisions: Sudoku.size)
                    .stroke(Color.secondary.opacity(0.5), lineWidth: 0.5)
                GridLines(divisions: Sudoku.boxSize)
                    .stroke(Color.primary, lineWidth: 2)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Cells

    private func cell(_ cell: SudokuCell, side: CGFloat) -> some View {
        let digit = game.board[cell.row, cell.col]
        let isGiven = game.isGiven(atRow: cell.row, col: cell.col)

        return Button {
            selection = (selection == cell) ? nil : cell
        } label: {
            ZStack {
                Rectangle().fill(background(for: cell, digit: digit))
                if digit != Sudoku.empty {
                    Text(String(digit))
                        .font(.system(size: side * 0.6, weight: isGiven ? .bold : .regular, design: .rounded))
                        .foregroundStyle(foreground(for: cell, isGiven: isGiven))
                }
            }
            .frame(width: side, height: side)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: cell, digit: digit, isGiven: isGiven))
        .accessibilityAddTraits(selection == cell ? .isSelected : [])
    }

    private func foreground(for cell: SudokuCell, isGiven: Bool) -> AnyShapeStyle {
        if game.board.hasConflict(atRow: cell.row, col: cell.col) { return AnyShapeStyle(Color.red) }
        return isGiven ? AnyShapeStyle(Color.primary) : AnyShapeStyle(.tint)
    }

    private func background(for cell: SudokuCell, digit: Int) -> AnyShapeStyle {
        guard let selection else { return AnyShapeStyle(Color.clear) }
        if cell == selection { return AnyShapeStyle(.tint.opacity(0.35)) }

        let selectedDigit = game.board[selection.row, selection.col]
        if digit != Sudoku.empty && digit == selectedDigit { return AnyShapeStyle(.tint.opacity(0.2)) }
        if cell.sharesUnit(with: selection, boxSize: Sudoku.boxSize) {
            return AnyShapeStyle(Color.secondary.opacity(0.12))
        }
        return AnyShapeStyle(Color.clear)
    }

    private func accessibilityLabel(for cell: SudokuCell, digit: Int, isGiven: Bool) -> String {
        let position = "Row \(cell.row + 1), column \(cell.col + 1)"
        guard digit != Sudoku.empty else { return "\(position), empty" }
        var label = "\(position), \(digit)"
        if isGiven { label += ", given" }
        if game.board.hasConflict(atRow: cell.row, col: cell.col) { label += ", conflict" }
        return label
    }
}

/// Evenly spaced horizontal and vertical lines, including the outer border.
private struct GridLines: Shape {
    let divisions: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for i in 0...divisions {
            let fraction = CGFloat(i) / CGFloat(divisions)
            let x = rect.minX + rect.width * fraction
            let y = rect.minY + rect.height * fraction
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        return path
    }
}

#endif
