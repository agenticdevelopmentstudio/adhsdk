---
id: add92e9b-94e5-412c-970f-5ea8e2eb9eed
title: "TextMate Resources"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Pinned vscode-textmate + WASM Oniguruma bundle, licence-filtered tm-grammars grammars and tm-themes themes, a linguist-joined language table, licences and a manifest, built deterministically by one Python script."
platforms:
  - macos
tags:
  - foundation
  - language
  - syntax-highlighting
  - textmate
  - build
depends-on: []
related: []
references:
  - tools/apple/textmate/build_textmate_resources.py (adhsdk)
  - tools/apple/textmate/entry.js (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Resources/TextMate/ (adhsdk)
approved-by: ""
approved-date: ""
---

# TextMate Resources

## Overview

The files a TextMate syntax highlighter needs at run time, built by one deterministic script from pinned npm packages: VS Code's own `vscode-textmate` engine and its WASM Oniguruma bundled into `highlighter.js` for a bare JavaScriptCore context, `onig.wasm`, the grammars of `tm-grammars` and the themes of `tm-themes` whose licences allow shipping, a language table joined from `linguist-languages`, one licence file per shipped grammar, theme and package, and a manifest of versions and checksums. The tree lives once, in `Resources/TextMate/` of the toolkit, belongs to no framework target, and is copied into an app bundle by the app; code receives its directory by injection.

## Behavioral Requirements

- **pinned-inputs**: Every input MUST come from an exact npm version recorded in `package.json` and `package-lock.json`; the build MUST install with `npm ci` and never resolve a range.
- **deterministic-output**: The same lock file MUST produce byte-identical output: JSON written with sorted keys and two-space indentation, files copied verbatim, no timestamps.
- **check-mode**: `--check` MUST rebuild into a temporary directory and exit 1, naming each missing, unexpected or differing path, when the committed tree differs; it MUST exit 0 when the tree is current.
- **licence-filter**: A grammar or theme MUST ship only when its licence is MIT, Apache-2.0, BSD-2-Clause, BSD-3-Clause, ISC or Unlicense. A grammar's licence is its `tm-grammars` metadata `license`, or for an embed-only grammar with no metadata row, its NOTICE entry's SPDX id; a disagreement between the two MUST fail the build.
- **licence-text**: Every shipped grammar and theme MUST have `LICENSES/grammar-<name>.txt` or `LICENSES/theme-<name>.txt` holding its source, licence URL, SPDX id and licence text; every package whose code or data ships MUST have `LICENSES/package-<name>.txt`. A shipped item with no licence text MUST fail the build.
- **bundle-api**: `highlighter.js` MUST be an esbuild IIFE (`--platform=neutral --target=safari17`) defining `globalThis.ADKHighlighter` with `create(wasmBytes)`, `setTheme(themeJSON)` and `highlight(text, scopeName)`, and MUST read grammars only through the host's `ADKHost.grammarText(scopeName)`.
- **raw-theme**: `setTheme` MUST build the engine theme from a VS Code theme as a first scope-less rule with `colors["editor.foreground"]` and `colors["editor.background"]`, then the theme's `tokenColors`; a `tokenColors` that is missing or not an array (a path) contributes no rules, and a TextMate-style `settings` array is read in its place.
- **highlight-output**: `highlight` MUST resolve to JSON `{"lines": [[[start, length, "#RRGGBB", fontStyle], ...], ...]}`, one entry per line split on `\n` or `\r\n`, with start and length in UTF-16 units within the line, the colour from the engine's colour map at `(metadata >>> 15) & 0x1ff`, the font style bits `(metadata >>> 11) & 0xf` (italic 1, bold 2, underline 4, strikethrough 8), no zero-length runs, and the rule stack carried from line to line. A scope with no grammar MUST reject.
- **language-table**: `languages.json` MUST list every shipped grammar that `tm-grammars` names as a language, as `{id, scopeName, aliases, extensions, filenames}`, with extensions and filenames the sorted union of every `linguist-languages` language whose `tmScope` equals the scope name.
- **manifest**: `manifest.json` MUST record every package version, the esbuild arguments, the allowed licences, each shipped grammar's name, scope and licence, each shipped theme, every dropped grammar and theme with its licence, and the sha256 of every other file in the tree.

## Appearance

Not applicable: The resources are data and a script; the viewer that draws highlighted text owns the appearance.

## States

Not applicable: The build is a one-shot command; the bundle keeps only the engine registry and a grammar cache between calls.

## Accessibility

Not applicable: The resources present no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| textmate-resources-001 | check-mode | `--check` against a missing or stale `--out` | exit 1, the differing paths listed. |
| textmate-resources-002 | check-mode, deterministic-output | `--check` right after a build into `--out` | exit 0, `up to date`. |
| textmate-resources-003 | licence-filter | `tm-grammars` 1.32.22, `tm-themes` 1.12.12 | 218 grammars kept, 42 dropped (none, NOASSERTION, GPL-3.0, GNU, MPL-2.0); 64 themes kept, `aurora-x` (GPL-3.0) dropped. |
| textmate-resources-004 | bundle-api, highlight-output | the README's `node -e` smoke test on Swift with Dark+ | `let` at `[0, 3]` coloured `#569CD6`, every line has runs. |
| textmate-resources-005 | bundle-api | the same bundle and `onig.wasm` in a bare `JSContext` without the JIT entitlement | Swift text highlights with non-empty colour runs. |

## Edge Cases

- **Null / empty input**: An empty text highlights to one line with no runs; an empty line has no runs.
- **Boundary values**: A grammar embedded by a shipped grammar but itself dropped (YAML front matter in Markdown) is not found, and the engine leaves that region in the embedding grammar's colours.
- **Concurrent access**: The bundle is single-threaded JavaScript; the host serialises calls on one context.
- **Error states**: `highlight` before `create` resolves, or on a scope with no grammar, rejects with an `Error`. A licence disagreement or missing licence text stops the build with the file named.
- **Offline / disconnected state**: The build needs the npm registry only for `npm ci`; the bundle needs no network.
- **Cancellation**: Not applicable: The resources have no concern of this kind beyond what Behavioral Requirements state.

## Configuration

None — the script takes only `--out` and `--check`; the pinned versions live in `package.json` and `package-lock.json`.

## Deep Linking

Not applicable: The resources define no URL scheme, route or navigation destination.

## Localization

Not applicable: The resources contain no user-facing string.

## Accessibility Options

Not applicable: The resources present no UI.

## Feature Flags

Not applicable: The resources contain no feature-flag reference.

## Analytics

Not applicable: The resources contain no analytics call.

## Privacy

Not applicable: The bundle reads only the text and grammars the host hands it and sends nothing anywhere.

## Logging

Not applicable: The bundle calls no logging API; the build prints its counts and total size to standard output.

## Platform Notes

- **SwiftUI**: Not applicable: The resources hold no Swift code; the toolkit's syntax highlighter loads `highlighter.js` and `onig.wasm` into a `JSContext` and supplies `ADKHost.grammarText`.
- **Compose**: The same tree runs in any JavaScript engine with WebAssembly; on Android a WebView or J2V8 host would supply `ADKHost`.
- **React/Web**: The bundle runs as is in a browser or Node (`vm.runInThisContext`); the README's smoke test is that host.
- **AppKit / UIKit**: The app copies the directory into `Contents/Resources/TextMate/`; JavaScriptCore runs the WASM interpreted without `com.apple.security.cs.allow-jit`, correct but 10-20 times slower.
- **WinUI 3**: A WebView2 host would supply `ADKHost`; nothing in the tree is Apple-specific.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `tools/apple/textmate/` | confirmed (1.0.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Resources/TextMate/` | confirmed (1.0.0) |

## Design Decisions

**Decision**: Themes are filtered by the same licence list as grammars.
**Rationale**: A GPL-3.0 theme file shipped in the app carries the same obligation as a GPL-3.0 grammar; one rule for both keeps the licence position in one place.
**Approved**: pending

**Decision**: Licence texts come from the packages' NOTICE files, never from the network.
**Rationale**: The build must be a pure function of the lock file for `--check` to mean anything; every shipped item's NOTICE entry carries its text, and an item without one stops the build instead of shipping unlicensed.
**Approved**: pending

**Decision**: Grammar and theme files are copied verbatim, not re-serialised.
**Rationale**: Their bytes stay identical to the pinned package, which keeps the checksums comparable with upstream and the diff of a version bump honest.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |

`separation-of-concerns` passes because the tree holds only data and the engine bundle; resolving languages, choosing themes and drawing runs belong to the toolkit's syntax highlighter and viewer.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
