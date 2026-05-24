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
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.8.0")
    ],
    targets: [
        .target(
            name: "MarkdownPreviewCore",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ],
            path: "Sources/MarkdownPreviewCore"
        ),
        .executableTarget(
            name: "MarkdownPreviewCoreTestRunner",
            dependencies: ["MarkdownPreviewCore"],
            path: "Tests/MarkdownPreviewCoreTestRunner"
        )
    ]
)
