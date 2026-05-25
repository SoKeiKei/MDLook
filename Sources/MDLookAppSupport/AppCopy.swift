import Foundation

public enum AppLanguage: String, CaseIterable, Equatable {
    case chinese
    case english

    public var toggled: AppLanguage {
        switch self {
        case .chinese:
            return .english
        case .english:
            return .chinese
        }
    }
}

public struct AppCopy: Equatable {
    public let language: AppLanguage

    public init(language: AppLanguage) {
        self.language = language
    }

    public var subtitle: String {
        switch language {
        case .chinese:
            return "为访达提供 Markdown 文件快速预览。\n本应用仅用于安装、检查和重置 Quick Look 扩展。"
        case .english:
            return "Quick Look Markdown previews for Finder.\nThis app only helps install, inspect, and reset the extension."
        }
    }

    public var toggleLanguageTitle: String {
        switch language {
        case .chinese:
            return "English"
        case .english:
            return "中文"
        }
    }

    public var appTitleLabel: String {
        switch language {
        case .chinese:
            return "主程序"
        case .english:
            return "App"
        }
    }

    public var versionLabel: String {
        switch language {
        case .chinese:
            return "程序版本"
        case .english:
            return "Version"
        }
    }

    public var extensionTitleLabel: String {
        switch language {
        case .chinese:
            return "扩展插件"
        case .english:
            return "Extension"
        }
    }

    public var installedAtTitleLabel: String {
        switch language {
        case .chinese:
            return "安装路径"
        case .english:
            return "Installed At"
        }
    }

    public var unknownValue: String {
        switch language {
        case .chinese:
            return "未知"
        case .english:
            return "Unknown"
        }
    }

    public var openSamplesTitle: String {
        switch language {
        case .chinese:
            return "打开示例文件夹"
        case .english:
            return "Open Samples"
        }
    }

    public var openREADMETitle: String {
        switch language {
        case .chinese:
            return "打开 README"
        case .english:
            return "Open README"
        }
    }

    public var showAppTitle: String {
        switch language {
        case .chinese:
            return "在访达中显示"
        case .english:
            return "Show App in Finder"
        }
    }

    public var copyResetCommandsTitle: String {
        switch language {
        case .chinese:
            return "复制重置命令"
        case .english:
            return "Copy Reset Commands"
        }
    }

    public var renderingToggleTitle: String {
        switch language {
        case .chinese:
            return "启用渲染预览"
        case .english:
            return "Enable Rendered Preview"
        }
    }

    public var renderingEnabledDescription: String {
        switch language {
        case .chinese:
            return "Quick Look 使用 Markdown 渲染后的阅读视图。"
        case .english:
            return "Quick Look uses the rendered Markdown reading view."
        }
    }

    public var renderingDisabledDescription: String {
        switch language {
        case .chinese:
            return "Quick Look 跳过 Markdown 渲染，显示安全转义后的源码视图。"
        case .english:
            return "Quick Look skips Markdown rendering and shows a safely escaped source view."
        }
    }



    public var diagnosticsTitle: String {
        switch language {
        case .chinese:
            return "诊断信息"
        case .english:
            return "Diagnostics"
        }
    }

    public var preferencesPathLabel: String {
        switch language {
        case .chinese:
            return "偏好文件"
        case .english:
            return "Preferences"
        }
    }

    public var renderedStateLabel: String {
        switch language {
        case .chinese:
            return "渲染预览"
        case .english:
            return "Rendered"
        }
    }



    public var enabledValue: String {
        switch language {
        case .chinese:
            return "开启"
        case .english:
            return "On"
        }
    }

    public var disabledValue: String {
        switch language {
        case .chinese:
            return "关闭"
        case .english:
            return "Off"
        }
    }

    public var copyDiagnosticsTitle: String {
        switch language {
        case .chinese:
            return "复制诊断信息"
        case .english:
            return "Copy Diagnostics"
        }
    }

    public var refreshQuickLookTitle: String {
        switch language {
        case .chinese:
            return "刷新 Quick Look"
        case .english:
            return "Refresh Quick Look"
        }
    }

    public var finderPreviewInstruction: String {
        switch language {
        case .chinese:
            return "在访达中选中一个 Markdown 文件，按空格键即可预览。"
        case .english:
            return "Select a Markdown file in Finder and press Space."
        }
    }

    public var resetInstruction: String {
        switch language {
        case .chinese:
            return "若访达仍显示源码，请复制重置命令并在终端中运行。"
        case .english:
            return "If Finder shows source, copy the reset commands and run them in Terminal."
        }
    }

    public var securityInstruction: String {
        switch language {
        case .chinese:
            return "出于安全考虑，网络图片默认关闭，原始 HTML 标签始终被屏蔽。"
        case .english:
            return "Remote images are off by default, and raw HTML is always blocked."
        }
    }

    public var extensionDisabledWarning: String {
        switch language {
        case .chinese:
            return "⚠️ 快速查看扩展未启用：由于 macOS 系统限制，此扩展无法自动启用。您需要手动在「系统设置 -> 通用 -> 登录项与扩展 -> 快速查看」中勾选启用 MDLook 扩展，否则预览无法正常工作。"
        case .english:
            return "⚠️ Quick Look Extension Disabled: Due to macOS security policies, you must manually enable MDLook Extension in 'System Settings -> General -> Login Items & Extensions -> Quick Look' for previews to work."
        }
    }

    public var openSettingsButtonTitle: String {
        switch language {
        case .chinese:
            return "去开启"
        case .english:
            return "Open Settings"
        }
    }
}
