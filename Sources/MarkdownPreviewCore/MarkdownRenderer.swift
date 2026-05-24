import Foundation

public struct MarkdownRenderer: MarkdownRendering {
    public init() {}

    public func render(_ request: RenderRequest) throws -> RenderResult {
        guard !request.markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PreviewRenderError.emptyDocument
        }

        guard request.markdown.utf8.count <= request.maxInputBytes else {
            throw PreviewRenderError.fileTooLarge
        }

        let parser = MarkdownBlockParser(sourceFileURL: request.sourceFileURL)
        let parsed = parser.render(markdown: request.markdown)
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

private struct MarkdownBlockParser {
    private let inline: MarkdownInlineRenderer

    init(sourceFileURL: URL) {
        inline = MarkdownInlineRenderer(resourceResolver: ResourceResolver(sourceFileURL: sourceFileURL))
    }

    func render(markdown: String) -> ParsedMarkdown {
        let lines = markdown.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        var context = RenderContext(inline: inline)
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                index += 1
                continue
            }

            if trimmed.hasPrefix("```") {
                index = context.appendCodeBlock(lines: lines, start: index)
                continue
            }

            if let heading = parseHeading(trimmed) {
                context.append(#"<h\#(heading.level)>\#(inline.renderText(heading.text))</h\#(heading.level)>"#)
                index += 1
                continue
            }

            if isTableStart(lines, index) {
                index = context.appendTable(lines: lines, start: index)
                continue
            }

            if trimmed.hasPrefix(">") {
                index = context.appendBlockquote(lines: lines, start: index)
                continue
            }

            if UnorderedListMarker(line: trimmed) != nil {
                index = context.appendUnorderedList(lines: lines, start: index)
                continue
            }

            if OrderedListMarker(line: trimmed) != nil {
                index = context.appendOrderedList(lines: lines, start: index)
                continue
            }

            if isRawHTML(trimmed) {
                context.addWarning(.rawHTMLRemoved)
                index += 1
                continue
            }

            index = context.appendParagraph(lines: lines, start: index)
        }

        return ParsedMarkdown(html: context.body.joined(separator: "\n"), warnings: context.warnings)
    }

    private func parseHeading(_ line: String) -> (level: Int, text: String)? {
        var count = 0
        for character in line {
            if character == "#" {
                count += 1
            } else {
                break
            }
        }
        guard (1...6).contains(count), line.dropFirst(count).first == " " else {
            return nil
        }
        return (count, String(line.dropFirst(count + 1)))
    }

    private func isTableStart(_ lines: [String], _ index: Int) -> Bool {
        guard index + 1 < lines.count else {
            return false
        }
        let header = lines[index].trimmingCharacters(in: .whitespaces)
        let separator = lines[index + 1].trimmingCharacters(in: .whitespaces)
        return header.contains("|") && separator.split(separator: "|").allSatisfy { cell in
            let trimmed = cell.trimmingCharacters(in: .whitespaces)
            return !trimmed.isEmpty && trimmed.allSatisfy { $0 == "-" || $0 == ":" }
        }
    }
}

private struct RenderContext {
    var body: [String] = []
    var warnings: [RenderWarning] = []

    private let inline: MarkdownInlineRenderer

    init(inline: MarkdownInlineRenderer) {
        self.inline = inline
    }

    mutating func append(_ html: String) {
        body.append(html)
    }

    mutating func addWarning(_ warning: RenderWarning) {
        if !warnings.contains(warning) {
            warnings.append(warning)
        }
    }

