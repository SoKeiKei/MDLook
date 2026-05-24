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
    assert(result.html.contains(#"<code class="language-swift">"#), "missing code block language")
    assert(result.html.contains("print(&quot;hello&quot;)"), "missing code block content")
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

private func rendersGFMTableAlignmentAndOrderedListStart() throws {
    let markdown = """
    | Left | Center | Right |
    | :--- | :---: | ---: |
    | A | B | C |

    3. third
    4. fourth
    """

    let result = try MarkdownRenderer().render(
        RenderRequest(markdown: markdown, sourceFileURL: sourceURL, maxInputBytes: 2_000_000)
    )

    assert(result.html.contains(#"<th align="left">Left</th>"#), "missing left table alignment")
    assert(result.html.contains(#"<th align="center">Center</th>"#), "missing center table alignment")
    assert(result.html.contains(#"<th align="right">Right</th>"#), "missing right table alignment")
    assert(result.html.contains(#"<td align="right">C</td>"#), "missing right table cell alignment")
    assert(result.html.contains(#"<ol start="3">"#), "missing ordered list start attribute")
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

    assert(result.html.contains("<li><p>parent</p><ul>") || result.html.contains("<li>parent<ul>"), "missing nested unordered list")
    assert(result.html.contains("child with <code>code</code>"), "missing nested list inline code")
    assert(result.html.contains("<del>removed</del> text"), "missing nested list strikethrough")
    assert(result.html.contains("<li><p>first</p><ol>") || result.html.contains("<li>first<ol>"), "missing nested ordered list")
    assert(result.html.contains("nested ordered"), "missing nested ordered content")
    assert(result.html.contains(##"<a href="#">unsafe</a>"##), "dangerous link was not neutralized")
    assert(!result.html.localizedCaseInsensitiveContains("javascript:alert"), "dangerous link leaked")
}

private func rendersAdditionalCommonMarkdown() throws {
    let markdown = """
    Setext Title
    ============

    Setext Subtitle
    ---------------

    ---

    ~~~json
    {"ok": true}
    ~~~

    Visit https://example.com/docs and contact mailto:hello@example.com.

    Escaped \\*stars\\* and \\[brackets\\].
    """

    let result = try MarkdownRenderer().render(
        RenderRequest(markdown: markdown, sourceFileURL: sourceURL, maxInputBytes: 2_000_000)
    )

    assert(result.html.contains("<h1>Setext Title</h1>"), "missing setext h1")
    assert(result.html.contains("<h2>Setext Subtitle</h2>"), "missing setext h2")
    assert(result.html.contains("<hr>"), "missing horizontal rule")
    assert(result.html.contains(#"<code class="language-json">"#), "missing tilde fenced code block language")
    assert(result.html.contains("{&quot;ok&quot;: true}"), "missing tilde fenced code block content")
    assert(result.html.contains(#"<a href="https://example.com/docs">https://example.com/docs</a>"#), "missing automatic URL link")
    assert(result.html.contains(#"<a href="mailto:hello@example.com">mailto:hello@example.com</a>"#), "missing automatic mailto link")
    assert(result.html.contains("Escaped *stars* and [brackets]."), "escaped punctuation did not render literally")
}

private func rendersHighlightAndCallouts() throws {
    let markdown = """
    ==highlighted text==

    > [!INFO]
    > Useful information.

    > [!WARNING]
    > Careful now.
    """

    let result = try MarkdownRenderer().render(
        RenderRequest(markdown: markdown, sourceFileURL: sourceURL, maxInputBytes: 2_000_000)
    )

    assert(result.html.contains("<mark>highlighted text</mark>"), "missing highlight mark")
    assert(result.html.contains(#"<blockquote class="callout callout-info">"#), "missing info callout")
    assert(result.html.contains(#"<strong>Info</strong>"#), "missing info callout title")
    assert(result.html.contains(#"<blockquote class="callout callout-warning">"#), "missing warning callout")
    assert(result.html.contains(#"<strong>Warning</strong>"#), "missing warning callout title")
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

private func rendersSampleDocuments() throws {
    let sampleNames = ["basic", "images", "security", "large", "regression"]
    let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

    for sampleName in sampleNames {
        let sampleURL = rootURL
            .appendingPathComponent("Samples", isDirectory: true)
            .appendingPathComponent("\(sampleName).md")
        let markdown = try String(contentsOf: sampleURL, encoding: .utf8)
        let result = try MarkdownRenderer().render(
            RenderRequest(markdown: markdown, sourceFileURL: sampleURL, maxInputBytes: 2_000_000)
        )

        assert(result.html.contains("<!doctype html>"), "sample \(sampleName) did not render as a document")
    }

    let realWorldURL = rootURL.appendingPathComponent("测试文档.md")
    if FileManager.default.fileExists(atPath: realWorldURL.path) {
        let markdown = try String(contentsOf: realWorldURL, encoding: .utf8)
        let result = try MarkdownRenderer().render(
            RenderRequest(markdown: markdown, sourceFileURL: realWorldURL, maxInputBytes: 2_000_000)
        )

        assert(result.html.contains("<!doctype html>"), "测试文档.md did not render as a document")
        assert(result.html.contains("<mark>高亮</mark>"), "测试文档.md highlight did not render")
        assert(result.html.contains(#"<blockquote class="callout callout-info">"#), "测试文档.md info callout did not render")
        assert(result.html.contains(#"<blockquote class="callout callout-warning">"#), "测试文档.md warning callout did not render")
    }
}

do {
    try rendersCommonMarkdownBlocks()
    try rendersTablesAndTaskLists()
    try rendersGFMTableAlignmentAndOrderedListStart()
    try rendersNestedListsAndInlineCode()
    try rendersAdditionalCommonMarkdown()
    try rendersHighlightAndCallouts()
    try resolvesLocalImagesAndReportsMissingImages()
    try resolvesImagesWithChineseNamesAndSpaces()
    try blocksRemoteImagesAndRemovesRawHTML()
    validatesEmptyAndOversizedInput()
    try rendersSampleDocuments()
    print("MarkdownPreviewCoreTestRunner: all checks passed")
} catch {
    fputs("FAIL: unexpected error \(error)\n", stderr)
    exit(1)
}
