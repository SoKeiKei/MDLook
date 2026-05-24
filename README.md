# MDLook

A local macOS Quick Look preview extension for Markdown files. MDLook renders Markdown into safe HTML so Finder previews are readable instead of raw source.

## Current Shape

- `MarkdownPreviewCore` is a SwiftPM library with the safe Markdown-to-HTML renderer.
- `App/MDLook` contains the lightweight SwiftUI container app.
- `App/MDLookExtension` contains the Quick Look preview provider.
- `project.yml` is an XcodeGen project definition for the app and extension targets.

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
open MDLook.xcodeproj
```

Choose the `MDLook` scheme, build and run the app once so macOS registers the extension.

You can also build from the command line:

```sh
xcodebuild -project MDLook.xcodeproj -scheme MDLook -configuration Debug -derivedDataPath DerivedData build
```

## Finder Verification

Use the sample files in `Samples/`:

```sh
qlmanage -r
qlmanage -r cache
qlmanage -p Samples/basic.md
```

You can also select a `.md` file in Finder and press Space.

If Finder keeps showing source, make sure the extension is enabled and reset Quick Look:

```sh
pluginkit -e use -i com.sokei.MDLook.MDLookExtension
qlmanage -r
qlmanage -r cache
killall Finder
```

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
