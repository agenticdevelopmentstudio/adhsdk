---
id: 54b48020-df78-4b41-853c-268ad0ea6b84
title: "Theme Style"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "ThemeStyle and buildScopedCss: render a theme's CSS as an inline style tag, globally or rewritten into an @scope block that can force light or dark."
platforms:
  - typescript
  - web
tags:
  - theme
  - appearance
  - color-mode
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Theme Style

## Overview

Theme Style turns a named theme into CSS on the page. `ThemeStyle` is a React component that looks the theme up in the manifest (`themes`, keyed by `ThemeKey`) and renders its stylesheet as one inline `style` element. With no `scope` the stylesheet is emitted verbatim and styles the whole document. With a `scope` (a CSS selector) the stylesheet is first rewritten by `buildScopedCss` into an `@scope (<selector>)` block, so the theme applies only inside that subtree and can coexist with the host page's own theme. An optional `colorMode` forces the light or dark variant of a scoped theme instead of following the document's `html.dark` class.

`buildScopedCss` is also exported from the module (though not re-exported by the package index), so external consumers can scope stylesheets that are not in the manifest. Most of the module's logic is the set of selector rewrites it applies to the theme stylesheets' root anchors (`html:root`, `:root`, `body`), because an anchor it does not recognise silently drops that theme's palette inside the scope.

## Behavioral Requirements

### Types and exports

- **theme-style-props**: `ThemeStyle` MUST accept `theme` (a `ThemeKey`, required), `scope` (an optional string) and `colorMode` (an optional `ThemeColorMode`, default `system`).
- **theme-color-mode-type**: `ThemeColorMode` MUST be exactly one of `system`, `light` or `dark`.
- **build-scoped-css-signature**: `buildScopedCss(css, scope, colorMode)` MUST take a stylesheet string and a scope selector, take `colorMode` as an optional third argument defaulting to `system`, and return a string.
- **public-transform**: `buildScopedCss` MUST be exported from the `ThemeStyle` module; the source's test calls it a public export whose legacy `:root` forms must keep resolving even though no shipped theme uses them. The package index re-exports only `ThemeStyle` and `ThemeStyleProps`, and `package.json` has no `./ThemeStyle` subpath, so the function is reachable by deep path to the built `ThemeStyle` entry, not from the package root.

### Component rendering

- **unknown-theme-renders-nothing**: When `themes[theme]` has no entry, `ThemeStyle` MUST return `null` and MUST NOT throw; the source comment gives a stale persisted choice or a typo in a consumer's theme list as the cases.
- **unscoped-passthrough**: When `scope` is absent or an empty string, `ThemeStyle` MUST emit the theme's CSS unchanged, `@import` lines included.
- **scoped-transform**: When `scope` is a non-empty string, `ThemeStyle` MUST emit the result of `buildScopedCss(entry.css, scope, colorMode)`.
- **color-mode-scoped-only**: `colorMode` MUST have no effect when `scope` is not set.
- **inline-style-element**: `ThemeStyle` MUST render a single `style` element inline in the component's own output, not append it to `document.head` through an effect, so the CSS is in server-rendered HTML and applies on first paint.
- **raw-css-body**: The `style` element's body MUST be set as raw HTML (`dangerouslySetInnerHTML`) so CSS punctuation such as `>` is not escaped; the source comment notes the CSS comes from the static theme manifest, not user input.
- **rerender-swaps-css**: Re-rendering with a different `theme`, `scope` or `colorMode` MUST replace the style body with the newly resolved CSS.

### Element ids

