// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SudokuSolver",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "SudokuSolver", targets: ["SudokuSolver"]),
        .executable(name: "sudoku", targets: ["SudokuCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .target(name: "SudokuSolver"),
        .executableTarget(
            name: "SudokuCLI",
            dependencies: [
                "SudokuSolver",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "SudokuSolverTests",
            dependencies: ["SudokuSolver"]
        ),
    ]
)
