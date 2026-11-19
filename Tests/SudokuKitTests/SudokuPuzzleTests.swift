import Testing
@testable import SudokuKit

struct SudokuPuzzleTests {
    @Test func namesAreUnique() {
        let names = SudokuPuzzle.all.map(\.name)
        #expect(Set(names).count == names.count)
    }

    @Test(arguments: SudokuPuzzle.all.map(\.name))
    func parses(name: String) throws {
        let puzzle = try #require(SudokuPuzzle.all.first { $0.name == name })
        _ = try SudokuParser.parse(puzzle.cells)
    }
}
