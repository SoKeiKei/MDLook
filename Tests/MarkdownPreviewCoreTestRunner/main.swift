import Foundation
import MarkdownPreviewCore

private let sourceURL = URL(fileURLWithPath: "/tmp/markdown-preview/readme.md")

@discardableResult
private func assert(_ condition: @autoclosure () -> Bool, _ message: String) -> Bool {
    if !condition() {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
    return true
}

private func assertThrows(_ expected: PreviewRenderError, _ operation: () throws -> Void) {
    do {
        try operation()
        fputs("FAIL: expected \(expected) to be thrown\n", stderr)
        exit(1)
    } catch let error as PreviewRenderError {
        assert(error == expected, "expected \(expected), got \(error)")
    } catch {
        fputs("FAIL: expected \(expected), got \(error)\n", stderr)
        exit(1)
    }
}

private func rendersCommonMarkdownBlocks() throws {
    let markdown = """
    # 标题 Title

    A paragraph with **bold**, *italic*, and [link](https://example.com).

    > quoted text

    - first
    - second

    1. one
    2. two

    ```swift
    print("hello")
    ```
    """

    let result = try MarkdownRenderer().render(
        RenderRequest(markdown: markdown, sourceFileURL: sourceURL, maxInputBytes: 2_000_000)
    )

    assert(result.html.contains("<!doctype html>"), "missing doctype")
    assert(result.html.contains("<h1>标题 Title</h1>"), "missing h1")
    assert(result.html.contains("<strong>bold</strong>"), "missing bold")
    assert(result.html.contains("<em>italic</em>"), "missing italic")
    assert(result.html.contains(#"<a href="https://example.com">link</a>"#), "missing link")
    assert(result.html.contains("<blockquote>"), "missing blockquote")
    assert(result.html.contains("<ul>"), "missing unordered list")
    assert(result.html.contains("<ol>"), "missing ordered list")
    assert(result.html.contains(#"<code class="language-swift">print(&quot;hello&quot;)</code>"#), "missing code block")
    assert(result.warnings.isEmpty, "unexpected warnings: \(result.warnings)")
}

private func rendersTablesAndTaskLists() throws {
    let markdown = """
    | Name | Done |
    | --- | --- |
    | Docs | yes |

    - [x] shipped
    - [ ] polish
    """

    let result = try MarkdownRenderer().render(
        RenderRequest(markdown: markdown, sourceFileURL: sourceURL, maxInputBytes: 2_000_000)
    )

    assert(result.html.contains("<table>"), "missing table")
    assert(result.html.contains("<th>Name</th>"), "missing table header")
    assert(result.html.contains("<td>Docs</td>"), "missing table cell")
    assert(result.html.contains(#"<input type="checkbox" checked disabled>"#), "missing checked task")
    assert(result.html.contains(#"<input type="checkbox" disabled>"#), "missing unchecked task")
}

private func rendersNestedListsAndInlineCode() throws {
    let markdown = """
    - parent
      - child with `code`
      - ~~removed~~ text
    - second

    1. first
       1. nested ordered
       2. nested second
    2. next

    [unsafe](javascript:alert(1))
    """

    let result = try MarkdownRenderer().render(
        RenderRequest(markdown: markdown, sourceFileURL: sourceURL, maxInputBytes: 2_000_000)
    )

    assert(result.html.contains("<li>parent<ul><li>child with <code>code</code></li><li><del>removed</del> text</li></ul></li>"), "missing nested unordered list")
    assert(result.html.contains("<li>first<ol><li>nested ordered</li><li>nested second</li></ol></li>"), "missing nested ordered list")
    assert(result.html.contains(##"<a href="#">unsafe</a>"##), "dangerous link was not neutralized")
    assert(!result.html.localizedCaseInsensitiveContains("javascript:alert"), "dangerous link leaked")
}

private func resolvesLocalImagesAndReportsMissingImages() throws {
    let tempDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDirectory) }

    let imageURL = tempDirectory.appendingPathComponent("assets/picture.png")
    try FileManager.default.createDirectory(at: imageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data([0x89, 0x50, 0x4E, 0x47]).write(to: imageURL)

    let markdownURL = tempDirectory.appendingPathComponent("doc.md")
    let markdown = """
    ![Existing](assets/picture.png)
    ![Missing](assets/missing.png)
    """

    let result = try MarkdownRenderer().render(
        RenderRequest(markdown: markdown, sourceFileURL: markdownURL, maxInputBytes: 2_000_000)
    )

    assert(result.html.contains(#"<img src="file://"#), "missing local image")
    assert(result.html.contains(#"alt="Existing""#), "missing image alt")
    assert(result.html.contains("Missing image: assets/missing.png"), "missing placeholder")
    assert(result.warnings.contains(.missingLocalImage("assets/missing.png")), "missing local image warning")
}

private func resolvesImagesWithChineseNamesAndSpaces() throws {
    let tempDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDirectory) }

    let imageURL = tempDirectory.appendingPathComponent("图片 目录/示例 图片.png")
    try FileManager.default.createDirectory(at: imageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data([0x89, 0x50, 0x4E, 0x47]).write(to: imageURL)

    let markdownURL = tempDirectory.appendingPathComponent("doc.md")
    let markdown = #"![中文 Alt](图片 目录/示例 图片.png)"#

    let result = try MarkdownRenderer().render(
        RenderRequest(markdown: markdown, sourceFileURL: markdownURL, maxInputBytes: 2_000_000)
    )

    assert(result.html.contains(#"<img src="file://"#), "missing local image with spaces")
    assert(result.html.contains("%E5%9B%BE%E7%89%87%20%E7%9B%AE%E5%BD%95"), "image URL was not percent encoded")
    assert(result.html.contains(#"alt="中文 Alt""#), "missing Chinese alt text")
    assert(result.warnings.isEmpty, "unexpected warnings for local image with spaces: \(result.warnings)")
}

private func blocksRemoteImagesAndRemovesRawHTML() throws {
    let markdown = """
    ![Remote](https://example.com/image.png)

    <script>alert("x")</script>
    <img src=x onerror=alert(1)>
    """

    let result = try MarkdownRenderer().render(
        RenderRequest(markdown: markdown, sourceFileURL: sourceURL, maxInputBytes: 2_000_000)
    )

    assert(!result.html.contains("https://example.com/image.png"), "remote image URL leaked")
    assert(!result.html.localizedCaseInsensitiveContains("<script"), "script leaked")
    assert(!result.html.localizedCaseInsensitiveContains("onerror"), "event attribute leaked")
    assert(result.html.contains("Remote image blocked"), "missing blocked image placeholder")
    assert(result.warnings.contains(.blockedRemoteResource("https://example.com/image.png")), "missing blocked warning")
    assert(result.warnings.contains(.rawHTMLRemoved), "missing raw HTML warning")
}

private func validatesEmptyAndOversizedInput() {
    assertThrows(.emptyDocument) {
        _ = try MarkdownRenderer().render(
            RenderRequest(markdown: "   \n", sourceFileURL: sourceURL, maxInputBytes: 2_000_000)
        )
    }

    assertThrows(.fileTooLarge) {
        _ = try MarkdownRenderer().render(
            RenderRequest(markdown: String(repeating: "a", count: 16), sourceFileURL: sourceURL, maxInputBytes: 8)
        )
    }
}

do {
    try rendersCommonMarkdownBlocks()
    try rendersTablesAndTaskLists()
    try rendersNestedListsAndInlineCode()
    try resolvesLocalImagesAndReportsMissingImages()
    try resolvesImagesWithChineseNamesAndSpaces()
    try blocksRemoteImagesAndRemovesRawHTML()
    validatesEmptyAndOversizedInput()
    print("MarkdownPreviewCoreTestRunner: all checks passed")
} catch {
    fputs("FAIL: unexpected error \(error)\n", stderr)
    exit(1)
}
