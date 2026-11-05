---
id: f86178c6-4255-4d66-86e7-0b3b5a2e00c0
title: Source Code Panel
domain: adhsdk://recipes/source-code-panel
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A syntax-highlighted code display component with optional copy and filename
  display.
platforms:
- typescript
- web
tags:
- code
- syntax-highlighting
- clipboard
- shiki
depends-on: []
related: []
references:
- https://shiki.style
approved-by: ''
approved-date: ''
---

# Source Code Panel

## Overview

The Source Code Panel displays syntax-highlighted source code with optional header containing filename and copy-to-clipboard button. It accepts code as a string, specifies the language for highlighting, and renders using Shiki syntax highlighter with theme support from toolkit-controlled CSS or explicit prop.

## Behavioral Requirements

- **render-code**: Component MUST display the provided code string.
- **accept-language**: Component MUST accept a `lang` prop specifying the language; defaults to `'tsx'` if unspecified.
- **shiki-highlighting**: Component MUST attempt to syntax-highlight code using Shiki, applying the resolved theme.
- **theme-from-prop**: Component MUST use the `theme` prop if provided; theme prop takes precedence over CSS-derived theme.
- **theme-from-css**: Component MUST read `--scp-shiki-theme` CSS custom property from the panel root element; property value is treated as a quoted string and quotes are stripped.
- **theme-fallback**: Component MUST use `'github-dark'` as the fallback theme when `theme` prop is not provided and `--scp-shiki-theme` is not set or empty.
- **watch-theme-changes**: Component MUST observe mutations to the `adh-sdk-theme` style element and re-read the theme CSS property when it changes, provided `theme` prop is not set.
- **header-when-content**: Component MUST display a header when filename is provided OR showCopy is true.
- **display-filename**: Component MUST display the filename in the header if provided; if filename is not provided, display the language code instead.
- **show-copy-button**: Component MUST display a "Copy" button when `showCopy` is true.
- **copy-on-click**: Component MUST copy the code string to clipboard when the copy button is clicked, using `navigator.clipboard.writeText`.
- **show-copied-state**: Component MUST display "Copied" text in the button for 1200ms after a successful copy operation.
- **reset-copied-state**: Component MUST return the button text to "Copy" after 1200ms in the copied state.
- **handle-copy-failure**: Component MUST silently no-op if clipboard access is denied or unavailable; no error message or state change occurs.
- **render-highlighted-html**: Component MUST render the Shiki-generated HTML directly into the DOM via `dangerouslySetInnerHTML` when highlighting succeeds. Shiki escapes the source `code` while producing this HTML, so only Shiki's own escaped output — never raw `code` — is ever injected. When this branch renders, the loading/error fallback `<pre>` is not rendered (see **clear-busy-on-error**).
- **fallback-to-preformatted**: Component MUST render code in a `<pre><code>` element with the plain code string when highlighting fails.
- **show-loading-state**: Component MUST display the plain `<pre><code>` fallback with `aria-busy="true"` attribute while highlighting is in progress.
- **clear-busy-on-error**: When highlighting fails, the fallback `<pre>` MUST render without the `aria-busy` attribute — the fallback persists, but is no longer marked busy. When highlighting succeeds instead, the fallback is not rendered at all; see **render-highlighted-html**.
- **discard-stale-highlight-results**: Component MUST discard the result of an in-progress highlight operation if `code`, `lang`, or `theme` changes before it resolves, or if the component unmounts; no state update is applied for a stale result.
- **support-maxheight**: Component MUST accept a `maxHeight` prop and apply it as inline CSS `max-height` style on the body container if provided; a numeric value is interpreted as pixels.
- **support-classname**: Component MUST accept a `className` prop and apply it to the root div; root element always has `scp-root` class, and provided className is appended.

## Appearance

- **Container**: Root div with class `scp-root`
- **Header**: Optional header element with class `scp-header`, displays only when filename or showCopy is true
- **Filename/Language span**: Class `scp-filename`, displays filename or language code
- **Copy button**: Class `scp-copy`, type="button", displays "Copy" or "Copied"
- **Body container**: Div with class `scp-body`, contains highlighted code or fallback
- **Highlighted code**: Div with class `scp-shiki`, receives Shiki-generated HTML
- **Fallback code**: `<pre>` with class `scp-fallback`, contains `<code>` child with plain text; may have `aria-busy` attribute during loading
- **Custom className**: Appended to root after `scp-root` if provided
- **Max height**: Applied as inline `max-height` CSS on body container if maxHeight prop is provided
- **Font**: Shiki theme controls font rendering in highlighted code; fallback uses browser default monospace
- **Colors**: Shiki theme controls syntax highlighting colors; fallback text color follows default foreground

