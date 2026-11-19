// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SudokuKit",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "SudokuKit", targets: ["SudokuKit"]),
        .executable(name: "sudoku", targets: ["SudokuCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .target(name: "SudokuKit"),
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
    ]
)
