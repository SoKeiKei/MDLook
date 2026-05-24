// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MDLook",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MarkdownPreviewCore",
            targets: ["MarkdownPreviewCore"]
        ),
        .executable(
            name: "MarkdownPreviewCoreTestRunner",
            targets: ["MarkdownPreviewCoreTestRunner"]
        )
    ],
    targets: [
        .target(
            name: "MarkdownPreviewCore",
            path: "Sources/MarkdownPreviewCore"
        ),
        .executableTarget(
            name: "MarkdownPreviewCoreTestRunner",
            dependencies: ["MarkdownPreviewCore"],
            path: "Tests/MarkdownPreviewCoreTestRunner"
        )
    ]
)
