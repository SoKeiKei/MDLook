import SwiftUI
import AppKit

struct ContentView: View {
    @State private var language: AppLanguage = .chinese
    @State private var isRenderingEnabled = AppPreferences().isRenderingEnabled
    @State private var isExtensionEnabled = false

    private let extensionBundleID = "com.sokei.MDLook.MDLookExtension"
    private let resetCommands = """
    pluginkit -e use -i com.sokei.MDLook.MDLookExtension
    qlmanage -r
    qlmanage -r cache
    killall Finder
    """
    private var copy: AppCopy {
        AppCopy(language: language)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header

            if !isExtensionEnabled {
                warningCard
            }

            statusSection

            Divider()

            renderingSection

            Divider()

            actionGrid

            Divider()

            verificationSection
        }
        .padding(24)
        .frame(width: 580, alignment: .leading)
        .task(id: isExtensionEnabled) {
            if isExtensionEnabled { return }
            checkExtensionStatus()
            if isExtensionEnabled { return }
            
            // 启动定时器轮询任务，并在主线程上执行
            let timerTask = Task { @MainActor in
                while !Task.isCancelled {
                    do {
                        try await Task.sleep(nanoseconds: 3_000_000_000)
                        checkExtensionStatus()
                    } catch {
                        break
                    }
                }
            }
            
            defer {
                timerTask.cancel()
            }
            
            // 监听窗口激活事件（切回 App 时即时检测）
            for await _ in NotificationCenter.default.notifications(named: NSApplication.willBecomeActiveNotification) {
                checkExtensionStatus()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 18) {
            appIcon

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .bottom, spacing: 8) {
                    Text("MDLook")
                        .font(.system(size: 30, weight: .semibold))
                    Text("v1.0")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)
                }

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

    private var warningCard: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(copy.extensionDisabledWarning)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 12)
            
            Button(action: openExtensionSettings) {
                Text(copy.openSettingsButtonTitle)
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.regular)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.red.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.red.opacity(0.25), lineWidth: 1)
        )
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            InfoRow(title: copy.appTitleLabel, value: Bundle.main.bundleIdentifier ?? copy.unknownValue)
            InfoRow(
                title: copy.extensionTitleLabel,
                value: extensionBundleID,
                statusText: isExtensionEnabled ? copy.enabledValue : copy.disabledValue,
                statusColor: isExtensionEnabled ? .green : .red
            )
            InfoRow(title: copy.installedAtTitleLabel, value: Bundle.main.bundleURL.path)
            InfoRow(title: copy.versionLabel, value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
        }
    }

    private var actionGrid: some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                ActionButton(title: copy.showAppTitle, systemImage: "app", action: showAppInFinder)
                ActionButton(title: copy.copyResetCommandsTitle, systemImage: "doc.on.doc", action: copyResetCommands)
            }
            GridRow {
                ActionButton(title: copy.copyDiagnosticsTitle, systemImage: "stethoscope", action: copyDiagnostics)
                ActionButton(title: copy.refreshQuickLookTitle, systemImage: "arrow.clockwise", action: refreshQuickLook)
            }
        }
    }

    private var renderingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $isRenderingEnabled) {
                Text(copy.renderingToggleTitle)
            }
            .toggleStyle(.switch)
            .onChange(of: isRenderingEnabled) { _, newValue in
                AppPreferences().isRenderingEnabled = newValue
            }

            Text(isRenderingEnabled ? copy.renderingEnabledDescription : copy.renderingDisabledDescription)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
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



    private func showAppInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }

    private func copyResetCommands() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(resetCommands, forType: .string)
    }

    private func copyDiagnostics() {
        let statusOutput = runAndGetOutput("/usr/bin/pluginkit", arguments: ["-m", "-i", extensionBundleID])
        let diagnostics = """
        MDLook Diagnostics
        App Bundle: \(Bundle.main.bundleURL.path)
        App Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")
        Extension Bundle ID: \(extensionBundleID)
        Preferences: \(AppPreferences.defaultStorageURL().path)
        Rendered Preview: \(isRenderingEnabled)
        Extension Status Output:
        \(statusOutput)
        Reset Commands:
        \(resetCommands)
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(diagnostics, forType: .string)
    }

    private func refreshQuickLook() {
        run("/usr/bin/qlmanage", arguments: ["-r"])
        run("/usr/bin/qlmanage", arguments: ["-r", "cache"])
        run("/usr/bin/killall", arguments: ["Finder"])
    }

    private func run(_ executable: String, arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        try? process.run()
    }

    private func runAndGetOutput(_ executable: String, arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? "no utf8 output"
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }

    private func checkExtensionStatus() {
        let output = runAndGetOutput("/usr/bin/pluginkit", arguments: ["-m", "-i", extensionBundleID])
        // pluginkit 输出的前缀含义：
        //   +  明确启用（用户手动勾选或 pluginkit -e use）
        //   ?  系统默认状态（首次安装后自动注册，实际正常工作）
        //   -  明确禁用（用户手动关闭或 pluginkit -e ignore）
        // 因此：只要 bundle ID 存在于输出中，且对应行不是 "-" 状态，即视为已启用。
        let lines = output.components(separatedBy: .newlines)
        let matchedLine = lines.first { $0.contains(extensionBundleID) }
        if let line = matchedLine {
            isExtensionEnabled = !line.hasPrefix("-")
        } else {
            isExtensionEnabled = false
        }
    }

    private func openExtensionSettings() {
        let urlString = "x-apple.systempreferences:com.apple.ExtensionsPreferences"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

private struct InfoRow: View {
    let title: String
    let value: String
    var statusText: String? = nil
    var statusColor: Color = .primary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(width: 92, alignment: .leading)

            HStack(alignment: .center, spacing: 6) {
                Text(value)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(2)
                
                if let statusText = statusText {
                    Text(statusText)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.12))
                        .foregroundColor(statusColor)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
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
