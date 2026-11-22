/// A small, fast random number generator that produces the same numbers for the same seed.
///
/// Pass it to ``SudokuGenerator`` to get reproducible puzzles:
///
/// ```swift
/// var rng = SplitMix64(seed: 42)
/// let puzzle = SudokuGenerator().generate(.medium, using: &rng)   // the same puzzle every time
/// ```
///
/// It implements the SplitMix64 algorithm. It is not suitable for cryptography.
public struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64

    /// Creates a generator.
    ///
    /// - Parameter seed: The starting state. Equal seeds give equal sequences.
    public init(seed: UInt64) {
        state = seed
    }

    /// Returns the next number in the sequence.
    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