## States

| State | Appearance change |
|-------|------------------|
| Default | Code is displayed with syntax highlighting applied or fallback `<pre><code>` if highlight pending |
| Copy button: "Copy" | Button text displays "Copy" |
| Copy button: "Copied" | Button text displays "Copied" for 1200ms after successful copy |
| Loading | Fallback `<pre><code>` renders with `aria-busy="true"` |
| Error (highlight failed) | Fallback `<pre><code>` renders without `aria-busy` |
| Hidden header | Header not rendered when both filename is falsy and showCopy is false |

## Accessibility

- **Role**: Container with code content; use `<pre>` and `<code>` for fallback to provide semantic meaning
- **Copy button**: Semantic `<button type="button">` element with text content ("Copy" or "Copied")
- **Loading indicator**: When loading, fallback `<pre>` element has `aria-busy="true"` to announce in-progress state
- **Code representation**: Fallback uses plain `<pre><code>` structure; Shiki HTML is injected as-is without additional ARIA labels
- **Minimum touch target**: Copy button SHOULD be at least 44×44pt; source CSS (`.scp-copy { padding: 0.15rem 0.5rem; font-size: 0.7rem; }` in `source-code-panel.css`) renders it well under that size

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| scp-001 | render-code | code="const x = 1" | Code string appears in rendered output |
| scp-002 | accept-language | lang="python" | Shiki receives "python" as language identifier |
| scp-003 | theme-from-prop | theme="nord" | Component uses "nord" theme, ignoring CSS property |
| scp-004 | theme-from-css | theme not provided, --scp-shiki-theme set to 'github-light' | Component uses "github-light" theme (quotes stripped) |
| scp-005 | theme-fallback | theme not provided, --scp-shiki-theme not set | Component uses "github-dark" as fallback |
| scp-006 | watch-theme-changes | theme not provided, the `#adh-sdk-theme` `<style>` element's content mutates (e.g. toolkit switches theme), changing the computed `--scp-shiki-theme` value | Component re-reads `--scp-shiki-theme` and updates highlighted output |
| scp-007 | header-when-content | filename provided | Header renders with filename |
| scp-008 | header-when-content | filename not provided, showCopy=true | Header renders with copy button |
| scp-009 | display-filename | filename="App.tsx" | Header displays "App.tsx" |
| scp-010 | display-filename | filename not provided, lang="jsx" | Header displays "jsx" |
| scp-011 | show-copy-button | showCopy=true | "Copy" button is visible and clickable |
| scp-012 | copy-on-click | showCopy=true, code="test" | Clicking "Copy" button copies "test" to clipboard |
| scp-013 | show-copied-state | Copy succeeds | Button text changes to "Copied" |
| scp-014 | reset-copied-state | "Copied" state active for 1200ms | Button text returns to "Copy" after 1200ms |
| scp-015 | handle-copy-failure | clipboard access denied | No error state or message; component continues functioning |
| scp-016 | render-highlighted-html | Shiki highlight succeeds | Shiki HTML renders in `.scp-shiki` div; fallback `<pre>` is not rendered |
| scp-017 | fallback-to-preformatted | Shiki highlight fails | Code renders in `<pre><code>` with class `scp-fallback` |
| scp-018 | show-loading-state | Highlighting in progress | Fallback `<pre>` renders with `aria-busy="true"` |
| scp-019 | clear-busy-on-error | Shiki highlighting fails | Fallback `<pre>` renders with class `scp-fallback` and no `aria-busy` attribute; `.scp-shiki` is not rendered |
| scp-020 | support-maxheight | maxHeight="400px" | Body container has inline style `max-height: 400px` |
| scp-021 | support-classname | className="custom-theme" | Root div has class `scp-root custom-theme` |
| scp-022 | fallback-to-preformatted | lang=null (explicit null, not omitted) | Shiki rejects the invalid language identifier and throws; component falls back to `<pre><code>` with no `aria-busy` |
| scp-023 | fallback-to-preformatted | lang="not-a-real-language" | Shiki rejects the unknown identifier and throws; component falls back to `<pre><code>` with no `aria-busy`, same as any other highlight failure |
| scp-024 | render-highlighted-html | code contains `<script>alert(1)</script>` | Shiki escapes the code before generating HTML; the rendered `.scp-shiki` markup contains no executable `<script>` element |
| scp-025 | discard-stale-highlight-results | `lang` (or `code`/`theme`) changes while a previous highlight call for the old value is still pending | The stale result is discarded when it resolves; only the highlight for the latest `code`/`lang`/`theme` updates `html`/`error` |

