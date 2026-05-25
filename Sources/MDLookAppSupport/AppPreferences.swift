import Foundation

public final class AppPreferences {
    public static let extensionBundleIdentifier = "com.sokei.MDLook.MDLookExtension"
    public static let renderingEnabledKey = "renderingEnabled"

    private let storageURL: URL

    public convenience init() {
        self.init(storageURL: Self.defaultStorageURL())
    }

    public init(storageURL: URL) {
        self.storageURL = storageURL
    }

    public var isRenderingEnabled: Bool {
        get {
            guard let data = try? Data(contentsOf: storageURL),
                  let values = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Bool],
                  let value = values[Self.renderingEnabledKey] else {
                return true
            }

            return value
        }
        set {
            let values = [Self.renderingEnabledKey: newValue]
            guard let data = try? PropertyListSerialization.data(fromPropertyList: values, format: .xml, options: 0) else {
                return
            }

            try? FileManager.default.createDirectory(
                at: storageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? data.write(to: storageURL, options: .atomic)
        }
    }

    public static func defaultStorageURL() -> URL {
        let bundleIdentifier = Bundle.main.bundleIdentifier
        let libraryURL: URL

        if bundleIdentifier == extensionBundleIdentifier {
            libraryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library")
        } else {
            libraryURL = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Containers")
                .appendingPathComponent(extensionBundleIdentifier)
                .appendingPathComponent("Data/Library")
        }

        return libraryURL
            .appendingPathComponent("Application Support/MDLook")
            .appendingPathComponent("Preferences.plist")
    }
}
