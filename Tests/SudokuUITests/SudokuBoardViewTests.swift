#if canImport(SwiftUI) && canImport(AppKit)
import AppKit
import Foundation
import SwiftUI
import Testing
import SudokuKit
@testable import SudokuUI

@MainActor
struct SudokuBoardViewTests {
    let puzzle = try! SudokuParser.parse(SudokuPuzzle.all[0].cells)

    /// Renders a view to a PNG in the temporary folder and returns its size.
    func render(_ view: some View, name: String) throws -> CGSize {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        let image = try #require(renderer.cgImage)
        let png = try #require(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).png")
        try png.write(to: url)
        return CGSize(width: image.width, height: image.height)
    }

    @Test func rendersBoardWithSelectionAndConflict() throws {
        var game = SudokuGame(puzzle: puzzle)
        game.set(4, atRow: 0, col: 2)   // correct entry
        game.set(5, atRow: 0, col: 3)   // conflicts with the 5 at (0, 0)
        let board = SudokuBoardView(game: game, selection: .constant(SudokuCell(row: 0, col: 2)))
            .frame(width: 360, height: 360)
            .padding()
            .background(Color.white)

        let size = try render(board, name: "SudokuBoardView")
        #expect(size.width >= 720 && size.height >= 720)
    }

    @Test func rendersNumberPad() throws {
        let pad = SudokuNumberPad(game: .constant(SudokuGame(puzzle: puzzle)), selection: SudokuCell(row: 0, col: 2))
            .frame(width: 360)
            .padding()
            .background(Color.white)

        let size = try render(pad, name: "SudokuNumberPad")
        #expect(size.width >= 720)
    }

    @Test func cellsShareUnits() {
        let cell = SudokuCell(row: 4, col: 4)
        #expect(cell.sharesUnit(with: SudokuCell(row: 4, col: 0)))   // row
        #expect(cell.sharesUnit(with: SudokuCell(row: 0, col: 4)))   // column
        #expect(cell.sharesUnit(with: SudokuCell(row: 3, col: 5)))   // box
        #expect(!cell.sharesUnit(with: SudokuCell(row: 0, col: 0)))
    }
}
#endif
