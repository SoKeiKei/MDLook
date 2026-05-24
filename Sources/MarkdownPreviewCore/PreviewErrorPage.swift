import Foundation

public enum PreviewErrorPage {
    public static func html(for error: PreviewRenderError) -> String {
        let message: String
        switch error {
        case .emptyDocument:
            message = "This Markdown file is empty."
        case .fileTooLarge:
            message = "This Markdown file is too large to preview safely."
        case .unsupportedEncoding:
            message = "This Markdown file is not valid UTF-8."
        case .unreadableFile:
            message = "This Markdown file could not be read."
        case .renderFailed:
            message = "This Markdown file could not be rendered."
        }

        return PreviewHTMLTemplate.document(body: #"<section class="error">\#(HTMLEscaping.text(message))</section>"#)
    }
}

