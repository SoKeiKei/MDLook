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

            if isFenceStart(trimmed) != nil {
                index = context.appendCodeBlock(lines: lines, start: index)
                continue
            }

            if let setext = parseSetextHeading(lines, index) {
                context.append(#"<h\#(setext.level)>\#(inline.renderText(setext.text))</h\#(setext.level)>"#)
                index += 2
                continue
            }

            if let heading = parseHeading(trimmed) {
                context.append(#"<h\#(heading.level)>\#(inline.renderText(heading.text))</h\#(heading.level)>"#)
                index += 1
                continue
            }

            if isHorizontalRule(trimmed) {
                context.append("<hr>")
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

            if let marker = ListMarker(line: line), !marker.isOrdered {
                index = context.appendList(lines: lines, start: index, ordered: false)
                continue
            }

            if let marker = ListMarker(line: line), marker.isOrdered {
                index = context.appendList(lines: lines, start: index, ordered: true)
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

    private func parseSetextHeading(_ lines: [String], _ index: Int) -> (level: Int, text: String)? {
        guard index + 1 < lines.count else {
            return nil
        }

        let text = lines[index].trimmingCharacters(in: .whitespaces)
        let underline = lines[index + 1].trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !isRawHTML(text), ListMarker(line: lines[index]) == nil else {
            return nil
        }

        if underline.count >= 2, underline.allSatisfy({ $0 == "=" }) {
            return (1, text)
        }

        if underline.count >= 2, underline.allSatisfy({ $0 == "-" }) {
            return (2, text)
        }

        return nil
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
        let fence = isFenceStart(first) ?? "```"
        let language = String(first.dropFirst(fence.count)).trimmingCharacters(in: .whitespaces)
        var codeLines: [String] = []
        var index = start + 1
        while index < lines.count {
            if lines[index].trimmingCharacters(in: .whitespaces).hasPrefix(fence) {
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

        if let callout = Callout(lines: quoteLines) {
            append(callout.render(inline: inline))
        } else {
            append("<blockquote><p>\(inline.renderText(quoteLines.joined(separator: " ")))</p></blockquote>")
        }
        warnings.append(contentsOf: inline.drainWarnings())
        return index
    }

    mutating func appendList(lines: [String], start: Int, ordered: Bool) -> Int {
        guard let marker = ListMarker(line: lines[start]), marker.isOrdered == ordered else {
            return start
        }

        var index = start
        append(renderList(lines: lines, index: &index, indent: marker.indent, ordered: ordered))
        warnings.append(contentsOf: inline.drainWarnings())
        return index
    }

    mutating func appendParagraph(lines: [String], start: Int) -> Int {
        var paragraphLines: [String] = []
        var index = start
        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || isFenceStart(trimmed) != nil || isRawHTML(trimmed) || ListMarker(line: lines[index]) != nil || isHorizontalRule(trimmed) {
                break
            }
            paragraphLines.append(trimmed)
            index += 1
        }
        append("<p>\(inline.renderText(paragraphLines.joined(separator: " ")))</p>")
        warnings.append(contentsOf: inline.drainWarnings())
        return index
    }

    private mutating func renderList(lines: [String], index: inout Int, indent: Int, ordered: Bool) -> String {
        var items: [String] = []

        while index < lines.count {
            guard let marker = ListMarker(line: lines[index]),
                  marker.indent == indent,
                  marker.isOrdered == ordered
            else {
                break
            }

            index += 1
            var item = renderListItemContent(marker.content)

            while index < lines.count,
                  let nested = ListMarker(line: lines[index]),
                  nested.indent > indent {
                item.html += renderList(lines: lines, index: &index, indent: nested.indent, ordered: nested.isOrdered)
            }

            items.append("<li\(item.attributes)>\(item.html)</li>")
        }

        let tag = ordered ? "ol" : "ul"
        return "<\(tag)>\(items.joined())</\(tag)>"
    }

    private mutating func renderListItemContent(_ content: String) -> (attributes: String, html: String) {
        if content.hasPrefix("[x] ") || content.hasPrefix("[X] ") {
            return (#" class="task-list-item""#, #"<input type="checkbox" checked disabled> \#(inline.renderText(String(content.dropFirst(4))))"#)
        }
        if content.hasPrefix("[ ] ") {
            return (#" class="task-list-item""#, #"<input type="checkbox" disabled> \#(inline.renderText(String(content.dropFirst(4))))"#)
        }
        return ("", inline.renderText(content))
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
            if text[index] == "\\" {
                let next = text.index(after: index)
                if next < text.endIndex, isEscapable(text[next]) {
                    output += HTMLEscaping.text(String(text[next]))
                    index = text.index(after: next)
                    continue
                }
            }

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

            if let autoLink = parseAutoLink(text, start: index) {
                output += renderAutoLink(destination: autoLink.destination)
                index = autoLink.end
                continue
            }

            if text[index...].hasPrefix("=="),
               let close = text[index...].dropFirst(2).range(of: "==") {
                let contentStart = text.index(index, offsetBy: 2)
                output += "<mark>\(renderText(String(text[contentStart..<close.lowerBound])))</mark>"
                index = close.upperBound
                continue
            }

            if text[index] == "`",
               let close = text[text.index(after: index)..<text.endIndex].firstIndex(of: "`") {
                let contentStart = text.index(after: index)
                output += "<code>\(HTMLEscaping.text(String(text[contentStart..<close])))</code>"
                index = text.index(after: close)
                continue
            }

            if text[index...].hasPrefix("~~"),
               let close = text[index...].dropFirst(2).range(of: "~~") {
                let contentStart = text.index(index, offsetBy: 2)
                output += "<del>\(renderText(String(text[contentStart..<close.lowerBound])))</del>"
                index = close.upperBound
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

    private func renderAutoLink(destination: String) -> String {
        let safeDestination = safeLinkDestination(destination)
        return #"<a href="\#(HTMLEscaping.attribute(safeDestination))">\#(HTMLEscaping.text(destination))</a>"#
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

    private func isEscapable(_ character: Character) -> Bool {
        "\\`*_{}[]()#+-.!".contains(character)
    }
}

private struct ListMarker {
    let indent: Int
    let content: String
    let isOrdered: Bool

    init?(line: String) {
        let indent = line.prefix { $0 == " " || $0 == "\t" }.reduce(0) { total, character in
            total + (character == "\t" ? 4 : 1)
        }
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            return nil
        }

        let prefix = trimmed.prefix(2)
        if prefix == "- " || prefix == "* " || prefix == "+ " {
            self.indent = indent
            isOrdered = false
            content = String(trimmed.dropFirst(2))
            return
        }

        guard let dotIndex = trimmed.firstIndex(of: "."),
              trimmed[trimmed.index(after: dotIndex)..<trimmed.endIndex].first == " "
        else {
            return nil
        }

        let number = trimmed[..<dotIndex]
        guard !number.isEmpty, number.allSatisfy(\.isNumber) else {
            return nil
        }

        self.indent = indent
        isOrdered = true
        content = String(trimmed[trimmed.index(dotIndex, offsetBy: 2)..<trimmed.endIndex])
    }
}

private struct Callout {
    let kind: String
    let title: String
    let bodyLines: [String]

    init?(lines: [String]) {
        guard let first = lines.first?.trimmingCharacters(in: .whitespaces),
              first.hasPrefix("[!"),
              first.hasSuffix("]")
        else {
            return nil
        }

        let rawKind = first.dropFirst(2).dropLast().lowercased()
        guard !rawKind.isEmpty, rawKind.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" }) else {
            return nil
        }

        kind = String(rawKind)
        title = rawKind.split(separator: "-")
            .map { part in part.prefix(1).uppercased() + part.dropFirst() }
            .joined(separator: " ")
        bodyLines = Array(lines.dropFirst())
    }

    func render(inline: MarkdownInlineRenderer) -> String {
        let titleHTML = "<p><strong>\(HTMLEscaping.text(title))</strong></p>"
        let bodyHTML = bodyLines.isEmpty
            ? ""
            : "<p>\(inline.renderText(bodyLines.joined(separator: " ")))</p>"
        return #"<blockquote class="callout callout-\#(HTMLEscaping.attribute(kind))">\#(titleHTML)\#(bodyHTML)</blockquote>"#
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

private func isFenceStart(_ line: String) -> String? {
    if line.hasPrefix("```") {
        return "```"
    }

    if line.hasPrefix("~~~") {
        return "~~~"
    }

    return nil
}

private func isHorizontalRule(_ line: String) -> Bool {
    let compact = line.filter { !$0.isWhitespace }
    guard compact.count >= 3 else {
        return false
    }

    return compact.allSatisfy { $0 == "-" }
        || compact.allSatisfy { $0 == "*" }
        || compact.allSatisfy { $0 == "_" }
}
