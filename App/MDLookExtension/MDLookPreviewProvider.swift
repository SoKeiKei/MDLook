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
        let previewStartedAt = ContinuousClock.now
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
            let readStartedAt = ContinuousClock.now
            let data = try Data(contentsOf: request.fileURL, options: [.mappedIfSafe])
            let readDuration = readStartedAt.duration(to: .now)
            logger.info("Successfully read file data, bytes: \(data.count), elapsed: \(Self.milliseconds(readDuration))ms")
            
            guard data.count <= maxInputBytes else {
                throw PreviewRenderError.fileTooLarge
            }
            guard let markdown = String(data: data, encoding: .utf8) else {
                throw PreviewRenderError.unsupportedEncoding
            }

            let preferences = AppPreferences()
            guard preferences.isRenderingEnabled else {
                html = PreviewHTMLTemplate.sourceDocument(
                    markdown: markdown,
                    fileName: request.fileURL.lastPathComponent
                )
                let totalDuration = previewStartedAt.duration(to: .now)
                logger.info("Rendered preview disabled; returning Markdown source view, elapsed: \(Self.milliseconds(totalDuration))ms")
                return QLPreviewReply(
                    dataOfContentType: .html,
                    contentSize: CGSize(width: 860, height: 1100)
                ) { reply in
                    reply.stringEncoding = .utf8
                    return html.data(using: .utf8) ?? Data()
                }
            }
            
            let result = try MarkdownRenderer().render(
                RenderRequest(
                    markdown: markdown,
                    sourceFileURL: request.fileURL,
                    maxInputBytes: maxInputBytes,
                    allowsRemoteImages: preferences.allowsRemoteImages
                )
            )
            html = result.html
            let totalDuration = previewStartedAt.duration(to: .now)
            logger.info("Successfully rendered Markdown to HTML, warnings: \(result.warnings.count), elapsed: \(Self.milliseconds(totalDuration))ms")
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

    private static func milliseconds(_ duration: Duration) -> Int64 {
        let components = duration.components
        return components.seconds * 1_000 + Int64(components.attoseconds / 1_000_000_000_000_000)
    }
}
