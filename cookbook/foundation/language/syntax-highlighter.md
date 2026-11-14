---
id: 6708bfd4-5b29-4bf9-b180-05904873906e
title: "Syntax Highlighter"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "TextMate syntax highlighting in JavaScriptCore: a first-wins grammar registry over bundled, VS Code extension and user grammars, a file-name/extension language resolver, and an actor that turns the bundled engine's output into styled runs per line."
platforms:
  - macos
tags:
  - foundation
  - language
  - syntax-highlighting
  - textmate
depends-on:
  - add92e9b-94e5-412c-970f-5ea8e2eb9eed
  - 0e35ddf2-3e87-4a5a-9fd9-24bafc7325b6
related: []
references:
  - packages/apple/AgenticDeveloperHubSDK/Language/Syntax/ (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/Extensions/GrammarContributionPoint.swift (adhsdk)
  - tools/apple/textmate/entry.js (adhsdk)
approved-by: ""
approved-date: ""
---

# Syntax Highlighter

## Overview

Colours source text with TextMate grammars. A `GrammarRegistry` answers grammar text by scope name and the language table from an ordered list of grammar sources (a user directory of `*.tmLanguage.json` files, then the enabled VS Code extensions' `contributes.grammars`, ahead of the bundled [TextMate resources](cookbook:add92e9b-94e5-412c-970f-5ea8e2eb9eed)); a `LanguageResolver` maps a file URL to a language id; and the `SyntaxHighlighter` actor runs the bundled `highlighter.js` and `onig.wasm` in one JavaScriptCore context and turns its output into one `StyledLine` of coloured runs per line, painted with a `CodeTheme` from the [theme engine](cookbook:0e35ddf2-3e87-4a5a-9fd9-24bafc7325b6). The diff and blame views colour code with it. Foundation and JavaScriptCore only: no AppKit, so it can run anywhere the Language framework runs. The extension source alone lives in the macOS framework, beside the other contribution points, where the extensions coordinator registers every point; it hands its grammars down through the `GrammarSource` protocol.

## Behavioral Requirements

- **resources-validated**: `TextMateResources(directory:)` MUST throw when `highlighter.js`, `onig.wasm`, `languages.json` or `manifest.json` is missing from the directory; code receives the directory by injection, never from a bundle lookup.
- **bundled-source**: `BundledGrammarSource` MUST read its languages from `languages.json` and map every scope name in `manifest.json`'s `grammars` (embed-only grammars included) to `grammars/<name>.json`, reading a grammar's text only when asked for it.
- **directory-source**: `DirectoryGrammarSource` MUST offer every `*.tmLanguage.json` in its directory whose JSON has a string `scopeName`, as a language whose id is the file name without `.tmLanguage.json` and whose `fileTypes` are matched as TextMate matches them: each is an extension, lowercased with a leading dot, and each that does not start with a dot is also an exact file name as written (`Makefile`). A file that is not such JSON, and a second file for a scope already taken, MUST be skipped with a log line, and a missing directory MUST give no languages.
- **extension-source**: `ExtensionGrammarSource`, built by `GrammarContributionPoint` from the extensions it has applied (the registry applies only enabled ones, and withdraws an extension when it is disabled), MUST offer every `contributes.grammars` entry whose `path` resolves inside its extension and ends in `.json` (`.tmLanguage.json` included); a plist `.tmLanguage`, a path that escapes the extension, a missing file, and a second claim on a scope (extensions taken in identifier order, then manifest order) MUST be skipped with a log line, a contested scope logged once while the conflict stands rather than on every rebuild. Every offered grammar MUST give its text by scope name. An entry with a `language` MUST also give a language with that id, the grammar's scope, and the aliases, extensions (lowercased with a leading dot, multi-dot values kept, glob and empty values dropped) and file names of every applied extension's `contributes.languages` entry with that id, whichever extension declares it, but only when that yields at least one extension or file name: an entry with neither would resolve no file and would hide a later source's language of the same id. One without a `language` (an injection grammar) MUST give no language. The source is a snapshot: it does not change when extensions do, and `hasGrammar` is a lookup.
- **first-source-wins**: `GrammarRegistry` MUST answer a scope's grammar text from the first source that has it, list each language id once (the first source's entry), and answer `scopeName(languageID:)` from that entry.
- **resolution-order**: `LanguageResolver.languageID(for:)` MUST try, in order, the override closure, an exact file name match, an extension match ignoring case (longest multi-dot extension first, so `x.h.in` tries `.h.in` before `.in`), and otherwise answer nil. Among languages claiming the same file name or extension, the earlier language in the registry wins.
- **limits**: `highlight` MUST answer nil, without running the engine, when the text is over `maximumBytes` (1 000 000 UTF-8 bytes) or any line is over `maximumLineLength` (10 000 UTF-16 units).
- **unknown-scope**: `highlight` MUST answer nil when the registry has no grammar for the scope, asking `hasGrammar(scopeName:)` (a dictionary lookup for the bundled source, a file-existence check for a directory) rather than reading the grammar.
- **line-split**: Lines MUST be split on `\r\n`, `\r` and `\n`, each one break, exactly as the bundle splits; the result MUST have one `StyledLine` per line, and a count that disagrees with the bundle's MUST throw.
- **runs**: Each run's `range` MUST be the bundle's UTF-16 `[start, length]` within its line; a range outside the line MUST throw. `fontStyle` carries the bits italic 1, bold 2, underline 4, strikethrough 8.
- **strict-colours**: A run colour MUST parse only as uppercase `#RRGGBB` (opaque) or `#RRGGBBAA`; any other text MUST throw `SyntaxHighlighterError.unexpectedColor`, never default.
- **one-engine**: The actor MUST own one `JSVirtualMachine` and `JSContext`, created on the first call that needs the engine, with the host object `ADKHost.grammarText(scopeName)` answering from the registry (`null` when absent) and `console` forwarded to the unified log.
- **promises-without-run-loop**: A bundle promise MUST be settled synchronously, by attaching `then` callbacks that record its outcome and reading it once the attaching call returns; JavaScriptCore drains microtasks when the outermost call returns, so the promise settles inside that call. A promise still pending when the call returns MUST throw `SyntaxHighlighterError.promiseDidNotSettle` rather than wait. The actor MUST never spin a run loop; WebAssembly compiles synchronously in the context so `create` settles the same way: `WebAssembly.instantiate` takes bytes (answering `{module, instance}`) or a `WebAssembly.Module` (answering its `Instance`), and a compile or link error rejects.
- **theme-once**: The theme MUST be handed to the bundle's `setTheme` only when it differs from the last one set.
- **no-reentry**: The engine path (creating the engine, setting the theme, highlighting) MUST have no suspension point, so concurrent first calls create one engine and every call is coloured by its theme. The WASM bytes MUST be released once the engine is created.
## Appearance

Not applicable: The highlighter returns coloured runs; the views that draw them own the appearance.

## States

- **No engine**: before the first highlight that reaches the engine; nothing is loaded.
- **Ready**: after the bundle is evaluated and `create` has resolved; grammars load on first use and stay cached in the bundle.
- A failed `create` leaves the actor without an engine; the next call tries again.

## Accessibility

Not applicable: The highlighter presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| syntax-highlighter-001 | runs, strict-colours, one-engine | `let x = 1` as `source.swift` with Dark+ (`themes/dark-plus.json`) | the run at `NSRange(0, 3)` is `#569CD6`. |
| syntax-highlighter-002 | line-split | `/* a` then `b */` on the next line | line 2's first run is Dark+'s comment colour `#6A9955`. |
| syntax-highlighter-003 | runs | a Markdown fenced `swift` block holding `let y = 1` | the `let` run inside the block is `#569CD6`. |
| syntax-highlighter-004 | limits | 1 000 001 bytes, or one line of 10 001 UTF-16 units | nil. |
| syntax-highlighter-005 | unknown-scope | scope `source.nonexistent` | nil. |
| syntax-highlighter-006 | first-source-wins | a user `swift.tmLanguage.json` (`scopeName` `source.swift`) ahead of the bundled source | the registry's `source.swift` text is the user file's. |
| syntax-highlighter-007 | resolution-order | `Package.swift`, `x.PY`, `Makefile`, an override answering `json`, `notes.unknownext` | `swift`, `python`, `make`, `json`, nil. |
| syntax-highlighter-008 | line-split | `a\rb`, `a\r\nb` | two lines each. |
| syntax-highlighter-009 | no-reentry, theme-once | eight concurrent first `highlight` calls with Dark+ on a new highlighter | every `let` run is `#569CD6`; one engine created; `setTheme` called once. |
| syntax-highlighter-010 | theme-once | Dark+, Dark+, Light+, Light+, Dark+ in turn | `setTheme` counts 1, 1, 2, 2, 3. |
| syntax-highlighter-011 | promises-without-run-loop | `new Promise(() => {})` | throws `promiseDidNotSettle`. |
| syntax-highlighter-012 | promises-without-run-loop | `WebAssembly.instantiate` with the empty module's bytes, with that `WebAssembly.Module`, and with `[1, 2, 3]` | `{module, instance}`; an `Instance`; rejected. |
| syntax-highlighter-013 | directory-source | a user grammar with `fileTypes` `["Makefile", "MK", ".gnu"]` | extensions `.makefile`, `.mk`, `.gnu`; file names `Makefile`, `MK`; `Makefile` and `rules.mk` resolve to it. |
| syntax-highlighter-014 | extension-source | an extension contributing grammar `source.widget` (`language` `widget`, `./syntaxes/widget.tmLanguage.json`), an injection grammar `text.widget.injection` (`./syntaxes/injection.json`), and language `widget` with aliases `["Widget"]`, extensions `[".Widget", "wdg"]`, filenames `["Widgetfile"]` | grammar text for both scopes is the files' text; one language: id `widget`, scope `source.widget`, aliases `["Widget"]`, extensions `.widget`, `.wdg`, file names `Widgetfile`; `x.wdg` resolves to `widget` through a registry over the source. |
| syntax-highlighter-015 | extension-source | the same extension, disabled | no languages; neither scope has a grammar. |
| syntax-highlighter-016 | extension-source | a grammar at `./syntaxes/old.tmLanguage` and one at `../outside.json` | neither scope has a grammar. |
| syntax-highlighter-017 | extension-source, first-source-wins | an extension contributing only grammar `source.cpp` (`language` `cpp`) and no `contributes.languages`, in a registry before a source declaring language `cpp` with extension `.cpp` | the extension source has no languages; `x.cpp` resolves to `cpp`; the grammar text for `source.cpp` is the extension's. |
| syntax-highlighter-018 | extension-source | grammar `source.gadget` (`language` `gadget`) from one extension, language `gadget` with extension `.gdg` and file name `Gadgetfile` from another | one language: id `gadget`, scope `source.gadget`, extensions `.gdg`, file names `Gadgetfile`. |
| syntax-highlighter-019 | extension-source | language `hin` declaring extension `.H.in`; a grammar at `./pl.plist` | extension `.h.in`, and `config.h.in` resolves to `hin`; `./pl.plist` gives no grammar. |
| syntax-highlighter-020 | extension-source | `alpha` and `beta` both claiming `source.shared`, then an unrelated extension applied and withdrawn, then `beta` withdrawn and re-applied | one conflict logged, none for the unrelated rebuilds, one more when the conflict returns. |

## Edge Cases

- **Null / empty input**: An empty text is one line with no runs.
- **Boundary values**: Exactly 1 000 000 bytes and a line of exactly 10 000 UTF-16 units are highlighted; one more is nil.
- **Concurrent access**: The actor serialises every call on its one context; JavaScriptCore's API lock covers the thread hops an actor makes.
- **Error states**: A bundle exception or rejected promise throws `SyntaxHighlighterError.javaScript` with the message; malformed output throws `malformedOutput`, an unknown colour `unexpectedColor`.
- **Offline / disconnected state**: Not applicable: everything is local.
- **Cancellation**: A highlight runs to completion once started; callers drop results they no longer need.

## Configuration

The TextMate resource directory and the ordered grammar sources are injected; the resolver takes an optional override closure.

## Deep Linking

Not applicable: The highlighter defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The highlighter contains no user-facing string.

## Accessibility Options

Not applicable: The highlighter presents no UI.

## Feature Flags

Not applicable: The highlighter contains no feature-flag reference.

## Analytics

Not applicable: The highlighter contains no analytics call.

## Privacy

Not applicable: The text is highlighted in process and sent nowhere.

## Logging

The bundle's `console` output and skipped user and extension grammar files go to the unified log through `Loggable` (the host app's subsystem; categories `SyntaxHighlighter`, `DirectoryGrammarSource` and `GrammarContributionPoint`), `console.warn` and `console.error` at error level.

