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
expect(chinese.appTitleLabel == "主程序", "Chinese status label should be localized")
expect(chinese.renderingToggleTitle == "启用渲染预览", "Chinese rendering toggle title should be localized")
expect(chinese.renderingEnabledDescription.contains("Markdown 渲染"), "Chinese enabled rendering description should be localized")
expect(chinese.remoteImagesToggleTitle == "允许网络图片", "Chinese remote image toggle title should be localized")
expect(chinese.remoteImagesDisabledDescription.contains("默认屏蔽"), "Chinese remote image disabled description should be localized")
expect(chinese.showAppTitle == "在访达中显示", "Chinese action should keep show app")
expect(chinese.copyResetCommandsTitle == "复制重置命令", "Chinese action should keep reset commands")

let english = AppCopy(language: .english)
expect(english.subtitle.contains("Finder"), "English subtitle should mention Finder")
expect(english.toggleLanguageTitle == "中文", "English UI should offer switching to Chinese")
expect(english.appTitleLabel == "App", "English status label should be localized")
expect(english.renderingToggleTitle == "Enable Rendered Preview", "English rendering toggle title should be localized")
expect(english.renderingDisabledDescription.contains("source view"), "English disabled rendering description should be localized")
expect(english.remoteImagesToggleTitle == "Allow Remote Images", "English remote image toggle title should be localized")
expect(english.remoteImagesEnabledDescription.contains("http"), "English remote image enabled description should mention remote schemes")
expect(english.showAppTitle == "Show App in Finder", "English action should be clearer")
expect(english.copyResetCommandsTitle == "Copy Reset Commands", "English action should keep reset commands")

let preferencesURL = FileManager.default.temporaryDirectory
    .appendingPathComponent("MDLookAppPreferences-\(UUID().uuidString)")
    .appendingPathExtension("plist")
let preferences = AppPreferences(storageURL: preferencesURL)
expect(preferences.isRenderingEnabled, "rendering should be enabled by default")
expect(!preferences.allowsRemoteImages, "remote images should be disabled by default")
preferences.isRenderingEnabled = false
preferences.allowsRemoteImages = true
expect(!preferences.isRenderingEnabled, "rendering disabled value should persist")
expect(preferences.allowsRemoteImages, "remote image enabled value should persist")
let reloadedPreferences = AppPreferences(storageURL: preferencesURL)
expect(!reloadedPreferences.isRenderingEnabled, "rendering disabled value should persist across instances")
expect(reloadedPreferences.allowsRemoteImages, "remote image enabled value should persist across instances")

print("MDLookAppLocalizationTestRunner: all checks passed")
