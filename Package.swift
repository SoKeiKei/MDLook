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
        ),
        .library(
            name: "MDLookAppSupport",
            targets: ["MDLookAppSupport"]
        ),
        .executable(
            name: "MDLookAppLocalizationTestRunner",
            targets: ["MDLookAppLocalizationTestRunner"]
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
        .target(
            name: "MDLookAppSupport",
            path: "Sources/MDLookAppSupport"
        ),
        .executableTarget(
            name: "MarkdownPreviewCoreTestRunner",
            dependencies: ["MarkdownPreviewCore"],
            path: "Tests/MarkdownPreviewCoreTestRunner"
        ),
        .executableTarget(
            name: "MDLookAppLocalizationTestRunner",
            dependencies: ["MDLookAppSupport"],
            path: "Tests/MDLookAppLocalizationTestRunner"
        )
    ]
)
