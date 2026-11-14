---
id: 345bb44b-1a4b-46ce-be8f-0796edbf70c9
title: "Theme Tokens"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Framework-free theme CSS parsing: split a theme's @import url() hrefs from its CSS and read the first :root block into an ordered custom-property map, plus the ThemeDelta type."
platforms:
  - typescript
  - web
tags:
  - theme
  - tokens
  - css
  - parsing
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Theme Tokens

## Overview

`tokens.ts` is the one parser for generated theme CSS. It is framework-free and isomorphic: it uses no DOM and no React, so the server-side theme style injector and the client theme editor share one implementation and cannot drift. It exports two pure functions and one type:

- `splitImports(css)` removes every `@import url(...)` rule from a theme's CSS and returns the removed hrefs beside the remaining CSS.
- `parseRootProps(css)` reads the first `:root { ... }` block of a generated theme and returns its custom properties as an insertion-ordered `Map` of name to value.
- `ThemeDelta` is the type of a theme's token map transferred as a delta: a record of custom-property name to value.

The header comment records that the token-classification, grouping and serialisation helpers that once lived in this file were dropped when the editor moved to free-form CSS, so the module is parsing only. The parser is regular-expression based; it is not a CSS parser, and the contract below describes exactly what those expressions accept. The themes package exposes the module as its `./tokens` export, and the ADH package imports it as `@adh-sdk/themes/tokens`: `AdhThemeStyle` calls both functions, and `themes-client` uses `ThemeDelta` for the stored theme `data` field and the theme write payload.

## Behavioral Requirements

### Public surface

- **exports**: The module MUST export `ThemeDelta`, `splitImports` and `parseRootProps`, and MUST export nothing else.
- **theme-delta-shape**: `ThemeDelta` MUST be `Record<string, string>`, a map from custom-property name to value; the module attaches no validation to it.
- **pure**: Both functions MUST be pure: they MUST NOT read or write the DOM, storage, the network or module state, and the same input MUST give the same output.
- **no-throw**: Neither function MUST throw on any string input; input that does not match yields an empty result, never an error.

### splitImports

- **imports-pattern**: `splitImports` MUST recognise an import rule as `@import`, whitespace, `url(`, optional whitespace, an optional single or double quote, the href, the same quote again, optional whitespace, `)`, optional whitespace and an optional `;`.
- **imports-href**: The href captured MUST be the text between the quotes (or between the parentheses when unquoted), up to the first `'`, `"` or `)`; for an unquoted href, any whitespace before the closing parenthesis is part of the captured text.
- **imports-order**: The returned `imports` array MUST list hrefs in the order the rules appear in the CSS, with duplicates kept.
- **imports-removed**: Every matched rule, including the whitespace and the `;` that follow its closing parenthesis, MUST be replaced by an empty string in `rest`; all other text, including whitespace before the rule, MUST be left unchanged.
- **imports-url-only**: The string form of an import (an `@import` followed by a quoted string rather than `url(`) MUST NOT be matched: it stays in `rest` and adds nothing to `imports`.
- **imports-none**: When no rule matches, `splitImports` MUST return an empty `imports` array and a `rest` equal to the input.
- **imports-everywhere**: Matching MUST NOT depend on position or context: a rule is removed wherever it appears in the string, including inside a comment.

### parseRootProps