## Edge Cases

- **Empty code string**: Component accepts empty string and renders empty or blank output; Shiki may return empty HTML.
- **Null or undefined lang**: `lang` defaults to `'tsx'` only when the prop is `undefined` — JS default parameters do not apply to an explicit `null`. A `null` (or any other invalid identifier) reaches Shiki, which throws; the component catches it and falls back to `<pre><code>` (see **fallback-to-preformatted**, scp-022).
- **Invalid language identifier**: An identifier Shiki doesn't recognize causes `ensureLanguage`/`codeToHtml` to throw. The component catches it the same as any other highlight failure and falls back to `<pre><code>` (see **fallback-to-preformatted**, scp-023).
- **Clipboard API unavailable**: Copy button click is silently no-op; no error state, no console message.
- **Missing adh-sdk-theme element**: Theme observer skips setup; component uses fallback or prop theme without mutation watching.
- **Very long code string**: Component renders full string; maxHeight prop constrains visual container with overflow scroll if needed.
- **Rapid theme changes**: MutationObserver triggers on each mutation; rapid CSS updates result in rapid re-reads and re-renders. Each theme update starts a new highlight call, and any call still pending from a previous theme is discarded per **discard-stale-highlight-results**.
- **showCopy=false and no filename**: Header element does not render; code is displayed without header.
- **Unmount or rapid prop changes during highlighting**: `useSourceCode` tracks each highlight call with a local cancellation flag; a result that resolves after `code`/`lang`/`theme` changed, or after the component unmounted, is discarded and never updates state (see **discard-stale-highlight-results**, scp-025).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| code | string | required | Source code to display |
| lang | string | 'tsx' | Language identifier for Shiki syntax highlighting |
| theme | string | undefined | Explicit Shiki theme name; if set, overrides CSS-derived theme |
| showCopy | boolean | true | Show copy-to-clipboard button in header |
| filename | string | undefined | Filename to display in header; if not provided, language code is shown |
| className | string | undefined | Additional CSS class to append to root element |
| maxHeight | string or number | undefined | Max height for code body container; applied as inline style. A numeric value is interpreted as pixels (React appends `px` to unitless numeric style values). |

## Deep Linking

Not applicable: Source Code Panel is a stateless display component with no internal navigation or deep-linkable state.

## Localization

| String Key | Default (en) | Context |
|-----------|---------------|---------|
| (hardcoded, not externalized) | "Copy" | Copy button default label |
| (hardcoded, not externalized) | "Copied" | Copy button label shown for 1200ms after a successful copy |

`"Copy"` and `"Copied"` are hardcoded string literals in `SourceCodePanel.tsx`; no prop or localization hook exists in source to translate them, so the component cannot currently be localized into another language without patching or wrapping it.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | N/A — no animation. The copy button's 100ms hover/focus-visible color transition (`source-code-panel.css`) is a micro-interaction, not motion the reduced-motion preference targets. |
| Increase Contrast | Shiki theme determines contrast; toolkit theme controls which Shiki theme is active |
| Differentiate Without Color | Shiki syntax highlighting relies on color differentiation; no fallback is provided in source |

## Feature Flags

Not applicable: Component has no feature flag logic; all functionality is controlled by props.

## Analytics

Not applicable: Component emits no events or analytics; copy action triggers no telemetry or logging.

## Privacy

Not applicable: Component accepts code string as input and displays it; clipboard write is user-initiated and platform-managed.

## Logging

Not applicable: Component performs no logging; errors in Shiki highlighting or clipboard access are silently caught.

## Platform Notes

- **SwiftUI**: SwiftUI has no direct Shiki integration. Use a `WebView` or equivalent to render HTML; inject Shiki CSS and the generated HTML from the equivalent React implementation. Detect theme changes via SwiftUI environment and pass as prop.
- **Compose**: Use `AndroidView` wrapping a WebView (Chromium-based) hosting the same Shiki-based implementation as the source, consistent with the other native platforms — see **Design Decisions**. Theme detection maps to system theme or explicit theme param. Button copy uses Compose's `Clipboard` or system clipboard API.
- **React/Web**: Source implementation. Use `SourceCodePanel` component directly; props match source signature. Theme resolution reads `--scp-shiki-theme` from DOM and respects explicit `theme` prop. Shiki version and available themes are fixed by the toolkit build.
- **AppKit / UIKit**: Use `WKWebView` or equivalent; serve the React component as a web page or embed pre-rendered HTML. Detect app theme via `NSAppearance` (macOS) or `UITraitCollection` (iOS) and inject theme as prop. Implement copy via `NSPasteboard` (macOS) or `UIPasteboard` (iOS).
- **WinUI 3**: Implement using `WebView2` control to host Shiki rendering. Resolve theme from `Application.Current.RequestedTheme` (Light/Dark) and map to Shiki theme names (e.g., Dark → "github-dark", Light → "github-light"). Implement copy button using `Windows.ApplicationModel.DataTransfer.Clipboard`. Handle missing clipboard gracefully with fallback or disabled state.

