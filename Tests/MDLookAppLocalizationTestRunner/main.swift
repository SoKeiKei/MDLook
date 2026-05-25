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

let english = AppCopy(language: .english)
expect(english.subtitle.contains("Finder"), "English subtitle should mention Finder")
expect(english.toggleLanguageTitle == "中文", "English UI should offer switching to Chinese")
expect(english.appTitleLabel == "App", "English status label should be localized")

print("MDLookAppLocalizationTestRunner: all checks passed")
