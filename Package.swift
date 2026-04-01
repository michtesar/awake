// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AwakeCore",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "AwakeCore",
            targets: ["AwakeCore"]
        )
    ],
    targets: [
        .target(
            name: "AwakeCore",
            path: "awake/CoreLogic"
        ),
        .testTarget(
            name: "AwakeCoreTests",
            dependencies: ["AwakeCore"],
            path: "Tests/AwakeCoreTests"
        )
    ]
)
