import SwiftUI
import AppKit

struct ContentView: View {
    @State private var language: AppLanguage = .chinese

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

    private var copy: AppCopy {
        AppCopy(language: language)
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
        HStack(alignment: .top, spacing: 18) {
            appIcon

            VStack(alignment: .leading, spacing: 6) {
                Text("MDLook")
                    .font(.system(size: 30, weight: .semibold))

                Text(copy.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 16)

            Button {
                language = language.toggled
            } label: {
                Label(copy.toggleLanguageTitle, systemImage: "globe")
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
        }
    }

    private var appIcon: some View {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .interpolation(.high)
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            InfoRow(title: copy.appTitleLabel, value: Bundle.main.bundleIdentifier ?? copy.unknownValue)
            InfoRow(title: copy.extensionTitleLabel, value: extensionBundleID)
            InfoRow(title: copy.installedAtTitleLabel, value: Bundle.main.bundleURL.path)
        }
    }

    private var actionGrid: some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                ActionButton(title: copy.openSamplesTitle, systemImage: "folder", action: openSamples)
                ActionButton(title: copy.openREADMETitle, systemImage: "book", action: openREADME)
            }

            GridRow {
                ActionButton(title: copy.showAppTitle, systemImage: "app", action: showAppInFinder)
                ActionButton(title: copy.copyResetCommandsTitle, systemImage: "doc.on.doc", action: copyResetCommands)
            }
        }
    }

    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(copy.finderPreviewInstruction, systemImage: "space")
            Label(copy.resetInstruction, systemImage: "arrow.clockwise")
            Label(copy.securityInstruction, systemImage: "lock.shield")
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
                .frame(width: 72, alignment: .leading)

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
