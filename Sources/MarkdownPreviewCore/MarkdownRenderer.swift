import Foundation
import Markdown

public struct MarkdownRenderer: MarkdownRendering {
    public init() {}

    public func render(_ request: RenderRequest) throws -> RenderResult {
        guard !request.markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PreviewRenderError.emptyDocument
        }

        guard request.markdown.utf8.count <= request.maxInputBytes else {
            throw PreviewRenderError.fileTooLarge
        }

        let renderer = SwiftMarkdownHTMLRenderer(sourceFileURL: request.sourceFileURL)
        let parsed = renderer.render(markdown: request.markdown)
        return RenderResult(
            html: PreviewHTMLTemplate.document(body: parsed.html),
            warnings: parsed.warnings
        )
    }
}

private struct ParsedMarkdown {
    let html: String
    let warnings: [RenderWarning]
}

private class SwiftMarkdownHTMLRenderer: MarkupVisitor {
    typealias Result = String

    private let resourceResolver: ResourceResolver
    private var warnings: [RenderWarning] = []
    private var footnoteDefinitions: [String: String] = [:]
    private var footnoteOrder: [String] = []
    private var footnoteReferenceCounts: [String: Int] = [:]
    private var inTableHead = false
    private var tableColumnAlignments: [Table.ColumnAlignment?] = []
    private var currentTableColumn = 0

    init(sourceFileURL: URL) {
        resourceResolver = ResourceResolver(sourceFileURL: sourceFileURL)
    }

    func render(markdown: String) -> ParsedMarkdown {
        let extracted = extractFootnotes(from: markdown)
        footnoteDefinitions = extracted.definitions
        footnoteOrder = []
        footnoteReferenceCounts = [:]

        let document = Document(parsing: normalizeMarkdownDestinations(extracted.markdown))
        let html = visit(document) + renderFootnotes()
        return ParsedMarkdown(html: html, warnings: warnings)
    }

    func visit(_ markup: Markup) -> String {
        if let document = markup as? Document {
            return visitDocument(document)
        } else if let heading = markup as? Heading {
            return visitHeading(heading)
        } else if let paragraph = markup as? Paragraph {
            return visitParagraph(paragraph)
        } else if let blockQuote = markup as? BlockQuote {
            return visitBlockQuote(blockQuote)
        } else if let codeBlock = markup as? CodeBlock {
            return visitCodeBlock(codeBlock)
        } else if let thematicBreak = markup as? ThematicBreak {
            return visitThematicBreak(thematicBreak)
        } else if let htmlBlock = markup as? HTMLBlock {
            return visitHTMLBlock(htmlBlock)
        } else if let inlineHTML = markup as? InlineHTML {
            return visitInlineHTML(inlineHTML)
        } else if let unorderedList = markup as? UnorderedList {
            return visitUnorderedList(unorderedList)
        } else if let orderedList = markup as? OrderedList {
            return visitOrderedList(orderedList)
        } else if let listItem = markup as? ListItem {
            return visitListItem(listItem)
        } else if let table = markup as? Table {
            return visitTable(table)
        } else if let tableHead = markup as? Table.Head {
            return visitTableHead(tableHead)
        } else if let tableBody = markup as? Table.Body {
            return visitTableBody(tableBody)
        } else if let tableRow = markup as? Table.Row {
            return visitTableRow(tableRow)
        } else if let tableCell = markup as? Table.Cell {
            return visitTableCell(tableCell)
        } else if let strong = markup as? Strong {
            return visitStrong(strong)
        } else if let emphasis = markup as? Emphasis {
            return visitEmphasis(emphasis)
        } else if let strikethrough = markup as? Strikethrough {
            return visitStrikethrough(strikethrough)
        } else if let inlineCode = markup as? InlineCode {
            return visitInlineCode(inlineCode)
        } else if let text = markup as? Text {
            return visitText(text)
        } else if let softBreak = markup as? SoftBreak {
            return visitSoftBreak(softBreak)
        } else if let lineBreak = markup as? LineBreak {
            return visitLineBreak(lineBreak)
        } else if let link = markup as? Link {
            return visitLink(link)
        } else if let image = markup as? Image {
            return visitImage(image)
        } else if let symbolLink = markup as? SymbolLink {
            return visitSymbolLink(symbolLink)
        } else if let inlineAttributes = markup as? InlineAttributes {
            return visitInlineAttributes(inlineAttributes)
        } else {
            return defaultVisit(markup)
        }
    }

