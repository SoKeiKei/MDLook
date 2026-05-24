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
- Remote images and file URL images are blocked.
- Relative local images are resolved from the Markdown file directory.
- Missing images render as placeholders and do not fail the document.
- Files larger than `2_000_000` bytes show a safe error page.

## Next Development Tasks

Recommended order for the next development window:

1. Continue hardening the Markdown renderer.
   - Current state: parsing uses `swift-markdown` backed by `cmark-gfm`, then MDLook renders the AST into controlled HTML.
   - Next step: add focused compatibility tests as real documents expose edge cases.
   - Acceptance target: headings, paragraphs, emphasis, links, images, nested lists, blockquotes, tables, task lists, fenced code blocks, escaping, and mixed Chinese/English text stay covered by tests.

2. Expand Quick Look regression samples.
   - Add samples for nested lists, tables, task lists, fenced code blocks, local images, Chinese filenames, image paths containing spaces, missing images, unsafe raw HTML, remote images, and large files.
   - Verify with both `qlmanage -p` and Finder Space preview after every meaningful extension change.

3. Improve the local install workflow.
   - Add a developer script that builds the app, installs it into `~/Applications` or `/Applications`, enables the extension, resets Quick Look, and prints the commands needed for manual Finder verification.
   - Keep the script local-development focused; signing and notarization should remain out of scope until rendering behavior is stable.

4. Prepare release packaging later.
   - Only start signing, notarization, DMG packaging, and update distribution after the renderer and install workflow are reliable.
   - Before the first public release, add a short privacy/security note explaining that MDLook renders local Markdown files, blocks remote resources, and does not intentionally send document contents anywhere.

## Feature Evaluation

These features were considered after the first usable Quick Look build:

- Menu bar resident app: not needed for v1. MDLook should stay lightweight and only run when Finder asks Quick Look for a preview. A menu bar extra is worth adding only if the app later needs persistent status, update checks, or user-controlled global behavior.
- Settings UI: not needed yet. The current v1 has no stable user-facing options beyond the safety policy, so adding settings now would create UI without meaningful choices. Revisit after renderer mode, theme, or file-size limits become configurable.
- Render/source mode switch inside Quick Look: defer. Quick Look preview extensions are best treated as short-lived preview providers, and the current implementation returns static safe HTML. A reliable mode switch would need a designed preference path, likely shared app group state, and careful validation that Finder refreshes previews predictably.
- Default shortcut for switching modes: defer with the mode switch. A global shortcut would imply a resident app, conflict handling, and possibly accessibility or event-monitoring behavior. For v1, Finder's Space preview should remain the primary interaction.

Near-term recommendation: keep v1 focused on fast rendered previews, safe local image handling, reliable install/reset tooling, and strong regression samples.

## v1 Non-Goals

- No Markdown editor.
- No document library or search.
- No signing, notarization, DMG, or App Store packaging.
- No Mermaid, math, footnotes, or document navigation.
- No remote image loading; remote images intentionally render as blocked placeholders.