## Design Decisions

**Decision**: Use Shiki for syntax highlighting instead of Highlight.js or Prism; non-web implementations embed a WebView (or WebView2) hosting this same Shiki-based implementation rather than reimplementing highlighting with a native or alternate JS library.
**Rationale**: Shiki's TextMate-grammar-based highlighting is higher fidelity than DOM-tokenizer libraries like Highlight.js/Prism; hosting the same web implementation via WebView guarantees pixel-identical output across platforms instead of approximating it with a second highlighting engine.
**Approved**: pending

**Decision**: Resolve the Shiki theme from the `--scp-shiki-theme` CSS custom property on the panel root, with an explicit `theme` prop as an override.
**Rationale**: CSS custom properties let the toolkit theme system update every panel synchronously without React context plumbing; the `theme` prop remains available for callers that need explicit control.
**Approved**: pending

**Decision**: Catch and silently no-op clipboard write errors rather than surfacing them to the user.
**Rationale**: Copy-to-clipboard is a convenience feature; source treats a failed copy as non-critical. If clipboard becomes essential to a workflow, error handling should be revisited.
**Approved**: pending

**Decision**: Hold the "Copied" button label for a hard-coded 1200ms after a successful copy, with no prop to configure the duration.
**Rationale**: A fixed, short duration gives clear visual feedback without requiring configuration; other implementations should match this timing for consistency.
**Approved**: pending

**Decision**: When Shiki highlighting fails, degrade to plain text inside a semantic `<pre><code>` element with no error message shown.
**Rationale**: Preserves readability of the code even when highlighting is unavailable, while keeping the failure silent and non-disruptive to the surrounding UI.
**Approved**: pending

**Decision**: Use a `MutationObserver` on the `#adh-sdk-theme` `<style>` element to detect toolkit theme switches and re-read `--scp-shiki-theme`.
**Rationale**: The toolkit already changes themes by mutating this style element; observing it directly avoids adding a separate theme-change event system. Other platforms should use their own theme-change callback/observer equivalent (system theme callbacks, CSS-in-JS observer, etc.).
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | failed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [progress-indication](agenticdevelopercookbook://compliance/performance#progress-indication) | passed | Performance |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | passed | Security |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Statuses rest on `SourceCodePanel.tsx` and `source-code-panel.css`: semantic `<button>`/`<pre>`/`<code>` markup and rem-based text sizing satisfy screen-reader, keyboard, dynamic-type and semantic-markup checks; `.scp-copy`'s `padding: 0.15rem 0.5rem` / `font-size: 0.7rem` plainly fails the 44×44pt touch target; contrast can't be confirmed without the consuming app's resolved `--color-*` token values; Shiki failures reach an explicit `error` state and rendered fallback while clipboard failures are fully swallowed with no state change, so error handling is only partial; the loading fallback shows `aria-busy` for the highlighter's async work; Shiki escapes `code` before its HTML is injected via `dangerouslySetInnerHTML`; and `"Copy"`/`"Copied"` are hardcoded string literals with no localization hook. `separation-of-concerns` passes because theme resolution and highlighting are delegated to `readShikiTheme` and the `useSourceCode` hook, separate from the rendering, and `unit-test-coverage` passes because `SourceCodePanel.test.tsx` renders it directly and asserts on the fallback code, filename header, and copy-button chrome.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename must-* requirements to subject-only names; split the highlight-complete fallback into success (no `<pre>`) and failure (`<pre>` without `aria-busy`) cases; document stale-async-result discarding and Shiki HTML-escaping with new test vectors; correct the theme-mutation trigger and touch-target/error-handling compliance statuses using source and CSS; reformat Design Decisions and Compliance into their canonical forms; resolve the WebView-vs-native-highlighter contradiction between Design Decisions and Platform Notes; document the hardcoded copy-button strings under Localization; add tags and the Shiki reference |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source |
