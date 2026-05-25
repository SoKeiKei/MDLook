# MDLook

[English](#english) | 中文

**MDLook** 是一个轻量的 macOS Markdown 快速预览扩展（Quick Look Extension）。在访达（Finder）中选中任意 `.md` 文件，按下**空格键**，即可立刻获得排版精美、安全可靠的阅读视图——无需打开任何编辑器，不占用任何后台资源。

---

## ✨ 为什么选择 MDLook

| | MDLook |
|---|---|
| **体积** | 轻量，无任何第三方运行时依赖 |
| **性能** | 纯 Swift 渲染，零 JavaScript 执行，瞬间出图 |
| **安全** | 完全沙盒隔离，自动剔除 XSS 攻击向量 |
| **隐私** | 不联网，所有渲染均在本机完成 |
| **外观** | 自动适配 macOS 亮色 / 暗色模式 |
| **免费** | MIT 开源，永久免费 |

---

## 💻 系统要求

> [!IMPORTANT]
> **仅支持搭载 Apple Silicon 芯片（M 系列）的 Mac。**
> 未对 Intel 芯片进行适配，亦未在低于 macOS 15 Sequoia 的系统上进行测试，不保证兼容性。

- **芯片**：Apple Silicon（M1 及以上）
- **系统**：macOS 15 Sequoia 或更高版本（推荐最新正式版）

---

## 🚀 快速安装

1. 前往 [Releases](../../releases) 下载最新的 `MDLook.dmg`。
2. 打开 DMG，将 `MDLook.app` 拖入「应用程序」文件夹。
3. 双击打开 `MDLook.app`，完成扩展注册。

> [!NOTE]
> 当前发布包为开源测试分发版本，**未做 Apple Developer 签名或 notarization**。
> macOS 首次打开时可能提示来源未验证；如遇拦截，请在访达中对 `MDLook.app` 右键选择“打开”，或前往系统设置中手动放行。

> [!IMPORTANT]
> **必须手动开启扩展**：由于 macOS 安全策略限制，系统无法自动启用第三方 Quick Look 扩展。安装后请前往：
>
> **「系统设置 → 通用 → 登录项与扩展 → 快速查看」**，找到 **MDLookExtension** 并打开开关。
>
> 若未开启，访达中的空格键预览将无效，且 MDLook 应用内会显示红色提示引导您完成这一步骤。

---

## 📖 核心特性

### 🎨 精致阅读排版
- 正文与标题限制 `720px` 黄金阅读宽度，代码块与表格延伸至 `860px`，形成类 Notion / Medium 的错落层次感。
- 字号 `16px`、行高 `1.75`、字距 `0.02em`，减少长文阅读疲劳。

### 📊 阅读数据徽章
- 文章顶部自动显示字数与预计阅读时间（SVG 矢量图标）。
- 中英文混合统计：CJK 字符按字符数计，英文按单词数计，精准兼容中英混排。

### ✏️ 高雅排版样式
- `==高亮==`：纸质书荧光笔底边划线效果，亮 / 暗色模式自动切换。
- `blockquote`：圆角淡色背景 + 左侧着色细边 + 斜体文字。
- GFM Callouts：完整支持 `[!NOTE]` `[!TIP]` `[!IMPORTANT]` `[!WARNING]` `[!CAUTION]`。
- 脚注：自动收集并渲染在文章底部。

### 💻 静态代码高亮（零 JavaScript）
- 纯 Swift 状态机分词，不加载任何外部脚本，沙盒内完全安全。
- 支持：**Swift、JSON、YAML、Bash/Shell、JavaScript/TypeScript、Python、HTML/XML、CSS**。
- LaTeX 公式（`$...$` 行内 / `$$...$$` 块级）：安全卡片预览。
- Mermaid：展示高亮源码 + 安全提示（沙盒内不执行 JS 画图）。

### 🔒 安全防护
- 自动剔除所有 `<script>` 标签与 XSS 攻击向量。
- 默认拦截所有网络图片，防止 IP / 隐私泄露。
- 拒绝 `file://` 外部图片协议。
- 超过 2 MB 的文件自动降级为纯文本安全视图。

---

## 🗂️ 项目结构

```
MDLook/
├── App/
│   ├── MDLook/                        # 宿主 App（SwiftUI）
│   │   ├── MDLookApp.swift            # App 入口
│   │   ├── ContentView.swift          # 主界面：状态检测、警告卡片、操作按钮
│   │   └── Assets.xcassets/           # 图标资源
│   └── MDLookExtension/               # Quick Look 扩展
│       └── MDLookPreviewProvider.swift # 扩展入口，调用渲染引擎
├── Sources/
│   ├── MarkdownPreviewCore/           # 核心渲染引擎（Swift Package）
│   │   ├── MarkdownRenderer.swift     # Markdown → HTML 主渲染器
│   │   ├── PreviewHTMLTemplate.swift  # HTML 模板与 CSS 样式表
│   │   ├── ResourceResolver.swift     # 本地资源路径解析
│   │   ├── HTMLEscaping.swift         # HTML 安全转义工具
│   │   ├── PreviewErrorPage.swift     # 降级错误页面
│   │   └── Models.swift               # 数据模型
│   └── MDLookAppSupport/              # 宿主 App 共享库
│       ├── AppCopy.swift              # 中英文 UI 文案
│       ├── AppPreferences.swift       # 用户偏好（渲染开关等）
│       └── QuickLookRefresher.swift   # Quick Look 刷新命令执行器
├── Tests/
│   ├── MarkdownPreviewCoreTestRunner/ # 核心渲染引擎单元测试
│   └── MDLookAppLocalizationTestRunner/ # 共享文案与偏好/刷新逻辑测试
├── Samples/
│   ├── regression.md                  # 全特性回归测试文档 ★
│   ├── images.md                      # 图片路径与安全拦截测试
│   ├── large.md                       # 超大文件降级测试
│   ├── real-world-readme.md           # 真实项目 README 渲染测试
│   └── assets/                        # 测试用图片资源
├── Scripts/
│   ├── install-dev.sh                 # 开发构建 & 安装脚本
│   ├── build-release.sh               # 打包 ZIP / DMG 发布脚本
│   └── uninstall.sh                   # 完整卸载脚本
├── Package.swift                      # Swift Package 定义
├── project.yml                        # XcodeGen 工程配置
└── README.md
```

---

## 🛠️ 本地开发

### 环境准备
```sh
brew install xcodegen
xcodegen generate
open MDLook.xcodeproj
```

### 编译 & 安装（开发用）
```sh
Scripts/install-dev.sh
```
仅编译并拷贝到 `/Applications/MDLook.app`，不自动操作扩展开关，方便手动测试。

### 编译核心库 & 运行测试
```sh
swift build
swift run MarkdownPreviewCoreTestRunner
swift run MDLookAppLocalizationTestRunner
```

### 刷新机制
- “刷新 Quick Look” 按钮通过 `QuickLookRefresher` 串行执行 `qlmanage -r`、`qlmanage -r cache` 与 `killall Finder`，并把失败结果反馈回 UI。

### 打包发布包（ZIP & DMG）
```sh
Scripts/build-release.sh
```
产物输出至 `dist/MDLook.zip` 和 `dist/MDLook.dmg`。
生成的 DMG 会排好拖拽安装布局，但默认仍是**未签名、未 notarize** 的开源测试包。

### 完整卸载
```sh
Scripts/uninstall.sh
```
注销扩展、清理偏好设置、删除应用包与本地 Debug 构建副本、刷新 Finder 缓存。

---

## 🔍 功能验证

在访达中选中以下示例文件并按**空格键**：

- [Samples/regression.md](Samples/regression.md)：**全特性回归测试文档**，涵盖 9 种代码高亮、数学公式、GFM Callouts、脚注、荧光笔标记、安全拦截等所有渲染特性。
- [Samples/images.md](Samples/images.md)：验证含空格、中文路径的本地图片及网络图片安全拦截。

---

## 📄 开源许可

本项目基于 **MIT 许可证** 开源，详见 [LICENSE](LICENSE)。

---
---

<a id="english"></a>

# MDLook (English)

[中文](#mdlook) | English

**MDLook** is a lightweight macOS Quick Look Extension for Markdown files. Select any `.md` file in Finder and press **Space** — get a beautifully formatted, secure reading view instantly. No editor needed, zero background resource usage.

---

## ✨ Why MDLook

| | MDLook |
|---|---|
| **Size** | Lightweight — no third-party runtime dependencies |
| **Performance** | Pure Swift rendering, zero JavaScript execution, instant preview |
| **Security** | Full sandbox isolation, automatic XSS vector removal |
| **Privacy** | Fully offline — all rendering happens on-device |
| **Appearance** | Adapts automatically to Light and Dark mode |
| **Price** | Free and open source (MIT) |

---

## 💻 System Requirements

> [!IMPORTANT]
> **Apple Silicon (M-series) Macs only.**
> Intel chips are not supported. Compatibility with macOS versions below macOS 15 Sequoia has not been tested and is not guaranteed.

- **Chip**: Apple Silicon (M1 or later)
- **OS**: macOS 15 Sequoia or later (latest release recommended)

---

## 🚀 Installation

1. Download the latest `MDLook.dmg` from [Releases](../../releases).
2. Open the DMG and drag `MDLook.app` into your Applications folder.
3. Launch `MDLook.app` once to register the extension.

> [!NOTE]
> Current release artifacts are open-source test builds and are **not signed with an Apple Developer certificate or notarized**.
> On first launch, macOS may warn that the app cannot be verified. If that happens, right-click `MDLook.app` in Finder and choose "Open", or allow it manually in System Settings.

> [!IMPORTANT]
> **Manual activation required**: Due to macOS security policies, third-party Quick Look extensions cannot be auto-enabled. After installation, go to:
>
> **System Settings → General → Login Items & Extensions → Quick Look**
>
> and toggle on **MDLookExtension**. If not enabled, pressing Space in Finder won't show the preview. The MDLook app will display a red warning banner guiding you through this step.

---

## 📖 Features

### 🎨 Refined Typography
- Body text and headings constrained to a `720px` optimal reading width; code blocks and tables extend to `860px` — a Notion / Medium-style layered layout.
- `16px` body size, `1.75` line height, `0.02em` letter spacing to reduce reading fatigue.

### 📊 Reading Stats Badge
- Word count and estimated reading time rendered at the top of each document with crisp SVG icons.
- Accurate CJK + English mixed counting: CJK characters counted individually, English words counted by whitespace tokens.

### ✏️ Elegant Visual Styles
- `==highlight==`: Book-style highlighter underline effect with Light/Dark mode support.
- `blockquote`: Soft rounded background, colored left border, italicized text.
- GFM Callouts: Full support for `[!NOTE]` `[!TIP]` `[!IMPORTANT]` `[!WARNING]` `[!CAUTION]`.
- Footnotes: Auto-collected and rendered at the bottom of the document.

### 💻 Static Syntax Highlighting (Zero JavaScript)
- Pure Swift state-machine lexer — no external scripts loaded, fully sandbox-safe.
- Supported: **Swift, JSON, YAML, Bash/Shell, JavaScript/TypeScript, Python, HTML/XML, CSS**.
- LaTeX (`$...$` inline / `$$...$$` block): Safe card-style preview.
- Mermaid: Highlighted source preview with security notice (JS diagram execution disabled in sandbox).

### 🔒 Security
- All `<script>` tags and XSS vectors are stripped automatically.
- Remote images blocked by default to protect IP and privacy.
- `file://` external image URLs are rejected.
- Files exceeding 2 MB gracefully degrade to a safe plain-text view.

---

## 🗂️ Project Structure

```
MDLook/
├── App/
│   ├── MDLook/                        # Host app (SwiftUI)
│   │   ├── MDLookApp.swift            # App entry point
│   │   ├── ContentView.swift          # Main UI: status detection, warning card, actions
│   │   └── Assets.xcassets/           # App icon assets
│   └── MDLookExtension/               # Quick Look Extension target
│       └── MDLookPreviewProvider.swift # Extension entry, calls rendering engine
├── Sources/
│   ├── MarkdownPreviewCore/           # Core rendering engine (Swift Package)
│   │   ├── MarkdownRenderer.swift     # Markdown → HTML main renderer
│   │   ├── PreviewHTMLTemplate.swift  # HTML template and CSS stylesheet
│   │   ├── ResourceResolver.swift     # Local resource path resolution
│   │   ├── HTMLEscaping.swift         # HTML safety escaping utilities
│   │   ├── PreviewErrorPage.swift     # Graceful degradation error page
│   │   └── Models.swift               # Data models
│   └── MDLookAppSupport/              # Shared host-app library
│       ├── AppCopy.swift              # Bilingual UI copy (zh/en)
│       ├── AppPreferences.swift       # User preferences (rendering toggle etc.)
│       └── QuickLookRefresher.swift   # Quick Look refresh command runner
├── Tests/
│   ├── MarkdownPreviewCoreTestRunner/ # Core renderer unit tests
│   └── MDLookAppLocalizationTestRunner/ # Shared copy / preferences / refresh tests
├── Samples/
│   ├── regression.md                  # Full-feature regression test document ★
│   ├── images.md                      # Image path and security blocking tests
│   ├── large.md                       # Large file degradation test
│   ├── real-world-readme.md           # Real-world README rendering test
│   └── assets/                        # Sample image assets
├── Scripts/
│   ├── install-dev.sh                 # Dev build & install script
│   ├── build-release.sh               # Package ZIP / DMG release script
│   └── uninstall.sh                   # Full uninstallation script
├── Package.swift                      # Swift Package manifest
├── project.yml                        # XcodeGen project configuration
└── README.md
```

---

## 🛠️ Development

### Setup
```sh
brew install xcodegen
xcodegen generate
open MDLook.xcodeproj
```

### Build & Install (Dev)
```sh
Scripts/install-dev.sh
```
Compiles and copies to `/Applications/MDLook.app` only — does not auto-register the extension, keeping the test environment clean.

### Build Core Library & Run Tests
```sh
swift build
swift run MarkdownPreviewCoreTestRunner
swift run MDLookAppLocalizationTestRunner
```

### Refresh Flow
- The “Refresh Quick Look” action uses `QuickLookRefresher` to run `qlmanage -r`, `qlmanage -r cache`, and `killall Finder` in order, surfacing command failures back to the UI.

### Package a Release (ZIP & DMG)
```sh
Scripts/build-release.sh
```
Outputs `dist/MDLook.zip` and `dist/MDLook.dmg`.
The generated DMG includes a drag-to-install Finder layout, but it is still an **unsigned, non-notarized** open-source test package by default.

### Uninstall
```sh
Scripts/uninstall.sh
```
Unregisters the extension, clears preferences, removes app bundles plus local Debug build copies, and resets Finder/QL caches.

---

## 🔍 Manual Testing

Open these sample files in Finder and press **Space**:

- [Samples/regression.md](Samples/regression.md): **Primary regression test document** — covers all rendering features: 9 syntax highlighting languages, math blocks, GFM callouts, footnotes, highlighter marks, and security blocking.
- [Samples/images.md](Samples/images.md): Validates local paths with spaces/CJK characters and remote image blocking.

---

## 📄 License

Licensed under the **MIT License**. See [LICENSE](LICENSE) for details.
