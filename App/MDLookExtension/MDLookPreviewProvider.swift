import Foundation
import QuickLookUI
import UniformTypeIdentifiers
import OSLog

private let logger = Logger(subsystem: "com.sokei.MDLook", category: "Extension")

@objc(MDLookPreviewProvider)
public final class MDLookPreviewProvider: QLPreviewProvider, QLPreviewingController {
    private let maxInputBytes = 2_000_000

    @objc(providePreviewForFileRequest:completionHandler:)
    public func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        logger.info("providePreview called for: \(request.fileURL.lastPathComponent)")
        
        let html: String
        let accessSecurityScoped = request.fileURL.startAccessingSecurityScopedResource()
        logger.info("Access security scoped resource: \(accessSecurityScoped)")
        
        defer {
            if accessSecurityScoped {
                request.fileURL.stopAccessingSecurityScopedResource()
                logger.info("Stopped accessing security scoped resource")
            }
        }
        
        do {
            let data = try Data(contentsOf: request.fileURL, options: [.mappedIfSafe])
            logger.info("Successfully read file data, bytes: \(data.count)")
            
            guard data.count <= maxInputBytes else {
                throw PreviewRenderError.fileTooLarge
            }
            guard let markdown = String(data: data, encoding: .utf8) else {
                throw PreviewRenderError.unsupportedEncoding
            }
            
            let result = try MarkdownRenderer().render(
                RenderRequest(
                    markdown: markdown,
                    sourceFileURL: request.fileURL,
                    maxInputBytes: maxInputBytes
                )
            )
            html = result.html
            logger.info("Successfully rendered Markdown to HTML, warnings: \(result.warnings.count)")
        } catch let error as PreviewRenderError {
            logger.error("PreviewRenderError: \(String(describing: error))")
            html = PreviewErrorPage.html(for: error)
        } catch {
            logger.error("Failed to read/render file: \(error.localizedDescription)")
            html = PreviewErrorPage.html(for: .unreadableFile)
        }

        return QLPreviewReply(
            dataOfContentType: .html,
            contentSize: CGSize(width: 860, height: 1100)
        ) { reply in
            reply.stringEncoding = .utf8
            return html.data(using: .utf8) ?? Data()
        }
    }
}
