import Foundation

public struct RenderRequest {
    public let markdown: String
    public let sourceFileURL: URL
    public let maxInputBytes: Int
    public let allowsRemoteImages: Bool

    public init(markdown: String, sourceFileURL: URL, maxInputBytes: Int, allowsRemoteImages: Bool = false) {
        self.markdown = markdown
        self.sourceFileURL = sourceFileURL
        self.maxInputBytes = maxInputBytes
        self.allowsRemoteImages = allowsRemoteImages
    }
}

public struct RenderResult {
    public let html: String
    public let warnings: [RenderWarning]

    public init(html: String, warnings: [RenderWarning]) {
        self.html = html
        self.warnings = warnings
    }
}

public enum RenderWarning: Equatable {
    case blockedRemoteResource(String)
    case missingLocalImage(String)
    case rawHTMLRemoved
}

public protocol MarkdownRendering {
    func render(_ request: RenderRequest) throws -> RenderResult
}

public enum PreviewRenderError: Error, Equatable {
    case emptyDocument
    case fileTooLarge
    case unsupportedEncoding
    case unreadableFile
    case renderFailed
}
