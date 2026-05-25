import Foundation
import MDLookAppSupport

@discardableResult
private func expect(_ condition: @autoclosure () -> Bool, _ message: String) -> Bool {
    if !condition() {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }

    return true
}

let chinese = AppCopy(language: .chinese)
expect(chinese.subtitle.contains("访达"), "Chinese subtitle should mention Finder in Chinese")
expect(chinese.toggleLanguageTitle == "English", "Chinese UI should offer switching to English")
expect(chinese.openGitHubTitle == "GitHub", "Chinese GitHub action should stay branded")
expect(chinese.appTitleLabel == "主程序", "Chinese status label should be localized")
expect(chinese.versionLabel == "程序版本", "Chinese version label should be localized")
expect(chinese.renderingToggleTitle == "启用渲染预览", "Chinese rendering toggle title should be localized")
expect(chinese.renderingEnabledDescription.contains("Markdown 渲染"), "Chinese enabled rendering description should be localized")

expect(chinese.diagnosticsTitle == "诊断信息", "Chinese diagnostics title should be localized")
expect(chinese.copyDiagnosticsTitle == "复制诊断信息", "Chinese diagnostics copy action should be localized")
expect(chinese.refreshQuickLookTitle == "刷新 Quick Look", "Chinese refresh action should be localized")
expect(chinese.showAppTitle == "在访达中显示", "Chinese action should keep show app")
expect(chinese.copyResetCommandsTitle == "复制重置命令", "Chinese action should keep reset commands")

let english = AppCopy(language: .english)
expect(english.subtitle.contains("Finder"), "English subtitle should mention Finder")
expect(english.toggleLanguageTitle == "中文", "English UI should offer switching to Chinese")
expect(english.openGitHubTitle == "GitHub", "English GitHub action should stay branded")
expect(english.appTitleLabel == "App", "English status label should be localized")
expect(english.versionLabel == "Version", "English version label should be localized")
expect(english.renderingToggleTitle == "Enable Rendered Preview", "English rendering toggle title should be localized")
expect(english.renderingDisabledDescription.contains("source view"), "English disabled rendering description should be localized")

expect(english.diagnosticsTitle == "Diagnostics", "English diagnostics title should be localized")
expect(english.copyDiagnosticsTitle == "Copy Diagnostics", "English diagnostics copy action should be localized")
expect(english.refreshQuickLookTitle == "Refresh Quick Look", "English refresh action should be localized")
expect(english.showAppTitle == "Show App in Finder", "English action should be clearer")
expect(english.copyResetCommandsTitle == "Copy Reset Commands", "English action should keep reset commands")
expect(english.dismissButtonTitle == "OK", "English dismiss button should be localized")
expect(english.commandLaunchFailedLabel == "failed to launch", "English launch failure label should be localized")
expect(english.commandExitedWithStatusLabel == "exited with status", "English exit status label should be localized")
expect(english.noCommandOutputLabel == "no output", "English empty output label should be localized")

expect(chinese.dismissButtonTitle == "知道了", "Chinese dismiss button should be localized")
expect(chinese.commandLaunchFailedLabel == "启动失败", "Chinese launch failure label should be localized")
expect(chinese.commandExitedWithStatusLabel == "退出状态", "Chinese exit status label should be localized")
expect(chinese.noCommandOutputLabel == "无输出", "Chinese empty output label should be localized")

let preferencesURL = FileManager.default.temporaryDirectory
    .appendingPathComponent("MDLookAppPreferences-\(UUID().uuidString)")
    .appendingPathExtension("plist")
let preferences = AppPreferences(storageURL: preferencesURL)
expect(preferences.isRenderingEnabled, "rendering should be enabled by default")

preferences.isRenderingEnabled = false

expect(!preferences.isRenderingEnabled, "rendering disabled value should persist")

let reloadedPreferences = AppPreferences(storageURL: preferencesURL)
expect(!reloadedPreferences.isRenderingEnabled, "rendering disabled value should persist across instances")

do {
    var recordedCommands: [QuickLookCommand] = []
    let refresher = QuickLookRefresher { command in
        recordedCommands.append(command)
        return .init(output: "", terminationStatus: 0)
    }

    try refresher.refresh()

    expect(
        recordedCommands == QuickLookRefresher.refreshCommands,
        "Quick Look refresher should execute commands in the documented order"
    )
} catch {
    fputs("FAIL: expected quick look refresher success, got \(error)\n", stderr)
    exit(1)
}

do {
    let refresher = QuickLookRefresher { command in
        if command == QuickLookRefresher.refreshCommands[1] {
            return .init(output: "cache reset failed", terminationStatus: 1)
        }
        return .init(output: "", terminationStatus: 0)
    }

    try refresher.refresh()
    fputs("FAIL: expected quick look refresher to throw on non-zero exit\n", stderr)
    exit(1)
} catch let error as CommandExecutionError {
    switch error {
    case let .nonZeroExit(command, status, output):
        expect(command == QuickLookRefresher.refreshCommands[1], "non-zero exit should point at the failing command")
        expect(status == 1, "non-zero exit should preserve the termination status")
        expect(output == "cache reset failed", "non-zero exit should preserve command output")
    default:
        fputs("FAIL: expected non-zero exit error, got \(error)\n", stderr)
        exit(1)
    }
} catch {
    fputs("FAIL: expected command execution error, got \(error)\n", stderr)
    exit(1)
}


print("MDLookAppLocalizationTestRunner: all checks passed")