    func defaultVisit(_ markup: Markup) -> String {
        renderChildren(of: markup)
    }

    func visitDocument(_ document: Document) -> String {
        renderChildren(of: document)
    }

    func visitHeading(_ heading: Heading) -> String {
        "<h\(heading.level)>\(renderChildren(of: heading))</h\(heading.level)>"
    }

    func visitParagraph(_ paragraph: Paragraph) -> String {
        "<p>\(renderChildren(of: paragraph))</p>"
    }

    func visitBlockQuote(_ blockQuote: BlockQuote) -> String {
        if let callout = renderCallout(blockQuote) {
            return callout
        }

        return "<blockquote>\(renderChildren(of: blockQuote))</blockquote>"
    }

    func visitCodeBlock(_ codeBlock: CodeBlock) -> String {
        let language = codeBlock.language?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedLanguage = language?.lowercased()
        let figureClass = normalizedLanguage == "mermaid" ? "code-block code-block-mermaid" : "code-block"
        let classAttribute = language.flatMap { $0.isEmpty ? nil : $0 }.map {
            #" class="language-\#(HTMLEscaping.attribute($0))""#
        } ?? ""
        let label = language.flatMap { $0.isEmpty ? nil : $0 }.map {
            "<figcaption>\(HTMLEscaping.text($0))</figcaption>"
        } ?? ""
        let note = normalizedLanguage == "mermaid"
            ? #"<div class="code-note">Mermaid source preview. Diagram execution is disabled for safety.</div>"#
            : ""
        let codeHTML = renderCode(codeBlock.code, language: language)
        return #"<figure class="\#(figureClass)">\#(label)\#(note)<pre><code\#(classAttribute)>\#(codeHTML)</code></pre></figure>"#
    }

    func visitThematicBreak(_ thematicBreak: ThematicBreak) -> String {
        "<hr>"
    }

    func visitHTMLBlock(_ html: HTMLBlock) -> String {
        addWarning(.rawHTMLRemoved)
        return ""
    }

    func visitInlineHTML(_ inlineHTML: InlineHTML) -> String {
        addWarning(.rawHTMLRemoved)
        return ""
    }

    func visitUnorderedList(_ unorderedList: UnorderedList) -> String {
        "<ul>\(renderChildren(of: unorderedList))</ul>"
    }

    func visitOrderedList(_ orderedList: OrderedList) -> String {
        let startAttribute = orderedList.startIndex == 1 ? "" : #" start="\#(orderedList.startIndex)""#
        return "<ol\(startAttribute)>\(renderChildren(of: orderedList))</ol>"
    }