    mutating func appendCodeBlock(lines: [String], start: Int) -> Int {
        let first = lines[start].trimmingCharacters(in: .whitespaces)
        let language = String(first.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        var codeLines: [String] = []
        var index = start + 1
        while index < lines.count {
            if lines[index].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                index += 1
                break
            }
            codeLines.append(lines[index])
            index += 1
        }

        let classAttribute = language.isEmpty ? "" : #" class="language-\#(HTMLEscaping.attribute(language))""#
        append(#"<pre><code\#(classAttribute)>\#(HTMLEscaping.text(codeLines.joined(separator: "\n")))</code></pre>"#)
        return index
    }

    mutating func appendTable(lines: [String], start: Int) -> Int {
        let headers = splitTableRow(lines[start])
        var index = start + 2
        var rows: [[String]] = []
        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            guard trimmed.contains("|"), !trimmed.isEmpty else {
                break
            }
            rows.append(splitTableRow(lines[index]))
            index += 1
        }

        let headerHTML = headers.map { "<th>\(inline.renderText($0))</th>" }.joined()
        let rowsHTML = rows.map { row in
            "<tr>" + row.map { "<td>\(inline.renderText($0))</td>" }.joined() + "</tr>"
        }.joined()
        append("<table><thead><tr>\(headerHTML)</tr></thead><tbody>\(rowsHTML)</tbody></table>")
        warnings.append(contentsOf: inline.drainWarnings())
        return index
    }

    mutating func appendBlockquote(lines: [String], start: Int) -> Int {
        var quoteLines: [String] = []
        var index = start
        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix(">") else {
                break
            }
            quoteLines.append(String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces))
            index += 1
        }

        append("<blockquote><p>\(inline.renderText(quoteLines.joined(separator: " ")))</p></blockquote>")
        warnings.append(contentsOf: inline.drainWarnings())
        return index
    }

    mutating func appendUnorderedList(lines: [String], start: Int) -> Int {
        var items: [String] = []
        var index = start
        while index < lines.count, let marker = UnorderedListMarker(line: lines[index].trimmingCharacters(in: .whitespaces)) {
            items.append(renderListItem(marker.content))
            index += 1
        }
        append("<ul>\(items.joined())</ul>")
        warnings.append(contentsOf: inline.drainWarnings())
        return index
    }

    mutating func appendOrderedList(lines: [String], start: Int) -> Int {
        var items: [String] = []
        var index = start
        while index < lines.count, let marker = OrderedListMarker(line: lines[index].trimmingCharacters(in: .whitespaces)) {
            items.append("<li>\(inline.renderText(marker.content))</li>")
            index += 1
        }
        append("<ol>\(items.joined())</ol>")
        warnings.append(contentsOf: inline.drainWarnings())
        return index
    }

    mutating func appendParagraph(lines: [String], start: Int) -> Int {
        var paragraphLines: [String] = []
        var index = start
        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("```") || isRawHTML(trimmed) || UnorderedListMarker(line: trimmed) != nil || OrderedListMarker(line: trimmed) != nil {
                break
            }
            paragraphLines.append(trimmed)
            index += 1
        }
        append("<p>\(inline.renderText(paragraphLines.joined(separator: " ")))</p>")
        warnings.append(contentsOf: inline.drainWarnings())
        return index
    }

    private mutating func renderListItem(_ content: String) -> String {
        if content.hasPrefix("[x] ") || content.hasPrefix("[X] ") {
            return #"<li class="task-list-item"><input type="checkbox" checked disabled> \#(inline.renderText(String(content.dropFirst(4))))</li>"#
        }
        if content.hasPrefix("[ ] ") {
            return #"<li class="task-list-item"><input type="checkbox" disabled> \#(inline.renderText(String(content.dropFirst(4))))</li>"#
        }
        return "<li>\(inline.renderText(content))</li>"
    }
}

private final class MarkdownInlineRenderer {
    private let resourceResolver: ResourceResolver
    private var warnings: [RenderWarning] = []

    init(resourceResolver: ResourceResolver) {
        self.resourceResolver = resourceResolver
    }

