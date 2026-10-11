// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "quicklinks",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "quicklinks", path: "Sources/quicklinks"),
        .testTarget(name: "quicklinksTests", dependencies: ["quicklinks"], path: "Tests/quicklinksTests")
    ]
)
