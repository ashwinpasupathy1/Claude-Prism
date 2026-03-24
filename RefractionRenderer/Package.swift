// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "RefractionRenderer",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "RefractionRenderer",
            targets: ["RefractionRenderer"]
        ),
    ],
    targets: [
        .target(
            name: "RefractionRenderer",
            path: "Sources/RefractionRenderer"
        ),
        .testTarget(
            name: "RefractionRendererTests",
            dependencies: ["RefractionRenderer"],
            path: "Tests/RefractionRendererTests"
        ),
    ]
)
