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
    private var inTableHead = false
    private var tableColumnAlignments: [Table.ColumnAlignment?] = []
    private var currentTableColumn = 0

    init(sourceFileURL: URL) {
        resourceResolver = ResourceResolver(sourceFileURL: sourceFileURL)
    }

    func render(markdown: String) -> ParsedMarkdown {
        let document = Document(parsing: normalizeMarkdownDestinations(markdown))
        let html = visit(document)
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
        let classAttribute = language.flatMap { $0.isEmpty ? nil : $0 }.map {
            #" class="language-\#(HTMLEscaping.attribute($0))""#
        } ?? ""
        let label = language.flatMap { $0.isEmpty ? nil : $0 }.map {
            "<figcaption>\(HTMLEscaping.text($0))</figcaption>"
        } ?? ""
        return #"<figure class="code-block">\#(label)<pre><code\#(classAttribute)>\#(HTMLEscaping.text(codeBlock.code))</code></pre></figure>"#
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