    func visitListItem(_ listItem: ListItem) -> String {
        switch listItem.checkbox {
        case .checked:
            return renderTaskListItem(listItem, inputHTML: #"<input type="checkbox" checked disabled>"#)
        case .unchecked:
            return renderTaskListItem(listItem, inputHTML: #"<input type="checkbox" disabled>"#)
        case nil:
            return "<li>\(renderChildren(of: listItem))</li>"
        }
    }

    func visitTable(_ table: Table) -> String {
        let previousAlignments = tableColumnAlignments
        tableColumnAlignments = table.columnAlignments
        let html = "<table>\(renderChildren(of: table))</table>"
        tableColumnAlignments = previousAlignments
        return html
    }

    func visitTableHead(_ tableHead: Table.Head) -> String {
        let wasInTableHead = inTableHead
        let previousColumn = currentTableColumn
        inTableHead = true
        currentTableColumn = 0
        let html = "<thead><tr>\(renderChildren(of: tableHead))</tr></thead>"
        inTableHead = wasInTableHead
        currentTableColumn = previousColumn
        return html
    }

    func visitTableBody(_ tableBody: Table.Body) -> String {
        guard !tableBody.isEmpty else {
            return ""
        }
        return "<tbody>\(renderChildren(of: tableBody))</tbody>"
    }

    func visitTableRow(_ tableRow: Table.Row) -> String {
        currentTableColumn = 0
        return "<tr>\(renderChildren(of: tableRow))</tr>"
    }

    func visitTableCell(_ tableCell: Table.Cell) -> String {
        guard tableCell.colspan > 0, tableCell.rowspan > 0 else {
            return ""
        }

        let tag = inTableHead ? "th" : "td"
        let alignment = currentTableColumn < tableColumnAlignments.count
            ? tableColumnAlignments[currentTableColumn]
            : nil
        currentTableColumn += 1

        var attributes = ""
        if let alignment {
            attributes += #" align="\#(alignment.htmlValue)""#
        }
        if tableCell.rowspan > 1 {
            attributes += #" rowspan="\#(tableCell.rowspan)""#
        }
        if tableCell.colspan > 1 {
            attributes += #" colspan="\#(tableCell.colspan)""#
        }

        return "<\(tag)\(attributes)>\(renderChildren(of: tableCell))</\(tag)>"
    }

    func visitStrong(_ strong: Strong) -> String {
        "<strong>\(renderChildren(of: strong))</strong>"
    }

    func visitEmphasis(_ emphasis: Emphasis) -> String {
        "<em>\(renderChildren(of: emphasis))</em>"
    }

    func visitStrikethrough(_ strikethrough: Strikethrough) -> String {
        "<del>\(renderChildren(of: strikethrough))</del>"
    }

    func visitInlineCode(_ inlineCode: InlineCode) -> String {
        "<code>\(HTMLEscaping.text(inlineCode.code))</code>"
    }

    func visitText(_ text: Text) -> String {
        renderHighlightedText(text.string)
    }

    func visitSoftBreak(_ softBreak: SoftBreak) -> String {
        "\n"
    }

    func visitLineBreak(_ lineBreak: LineBreak) -> String {
        "<br>"
    }

    func visitLink(_ link: Link) -> String {
        let destination = safeLinkDestination(link.destination ?? "")
        return #"<a href="\#(HTMLEscaping.attribute(destination))">\#(renderChildren(of: link))</a>"#
    }

    func visitImage(_ image: Image) -> String {
        let alt = plainText(for: image)
        switch resourceResolver.resolveImage(image.source ?? "") {
        case .local(let url):
            let title = image.title.map { #" title="\#(HTMLEscaping.attribute($0))""# } ?? ""
            return #"<img src="\#(HTMLEscaping.attribute(url.absoluteString))" alt="\#(HTMLEscaping.attribute(alt))"\#(title)>"#
        case .missing(let path):
            addWarning(.missingLocalImage(path))
            return #"<span class="image-placeholder">Missing image: \#(HTMLEscaping.text(path))</span>"#
        case .blockedRemote(let path):
            addWarning(.blockedRemoteResource(path))
            return #"<span class="image-placeholder">Remote image blocked</span>"#
        }
    }

    func visitSymbolLink(_ symbolLink: SymbolLink) -> String {
        symbolLink.destination.map { "<code>\(HTMLEscaping.text($0))</code>" } ?? ""
    }

    func visitInlineAttributes(_ attributes: InlineAttributes) -> String {
        renderChildren(of: attributes)
    }

    private func renderChildren(of markup: Markup) -> String {
        var result = ""
        for child in markup.children {
            result += visit(child)
        }
        return result
    }

    private func renderTaskListItem(_ listItem: ListItem, inputHTML: String) -> String {
        var children = Array(listItem.children)
        let firstLineHTML: String

        if let firstParagraph = children.first as? Paragraph {
            firstLineHTML = renderChildren(of: firstParagraph)
            children.removeFirst()
        } else if let firstChild = children.first {
            firstLineHTML = visit(firstChild)
            children.removeFirst()
        } else {
            firstLineHTML = ""
        }

        let restHTML = children.map { visit($0) }.joined()
        return #"<li class="task-list-item"><label>\#(inputHTML) <span>\#(firstLineHTML)</span></label>\#(restHTML)</li>"#
    }

    private func renderCode(_ code: String, language: String?) -> String {
        switch language?.lowercased() {
        case "swift":
            return renderSwiftCode(code)
        case "json":
            return renderJSONCode(code)
        case "yaml", "yml":
            return renderYAMLCode(code)
        case "bash", "sh", "shell", "zsh":
            return renderShellCode(code)
        default:
            return HTMLEscaping.text(code)
        }
    }

    private func renderSwiftCode(_ code: String) -> String {
        let keywords: Set<String> = [
            "actor", "as", "async", "await", "break", "case", "catch", "class", "continue",
            "default", "defer", "do", "else", "enum", "extension", "false", "for", "func",
            "guard", "if", "import", "in", "init", "let", "nil", "private", "public", "return",
            "self", "static", "struct", "switch", "throw", "throws", "true", "try", "var", "while"
        ]

        var output = ""

        for line in code.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            var index = line.startIndex

            while index < line.endIndex {
                let remainder = line[index...]

                if remainder.hasPrefix("//") {
                    output += #"<span class="tok-comment">\#(HTMLEscaping.text(String(remainder)))</span>"#
                    index = line.endIndex
                    continue
                }

                if line[index] == "\"" {
                    let end = findStringEnd(in: line, from: index)
                    output += #"<span class="tok-string">\#(HTMLEscaping.text(String(line[index..<end])))</span>"#
                    index = end
                    continue
                }

                if isIdentifierStart(line[index]) {
                    let end = readIdentifier(in: line, from: index)
                    let word = String(line[index..<end])
                    if keywords.contains(word) {
                        output += #"<span class="tok-keyword">\#(HTMLEscaping.text(word))</span>"#
                    } else {
                        output += HTMLEscaping.text(word)
                    }
                    index = end
                    continue
                }

                output += HTMLEscaping.text(String(line[index]))
                index = line.index(after: index)
            }

            output += "\n"
        }

        return output
    }

    private func renderJSONCode(_ code: String) -> String {
        var output = ""
        var index = code.startIndex
        var expectingKey = true

        while index < code.endIndex {
            let character = code[index]

            if character == "\"" {
                let end = findStringEnd(in: code, from: index)
                var lookahead = end
                while lookahead < code.endIndex, code[lookahead].isWhitespace {
                    lookahead = code.index(after: lookahead)
                }

                let tokenClass = expectingKey && lookahead < code.endIndex && code[lookahead] == ":" ? "tok-key" : "tok-string"
                output += #"<span class="\#(tokenClass)">\#(HTMLEscaping.text(String(code[index..<end])))</span>"#
                index = end
                expectingKey = false
                continue
            }

            if character == ":" {
                output += ":"
                expectingKey = false
                index = code.index(after: index)
                continue
            }

            if character == "," || character == "{" {
                output += HTMLEscaping.text(String(character))
                expectingKey = true
                index = code.index(after: index)
                continue
            }

            if character == "}" || character == "[" || character == "]" {
                output += HTMLEscaping.text(String(character))
                index = code.index(after: index)
                continue
            }

            if character.isNumber || character == "-" {
                let end = readJSONNumber(in: code, from: index)
                output += #"<span class="tok-number">\#(HTMLEscaping.text(String(code[index..<end])))</span>"#
                index = end
                continue
            }

            if let literal = readJSONLiteral(in: code, from: index) {
                output += #"<span class="tok-literal">\#(literal.value)</span>"#
                index = literal.end
                continue
            }

            output += HTMLEscaping.text(String(character))
            index = code.index(after: index)
        }

        return output
    }

    private func renderYAMLCode(_ code: String) -> String {
        var output = ""

        for line in code.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            let firstNonWhitespace = line.firstIndex { !$0.isWhitespace } ?? line.endIndex

            if firstNonWhitespace < line.endIndex, line[firstNonWhitespace] == "#" {
                output += HTMLEscaping.text(String(line[..<firstNonWhitespace]))
                output += #"<span class="tok-comment">\#(HTMLEscaping.text(String(line[firstNonWhitespace...])))</span>"#
                output += "\n"
                continue
            }

            guard let colon = yamlKeyDelimiter(in: line, after: firstNonWhitespace) else {
                output += HTMLEscaping.text(line) + "\n"
                continue
            }

            let leading = String(line[..<firstNonWhitespace])
            let key = String(line[firstNonWhitespace..<colon])
            let valueStart = line.index(after: colon)
            output += HTMLEscaping.text(leading)
            output += #"<span class="tok-key">\#(HTMLEscaping.text(key))</span>:"#
            output += renderYAMLValue(String(line[valueStart...]))
            output += "\n"
        }

        return output
    }

    private func yamlKeyDelimiter(in line: String, after start: String.Index) -> String.Index? {
        var index = start

        while index < line.endIndex {
            let character = line[index]
            if character == ":" {
                let next = line.index(after: index)
                if next == line.endIndex || line[next].isWhitespace {
                    return index
                }
            }
            if character == "#" {
                return nil
            }
            index = line.index(after: index)
        }

        return nil
    }

    private func renderYAMLValue(_ value: String) -> String {
        let leadingEnd = value.firstIndex { !$0.isWhitespace } ?? value.endIndex
        let leading = String(value[..<leadingEnd])
        let rawValue = String(value[leadingEnd...])

        guard !rawValue.isEmpty else {
            return HTMLEscaping.text(value)
        }

        if rawValue.hasPrefix("\"") || rawValue.hasPrefix("'") {
            return HTMLEscaping.text(leading) + #"<span class="tok-string">\#(HTMLEscaping.text(rawValue))</span>"#
        }

        if ["true", "false", "null", "~"].contains(rawValue.lowercased()) {
            return HTMLEscaping.text(leading) + #"<span class="tok-literal">\#(HTMLEscaping.text(rawValue))</span>"#
        }

        if rawValue.allSatisfy({ $0.isNumber || ".-+eE".contains($0) }) {
            return HTMLEscaping.text(leading) + #"<span class="tok-number">\#(HTMLEscaping.text(rawValue))</span>"#
        }

        return HTMLEscaping.text(value)
    }

    private func renderShellCode(_ code: String) -> String {
        let keywords: Set<String> = [
            "case", "do", "done", "elif", "else", "esac", "export", "fi", "for",
            "function", "if", "in", "local", "return", "select", "then", "until", "while"
        ]
        var output = ""

        for line in code.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            var index = line.startIndex

            while index < line.endIndex {
                let character = line[index]
                if character == "#" {
                    output += #"<span class="tok-comment">\#(HTMLEscaping.text(String(line[index...])))</span>"#
                    index = line.endIndex
                    continue
                }

                if character == "\"" || character == "'" {
                    let end = findStringEnd(in: line, from: index, quote: character)
                    output += #"<span class="tok-string">\#(HTMLEscaping.text(String(line[index..<end])))</span>"#
                    index = end
                    continue
                }

                if isIdentifierStart(character) {
                    let end = readIdentifier(in: line, from: index)
                    let word = String(line[index..<end])
                    if keywords.contains(word) {
                        output += #"<span class="tok-keyword">\#(HTMLEscaping.text(word))</span>"#
                    } else {
                        output += HTMLEscaping.text(word)
                    }
                    index = end
                    continue
                }

                output += HTMLEscaping.text(String(character))
                index = line.index(after: index)
            }

            output += "\n"
        }

        return output
    }

