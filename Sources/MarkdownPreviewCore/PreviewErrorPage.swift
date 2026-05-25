import Foundation

public enum PreviewErrorPage {
    public static func html(for error: PreviewRenderError) -> String {
        let message: String
        let guidance: String
        switch error {
        case .emptyDocument:
            message = "This Markdown file is empty."
            guidance = "Add content to the file, then preview it again in Finder."
        case .fileTooLarge:
            message = "This Markdown file is too large to preview safely."
            guidance = "MDLook previews files up to 2 MB. Use rendering source mode or split the document before previewing it."
        case .unsupportedEncoding:
            message = "This Markdown file is not valid UTF-8."
            guidance = "Save it as UTF-8 and reopen Quick Look."
        case .unreadableFile:
            message = "This Markdown file could not be read."
            guidance = "Check that the file still exists and that Finder has permission to access it."
        case .renderFailed:
            message = "This Markdown file could not be rendered."
            guidance = "Try source mode from the MDLook app, then refresh Quick Look."
        }

        return PreviewHTMLTemplate.document(
            body: """
            <section class="error-page">
              <p class="error-kicker">MDLook</p>
              <h1>Preview unavailable</h1>
              <p>\(HTMLEscaping.text(message))</p>
              <p class="error-guidance">\(HTMLEscaping.text(guidance))</p>
            </section>
            """
        )
    }
}
