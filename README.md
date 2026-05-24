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

Useful manual regression files:

- `Samples/basic.md`: common Markdown structure.
- `Samples/regression.md`: nested lists, inline code, deleted text, unsafe links, and raw HTML removal.
- `Samples/images.md`: local images, Chinese/space-containing image paths, missing images, and remote image blocking.
- `Samples/security.md`: script and raw HTML removal.
- `Samples/large.md`: instructions for generating an oversized file.

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

## Next Development Tasks

Recommended order for the next development window:

1. Upgrade the Markdown renderer.
   - Current state: the renderer is intentionally small and suitable for the first working Quick Look preview.
   - Next step: evaluate `cmark-gfm` or `swift-markdown`, then replace or wrap the current renderer without weakening the existing safety policy.
   - Acceptance target: headings, paragraphs, emphasis, links, images, nested lists, blockquotes, tables, task lists, fenced code blocks, escaping, and mixed Chinese/English text are covered by tests.

2. Expand Quick Look regression samples.
   - Add samples for nested lists, tables, task lists, fenced code blocks, local images, Chinese filenames, image paths containing spaces, missing images, unsafe raw HTML, remote images, and large files.
   - Verify with both `qlmanage -p` and Finder Space preview after every meaningful extension change.

3. Improve the local install workflow.
   - Add a developer script that builds the app, installs it into `~/Applications` or `/Applications`, enables the extension, resets Quick Look, and prints the commands needed for manual Finder verification.
   - Keep the script local-development focused; signing and notarization should remain out of scope until rendering behavior is stable.

4. Prepare release packaging later.
   - Only start signing, notarization, DMG packaging, and update distribution after the renderer and install workflow are reliable.
   - Before the first public release, add a short privacy/security note explaining that MDLook renders local Markdown files, blocks remote resources, and does not intentionally send document contents anywhere.

## v1 Non-Goals

- No Markdown editor.
- No document library or search.
- No signing, notarization, DMG, or App Store packaging.
- No Mermaid, math, footnotes, or document navigation.