    private func findStringEnd(in text: String, from start: String.Index, quote: Character = "\"") -> String.Index {
        var index = text.index(after: start)
        var escaped = false

        while index < text.endIndex {
            if escaped {
                escaped = false
            } else if text[index] == "\\" {
                escaped = true
            } else if text[index] == quote {
                return text.index(after: index)
            }
            index = text.index(after: index)
        }

        return text.endIndex
    }

    private func isIdentifierStart(_ character: Character) -> Bool {
        character == "_" || character.isLetter
    }

    private func isIdentifierContinuation(_ character: Character) -> Bool {
        character == "_" || character.isLetter || character.isNumber
    }

    private func readIdentifier(in text: String, from start: String.Index) -> String.Index {
        var index = start
        while index < text.endIndex, isIdentifierContinuation(text[index]) {
            index = text.index(after: index)
        }
        return index
    }

    private func readJSONNumber(in text: String, from start: String.Index) -> String.Index {
        var index = start
        while index < text.endIndex, text[index].isNumber || ".-+eE".contains(text[index]) {
            index = text.index(after: index)
        }
        return index
    }

    private func readJSONLiteral(in text: String, from start: String.Index) -> (value: String, end: String.Index)? {
        for literal in ["true", "false", "null"] {
            if text[start...].hasPrefix(literal) {
                return (literal, text.index(start, offsetBy: literal.count))
            }
        }
        return nil
    }

