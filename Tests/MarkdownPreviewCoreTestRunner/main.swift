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
    assert(result.html.contains(#"<a class="link-external" href="https://example.com">link</a>"#), "missing external link")
    assert(result.html.contains("<blockquote>"), "missing blockquote")
    assert(result.html.contains("<ul>"), "missing unordered list")
    assert(result.html.contains("<ol>"), "missing ordered list")
    assert(result.html.contains(#"<code class="language-swift">"#), "missing code block language")
    assert(result.html.contains("print("), "missing code block content")
    assert(result.html.contains("&quot;hello&quot;"), "missing escaped string content")
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
    assert(result.html.contains(#"<li class="task-list-item"><label><input type="checkbox" checked disabled> <span>shipped</span></label></li>"#), "checked task checkbox and text should render on one line")
    assert(result.html.contains(#"<li class="task-list-item"><label><input type="checkbox" disabled> <span>polish</span></label></li>"#), "unchecked task checkbox and text should render on one line")
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
    assert(result.html.contains(##"<a class="link-unsafe" href="#" title="Blocked unsafe link">unsafe</a>"##), "dangerous link was not neutralized")
    assert(!result.html.localizedCaseInsensitiveContains("javascript:alert"), "dangerous link leaked")
}

private func rendersAdditionalCommonMarkdown() throws {
    let markdown = """
    ---
    title: Front Matter
    draft: false
    ---

    Setext Title
    ============

    Setext Subtitle
    ---------------

    ---

    ~~~json
    {"ok": true}
    ~~~

    Visit https://example.com/docs and contact mailto:hello@example.com.

    Term
    : Definition with ==highlight==

    Water is H~[2]~O and energy is E = mc^2^.

    Escaped \\*stars\\* and \\[brackets\\].
    """

    let result = try MarkdownRenderer().render(
        RenderRequest(markdown: markdown, sourceFileURL: sourceURL, maxInputBytes: 2_000_000)
    )

    assert(result.html.contains(#"<section class="front-matter">"#), "missing front matter wrapper")
    assert(result.html.contains(#"<summary>front matter</summary>"#), "missing front matter summary")
    assert(result.html.contains(#"<span class="tok-key">title</span>: Front Matter"#), "missing rendered front matter key")
    assert(result.html.contains(#"<span class="tok-key">draft</span>: <span class="tok-literal">false</span>"#), "missing rendered front matter literal")
    assert(result.html.contains("<h1>Setext Title</h1>"), "missing setext h1")
    assert(result.html.contains("<h2>Setext Subtitle</h2>"), "missing setext h2")
    assert(result.html.contains("<hr>"), "missing horizontal rule")
    assert(result.html.contains(#"<code class="language-json">"#), "missing tilde fenced code block language")
    assert(result.html.contains("&quot;ok&quot;"), "missing tilde fenced code block key")
    assert(result.html.contains("true"), "missing tilde fenced code block value")
    assert(result.html.contains(#"<a class="link-external" href="https://example.com/docs">https://example.com/docs</a>"#), "missing automatic URL link")
    assert(result.html.contains(#"<a class="link-mail" href="mailto:hello@example.com">mailto:hello@example.com</a>"#), "missing automatic mailto link")
    assert(result.html.contains("<dl><dt>Term</dt><dd>Definition with <mark>highlight</mark></dd></dl>"), "missing definition list")
    assert(result.html.contains("Water is H<sub>2</sub>O and energy is E = mc<sup>2</sup>."), "missing subscript or superscript")
    assert(result.html.contains("Escaped *stars* and [brackets]."), "escaped punctuation did not render literally")
}

private func rendersCodeBlockLanguageLabels() throws {
    let markdown = """
    ```swift
    // greeting
    let value = "hello"
    ```

    ```json
    {"ok": true, "count": 3}
    ```

    ```mermaid
    graph TD
      A --> B
    ```

    ```yaml
    name: MDLook
    enabled: true
    count: 3
    # note
    ```

    ```bash
    # install
    export APP_NAME="MDLook"
    if [ -n "$APP_NAME" ]; then
      echo "ready"
    fi
    ```
    """

    let result = try MarkdownRenderer().render(
        RenderRequest(markdown: markdown, sourceFileURL: sourceURL, maxInputBytes: 2_000_000)
    )

    assert(result.html.contains(#"<figure class="code-block">"#), "missing code block wrapper")
    assert(result.html.contains(#"<figcaption>swift</figcaption>"#), "missing swift language label")
    assert(result.html.contains(#"<figcaption>json</figcaption>"#), "missing json language label")
    assert(result.html.contains(#"<figcaption>mermaid</figcaption>"#), "missing mermaid language label")
    assert(result.html.contains(#"<code class="language-swift">"#), "missing swift language class")
    assert(result.html.contains(#"<code class="language-json">"#), "missing json language class")
    assert(result.html.contains(#"<code class="language-mermaid">"#), "missing mermaid language class")
    assert(result.html.contains(#"<code class="language-yaml">"#), "missing yaml language class")
    assert(result.html.contains(#"<code class="language-bash">"#), "missing bash language class")
    assert(result.html.contains(#"<figure class="code-block code-block-mermaid">"#), "missing mermaid-specific code block wrapper")
    assert(result.html.contains(#"<div class="code-note">Mermaid source preview. Diagram execution is disabled for safety.</div>"#), "missing mermaid safe preview note")
    assert(result.html.contains(#"<span class="tok-comment">// greeting</span>"#), "missing swift comment token")
    assert(result.html.contains(#"<span class="tok-keyword">let</span> value = <span class="tok-string">&quot;hello&quot;</span>"#), "missing swift highlighted tokens")
    assert(result.html.contains(#"<span class="tok-key">&quot;ok&quot;</span>: <span class="tok-literal">true</span>"#), "missing json key or literal token")
    assert(result.html.contains(#"<span class="tok-key">&quot;count&quot;</span>: <span class="tok-number">3</span>"#), "missing json key or number token")
    assert(result.html.contains(#"<span class="tok-key">name</span>: MDLook"#), "missing yaml key token")
    assert(result.html.contains(#"<span class="tok-key">enabled</span>: <span class="tok-literal">true</span>"#), "missing yaml literal token")
    assert(result.html.contains(#"<span class="tok-key">count</span>: <span class="tok-number">3</span>"#), "missing yaml number token")
    assert(result.html.contains(#"<span class="tok-comment"># note</span>"#), "missing yaml comment token")
    assert(result.html.contains(#"<span class="tok-keyword">export</span> APP_NAME=<span class="tok-string">&quot;MDLook&quot;</span>"#), "missing bash export or string token")
    assert(result.html.contains(#"<span class="tok-keyword">if</span> [ -n <span class="tok-string">&quot;$APP_NAME&quot;</span> ]; <span class="tok-keyword">then</span>"#), "missing bash conditional tokens")
    assert(result.html.contains(#"<span class="tok-keyword">fi</span>"#), "missing bash fi token")
}

private func rendersHighlightAndCallouts() throws {
    let markdown = """
    ==highlighted text==

    Inline math $E = mc^2$ stays safe.

    $$
    a^2 + b^2 = c^2
    $$

    > [!INFO]
    > Useful information.

    > [!WARNING]
    > Careful now.
    """

    let result = try MarkdownRenderer().render(
        RenderRequest(markdown: markdown, sourceFileURL: sourceURL, maxInputBytes: 2_000_000)
    )

    assert(result.html.contains("<mark>highlighted text</mark>"), "missing highlight mark")
    assert(result.html.contains(#"Inline math <span class="math-source">E = mc^2</span> stays safe."#), "missing inline math source preview")
    assert(result.html.contains(#"<figure class="math-block"><figcaption>math source preview</figcaption><pre><code>a^2 + b^2 = c^2</code></pre></figure>"#), "missing block math source preview")
    assert(result.html.contains(#"<blockquote class="callout callout-info">"#), "missing info callout")
    assert(result.html.contains(#"<strong>Info</strong>"#), "missing info callout title")
    assert(result.html.contains(#"<blockquote class="callout callout-warning">"#), "missing warning callout")
    assert(result.html.contains(#"<strong>Warning</strong>"#), "missing warning callout title")
}

private func rendersAdditionalGitHubCallouts() throws {
    let markdown = """
    > [!NOTE]
    > A note.

    > [!TIP]
    > A tip.

    > [!IMPORTANT]
    > Important context.

    > [!CAUTION]
    > Caution text.
    """

    let result = try MarkdownRenderer().render(
        RenderRequest(markdown: markdown, sourceFileURL: sourceURL, maxInputBytes: 2_000_000)
    )

    assert(result.html.contains(#"<blockquote class="callout callout-note">"#), "missing note callout")
    assert(result.html.contains(#"<strong>Note</strong>"#), "missing note callout title")
    assert(result.html.contains(#"<blockquote class="callout callout-tip">"#), "missing tip callout")
    assert(result.html.contains(#"<strong>Tip</strong>"#), "missing tip callout title")
    assert(result.html.contains(#"<blockquote class="callout callout-important">"#), "missing important callout")
    assert(result.html.contains(#"<strong>Important</strong>"#), "missing important callout title")
    assert(result.html.contains(#"<blockquote class="callout callout-caution">"#), "missing caution callout")
    assert(result.html.contains(#"<strong>Caution</strong>"#), "missing caution callout title")
}

private func rendersFootnotes() throws {
    let markdown = """
    Text with a footnote[^first] and repeated footnote[^first].
    Text with a multi-line footnote[^multi].

    [^first]: Footnote with **bold** text and `code`.

    [^multi]: First line.
        Continued with **bold** text.

        - Nested item
    """

    let result = try MarkdownRenderer().render(
        RenderRequest(markdown: markdown, sourceFileURL: sourceURL, maxInputBytes: 2_000_000)
    )

    assert(result.html.contains(##"<sup class="footnote-ref"><a href="#fn-first" id="fnref-first">1</a></sup>"##), "missing first footnote reference")
    assert(result.html.contains(##"<sup class="footnote-ref"><a href="#fn-first" id="fnref-first-2">1</a></sup>"##), "missing repeated footnote reference")
    assert(result.html.contains(#"<section class="footnotes">"#), "missing footnote section")
    assert(result.html.contains(#"<li id="fn-first">"#), "missing footnote definition")
    assert(result.html.contains("Footnote with <strong>bold</strong> text and <code>code</code>."), "missing rendered footnote content")
    assert(result.html.contains(##"<sup class="footnote-ref"><a href="#fn-multi" id="fnref-multi">2</a></sup>"##), "missing multi-line footnote reference")
    assert(result.html.contains(#"<li id="fn-multi">"#), "missing multi-line footnote definition")
    assert(result.html.contains("<p>First line.\nContinued with <strong>bold</strong> text.</p>"), "missing multi-line footnote continuation")
    assert(
        result.html.contains("<ul><li>Nested item</li></ul>")
            || result.html.contains("<ul><li><p>Nested item</p></li></ul>"),
        "missing multi-line footnote nested list"
    )
    assert(result.html.contains(##"<a href="#fnref-first" class="footnote-backref">↩</a>"##), "missing first footnote backref")
    assert(!result.html.contains("[^first]:"), "footnote definition leaked")
    assert(!result.html.contains("[^multi]:"), "multi-line footnote definition leaked")
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

    assert(result.html.contains(#"<figure class="image-figure image-local">"#), "missing local image figure")
    assert(result.html.contains(#"<img class="markdown-image" src="file://"#), "missing local image")
    assert(result.html.contains(#"loading="lazy" decoding="async""#), "missing image loading hints")
    assert(result.html.contains(#"alt="Existing""#), "missing image alt")
    assert(!result.html.contains(#"title=""#), "unexpected empty image title")
    assert(result.html.contains(#"<figcaption>Existing</figcaption>"#), "missing image alt caption")
    assert(result.html.contains(#"<span class="image-placeholder image-missing">Missing image: assets/missing.png</span>"#), "missing placeholder")
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
    let markdown = #"![中文 Alt](图片 目录/示例 图片.png "图片标题")"#

    let result = try MarkdownRenderer().render(
        RenderRequest(markdown: markdown, sourceFileURL: markdownURL, maxInputBytes: 2_000_000)
    )

    assert(result.html.contains(#"<figure class="image-figure image-local">"#), "missing local image figure with spaces")
    assert(result.html.contains(#"<img class="markdown-image" src="file://"#), "missing local image with spaces")
    assert(result.html.contains("%E5%9B%BE%E7%89%87%20%E7%9B%AE%E5%BD%95"), "image URL was not percent encoded")
    assert(result.html.contains(#"alt="中文 Alt""#), "missing Chinese alt text")
    assert(result.html.contains(#"title="图片标题""#), "missing Chinese image title")
    assert(result.html.contains(#"<figcaption>图片标题</figcaption>"#), "missing Chinese image caption")
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
    assert(result.html.contains(#"<span class="image-placeholder image-blocked">Remote image blocked</span>"#), "missing blocked image placeholder")
    assert(result.warnings.contains(.blockedRemoteResource("https://example.com/image.png")), "missing blocked warning")
    assert(result.warnings.contains(.rawHTMLRemoved), "missing raw HTML warning")
}

private func allowsRemoteImagesWhenRequested() throws {
    let markdown = """
    ![Remote](https://example.com/image.png "Remote title")
    """

    let result = try MarkdownRenderer().render(
        RenderRequest(
            markdown: markdown,
            sourceFileURL: sourceURL,
            maxInputBytes: 2_000_000,
            allowsRemoteImages: true
        )
    )

    assert(result.html.contains(#"<figure class="image-figure image-remote">"#), "missing remote image figure")
    assert(result.html.contains(#"<img class="markdown-image" src="https://example.com/image.png" alt="Remote" title="Remote title" loading="lazy" decoding="async" referrerpolicy="no-referrer">"#), "missing allowed remote image")
    assert(result.html.contains(#"<figcaption>Remote title</figcaption>"#), "missing remote image caption")
    assert(!result.html.contains("Remote image blocked"), "remote image should not be blocked when allowed")
    assert(result.warnings.isEmpty, "unexpected remote image warnings: \(result.warnings)")
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

private func rendersActionableErrorPages() {
    let tooLargeHTML = PreviewErrorPage.html(for: .fileTooLarge)
    assert(tooLargeHTML.contains(#"<section class="error-page">"#), "missing structured error page")
    assert(tooLargeHTML.contains("<h1>Preview unavailable</h1>"), "missing error title")
    assert(tooLargeHTML.contains("2 MB"), "missing file size limit guidance")
    assert(tooLargeHTML.contains("rendering source mode"), "missing source mode suggestion")

    let encodingHTML = PreviewErrorPage.html(for: .unsupportedEncoding)
    assert(encodingHTML.contains("not valid UTF-8"), "missing encoding explanation")
    assert(encodingHTML.contains("Save it as UTF-8"), "missing encoding recovery guidance")
}

private func rendersSampleDocuments() throws {
    let sampleNames = [
        "basic",
        "images",
        "security",
        "large",
        "regression",
        "real-world-readme",
        "changelog",
        "notes",
    ]
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

private func rendersImageSampleWithRemoteToggle() throws {
    let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let sampleURL = rootURL
        .appendingPathComponent("Samples", isDirectory: true)
        .appendingPathComponent("images.md")
    let markdown = try String(contentsOf: sampleURL, encoding: .utf8)

    let defaultResult = try MarkdownRenderer().render(
        RenderRequest(markdown: markdown, sourceFileURL: sampleURL, maxInputBytes: 2_000_000)
    )
    assert(defaultResult.html.contains("Remote image blocked"), "remote image should be blocked by default in sample")
    assert(defaultResult.html.contains(#"<figure class="image-figure image-local">"#), "image sample should render local image figures")

    let remoteEnabledResult = try MarkdownRenderer().render(
        RenderRequest(
            markdown: markdown,
            sourceFileURL: sampleURL,
            maxInputBytes: 2_000_000,
            allowsRemoteImages: true
        )
    )
    assert(remoteEnabledResult.html.contains(#"<figure class="image-figure image-remote">"#), "image sample should render remote image figure when enabled")
    assert(remoteEnabledResult.html.contains("https://upload.wikimedia.org/wikipedia/commons/4/48/Markdown-mark.svg"), "image sample should include remote test image URL when enabled")
}

do {
    try rendersCommonMarkdownBlocks()
    try rendersTablesAndTaskLists()
    try rendersGFMTableAlignmentAndOrderedListStart()
    try rendersNestedListsAndInlineCode()
    try rendersAdditionalCommonMarkdown()
    try rendersCodeBlockLanguageLabels()
    try rendersHighlightAndCallouts()
    try rendersAdditionalGitHubCallouts()
    try rendersFootnotes()
    try resolvesLocalImagesAndReportsMissingImages()
    try resolvesImagesWithChineseNamesAndSpaces()
    try blocksRemoteImagesAndRemovesRawHTML()
    try allowsRemoteImagesWhenRequested()
    validatesEmptyAndOversizedInput()
    rendersActionableErrorPages()
    try rendersSampleDocuments()
    try rendersImageSampleWithRemoteToggle()
    print("MarkdownPreviewCoreTestRunner: all checks passed")
} catch {
    fputs("FAIL: unexpected error \(error)\n", stderr)
    exit(1)
}
