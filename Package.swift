// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SudokuKit",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "SudokuKit", targets: ["SudokuKit"]),
        .library(name: "SudokuUI", targets: ["SudokuUI"]),
        .executable(name: "sudoku", targets: ["SudokuCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .target(name: "SudokuKit"),
        // SwiftUI views. Every file is wrapped in `#if canImport(SwiftUI)`,
        // so on Linux this target builds as an empty module.
        .target(
            name: "SudokuUI",
            dependencies: ["SudokuKit"]
        ),
        .executableTarget(
            name: "SudokuCLI",
            dependencies: [
                "SudokuKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "SudokuKitTests",
            dependencies: ["SudokuKit"]
        ),
        .testTarget(
            name: "SudokuCLITests",
            dependencies: ["SudokuCLI", "SudokuKit"]
        ),
        .testTarget(
            name: "SudokuUITests",
            dependencies: ["SudokuUI", "SudokuKit"]
        ),
    ]
)
