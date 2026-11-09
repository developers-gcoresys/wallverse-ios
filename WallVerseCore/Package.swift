// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WallVerseCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "WallVerseCore", targets: ["WallVerseCore"])
    ],
    targets: [
        .target(name: "WallVerseCore"),
        .executableTarget(name: "CoreChecks", dependencies: ["WallVerseCore"], path: "Checks"),
        .testTarget(name: "WallVerseCoreTests", dependencies: ["WallVerseCore"])
    ]
)
