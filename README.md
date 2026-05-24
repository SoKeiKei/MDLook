# Markdown Quick Look Preview

A local macOS Quick Look preview extension for Markdown files. The first version renders Markdown into safe HTML so Finder previews are readable instead of raw source.

## Current Shape

- `MarkdownPreviewCore` is a SwiftPM library with the safe Markdown-to-HTML renderer.
- `App/MarkdownQuickLookPreview` contains the lightweight SwiftUI container app.
- `App/MarkdownPreviewExtension` contains the Quick Look preview provider.
- `project.yml` is an XcodeGen project definition for the app and extension targets.

This machine currently has Command Line Tools selected, not full Xcode, so the Quick Look app target cannot be built here with `xcodebuild` yet.

## Build The Core Renderer

```sh
swift build
swift run MarkdownPreviewCoreTestRunner
```

## Generate The Xcode Project

Install Xcode and select it:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Install XcodeGen if needed:

```sh
brew install xcodegen
```

Generate and open the project:

```sh
xcodegen generate
open MarkdownQuickLookPreview.xcodeproj
```

Choose the `MarkdownQuickLookPreview` scheme, build and run the app once so macOS registers the extension.

## Finder Verification

Use the sample files in `Samples/`:

```sh
qlmanage -r
qlmanage -r cache
qlmanage -p Samples/basic.md
```

You can also select a `.md` file in Finder and press Space.

## Security Policy

- Scripts and raw HTML are removed from preview output.
- Remote images and file URL images are blocked.
- Relative local images are resolved from the Markdown file directory.
- Missing images render as placeholders and do not fail the document.
- Files larger than `2_000_000` bytes show a safe error page.

## v1 Non-Goals

- No Markdown editor.
- No document library or search.
- No signing, notarization, DMG, or App Store packaging.
- No Mermaid, math, footnotes, or document navigation.