- **root-block-first**: `parseRootProps` MUST read only the first match of `:root`, optional whitespace, `{`, any run of characters that are not `}`, `}`; later `:root` blocks MUST be ignored.
- **root-block-ends-at-brace**: The block MUST end at the first `}` after the opening `{`; a declaration after that brace is not read.
- **root-block-anywhere**: The block match MUST NOT be anchored, so a `:root` that is part of a longer selector (for example `html:root`) is matched too.
- **root-missing**: When the CSS has no `:root` block, `parseRootProps` MUST return an empty `Map`.
- **prop-pattern**: A custom property MUST be recognised as `--`, one or more word characters or hyphens, optional whitespace, `:`, optional whitespace, a value of one or more characters other than `;`, and a terminating `;`. Word characters are ASCII letters, digits and underscore.
- **prop-name-verbatim**: The map key MUST be the name including its leading `--`, with its case unchanged.
- **prop-value-trimmed**: The map value MUST be the captured value with leading and trailing whitespace trimmed; interior whitespace and newlines MUST be kept.
- **prop-semicolon-required**: A declaration with no terminating `;` (the last declaration of a block that omits it) MUST NOT be read.
- **prop-value-ends-at-semicolon**: A value MUST end at its first `;`, so a value that contains a semicolon (for example a `url(data:...;base64,...)`) is cut at that semicolon.
- **prop-ordered**: The `Map` MUST iterate in order of first appearance.
- **prop-duplicates**: When a name is declared twice, the later value MUST replace the earlier one, and the entry MUST keep the position of the first declaration.
- **prop-empty-value-kept**: A declaration whose value is only whitespace MUST still be read and stored as the empty string (the guard skips a match only when a capture is the empty string, and the value pattern cannot capture nothing).
- **non-custom-ignored**: Declarations that are not custom properties (names not starting with `--`) MUST be ignored.
- **comments-not-parsed**: The parser MUST NOT recognise CSS comments: a custom property written inside a comment within the block is read as if it were live.

### Ordering and concurrency

- **no-shared-state**: The shared module-level global regular expressions MUST NOT leak a match position between calls; `String.replace` and `matchAll` each start from the beginning of the string, so repeated and re-entrant calls give identical results.
- **synchronous**: Both functions MUST be synchronous and perform no I/O.

### Consumers

- **consumer-delta**: Consumer behaviour, recorded for orientation: the ADH theme style injector (its theme-switcher assets) parses the default theme's `:root` block, then for each switcher theme splits off the imports; a full-palette theme ships its remaining CSS whole with no delta, while any other theme ships a `:root` block of only the entries whose value differs from the base value. This module does not compute deltas.

## Appearance

Not applicable — this is a pure string-parsing module, not a visual component.

## States

Not applicable — this is a pure string-parsing module, not a visual component.

## Accessibility

Not applicable — this is a pure string-parsing module, not a visual component.

## Conformance Test Vectors

No test sits beside `tokens.ts`. The themes package tests (`appearanceScope.test.ts`, `AppearanceScope.test.tsx`, `buildScopedCss.test.ts`, `clearAppearance.test.ts`, `darkAlwaysThemes.test.ts`, `DocumentLoadScript.test.tsx`, `rescued-themes.test.ts`, `ThemeStyle.test.tsx`) do not target these functions, so the vectors below are derived from the regular expressions in the source and are the tests a port should write.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tokens-001 | imports-pattern, imports-href, imports-removed | `splitImports('@import url("a.css");body{}')` | `imports` is `["a.css"]`; `rest` is `body{}` |
| tokens-002 | imports-pattern, imports-removed | `splitImports("@import url( 'b.css' ) ;x")` | `imports` is `["b.css"]`; `rest` is `x` |
| tokens-003 | imports-pattern, imports-href | `splitImports("@import url(c.css)x")` (unquoted, no semicolon) | `imports` is `["c.css"]`; `rest` is `x` |
| tokens-004 | imports-order, imports-removed | `splitImports('@import url(a.css);p{}@import url(b.css);q{}')` | `imports` is `["a.css", "b.css"]`; `rest` is `p{}q{}` |
| tokens-005 | imports-order | `splitImports('@import url(a.css);@import url(a.css);')` | `imports` is `["a.css", "a.css"]`; `rest` is the empty string |
| tokens-006 | imports-url-only, imports-none | `splitImports('@import "d.css";p{}')` | `imports` is `[]`; `rest` equals the input |
| tokens-007 | imports-none, no-throw | `splitImports("")` | `imports` is `[]`; `rest` is `""` |
| tokens-008 | imports-everywhere | `splitImports('/* @import url(e.css); */p{}')` | `imports` is `["e.css"]`; `rest` is `/*  */p{}` |
| tokens-009 | prop-pattern, prop-name-verbatim, prop-value-trimmed | `parseRootProps(":root{--a:1; --B : two words ;}")` | Map with `--a` to `1` and `--B` to `two words`, in that order |
| tokens-010 | root-missing, no-throw | `parseRootProps("body{--a:1;}")` and `parseRootProps("")` | Both return an empty Map |
| tokens-011 | root-block-first | `parseRootProps(":root{--a:1;} :root{--b:2;}")` | Map has only `--a` |
| tokens-012 | prop-semicolon-required | `parseRootProps(":root{--a:1;--b:2}")` | Map has only `--a` |
| tokens-013 | prop-duplicates, prop-ordered | `parseRootProps(":root{--a:1;--b:2;--a:3;}")` | Entries in order `--a` to `3`, `--b` to `2` |
| tokens-014 | prop-value-ends-at-semicolon | `parseRootProps(":root{--i:url(data:image/png;base64,AA);}")` | `--i` maps to `url(data:image/png` |
| tokens-015 | prop-empty-value-kept | `parseRootProps(":root{--a: ;}")` | Map has `--a` to the empty string |
| tokens-016 | non-custom-ignored | `parseRootProps(":root{color:red;--a:1;}")` | Map has only `--a` |
| tokens-017 | root-block-ends-at-brace | `parseRootProps(":root{--a:1;} p{--b:2;}")` | Map has only `--a` |
| tokens-018 | root-block-anywhere | `parseRootProps("html:root{--a:1;}")` | Map has `--a` to `1` |
| tokens-019 | comments-not-parsed | `parseRootProps(":root{/* --a:1; */--b:2;}")` | Map has `--a` to `1` and `--b` to `2` |
| tokens-020 | prop-pattern | `parseRootProps(":root{--é:1;--a_b-c:2;}")` | Map has only `--a_b-c` to `2`; the non-ASCII name is not matched |
| tokens-021 | no-shared-state, pure | Call `splitImports` twice on the same string containing an import | Both calls return equal results |

