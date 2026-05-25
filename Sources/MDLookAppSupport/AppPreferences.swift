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
            boolValue(forKey: Self.renderingEnabledKey, defaultValue: true)
        }
        set {
            setBoolValue(newValue, forKey: Self.renderingEnabledKey)
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

    public var storageDescription: String {
        storageURL.path
    }

    private func boolValue(forKey key: String, defaultValue: Bool) -> Bool {
        guard let values = readValues(),
              let value = values[key] else {
            return defaultValue
        }

        return value
    }

    private func setBoolValue(_ value: Bool, forKey key: String) {
        var values = readValues() ?? [:]
        values[key] = value

        guard let data = try? PropertyListSerialization.data(fromPropertyList: values, format: .xml, options: 0) else {
            return
        }

        try? FileManager.default.createDirectory(
            at: storageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: storageURL, options: .atomic)
    }

    private func readValues() -> [String: Bool]? {
        guard let data = try? Data(contentsOf: storageURL) else {
            return nil
        }

        return try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Bool]
    }
}