- **global-id**: An unscoped `style` element MUST carry the id `adh-sdk-theme`.
- **scoped-id-prefix**: A scoped `style` element MUST carry an id of the form `adh-sdk-theme-scoped-<slug>` when `scope` is already its own slug, and `adh-sdk-theme-scoped-<slug>-<hash>` otherwise, where `<hash>` is the 32-bit FNV-1a hash of the raw `scope` string in base 36.
- **scoped-id-slug**: The slug MUST be built by replacing every run of characters outside `a-z`, `A-Z`, `0-9`, `_` and `-` with a single `-`, trimming leading and trailing `-`, then lowercasing.
- **distinct-scope-ids**: Two different `scope` strings MUST get different ids, even when they reduce to the same slug (for example `.host-a`, `#host-a`, `.Host-A` and `host-a`). The hash suffix on every scope that is not its own slug guarantees this.

### Scoped CSS output

- **scope-wrapper**: `buildScopedCss` MUST return the hoisted imports, a newline, `@scope (<scope>) {`, a newline, the rewritten body, a newline and `}`.
- **import-hoisting**: Every line of the form `@import url(...);` (the entire line, optional trailing whitespace) MUST be removed from the body and placed, joined by newlines, before the `@scope` block, because an `@import` is invalid inside a rule.
- **import-form-limit**: Only the `@import url(...)` form on its own line is hoisted; an `@import` written any other way stays in the body.
- **anchors-at-line-start**: Every root-anchor rewrite MUST match only at a line start, after optional spaces or tabs, or after a comma and optional whitespace, so an indented rule (such as one nested in a media block) is rewritten and prose or property values are not.
- **horizontal-whitespace-only**: The leading-whitespace allowance MUST be spaces and tabs only, never newlines, so a match cannot swallow a preceding blank line.
- **html-root-bare**: A bare `html:root` anchor (followed by whitespace, a comma or `{`) MUST become `:scope`.
- **html-root-qualified**: An `html:root` anchor followed by any run of attribute selectors or `:not(...)` qualifiers MUST be rewritten to `html<qualifiers> :scope`, moving the qualifiers onto an `html` ancestor of the scope, because they describe the document, not the scoped element.
- **html-root-light-anchor**: An `html:root[data-color-mode]:not(.dark)` anchor that is the entire selector of its own rule (immediately followed by optional whitespace and `{`) MUST be rewritten according to `colorMode`: `system` gives `html[data-color-mode]:not(.dark) :scope`, `light` gives `:scope`, `dark` gives `:scope.pc-colormode-off`.
- **light-anchor-not-in-lists**: The same discriminator MUST NOT receive the colorMode rewrite when it is followed by a comma or by further qualifiers (it is then not directly followed by `{`); it takes the qualified rewrite instead, so dark-always themes (charcoal, fishlamp), whose combined selector list ends in qualified members, get no light variant forced on them. The rule is a lookahead for `{`, not a check that the item stands alone: the same discriminator written as the last item of a comma list, directly before `{`, would still receive the colorMode rewrite.
- **legacy-root-dark**: A `:root.dark` anchor MUST become `:scope` for `dark`, `:scope.pc-colormode-off` for `light` and `html.dark :scope` for `system`.
- **legacy-root-not-dark**: A `:root:not(.dark)` anchor MUST become `:scope` for `light`, `:scope.pc-colormode-off` for `dark` and `html:not(.dark) :scope` for `system`.
- **legacy-root-bare**: A bare `:root` anchor (followed by whitespace, a comma, `{` or `:`) MUST become `:scope`.
- **body-anchor**: A `body` selector (followed by whitespace, a comma, `{`, `:` or `.`) MUST become `:scope`.
- **rewrite-order**: The rewrites MUST run in this order: import removal, `html:root` light anchor, `html:root` qualified, `html:root` bare, `:root.dark`, `:root:not(.dark)`, bare `:root`, `body`; qualified forms are tried before bare ones so a document qualifier is never left on the scoped element.
- **forced-mode-keeps-dark-block**: For `light`, the bare `html:root` dark block MUST NOT be removed; both blocks become `:scope` and the light block wins because it is later in source order. For `dark`, the light block is sent to the never-matching selector.
- **never-selector**: The never-matching selector MUST be `:scope.pc-colormode-off`.
- **system-mode-default**: With `colorMode` of `system`, the output MUST follow the document: dark rules apply under `html.dark` and light rules under `html:not(.dark)` or `html[data-color-mode]:not(.dark)`.
- **no-anchor-left-behind**: No shipped theme's scoped output MUST contain an unrewritten `:root` or `html:root` anchor at a line start or after a comma; the source test asserts this against every stylesheet in the manifest.
- **scope-not-escaped**: `buildScopedCss` MUST insert `scope` into the `@scope (...)` prelude as given, with no validation or escaping; an invalid selector yields CSS the browser ignores.

