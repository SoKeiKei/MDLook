import SwiftUI
import AppKit

struct ContentView: View {
    private let extensionBundleID = "com.sokei.MDLook.MDLookExtension"
    private let resetCommands = """
    pluginkit -e use -i com.sokei.MDLook.MDLookExtension
    qlmanage -r
    qlmanage -r cache
    killall Finder
    """
    private var repositoryURL: URL? {
        let candidates = [
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
            Bundle.main.bundleURL.deletingLastPathComponent()
        ]

        return candidates.first { candidate in
            FileManager.default.fileExists(atPath: candidate.appendingPathComponent("README.md").path)
                && FileManager.default.fileExists(atPath: candidate.appendingPathComponent("Samples").path)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header

            statusSection

            Divider()

            actionGrid

            Divider()

            verificationSection
        }
        .padding(32)
        .frame(width: 680, alignment: .leading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MDLook")
                .font(.system(size: 30, weight: .semibold))

            Text("Quick Look Markdown previews for Finder. This app only helps install, inspect, and reset the extension.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            InfoRow(title: "App", value: Bundle.main.bundleIdentifier ?? "Unknown")
            InfoRow(title: "Extension", value: extensionBundleID)
            InfoRow(title: "Installed At", value: Bundle.main.bundleURL.path)
        }
    }

    private var actionGrid: some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                ActionButton(title: "Open Samples", systemImage: "folder", action: openSamples)
                ActionButton(title: "Open README", systemImage: "book", action: openREADME)
            }

            GridRow {
                ActionButton(title: "Show App", systemImage: "app", action: showAppInFinder)
                ActionButton(title: "Copy Reset Commands", systemImage: "doc.on.doc", action: copyResetCommands)
            }
        }
    }

    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Select a Markdown file in Finder and press Space.", systemImage: "space")
            Label("If Finder shows source, copy the reset commands and run them in Terminal.", systemImage: "arrow.clockwise")
            Label("Remote images and raw HTML are blocked by design.", systemImage: "lock.shield")
        }
        .labelStyle(.titleAndIcon)
        .foregroundStyle(.secondary)
    }

    private func openSamples() {
        openRepositoryPath("Samples", fallback: Bundle.main.bundleURL.deletingLastPathComponent())
    }

    private func openREADME() {
        openRepositoryPath("README.md", fallback: Bundle.main.bundleURL)
    }

    private func showAppInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }

    private func copyResetCommands() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(resetCommands, forType: .string)
    }

    private func openRepositoryPath(_ relativePath: String, fallback: URL) {
        guard let repositoryURL else {
            NSWorkspace.shared.open(fallback)
            return
        }

        NSWorkspace.shared.open(repositoryURL.appendingPathComponent(relativePath))
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(2)
        }
    }
}

private struct ActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(width: 210, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}

#Preview {
    ContentView()
}