## Edge Cases

- **Empty or no-match input**: `splitImports("")` MUST return no imports and an empty `rest`; `parseRootProps("")` MUST return an empty Map. Neither throws.
- **Non-string input**: Both functions are typed to take a `string`; the source does no runtime check, so a non-string argument is a caller error outside the contract.
- **String-form imports**: An `@import "x.css"` rule is left in `rest` and not reported (MUST). The imports of the generated themes use the `url(...)` form, so this is the contract rather than a defect.
- **Imports inside comments or other text**: A matching rule is removed and reported wherever it occurs (MUST), with no awareness of comments.
- **Last declaration without a semicolon**: Dropped silently (MUST). Generated theme CSS ends every declaration with `;`; free-form CSS from the editor may not, and its last property is then missing from the map.
- **Value containing a semicolon**: Cut at the first `;` (MUST). A data URL or other value with an interior semicolon is truncated and the remainder discarded.
- **Value containing a closing brace**: The block ends at the first `}` anywhere inside it, including inside a quoted string or a function value, so later declarations are lost (MUST).
- **Duplicate property names**: The last value wins and the first position is kept (MUST).
- **Whitespace-only value**: Stored as the empty string (MUST).
- **Multiple `:root` blocks**: Only the first is read (MUST); the comment on the block pattern says the first `:root` block of a generated theme is its token block and what follows is theme-independent.
- **Concurrent access**: Not a concern; the functions are synchronous and pure, and JavaScript runs them one at a time. The module-level regular expressions carry the global flag but are used only through `replace` and `matchAll`, which do not depend on a prior match position.
- **Error states, offline and cancellation**: Not applicable; there is no I/O, no dependency that can fail and no long-running work to cancel. Malformed CSS never raises; it yields fewer entries.
- **Very large input**: The source sets no size limit and no timeout; the patterns are single linear scans.

## Configuration

Not applicable: the functions take only the CSS string, and the module has no parameters, defaults, environment variables, settings keys or injected dependencies.

## Deep Linking

Not applicable: the module parses strings and has no routes, URLs of its own or entry points.

## Localization

Not applicable: the module returns no user-facing text and raises no error messages.

## Accessibility Options

Not applicable: the module has no visual output and does not respond to reduce-motion, contrast or colour-differentiation options.

## Feature Flags

Not applicable: the source defines and reads no flags.

## Analytics

Not applicable: the source emits no events.

## Privacy

Not applicable: the module holds no state, stores nothing, transmits nothing and handles only theme CSS text, which is not personal data.

## Logging

Not applicable: the source contains no log calls.

## Platform Notes

