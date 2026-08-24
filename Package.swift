// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KillerSudoku",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "KillerSudokuCore"),
        .executableTarget(
            name: "KillerSudoku",
            dependencies: ["KillerSudokuCore"]
        ),
        .testTarget(
            name: "KillerSudokuCoreTests",
            dependencies: ["KillerSudokuCore"]
        ),
    ]
)