### Ordering and concurrency

Not applicable: `buildScopedCss` is a synchronous pure function, `ThemeStyle` renders synchronously on the single JavaScript thread with no effects, and neither keeps module state beyond compiled regular expressions and constants.

### Persistence, network and side effects

Not applicable: the module reads no storage, makes no network request and writes nothing but the rendered `style` element. The `@import` lines it hoists are fetched by the browser, not by this code.

## Appearance

Not applicable — this is a stylesheet injector, not a visual component. Its only output is a `style` element, which has no rendered box; what it paints is defined by the theme stylesheets themselves.

## States

Not applicable — this is a stylesheet injector, not a visual component. Its logical outcomes (unscoped, scoped, unknown theme) are specified under Behavioral Requirements.

## Accessibility

Not applicable — this is a stylesheet injector, not a visual component. It renders no interactive or text content.

## Conformance Test Vectors

Vectors 001 to 011 derive from `__tests__/ThemeStyle.test.tsx` and `__tests__/buildScopedCss.test.ts` beside the source; the rest derive from the source. The component tests mock the manifest with a stub theme whose CSS is `:root:not(.dark) { --a: 1; } :root.dark { --a: 2; }`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| theme-style-001 | global-id, inline-style-element, unscoped-passthrough | `ThemeStyle.test.tsx` "renders an unscoped theme inline": `<ThemeStyle theme="stub" />` | a `style` in the render container with id `adh-sdk-theme`, none in `document.head`, body contains `--a: 1` |
| theme-style-002 | scoped-id-prefix, scoped-id-slug | "gives two differently-scoped renders two different ids": scopes `.host-a` and `.host-b` rendered on one page | both ids non-empty and different from each other |
| theme-style-003 | theme-color-mode-type, legacy-root-dark, legacy-root-not-dark | "resolves colorMode dark and light to different CSS": scope `.host`, `colorMode` `dark` then `light` | the two style bodies differ |
| theme-style-004 | system-mode-default | "defaults colorMode to system": scope `.host`, no `colorMode` | body contains `html.dark :scope` and `html:not(.dark) :scope` |
| theme-style-005 | unknown-theme-renders-nothing | "renders nothing for an unknown theme key": `theme="not-a-real-theme"` | render does not throw and no `style` element exists |
| theme-style-006 | html-root-bare, scope-wrapper | `buildScopedCss.test.ts` "rewrites a full-palette theme's dark anchor": input `html:root {` with a custom property, scope `.host` | output contains `:scope {` and `@scope (.host)` |
| theme-style-007 | html-root-light-anchor | "keeps the light block conditional on data-color-mode": input `html:root[data-color-mode]:not(.dark) {...}` | output contains `html[data-color-mode]:not(.dark) :scope {` and no line is a bare `:scope {` |
| theme-style-008 | legacy-root-bare, legacy-root-dark | "still resolves the legacy :root / :root.dark pair": `:root {` and `:root.dark {` blocks | output contains `:scope {` and `html.dark :scope {` |
| theme-style-009 | import-hoisting | "hoists @import above the @scope block": an `@import url('https://fonts.example/x.css');` line then `html:root {` | the `@import` appears before `@scope` in the output |
| theme-style-010 | forced-mode-keeps-dark-block, light-anchor-not-in-lists | "light/dark against dracula" and "leaves charcoal.css byte-identical": dracula with `light`, then `dark`; charcoal with all three modes | dracula `light`: at least two bare `:scope {` rules and no `html[data-color-mode]`; dracula `dark`: contains `:scope.pc-colormode-off {`; charcoal output identical for `system`, `light` and `dark` |
| theme-style-011 | no-anchor-left-behind | "leaves no unrewritten root anchor in any shipped theme": every key in `themeIds`, scope `.host` | no output matches a line-start or comma-preceded `:root` or `html:root` |
| theme-style-012 | html-root-qualified | input `html:root[data-contrast='high'] {` with scope `.host` | output contains `html[data-contrast='high'] :scope {` |
| theme-style-013 | anchors-at-line-start, horizontal-whitespace-only | input with `  html:root {` indented inside a media block, preceded by a blank line | the rule becomes `  :scope {` and the blank line is kept |
| theme-style-014 | body-anchor | input `body {` and `body.dark {` | each becomes `:scope {` and `:scope.dark {` |
| theme-style-015 | scoped-id-slug | scope `Host B > .x` | id is `adh-sdk-theme-scoped-host-b-x-g3a3in` (the run space, `>`, space, `.` collapses to one `-`; the scope is not its own slug, so the FNV-1a hash is appended) |
| theme-style-016 | color-mode-scoped-only | `<ThemeStyle theme="stub" colorMode="dark" />` with no `scope` | body equals the stub CSS exactly |
| theme-style-017 | distinct-scope-ids, scoped-id-prefix | "keeps scopes that differ only in punctuation or case on different ids": scopes `.host-a`, `#host-a`, `.Host-A`, `host-a` | four distinct ids; `host-a` gives `adh-sdk-theme-scoped-host-a`; `.host-a` gives `adh-sdk-theme-scoped-host-a-5l1jl5`; `#host-a` gives `adh-sdk-theme-scoped-host-a-lcrp5y` |
## Edge Cases

