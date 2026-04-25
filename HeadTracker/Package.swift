// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HeadTracker",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .executableTarget(
            name: "HeadTracker",
            dependencies: [],
            path: "Sources/HeadTracker"
        )
    ]
)
