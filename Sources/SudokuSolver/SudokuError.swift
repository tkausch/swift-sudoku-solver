import Foundation

/// Why a puzzle typed in by the player can't be played.
public enum SudokuError: LocalizedError, Equatable {
    case wrongLength(Int)
    case invalidCharacter(Character)
    case conflictingDigits
    case noSolution
    case multipleSolutions

    public var errorDescription: String? {
        switch self {
        case .wrongLength(let n): "A puzzle needs 81 cells, but this one has \(n)."
        case .invalidCharacter(let c): "\u{201C}\(c)\u{201D} isn't allowed. Use digits 1–9, and 0 or . for empty cells."
        case .conflictingDigits: "The same digit appears twice in a row, column or box."
        case .noSolution: "This puzzle has no solution."
        case .multipleSolutions: "This puzzle has more than one solution."
        }
    }
}
