import Foundation
import QuickLookUI
import UniformTypeIdentifiers

@objc(PreviewProvider)
final class PreviewProvider: QLPreviewProvider {
    private let maxInputBytes = 2_000_000

    func providePreview(
        for request: QLFilePreviewRequest,
        completionHandler handler: @escaping (QLPreviewReply?, Error?) -> Void
    ) {
        let html: String

        do {
            let data = try Data(contentsOf: request.fileURL, options: [.mappedIfSafe])
            guard data.count <= maxInputBytes else {
                throw PreviewRenderError.fileTooLarge
            }
            guard let markdown = String(data: data, encoding: .utf8) else {
                throw PreviewRenderError.unsupportedEncoding
            }
            html = try MarkdownRenderer().render(
                RenderRequest(
                    markdown: markdown,
                    sourceFileURL: request.fileURL,
                    maxInputBytes: maxInputBytes
                )
            ).html
        } catch let error as PreviewRenderError {
            html = PreviewErrorPage.html(for: error)
        } catch {
            html = PreviewErrorPage.html(for: .unreadableFile)
        }

        let reply = QLPreviewReply(
            dataOfContentType: .html,
            contentSize: CGSize(width: 860, height: 1100)
        ) { _ in
            html.data(using: .utf8) ?? Data()
        }

        handler(reply, nil)
    }
}
