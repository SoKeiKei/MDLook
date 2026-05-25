# MDLook

[English Version](#english) | [英文版](#english)

本地 macOS Markdown 快速预览 (Quick Look) 扩展插件。MDLook 能够将 Markdown 源码实时渲染为排版雅致、安全的静态 HTML。您在 macOS Finder 中选中 `.md` 文件并按 **空格键**，即可获得极其温润、高级的长文阅读与代码块高亮预览体验，无需开启任何编辑器。

---

## 📖 核心特性

### 1. 黄金比例阅读排版
- **宽度分栏设计**：对标题 (`h1`-`h6`) , 正文段落 (`p`) , 无序/有序列表 (`ul`, `ol`) , 引用块 (`blockquote`) 限制最大宽度为 `720px`；而代码块 (`pre`) , 数学公式块, 表格 (`table`) 以及包含图注的独立图片卡片则呈现为 `860px` 宽度。这带来了类似于 Notion 和 Medium 般错落有致、符合视线移动规律的精致排版。
- **排版间距与字距**：全局字体大小为 `16px`，行高为开阔的 `1.75`，字间距配置了 `0.02em` 的轻微留白，降低长文阅读疲劳感。

### 2. 阅读数据统计徽章
- **阅读统计栏**：在文章首部（Front-matter 之下）渲染包含内联 SVG 矢量图标的元数据栏，直观显示文章字数及预计阅读时间。
- **中英文混合统计算法**：由底层的 Swift 渲染引擎在解析时进行统计，中文/日文/韩文按字符个数计算，英文单词按空格分词后的单词数进行计算，完美兼容中英混排。阅读时间按每分钟 300 字的正常速度进行估算（最少为 1 分钟）。

### 3. 高雅的文字与图示排版
- **纸质书荧光笔高亮**：`==高亮==` 文本呈现具有纸质书划线涂抹质感的底边半透明着色（`linear-gradient`），且自适应亮色与暗色模式。
- **温润的引用与图注**：普通引用 `blockquote` 采用极淡圆角背景与醒目的左侧细边，文字呈斜体；独立图片的图注 `figcaption` 采用居中、斜体且无边框的插画图注风。
- **呼出块支持 (Callouts)**：解析 GFM 语法的 `[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, `[!CAUTION]`，并呈现不同着色、精致圆角与内联粗体标题。

### 4. 纯静态代码块高亮
- **零 JS 安全高亮**：基于纯 Swift 字符状态机分词，不需要在预览中加载任何外部 JavaScript 渲染脚本。
- **支持语言**：高亮 **Swift**、**JSON**、**YAML**、**Bash/Shell**、**JavaScript/TypeScript**、**Python**、**HTML/XML** 和 **CSS**。
- **Mermaid 源码预览**：对 Mermaid 流程图呈现其高亮源码及安全警示，由于沙盒安全性考量，不执行其 JavaScript 画图。
- **数学公式安全预览**：支持行内 `$a^2+b^2=c^2$` 与块级 `$$` LaTeX 公式源码的安全底色卡片预览。

### 5. 安全防护与纯净容器
- **沙盒与净化**：自动剔除所有 Script 标签和原生 XSS 攻击向量，将网络图片统一替换为带有隐私保护的被拦截占位卡片。
- **纯净的宿主容器**：宿主 App 界面极其精简，窗口大小自适应内容宽度，不包含任何多余的空白边缘或滚动条。

---

## 🛠️ 构建与本地开发

### 1. 编译核心渲染引擎
您可以在终端中直接编译底层库并运行所有单元测试（包含中英文统计、高亮路由、脚注跳转等）：
```sh
swift build
swift run MarkdownPreviewCoreTestRunner
```

### 2. 生成 Xcode 工程文件
项目采用 XcodeGen 进行工程定义。编译前需安装 `xcodegen`：
```sh
# 安装 xcodegen 依赖
brew install xcodegen

# 生成 Xcode 项目
xcodegen generate
open MDLook.xcodeproj
```
您可以在 Xcode 中选择 `MDLook` 方案，直接运行一次，macOS 会自动向系统注册该 Quick Look 预览插件。

### 3. 本地开发与安装
在修改代码后，直接在您本地的**常规终端**（不要在受限的沙盒终端内）执行一键部署脚本：
```sh
Scripts/install-dev.sh
```
该脚本将编译 `MDLook`，将其安装到 `/Applications/MDLook.app`，启用 Quick Look 预览插件，并强制刷新系统的 Finder 与 QL 预览缓存。

> [!IMPORTANT]
> **手动开启扩展**：由于 macOS 的安全机制，系统无法自动启用该扩展。安装完成后，您**必须**手动前往 **「系统设置 -> 通用 -> 登录项与扩展 -> 快速查看」**，勾选启用 **MDLookExtension** 开关。若未启用，在访达中按空格键将无法看到预览，且 MDLook 宿主 App 内会显示红色警告。

### 4. 打包 Release 发布包 (ZIP & DMG)
```sh
Scripts/build-release.sh
```
这将在工作区根目录的 `dist/` 目录下打包生成 `MDLook.zip` 与 `MDLook.dmg`（带拖拽安装至 Applications 快捷方式的磁盘映像），方便在您自己的 Mac 间分发与部署。

### 5. 完整卸载与清理
如果您需要彻底清除本地已安装的 MDLook 和它的预览扩展：
```sh
Scripts/uninstall.sh
```
该脚本将停用并注销 Quick Look 扩展、清理系统偏好设置、删除应用包，并强制刷新 Finder 和系统缓存。

---

## 🔍 回归测试与体验

我们内置了多个涵盖全渲染特性的 Markdown 回归测试文档。您可以在 Finder 中点击它们并按 **空格键** 查验渲染：
- [Samples/regression.md](Samples/regression.md)：**主要测试文档**，包含了当前渲染器支持的所有高级语法、9种高亮代码、数学公式、GFM 呼出块、脚注和安全性拦截。
- [Samples/images.md](Samples/images.md)：测试本地路径、带空格及中文路径、以及网络图片的安全拦截。

---

## ⚖️ 安全机制 (Security Policy)

- 剔除所有原生 Script 与事件处理器，消除 XSS 隐患。
- 默认隔离所有网络图片，防止 IP 或隐私泄露。
- 拒绝任何 `file://` 外部图片协议。
- 最大支持 `2 MB` 的文件预览，超过该上限自动降级至安全的纯文本预览模式。

---

## 📄 开源声明

本项目基于 **MIT 许可证** 开源。详细授权条款请参阅项目根目录下的 [LICENSE](LICENSE) 文件。

---
---

<a id="english"></a>

# MDLook (English Version)

A local macOS Quick Look preview extension for Markdown files. MDLook renders Markdown source files into beautifully structured, secure, static HTML. Pressing **Space** on any `.md` file in Finder gives you a premium, book-like reading experience and syntax-highlighted code blocks instantly without launching heavyweight editors.

---

## 📖 Key Features

### 1. Typography & Readability
- **Optimal Line Width Constraints**: Paragraphs (`p`), headings (`h1`-`h6`), lists (`ul`, `ol`), blockquotes, and the metadata stats badge are restricted to a maximum width of `720px`. In contrast, code blocks (`pre`), math blocks, tables, and standalone figure images extend to `860px`. This layout provides a readable, Notion/Medium-like presentation.
- **Enhanced Font & Spacing**: The body text size is `16px` with a generous line height of `1.75` and a slight character spacing padding of `0.02em` to reduce reading fatigue.

### 2. Reading Metadata
- **Reading Stats Badge**: Appends a metadata block below the front-matter showing the total word count and estimated reading time with crisp SVG vector icons.
- **Mixed CJK/English Word Counting**: The counting algorithm dynamically processes CJK characters (Chinese, Japanese, Korean) individually, while counting English words based on space-separated tokens, ensuring accuracy for bilingual writing.

### 3. Highlighting & Layout
- **Highlighter Underline Effect**: `==highlight==` text is rendered with a handwritten-like highlighter stroke using a bottom-aligned `linear-gradient` that adapts gracefully to both Light and Dark macOS color schemes.
- **Improved Quotes & Captions**: Blockquotes (`blockquote`) are rendered with a soft, rounded light-gray background, a colored left border, and italicized font. Standalone images display captions (`figcaption`) centered, italicized, and without borders.
- **GitHub Callouts**: Full support for GFM alert tags: `[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, and `[!CAUTION]`.

### 4. Lightweight Static Syntax Highlighting
- **Zero-JS Highlighter**: Uses a pure Swift state-machine lexer to highlight code blocks safely without loading JavaScript engines.
- **Supported Languages**: **Swift**, **JSON**, **YAML**, **Bash/Shell**, **JavaScript/TypeScript**, **Python**, **HTML/XML**, and **CSS**.
- **Mermaid Graph Previews**: Safeguarded source preview is shown for Mermaid code. Execution of diagrams is disabled for sandbox safety.
- **Math Equation Previews**: Renders LaTeX formulas (`$E=mc^2$` and block `$$`) inside safe preview containers.

### 5. Security & Cleaner UI
- **Sandbox & Purifying**: Scripts and raw HTML are completely stripped out to prevent XSS. Remote images are blocked by default to protect privacy.
- **Cleaner App UI**: The host app window adapts automatically to fit the content size, avoiding redundant scrollbars and empty margins.

---

## 🛠️ Build & Development

### 1. Build & Test the Core Renderer
You can build the underlying core library and run the suite of unit tests directly in your terminal:
```sh
swift build
swift run MarkdownPreviewCoreTestRunner
```

### 2. Generate Xcode Projects
We use XcodeGen to manage targets. Make sure `xcodegen` is installed:
```sh
brew install xcodegen
xcodegen generate
open MDLook.xcodeproj
```
Select the `MDLook` scheme in Xcode, build, and run it once. macOS will register the Quick Look extension automatically.

### 3. Build & Install
After updating code, run the development installer from your **regular shell**:
```sh
Scripts/install-dev.sh
```
This builds `MDLook`, copies it into `/Applications/MDLook.app`, registers the extension, and refreshes QL/Finder caches.

> [!IMPORTANT]
> **Enable Extension Manually**: Due to macOS security policies, the system cannot automatically enable this extension. After installation, you **must** manually go to **'System Settings -> General -> Login Items & Extensions -> Quick Look'** and toggle on **MDLookExtension**. If not enabled, pressing Space in Finder will not trigger the preview, and a red warning will be displayed inside the MDLook host app.

### 4. Build a Release Package
```sh
Scripts/build-release.sh
```
This packages the app into `dist/MDLook.zip` and `dist/MDLook.dmg` (disk image featuring drag-and-drop Applications install shortcut) for local deployment.

### 5. Complete Uninstallation
To completely remove MDLook and its preview extension from your system:
```sh
Scripts/uninstall.sh
```
This script unregisters the extension, clears user preferences, deletes the app bundles, and resets Finder and Quick Look caches.

---

## 🔍 Verification & Manual Tests

To verify features, select any of the sample documents in Finder and press **Space**:
- [Samples/regression.md](Samples/regression.md): **the primary verification document** covering all rendering features, mathematical blocks, alert callouts, footnotes, and syntax highlighting.
- [Samples/images.md](Samples/images.md): validates file paths (spaces, CJK characters) and remote blocking mechanisms.

---

## ⚖️ Security Policy

- Scripts and raw HTML are completely stripped out to prevent XSS.
- Remote images are blocked by default to protect user IP and metadata privacy.
- `file://` external image URLs are blocked.
- Previews degrade gracefully to a safe text viewer for files exceeding `2,000,000` bytes.

---

## 📄 License

This project is licensed under the terms of the **MIT License**. For details, please see the [LICENSE](LICENSE) file.