- **SwiftUI**: Start from a small struct with two static functions, using `NSRegularExpression` or Swift `Regex` for the same patterns, and an array of name and value pairs for the property map, since a `Dictionary` does not keep insertion order. A native app would normally not parse CSS at all; it would hold tokens as a typed theme struct injected through the SwiftUI `Environment`, with `Color` and `Font` values instead of strings. Keep a parser only when it must read the shared theme CSS.
- **Compose**: Use Kotlin `Regex` with `findAll` and a `LinkedHashMap<String, String>`; `put` on an existing key keeps the first position and replaces the value, which matches the duplicate rule. A native app would map tokens onto `MaterialTheme` colorScheme, typography and shapes rather than parse CSS.
- **React/Web**: The source is `packages/web/packages/themes/src/tokens.ts`, exported as `@adh-sdk/themes/tokens` and used by the ADH package's `AdhThemeStyle.tsx` and `themes-client.ts`. It has no `"use client"` directive and imports nothing, so it runs unchanged in server components, the browser and Node. A port keeps the regular expressions as written; a browser could read the same data through `getComputedStyle`, but that needs a DOM and would break the server-side use.
- **AppKit / UIKit**: Same as SwiftUI for the parsing itself. Apply the result to `NSColor` and `UIColor` assets or one theme object consulted by views; there is no CSS cascade, and `NSAppearance` or `UITraitCollection` chooses the light or dark variants.
- **WinUI 3**: Use `System.Text.RegularExpressions.Regex` with the same patterns and `RegexOptions.ECMAScript`, so `\w` stays ASCII-only (in .NET `\w` otherwise matches Unicode letters and would accept names such as `--é`). Return the properties as a `List<KeyValuePair<string, string>>` or an `OrderedDictionary<string, string>` (.NET 9), because `Dictionary<string, string>` does not guarantee order and the contract needs first-position, last-value-wins semantics. `ThemeDelta` maps to `IReadOnlyDictionary<string, string>` and serialises with `System.Text.Json`. In a WinUI app the tokens are usually not CSS: they live in a `ResourceDictionary` with `ThemeDictionaries` keyed `Light` and `Dark` holding `SolidColorBrush` and `x:Double` resources, read with `ThemeResource`. A CSS-token parser is needed only to import the shared theme text, after which each name becomes a resource key and each value is converted to a `Color` or `Brush` and written to `Application.Current.Resources`. The `@import` hrefs have no XAML equivalent; font imports map to `FontFamily` URIs such as `ms-appx:///Assets/Fonts/Font.ttf#Family`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| ios | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| web | `packages/web/packages/themes/src/tokens.ts` | confirmed (1.0.1) |

## Design Decisions

**Decision**: Keep the parser free of the DOM and React.
**Rationale**: The header comment states that it is shared by the server-side injector and the client editor so there is one parser and no drift.
**Approved**: pending

**Decision**: Parse with regular expressions instead of a CSS parser.
**Rationale**: Inferred from the source: the input is generated theme CSS with a known shape (a leading `:root` token block), so a few patterns suffice and need no dependency. The cost is the edge cases listed above (semicolons and braces inside values, comments, a missing final semicolon).
**Approved**: pending

**Decision**: Read only the first `:root` block.
**Rationale**: The comment on the block pattern says the first `:root` block of a generated theme is its token block, and the utilities and body rules that follow are theme-independent.
**Approved**: pending

**Decision**: Drop the token-classification, grouping and serialisation helpers.
**Rationale**: The header comment records they were removed when the editor moved to free-form CSS, leaving parsing only; `ThemeDelta` remains as the transfer type.
**Approved**: pending

**Decision**: Return the properties as a `Map` rather than a plain object.
**Rationale**: The doc comment calls it an ordered prop to value map; consumers iterate it in declaration order when building a delta block.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | partial | internationalization |

The module does one thing, string parsing with no DOM, React or I/O, so separation of concerns passes. No test file targets `tokens.ts`; its consumers are exercised only indirectly, so unit-test coverage fails. The functions never throw, but malformed input (a missing final semicolon, a value with a semicolon or brace) quietly yields fewer or shorter entries with no signal, so explicit error handling is partial. Property names accept only ASCII word characters while values and hrefs pass any text through unchanged, so unicode support is partial.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Claims verified against source |
