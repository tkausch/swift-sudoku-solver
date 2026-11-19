import Testing
@testable import SudokuKit

struct ClassicPuzzlesTests {
    @Test func namesAreUnique() {
        let names = ClassicPuzzles.all.map(\.name)
        #expect(Set(names).count == names.count)
    }

    @Test(arguments: ClassicPuzzles.all.map(\.name))
    func parses(name: String) throws {
        let puzzle = try #require(ClassicPuzzles.all.first { $0.name == name })
        _ = try SudokuParser.parse(puzzle.cells)
    }
}
