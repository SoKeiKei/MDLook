import Foundation

struct ResourceResolver {
    private let sourceFileURL: URL

    init(sourceFileURL: URL) {
        self.sourceFileURL = sourceFileURL
    }

    func resolveImage(_ rawPath: String) -> ImageResolution {
        guard let components = URLComponents(string: rawPath),
              let scheme = components.scheme?.lowercased(),
              !scheme.isEmpty
        else {
            return resolveLocalImage(rawPath)
        }

        if scheme == "http" || scheme == "https" {
            return .blockedRemote(rawPath)
        }

        if scheme == "file" {
            return .blockedRemote(rawPath)
        }

        return .blockedRemote(rawPath)
    }

    private func resolveLocalImage(_ rawPath: String) -> ImageResolution {
        let baseDirectory = sourceFileURL.deletingLastPathComponent()
        let path = rawPath.removingPercentEncoding ?? rawPath
        let candidate = URL(fileURLWithPath: path, relativeTo: baseDirectory)
            .standardizedFileURL
            .resolvingSymlinksInPath()
        let basePath = baseDirectory.standardizedFileURL.resolvingSymlinksInPath().path
        guard candidate.path == basePath || candidate.path.hasPrefix(basePath + "/") else {
            return .blockedRemote(path)
        }

        guard FileManager.default.fileExists(atPath: candidate.path) else {
            return .missing(path)
        }

        return .local(candidate)
    }
}

enum ImageResolution {
    case local(URL)
    case remote(String)
    case missing(String)
    case blockedRemote(String)
}