    private func renderCallout(_ blockQuote: BlockQuote) -> String? {
        guard let firstParagraph = blockQuote.child(at: 0) as? Paragraph else {
            return nil
        }

        let marker = plainText(for: firstParagraph).trimmingCharacters(in: .whitespacesAndNewlines)
        guard marker.hasPrefix("[!"), marker.contains("]") else {
            return nil
        }

        let markerEnd = marker.firstIndex(of: "]")!
        let rawKind = marker[marker.index(marker.startIndex, offsetBy: 2)..<markerEnd].lowercased()
        guard !rawKind.isEmpty, rawKind.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" }) else {
            return nil
        }

        let title = rawKind.split(separator: "-")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")

        var bodyParts: [String] = []
        let remainder = marker[marker.index(after: markerEnd)...].trimmingCharacters(in: .whitespacesAndNewlines)
        if !remainder.isEmpty {
            bodyParts.append("<p>\(renderHighlightedText(String(remainder)))</p>")
        }
        for child in blockQuote.children.dropFirst() {
            bodyParts.append(visit(child))
        }

        return #"<blockquote class="callout callout-\#(HTMLEscaping.attribute(String(rawKind)))"><p><strong>\#(HTMLEscaping.text(title))</strong></p>\#(bodyParts.joined())</blockquote>"#
    }

    private func plainText(for markup: Markup) -> String {
        if let text = markup as? Text {
            return text.string
        }
        if let inlineCode = markup as? InlineCode {
            return inlineCode.code
        }
        if let inlineHTML = markup as? InlineHTML {
            return inlineHTML.rawHTML
        }
        if markup is SoftBreak || markup is LineBreak {
            return "\n"
        }
        return markup.children.map { plainText(for: $0) }.joined()
    }

    private func renderHighlightedText(_ text: String) -> String {
        var output = ""
        var index = text.startIndex

        while index < text.endIndex {
            let remainder = text[index...]
            if remainder.hasPrefix("=="),
               let end = remainder.dropFirst(2).range(of: "==") {
                let contentStart = text.index(index, offsetBy: 2)
                output += "<mark>\(HTMLEscaping.text(String(text[contentStart..<end.lowerBound])))</mark>"
                index = end.upperBound
                continue
            }

            if let autoLink = parseAutoLink(text, start: index) {
                output += renderAutoLink(destination: autoLink.destination)
                index = autoLink.end
                continue
            }

            if let footnote = parseFootnoteReference(text, start: index) {
                output += renderFootnoteReference(footnote.id)
                index = footnote.end
                continue
            }

            output += HTMLEscaping.text(String(text[index]))
            index = text.index(after: index)
        }

        return output
    }

    private func parseAutoLink(_ text: String, start: String.Index) -> (destination: String, end: String.Index)? {
        let remainder = text[start...]
        let prefixes = ["https://", "http://", "mailto:"]
        guard prefixes.contains(where: { remainder.hasPrefix($0) }) else {
            return nil
        }

        var end = start
        while end < text.endIndex, !text[end].isWhitespace {
            end = text.index(after: end)
        }

        var destination = String(text[start..<end])
        while let last = destination.last, ".,;:)".contains(last) {
            destination.removeLast()
            end = text.index(before: end)
        }

        guard !destination.isEmpty else {
            return nil
        }

        return (destination, end)
    }

    private func renderAutoLink(destination: String) -> String {
        let safeDestination = safeLinkDestination(destination)
        return #"<a href="\#(HTMLEscaping.attribute(safeDestination))">\#(HTMLEscaping.text(destination))</a>"#
    }

    private func parseFootnoteReference(_ text: String, start: String.Index) -> (id: String, end: String.Index)? {
        let remainder = text[start...]
        guard remainder.hasPrefix("[^"),
              let close = remainder.firstIndex(of: "]") else {
            return nil
        }

        let idStart = text.index(start, offsetBy: 2)
        guard idStart < close else {
            return nil
        }

        let id = String(text[idStart..<close])
        guard footnoteDefinitions[id] != nil else {
            return nil
        }

        return (id, text.index(after: close))
    }

    private func renderFootnoteReference(_ id: String) -> String {
        if !footnoteOrder.contains(id) {
            footnoteOrder.append(id)
        }

        let number = (footnoteOrder.firstIndex(of: id) ?? 0) + 1
        let count = (footnoteReferenceCounts[id] ?? 0) + 1
        footnoteReferenceCounts[id] = count

        let slug = footnoteSlug(id)
        let referenceID = count == 1 ? "fnref-\(slug)" : "fnref-\(slug)-\(count)"
        return ##"<sup class="footnote-ref"><a href="#fn-\##(HTMLEscaping.attribute(slug))" id="\##(HTMLEscaping.attribute(referenceID))">\##(number)</a></sup>"##
    }

    private func renderFootnotes() -> String {
        guard !footnoteOrder.isEmpty else {
            return ""
        }

        let items = footnoteOrder.compactMap { id -> String? in
            guard let definition = footnoteDefinitions[id] else {
                return nil
            }

            let slug = footnoteSlug(id)
            let content = renderFootnoteDefinition(definition)
            let backrefs = renderFootnoteBackrefs(id: id, slug: slug)
            return #"<li id="fn-\#(HTMLEscaping.attribute(slug))">\#(content) \#(backrefs)</li>"#
        }.joined()

        return #"<section class="footnotes"><hr><ol>\#(items)</ol></section>"#
    }

    private func renderFootnoteDefinition(_ definition: String) -> String {
        let document = Document(parsing: normalizeMarkdownDestinations(definition))
        let html = renderChildren(of: document)

        if html.hasPrefix("<p>"), html.hasSuffix("</p>") {
            return String(html.dropFirst(3).dropLast(4))
        }

        return html
    }

    private func renderFootnoteBackrefs(id: String, slug: String) -> String {
        let count = footnoteReferenceCounts[id] ?? 0
        guard count > 0 else {
            return ""
        }

        return (1...count).map { index in
            let referenceID = index == 1 ? "fnref-\(slug)" : "fnref-\(slug)-\(index)"
            return ##"<a href="#\##(HTMLEscaping.attribute(referenceID))" class="footnote-backref">↩</a>"##
        }.joined(separator: " ")
    }

    private func footnoteSlug(_ id: String) -> String {
        var slug = ""

        for scalar in id.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) || scalar == "-" || scalar == "_" {
                slug.unicodeScalars.append(scalar)
            } else {
                slug += String(format: "%%%02X", scalar.value)
            }
        }

        return slug.isEmpty ? "note" : slug
    }

    private func safeLinkDestination(_ destination: String) -> String {
        guard let scheme = URLComponents(string: destination)?.scheme?.lowercased() else {
            return destination
        }
        return ["http", "https", "mailto"].contains(scheme) ? destination : "#"
    }

    private func addWarning(_ warning: RenderWarning) {
        if !warnings.contains(warning) {
            warnings.append(warning)
        }
    }

    private func normalizeMarkdownDestinations(_ markdown: String) -> String {
        var output = ""
        var index = markdown.startIndex

        while index < markdown.endIndex {
            if markdown[index] == "]" {
                let next = markdown.index(after: index)
                if next < markdown.endIndex,
                   markdown[next] == "(",
                   let close = markdown[next...].firstIndex(of: ")") {
                    let destinationStart = markdown.index(after: next)
                    let destination = String(markdown[destinationStart..<close])
                    output.append(markdown[index])
                    output.append("(")
                    output.append(normalizeDestination(destination))
                    output.append(")")
                    index = markdown.index(after: close)
                    continue
                }
            }

            output.append(markdown[index])
            index = markdown.index(after: index)
        }

        return output
    }

    private func extractFootnotes(from markdown: String) -> (markdown: String, definitions: [String: String]) {
        var definitions: [String: String] = [:]
        var keptLines: [String] = []
        var inFence = false
        var fenceMarker: String?

        for line in markdown.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            if let marker = fenceMarker {
                keptLines.append(line)
                if line.trimmingCharacters(in: .whitespaces).hasPrefix(marker) {
                    inFence = false
                    fenceMarker = nil
                }
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                inFence = true
                fenceMarker = String(trimmed.prefix(3))
                keptLines.append(line)
                continue
            }

            if !inFence, let definition = parseFootnoteDefinition(line) {
                definitions[definition.id] = definition.text
            } else {
                keptLines.append(line)
            }
        }

        return (keptLines.joined(separator: "\n"), definitions)
    }

    private func parseFootnoteDefinition(_ line: String) -> (id: String, text: String)? {
        guard line.hasPrefix("[^"),
              let close = line.firstIndex(of: "]") else {
            return nil
        }

        let colon = line.index(after: close)
        guard colon < line.endIndex, line[colon] == ":" else {
            return nil
        }

        let idStart = line.index(line.startIndex, offsetBy: 2)
        let id = String(line[idStart..<close])
        let textStart = line.index(after: colon)
        let text = String(line[textStart...]).trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty, !text.isEmpty else {
            return nil
        }

        return (id, text)
    }

    private func normalizeDestination(_ destination: String) -> String {
        guard destination.contains(" ") else {
            return destination
        }

        if let titleStart = titleDelimiterStart(in: destination) {
            let path = String(destination[..<titleStart]).trimmingCharacters(in: .whitespacesAndNewlines)
            let title = String(destination[titleStart...])
            return path.replacingOccurrences(of: " ", with: "%20") + title
        }

        return destination.replacingOccurrences(of: " ", with: "%20")
    }

    private func titleDelimiterStart(in destination: String) -> String.Index? {
        var index = destination.startIndex

        while index < destination.endIndex {
            guard destination[index].isWhitespace else {
                index = destination.index(after: index)
                continue
            }

            var next = destination.index(after: index)
            while next < destination.endIndex, destination[next].isWhitespace {
                next = destination.index(after: next)
            }

            if next < destination.endIndex, "\"'(".contains(destination[next]) {
                return index
            }

            index = destination.index(after: index)
        }

        return nil
    }
}

private extension Table.ColumnAlignment {
    var htmlValue: String {
        switch self {
        case .left:
            return "left"
        case .center:
            return "center"
        case .right:
            return "right"
        }
    }
}
