---
id: 6708bfd4-5b29-4bf9-b180-05904873906e
title: "Syntax Highlighter"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "TextMate syntax highlighting in JavaScriptCore: a first-wins grammar registry over bundled and user grammars, a file-name/extension language resolver, and an actor that turns the bundled engine's output into styled runs per line."
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
  - tools/apple/textmate/entry.js (adhsdk)
approved-by: ""
approved-date: ""
---

# Syntax Highlighter

## Overview

Colours source text with TextMate grammars. A `GrammarRegistry` answers grammar text by scope name and the language table from an ordered list of grammar sources (a user directory of `*.tmLanguage.json` files ahead of the bundled [TextMate resources](cookbook:add92e9b-94e5-412c-970f-5ea8e2eb9eed)); a `LanguageResolver` maps a file URL to a language id; and the `SyntaxHighlighter` actor runs the bundled `highlighter.js` and `onig.wasm` in one JavaScriptCore context and turns its output into one `StyledLine` of coloured runs per line, painted with a `CodeTheme` from the [theme engine](cookbook:0e35ddf2-3e87-4a5a-9fd9-24bafc7325b6). The diff and blame views colour code with it. Foundation and JavaScriptCore only: no AppKit, so it can run anywhere the Language framework runs.

## Behavioral Requirements

- **resources-validated**: `TextMateResources(directory:)` MUST throw when `highlighter.js`, `onig.wasm`, `languages.json` or `manifest.json` is missing from the directory; code receives the directory by injection, never from a bundle lookup.
- **bundled-source**: `BundledGrammarSource` MUST read its languages from `languages.json` and map every scope name in `manifest.json`'s `grammars` (embed-only grammars included) to `grammars/<name>.json`, reading a grammar's text only when asked for it.
- **directory-source**: `DirectoryGrammarSource` MUST offer every `*.tmLanguage.json` in its directory whose JSON has a string `scopeName`, as a language whose id is the file name without `.tmLanguage.json` and whose extensions are its `fileTypes`, each lowercased with a leading dot; a file that is not such JSON MUST be skipped, and a missing directory MUST give no languages.
- **first-source-wins**: `GrammarRegistry` MUST answer a scope's grammar text from the first source that has it, list each language id once (the first source's entry), and answer `scopeName(languageID:)` from that entry.
- **resolution-order**: `LanguageResolver.languageID(for:)` MUST try, in order, the override closure, an exact file name match, an extension match ignoring case (longest multi-dot extension first, so `x.h.in` tries `.h.in` before `.in`), and otherwise answer nil. Among languages claiming the same file name or extension, the earlier language in the registry wins.
- **limits**: `highlight` MUST answer nil, without running the engine, when the text is over `maximumBytes` (1 000 000 UTF-8 bytes) or any line is over `maximumLineLength` (10 000 UTF-16 units).
- **unknown-scope**: `highlight` MUST answer nil when the registry has no grammar for the scope.
- **line-split**: Lines MUST be split on `\r\n`, `\r` and `\n`, each one break, exactly as the bundle splits; the result MUST have one `StyledLine` per line, and a count that disagrees with the bundle's MUST throw.
- **runs**: Each run's `range` MUST be the bundle's UTF-16 `[start, length]` within its line; a range outside the line MUST throw. `fontStyle` carries the bits italic 1, bold 2, underline 4, strikethrough 8.
- **strict-colours**: A run colour MUST parse only as uppercase `#RRGGBB` (opaque) or `#RRGGBBAA`; any other text MUST throw `SyntaxHighlighterError.unexpectedColor`, never default.
- **one-engine**: The actor MUST own one `JSVirtualMachine` and `JSContext`, created on the first call that needs the engine, with the host object `ADKHost.grammarText(scopeName)` answering from the registry (`null` when absent) and `console` forwarded to the unified log.
- **promises-without-run-loop**: A bundle promise MUST be awaited by attaching `then` callbacks that resume a checked continuation; JavaScriptCore drains microtasks when the outermost call returns, so the promise settles inside that call. A promise still pending when the call returns MUST throw `SyntaxHighlighterError.promiseDidNotSettle` rather than wait. The actor MUST never spin a run loop; WebAssembly compiles synchronously in the context so `create` settles the same way.
- **theme-once**: The theme MUST be handed to the bundle's `setTheme` only when it differs from the last one set.

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

The bundle's `console` output and skipped user grammar files go to the unified log through `Loggable` (the host app's subsystem; categories `SyntaxHighlighter` and `DirectoryGrammarSource`), `console.warn` and `console.error` at error level.

## Platform Notes

- **SwiftUI**: Views take `[StyledLine]` and draw runs with their own fonts; the highlighter itself is UI-free.
- **Compose**: The same bundle runs in any JavaScript engine with WebAssembly and promises; the host contract is `ADKHost.grammarText`.
- **React/Web**: The bundle runs as is in a browser; no Swift side is needed.
- **AppKit / UIKit**: JavaScriptCore without `com.apple.security.cs.allow-jit` interprets, correct but slower; the limits keep the worst case bounded.
- **WinUI 3**: A WebView2 host would supply `ADKHost`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Language/Syntax/TextMateResources.swift` | confirmed (1.0.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Language/Syntax/GrammarSource.swift` | confirmed (1.0.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Language/Syntax/GrammarRegistry.swift` | confirmed (1.0.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Language/Syntax/LanguageResolver.swift` | confirmed (1.0.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Language/Syntax/SyntaxHighlighter.swift` | confirmed (1.0.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Language/Syntax/StyledLine.swift` | confirmed (1.0.0) |

## Design Decisions

**Decision**: Promises are awaited through `then` callbacks inside the actor's own call, never by running a run loop.
**Rationale**: JavaScriptCore drains microtasks when the outermost call returns, and the bundle uses nothing but promises, so every promise settles before the call returns; spinning a run loop from an actor would block a cooperative thread and could re-enter unrelated work.
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
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