    func renderText(_ text: String) -> String {
        var output = ""
        var index = text.startIndex

        while index < text.endIndex {
            if text[index...].hasPrefix("!["),
               let parsed = parseBracketed(text, start: index, markerLength: 2) {
                output += renderImage(alt: parsed.label, destination: parsed.destination)
                index = parsed.end
                continue
            }

            if text[index] == "[",
               let parsed = parseBracketed(text, start: index, markerLength: 1) {
                output += renderLink(label: parsed.label, destination: parsed.destination)
                index = parsed.end
                continue
            }

            if text[index...].hasPrefix("**"),
               let close = text[index...].dropFirst(2).range(of: "**") {
                let contentStart = text.index(index, offsetBy: 2)
                output += "<strong>\(renderText(String(text[contentStart..<close.lowerBound])))</strong>"
                index = close.upperBound
                continue
            }

            if text[index] == "*",
               let close = text[text.index(after: index)..<text.endIndex].firstIndex(of: "*") {
                let contentStart = text.index(after: index)
                output += "<em>\(renderText(String(text[contentStart..<close])))</em>"
                index = text.index(after: close)
                continue
            }

            output += HTMLEscaping.text(String(text[index]))
            index = text.index(after: index)
        }

        return output
    }

    func drainWarnings() -> [RenderWarning] {
        let current = warnings
        warnings.removeAll()
        return current
    }

    private func parseBracketed(_ text: String, start: String.Index, markerLength: Int) -> (label: String, destination: String, end: String.Index)? {
        let labelStart = text.index(start, offsetBy: markerLength)
        guard let labelEnd = text[labelStart..<text.endIndex].firstIndex(of: "]") else {
            return nil
        }
        let parenStart = text.index(after: labelEnd)
        guard parenStart < text.endIndex, text[parenStart] == "(" else {
            return nil
        }
        let destinationStart = text.index(after: parenStart)
        guard let destinationEnd = text[destinationStart..<text.endIndex].firstIndex(of: ")") else {
            return nil
        }

        return (
            String(text[labelStart..<labelEnd]),
            String(text[destinationStart..<destinationEnd]),
            text.index(after: destinationEnd)
        )
    }

    private func renderLink(label: String, destination: String) -> String {
        let safeDestination = safeLinkDestination(destination)
        return #"<a href="\#(HTMLEscaping.attribute(safeDestination))">\#(renderText(label))</a>"#
    }

    private func renderImage(alt: String, destination: String) -> String {
        switch resourceResolver.resolveImage(destination) {
        case .local(let url):
            return #"<img src="\#(HTMLEscaping.attribute(url.absoluteString))" alt="\#(HTMLEscaping.attribute(alt))">"#
        case .missing(let path):
            warnings.append(.missingLocalImage(path))
            return #"<span class="image-placeholder">Missing image: \#(HTMLEscaping.text(path))</span>"#
        case .blockedRemote(let path):
            warnings.append(.blockedRemoteResource(path))
            return #"<span class="image-placeholder">Remote image blocked</span>"#
        }
    }

    private func safeLinkDestination(_ destination: String) -> String {
        guard let scheme = URLComponents(string: destination)?.scheme?.lowercased() else {
            return destination
        }
        return ["http", "https", "mailto"].contains(scheme) ? destination : "#"
    }
}

private struct UnorderedListMarker {
    let content: String

    init?(line: String) {
        guard line.count >= 2 else {
            return nil
        }
        let prefix = line.prefix(2)
        guard prefix == "- " || prefix == "* " || prefix == "+ " else {
            return nil
        }
        content = String(line.dropFirst(2))
    }
}

private struct OrderedListMarker {
    let content: String

    init?(line: String) {
        guard let dotIndex = line.firstIndex(of: ".") else {
            return nil
        }
        guard line[line.index(after: dotIndex)..<line.endIndex].first == " " else {
            return nil
        }
        let number = line[..<dotIndex]
        guard !number.isEmpty, number.allSatisfy(\.isNumber) else {
            return nil
        }
        content = String(line[line.index(dotIndex, offsetBy: 2)..<line.endIndex])
    }
}

private func splitTableRow(_ line: String) -> [String] {
    var trimmed = line.trimmingCharacters(in: .whitespaces)
    if trimmed.hasPrefix("|") {
        trimmed.removeFirst()
    }
    if trimmed.hasSuffix("|") {
        trimmed.removeLast()
    }
    return trimmed.split(separator: "|", omittingEmptySubsequences: false)
        .map { $0.trimmingCharacters(in: .whitespaces) }
}

private func isRawHTML(_ line: String) -> Bool {
    line.hasPrefix("<") && line.contains(">")
}
