// swift-tools-version: 6.0
import PackageDescription

// The app is here to be *reviewed*, not built in CI — see README.md.
let package = Package(
    name: "PlaygroundApp",
    platforms: [.iOS(.v18), .macOS(.v15)],
    targets: [
        .target(name: "PlaygroundApp")
    ]
)
