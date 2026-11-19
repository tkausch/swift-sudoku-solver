/// How many clues a generated puzzle keeps. All generated puzzles can be solved
/// with naked singles; fewer clues means more cells to work out.
public enum Difficulty: String, CaseIterable, Identifiable, Sendable {
    case easy, medium, hard

    public var id: Self { self }
    public var title: String { rawValue.capitalized }

    public var minimumClues: Int {
        switch self {
        case .easy: 42
        case .medium: 34
        case .hard: 17   // as few as the generator can reach, typically 27–32
        }
    }
}
