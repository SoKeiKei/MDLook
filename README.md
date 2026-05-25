# MDLook

A local macOS Quick Look preview extension for Markdown files. MDLook renders Markdown into safe HTML so Finder previews are readable instead of raw source.

## Current Shape

- `MarkdownPreviewCore` is a SwiftPM library with a `swift-markdown`/`cmark-gfm` parser and a safe Markdown-to-HTML renderer.
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

## Install For Local Development

Use the development installer after code changes:

```sh
Scripts/install-dev.sh
```

The script builds `MDLook`, installs it into `/Applications`, removes duplicate development installs from `~/Applications`, enables the extension, refreshes Quick Look caches, restarts Finder, and prints sample `qlmanage -p` commands. Set `MDLOOK_INSTALL_DIR` if you need a different install location.

## Build A Local Release Zip

For a lightweight local package:

```sh
Scripts/build-release.sh
```

The script builds the Release configuration and writes `dist/MDLook.zip`. This package is useful for testing on your own Mac, but it is still unsigned and not notarized for public distribution.

## Finder Verification

Use the sample files in `Samples/`:

```sh
qlmanage -r
qlmanage -r cache
qlmanage -p Samples/basic.md
```

Useful manual regression files:

- `Samples/basic.md`: common Markdown structure.
- `Samples/regression.md`: nested lists, inline code, deleted text, unsafe links, and raw HTML removal.
- `Samples/images.md`: local images, Chinese/space-containing image paths, missing images, and remote image blocking.
- `Samples/real-world-readme.md`: open-source README style document.
- `Samples/changelog.md`: release note style document with footnotes and tables.
- `Samples/notes.md`: mixed Chinese/English notes with front matter and callouts.
- `Samples/security.md`: script and raw HTML removal.
- `Samples/large.md`: instructions for generating an oversized file.
- `测试文档.md`: real-world Chinese Markdown sample used to catch styling regressions.

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
- Remote images are blocked by default. They can be enabled from the MDLook app when you trust the document source.
- `file://` image URLs are blocked.
- Relative local images are resolved from the Markdown file directory.
- Missing images render as placeholders and do not fail the document.
- Files larger than `2_000_000` bytes show a safe error page.

## Next Development Tasks

Recommended order for the next development window:

1. Keep hardening the Markdown renderer with documents found in real use.
   - Current state: headings, paragraphs, emphasis, links, images, nested lists, blockquotes, tables, task lists, fenced code blocks, escaping, Chinese/English text, callouts, footnotes, front matter, safe math source previews, definition lists, highlight, subscript, and superscript are covered by tests.
   - Next step: add focused compatibility tests when a real document exposes an edge case.

2. Improve public distribution.
   - Current state: `Scripts/install-dev.sh` handles local development installs, and `Scripts/build-release.sh` creates a local unsigned zip.
   - Next step: add signing, notarization, and a DMG only after the renderer is stable enough for a public v1.

3. Add optional advanced settings later.
   - Candidate settings: file size limit, preview width, theme override, and a source/render default.
   - Keep these out of the Quick Look preview itself unless Finder refresh behavior is proven reliable.

## Feature Evaluation

These features were considered after the first usable Quick Look build:

- Menu bar resident app: not needed for v1. MDLook should stay lightweight and only run when Finder asks Quick Look for a preview. A menu bar extra is worth adding only if the app later needs persistent status, update checks, or user-controlled global behavior.
- Settings UI: partially useful now. MDLook exposes rendering on/off, remote image loading, language switching, diagnostics copy, and Quick Look refresh. More settings should wait until there is a clear user need.
- Render/source mode switch inside Quick Look: defer. Quick Look preview extensions are best treated as short-lived preview providers, and the current implementation returns static safe HTML. A reliable mode switch would need a designed preference path, likely shared app group state, and careful validation that Finder refreshes previews predictably.
- Default shortcut for switching modes: defer with the mode switch. A global shortcut would imply a resident app, conflict handling, and possibly accessibility or event-monitoring behavior. For v1, Finder's Space preview should remain the primary interaction.

Near-term recommendation: keep v1 focused on fast rendered previews, safe local image handling, reliable install/reset tooling, and strong regression samples.

## v1 Non-Goals

- No Markdown editor.
- No document library or search.
- No signing, notarization, DMG, or App Store packaging.
- No executed Mermaid or math rendering; source previews are shown safely.
- No document navigation.