## Platform Notes

- **SwiftUI**: Views take `[StyledLine]` and draw runs with their own fonts; the highlighter itself is UI-free.
- **Compose**: The same bundle runs in any JavaScript engine with WebAssembly and promises; the host contract is `ADKHost.grammarText`.
- **React/Web**: The bundle runs as is in a browser; no Swift side is needed.
- **AppKit / UIKit**: JavaScriptCore without `com.apple.security.cs.allow-jit` interprets, correct but slower; the limits keep the worst case bounded.
- **WinUI 3**: A WebView2 host would supply `ADKHost`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Language/Syntax/TextMateResources.swift` | confirmed (1.1.1) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Language/Syntax/GrammarSource.swift` | confirmed (1.1.1) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Language/Syntax/GrammarRegistry.swift` | confirmed (1.1.1) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Language/Syntax/LanguageResolver.swift` | confirmed (1.1.1) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Language/Syntax/SyntaxHighlighter.swift` | confirmed (1.1.1) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Language/Syntax/StyledLine.swift` | confirmed (1.1.1) |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Extensions/GrammarContributionPoint.swift` | confirmed (1.1.1) |

## Design Decisions

**Decision**: Promises are settled synchronously through `then` callbacks inside the actor's own call, never by a continuation and never by running a run loop.
**Rationale**: JavaScriptCore drains microtasks when the outermost call returns, and the bundle uses nothing but promises, so every promise settles before the call returns; spinning a run loop from an actor would block a cooperative thread and could re-enter unrelated work, and an `await` on the engine path would let the actor be re-entered between creating the engine and setting the theme.
**Approved**: pending

**Decision**: `WebAssembly.instantiate` is replaced in the context with a synchronous `Module` + `Instance` that returns a resolved promise.
**Rationale**: An asynchronous compile may finish on JavaScriptCore's deferred-work timer, which only a run loop fires; compiling synchronously keeps `create` inside the one call regardless of JIT availability.
**Approved**: pending

**Decision**: Over the limits the answer is nil (uncoloured), not a partial highlight.
**Rationale**: A huge or minified file costs seconds in an interpreted engine; showing it plain keeps the viewer responsive and the rule simple.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |

`separation-of-concerns` passes because grammar lookup, language resolution and highlighting are separate types, and drawing belongs to the views.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-11-13 | Mike Fullerton | A grammar adds a language only when its join yields an extension or file name; a contested scope is logged once while it stands |
| 1.1.0 | 2026-11-13 | Mike Fullerton | Extension grammars: `ExtensionGrammarSource` from `contributes.grammars` joined with `contributes.languages` |
| 1.0.1 | 2026-11-13 | Mike Fullerton | Synchronous promise settling with no suspension on the engine path, hasGrammar, fileTypes as file names, both instantiate forms |
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