- **Unknown theme key** (MUST): `ThemeStyle` renders nothing and does not throw, so a stale persisted choice does not take the page down.
- **Empty scope string** (MUST): treated as no scope; the CSS is emitted unscoped under `adh-sdk-theme`.
- **Empty stylesheet** (MUST): `buildScopedCss('', '.host')` returns an empty import line, then an `@scope (.host)` block with an empty body.
- **No imports** (MUST): the hoisted-imports part is an empty string, so the output begins with a newline.
- **Stylesheet with no recognised anchor** (MUST): rules pass through unchanged inside the `@scope` block; the module does not warn, which is how a new anchor shape would silently drop a palette (the reason the shipped-theme test exists).
- **Dark-always themes** (MUST): a theme whose light discriminator is followed by a comma or carries further qualifiers (charcoal's combined selector list) gets no light variant forced under `light`; its output is identical in all three modes.
- **Forced light keeps the dark block** (MUST): under `light` the dark `html:root` block still applies as `:scope`; the light block only wins by coming later in the stylesheet, so a theme with its light block first would render dark.
- **Selector that reduces to an empty or shared slug** (SHOULD NOT occur): a scope of only punctuation yields an empty slug and the id `adh-sdk-theme-scoped--<hash>`. Distinct selectors that share a slug still get distinct ids through the hash suffix (`distinct-scope-ids`).
- **Invalid scope selector** (not validated): the string is inserted as given and the browser discards the invalid `@scope` rule, so the theme silently does not apply.
- **Browser without `@scope` support** (not handled): the source has no fallback, so an engine that lacks `@scope` ignores the whole scoped block.
- **Unscoped colorMode** (MUST): `colorMode` is ignored without `scope`.
- **Multiple scoped themes on one page** (MUST): each scope gets its own id, so several blocks coexist; this is the case the id scheme exists for.
- **Server rendering** (MUST): the `style` element is part of the server HTML; nothing depends on `window` or `document`.
- **Network and offline**: not applicable; the module makes no requests (hoisted `@import` lines are the browser's concern).
- **Concurrent access**: not applicable; synchronous and stateless.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `theme` | `ThemeKey` | required | Key into the `themes` manifest |
| `scope` | `string` | none | CSS selector to confine the theme to; absent or empty means document-wide |
| `colorMode` | `ThemeColorMode` | `system` | `system` follows `html.dark`; `light` or `dark` forces a variant; scoped use only |

Fixed constants: global id `adh-sdk-theme`; scoped id prefix `adh-sdk-theme-scoped`; never-matching selector `:scope.pc-colormode-off`; document selectors `html.dark :scope`, `html:not(.dark) :scope` and `html[data-color-mode]:not(.dark) :scope`. The injected dependency is the `themes` manifest imported from `./manifest`, which the component test replaces with a mock.

## Deep Linking

Not applicable: the module reads no URL and registers no routes.

## Localization

Not applicable: the module has no user-facing strings; it renders CSS only and its single failure path returns `null` without a message.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the module animates nothing; any media-query handling lives in the theme stylesheets it passes through. |
| Increase Contrast | Not applicable to the code itself: it moves `[data-contrast=...]` qualifiers onto an `html` ancestor so contrast variants in a theme keep working inside a scope, but it reads no preference. |
| Differentiate Without Color | Not applicable: the module has no visual output of its own. |

## Feature Flags

Not applicable: the module reads no feature flag.

## Analytics

Not applicable: the module emits no events.

## Privacy

- **Data collected**: none.
- **Storage**: none; the module reads and writes no storage.
- **Transmission**: none from this code; a hoisted `@import url(...)` is fetched by the browser from whatever host the theme names.
- **Retention**: not applicable; the `style` element lives only as long as the component is mounted.

## Logging

Not applicable: the module makes no log calls; an unknown theme returns `null` silently, as the source comment intends.

## Platform Notes

- **SwiftUI**: There is no stylesheet to inject. Model a theme as a value type of colors and fonts placed in the environment (`EnvironmentValues` key) on a subtree root, which gives the same scoped effect as `@scope`. Force light or dark on that subtree with `.preferredColorScheme(.light)` or `.dark`; `system` is the default and follows the surrounding scheme.
- **Compose**: Wrap the subtree in a nested `MaterialTheme` with its own `ColorScheme`, which scopes colors by composition. Choose the scheme with `isSystemInDarkTheme()` for `system` or a fixed `lightColorScheme` or `darkColorScheme` to force a mode. Nothing is rewritten at runtime.
- **React/Web**: The source is `packages/web/packages/themes/src/ThemeStyle.tsx`, backed by `manifest.ts` and the stylesheets under `src/styles`, with tests in `src/__tests__/ThemeStyle.test.tsx` and `buildScopedCss.test.ts`. The behavior depends on CSS `@scope` and the `:scope` selector, and on rendering the `style` element inline so server HTML carries it.
- **AppKit / UIKit**: Apply a theme as a set of semantic colors resolved through `NSAppearance` or `UITraitCollection` on one view subtree. Force a mode with `NSView.appearance` (set to `NSAppearance(named: .darkAqua)` or `.aqua`) or `overrideUserInterfaceStyle` on a `UIView`. There is no text rewriting; the equivalent of the never-matching selector is simply not applying the variant.
- **WinUI 3**: Express a theme as a `ResourceDictionary` with `ThemeDictionaries` keyed `Light` and `Dark`, merged into the `Resources` of the subtree's root `FrameworkElement` (a `Grid` or `Page`) so it is scoped by resource lookup rather than by selector rewriting. Force a variant with `FrameworkElement.RequestedTheme` set to `ElementTheme.Light` or `Dark`; `ElementTheme.Default` is `system` and follows the app theme. Swap themes by replacing the dictionary in `MergedDictionaries` and let `{ThemeResource}` bindings update. If CSS must be rewritten at runtime (for example for a WebView2 host), `buildScopedCss` ports as a pure `string` to `string` method using `System.Text.RegularExpressions.Regex` with `RegexOptions.Multiline`, the same anchor patterns and the same ordered `Replace` calls; keep the horizontal-whitespace rule as the class `[ \t]`, not `\s`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| ios | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| web | `packages/web/packages/themes/src/ThemeStyle.tsx` | confirmed (1.0.1) |

## Design Decisions

**Decision**: Render the `style` element inline during render instead of appending it to `document.head` in an effect.
**Rationale**: The source comment states it puts the CSS in the SSR HTML and applies it on first paint, avoiding a flash of unstyled content; the test file records that a head-side-effect version once passed every gate unnoticed.
**Approved**: pending

**Decision**: Use one element id per scope (`adh-sdk-theme-scoped-<slug>`, plus a hash of the raw selector when the selector is not its own slug) instead of a shared scoped id.
**Rationale**: The source comment says a page can carry several scoped themes, and a shared id would be duplicate invalid HTML where `getElementById` silently returns the first.
**Approved**: pending

**Decision**: Rewrite the stylesheet text with ordered regular expressions into an `@scope` block instead of authoring scoped stylesheets.
**Rationale**: Inferred from the source: the same shipped theme stylesheets (the source comments count 41; the manifest lists 39 themes) serve both document-wide and scoped use. The cost, documented in the comments, is that an unrecognised anchor drops the whole palette with no error, which is why a test runs every shipped theme.
**Approved**: pending

**Decision**: Move document-state qualifiers (`[data-color-mode]`, `:not(.dark)`, `[data-contrast=...]`) onto an `html` ancestor of `:scope`.
**Rationale**: The source comment explains these qualifiers describe the document, not the scoped element; hanging them on the scoped element matches nothing, silently.
**Approved**: pending

**Decision**: Match the light anchor only when it is the whole selector of its own rule.
**Rationale**: The source comment states dark-always themes (charcoal, fishlamp) carry the same discriminator as one comma-list item, and rewriting it would hand them a light variant they do not have.
**Approved**: pending

**Decision**: For forced `light`, collapse the light block to `:scope` and leave the dark block in place, relying on source order.
**Rationale**: The source comment states the dark block is never removed; the light block wins because it is later. This ties correctness to the stylesheet order of full-palette themes.
**Approved**: pending

**Decision**: Allow only spaces and tabs before an anchor, not any whitespace.
**Rationale**: The source comment says `\s*` would eat newlines and let one match swallow a preceding blank line, while indented anchors inside media blocks do exist.
**Approved**: pending

**Decision**: Keep the legacy `:root`, `:root.dark` and `:root:not(.dark)` rewrites although no shipped theme uses them.
**Rationale**: The source test calls this a contract regression test: `buildScopedCss` is public and an external stylesheet may still use that shape.
**Approved**: pending

**Decision**: Return `null` for an unknown theme key rather than throw.
**Rationale**: The source comment: a throw would take down a whole page over a style tag.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | platform-compliance |

The module keeps one concern: it turns a theme key into a style element, a pure function does the rewriting, and the manifest and stylesheets live elsewhere, so separation of concerns passes. Two test files sit beside the source and cover rendering, ids, every colorMode path, import hoisting and the real stylesheets, so unit-test coverage passes; the attribute-qualified, indented and `body` rewrites are covered only by the source's comments and the shipped-theme sweep, not by dedicated assertions. An unknown theme is handled explicitly, but an invalid scope or an unrecognised anchor fails without any signal, so explicit error handling is partial. Following the document's `html.dark` class by default and offering a forced mode satisfies platform theming.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Every distinct scope gets a distinct style id through an FNV-1a hash suffix; claims verified against source |
