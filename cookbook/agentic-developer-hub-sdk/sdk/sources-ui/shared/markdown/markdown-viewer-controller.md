---
id: 8f2e1c9d-7a4b-4c2e-9d8e-5f6c7d8e9f0a
title: "Markdown Viewer"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Read-only markdown viewer with theme persistence and syntax highlighting."
platforms:
  - typescript
  - web
  - swift
  - macos
  - ios
tags:
  - markdown
  - viewer
  - theming
  - syntax-highlighting
depends-on:
  - 316aed50-a6cb-4ece-977c-8d6dacb2186b
  - 840b5a7a-921a-4770-8dea-5ffbf9a2ee6c
  - 3562bffe-c137-4f4e-91da-f9ef27a5b712
related:
  - ee901ea5-cf3e-4276-8367-0693911bc02e
references: []
approved-by: ""
approved-date: ""
---

# Markdown Viewer

## Overview

A read-only markdown document viewer with theme persistence and syntax-highlighted code blocks. The component fetches formatted markdown content by document ID, renders it as sanitized HTML, and applies a persisted reading theme via a palette system. Used to display pre-formatted documentation, guides, or user-generated content without requiring editor capabilities.

## Behavioral Requirements

- **fetch-by-id**: Component MUST fetch markdown content by document `id` via the configured fetcher.
- **fetch-timeout**: Fetch operation MUST abort its `AbortSignal` if it exceeds the configured `timeoutMs` (default 15000ms). Reaching the error state from this depends on the fetcher honoring that signal (rejecting once aborted, as the default native-fetch fetcher does); a fetcher that ignores `AbortSignal` is not itself interrupted and can still resolve, or keep loading, past the timeout.
- **abort-on-id-change**: If `id` changes while a fetch is in flight, the component MUST abort the previous fetch's `AbortSignal`. With a fetcher that honors the signal, this makes any late response for the stale id rejected and ignored. Exception: if the stale fetch had already timed out before `id` changed, its signal is already aborted with the timeout reason, and the id-change cleanup's second `abort()` call is a no-op that cannot change that reason — so with a fetcher that does not honor `AbortSignal`, a late success or error for the stale id can still overwrite the newer id's state instead of being ignored (see Edge Cases).
- **fetch-error-handling**: Component MUST display an error state with the error message if the fetch fails.
- **sanitized-rendering**: Markdown content MUST be rendered as sanitized HTML using an allowlist: elements limited to prose structure (headings, paragraphs, lists, tables, blockquotes, code, links, images, inline emphasis, `details`/`summary`, and similar), with `<script>`, `<style>`, `<iframe>`, `<object>`, `<embed>`, and `<form>` always stripped. `href`/`cite` accept only the `http`, `https`, `mailto`, and `tel` protocols and `src` accepts only `http`/`https` (no `javascript:` or other schemes). No `on*` event-handler attribute is permitted on any element.
- **code-syntax-highlighting**: Code blocks in markdown MUST receive syntax highlighting via the configured highlighter.
- **theme-persistence**: On web, the component MUST persist the selected theme ID to storage (`localStorage`) so it survives app restarts — the component owns this state itself. On Apple, the component does not select or persist a theme: `palette` is a host-injected configuration value, and the host application owns theme selection and any persistence of it (e.g. via `UserDefaults`, if the host chooses to persist).
- **theme-palette-application**: Active theme palette MUST be applied to all rendered content (text colors, backgrounds, code highlighting).
- **toolbar-display**: Component MUST render a toolbar containing the document title and a theme switcher control.
- **document-title-display**: Toolbar MUST display the document's title (or empty string if not yet loaded).
- **theme-switcher-touch-target**: The toolbar theme switcher control MUST have a tap target of at least 44×44pt (iOS) / 48×48dp (Android).
- **loading-state**: While fetch is in progress, component MUST display a loading indicator with live region announcement.
- **idle-state**: Before any document is requested, component MUST display an idle message ("No document selected").
- **empty-state**: If document fetches successfully but content is empty or whitespace-only, component MUST display an empty state message.
- **no-flash-theme**: On web with SSR, a pre-hydration bootstrap script SHOULD apply the persisted theme before React hydration to prevent flash of default theme.

## Appearance

- **Container**: Rounded corners (12px), border (1px), semi-transparent background.
- **Toolbar**: Horizontal bar with title and theme switcher. Padding: 12px vertical × 16px horizontal.
- **Content area**: Scrollable region carrying viewer-owned `--mdv-*` CSS custom properties (web) or applied palette (Apple). Background, text, and code colors are theme-dependent.
- **Loading spinner**: Centered icon with "Loading…" text. Color: currentColor (inherits from content root).
- **Error state**: Centered alert icon with title "Failed to load document" and error detail text. Title color matches alert semantic (typically red/orange).
- **Empty state**: Centered document icon with "Empty document" title and "This document has no content yet" detail.

## States

| State | Appearance change |
|-------|------------------|
| Idle | "No document selected" centered message. |
| Loading | Spinner icon, "Loading…" title, `aria-live="polite"` and `aria-busy="true"`. |
| Error | Alert icon (red/orange), "Failed to load document" title, error detail text below, `role="alert"`. No retry action; the caller re-triggers a fetch by changing `id` (or remounting). |
| Success | Rendered markdown content in active theme palette; toolbar displays document title. |
| Success–Empty | Document icon, "Empty document" title, "This document has no content yet" detail — distinct copy from Idle's "No document selected." |

## Accessibility

- **Role and structure**: Markdown is rendered with semantic HTML headings, lists, and emphasis. The viewer itself is a region containing document content.
- **Live regions**: Loading state uses `aria-live="polite"` and `aria-busy="true"` to announce fetch progress.
- **Error alerts**: Error state uses `role="alert"` so assistive technology announces failures immediately.
- **Color not sole differentiator**: Error state icon is distinct from idle/loading icons (different shapes, not color alone).
- **Keyboard navigation**: The theme switcher is a native `<select>` element (natively focusable and operable via keyboard; no extra ARIA needed). Links and interactive elements in rendered markdown are tab-navigable.
- **Minimum touch target**: See **theme-switcher-touch-target**.
- **Labels**: All interactive controls (theme switcher) have accessible labels via `aria-label` or visible text.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mdv-001 | fetch-by-id | `id="abc123"` | Fetcher is called with id `"abc123"`. |
| mdv-002 | idle-state | `id=undefined` | Component enters idle state; no fetch occurs. |
| mdv-003 | fetch-timeout | `timeoutMs=5000`, fetch hangs >5s, using the default native-fetch fetcher | Fetch's `AbortSignal` is aborted; the fetcher rejects on abort, so the error state is shown. A fetcher that does not honor `AbortSignal` is not interrupted and can keep loading, or resolve, past the timeout instead. |
| mdv-004 | fetch-error-handling | Fetcher returns error with message | Error state displays error message in detail text. |
| mdv-005 | sanitized-rendering | Markdown with `<script>alert('xss')</script>` | Script tag is removed; no script executes. |
| mdv-006 | code-syntax-highlighting | Markdown with ` ```js\nvar x=1;\n``` ` (web) | Rendered `<code>` contains `<span>` elements carrying inline `--shiki-light`/`--shiki-dark` custom properties (JavaScript tokens are colorized); no bare color literal appears in the HTML. |
| mdv-007 | theme-persistence | (Web) User selects theme "dark"; app restarts | On restart, "dark" theme is still active. |
| mdv-008 | theme-palette-application | Active palette has `--mdv-text: #fff` | Content root carries inline style `--mdv-text: #fff`; rendered text resolves to `#fff` via `var(--mdv-text)`. |
| mdv-009 | toolbar-display | Component renders | Toolbar is visible with title and theme switcher. |
| mdv-010 | document-title-display | `title="My Doc"` in fetched document | Toolbar displays "My Doc". |
| mdv-011 | loading-state | Fetch is in progress | Spinner icon and "Loading…" text are visible. |
| mdv-012 | idle-state | Component renders before `id` is set | "No document selected" message is shown. |
| mdv-013 | empty-state | Content is `""` or whitespace-only | "Empty document" icon and message are shown. |
| mdv-014 | no-flash-theme | (Web SSR) User has persisted theme "dark" | Dark theme is applied before first paint (no visible theme flash). |
| mdv-015 | theme-switcher-touch-target | Component renders | Theme switcher control's hit area measures at least 44×44pt (iOS) / 48×48dp (Android). |
| mdv-016 | abort-on-id-change | `id` changes from `"abc"` to `"xyz"` while `"abc"`'s fetch is pending, using the default native-fetch fetcher | `"abc"`'s fetch's `AbortSignal` is aborted and the fetcher rejects; only `"xyz"`'s result (success or error) is reflected in state. If `"abc"` had already timed out before `id` changed, and the fetcher ignores `AbortSignal`, `"abc"`'s late result can instead overwrite `"xyz"`'s state — see Edge Cases. |
| mdv-017 | sanitized-rendering | Markdown link with text `link` and target `javascript:alert(1)` | Rendered `<a>` has no `href` attribute (disallowed protocol dropped by the sanitizer). |
| mdv-018 | sanitized-rendering | Raw HTML `<img src=x onerror=alert(1)>` | `onerror` attribute is stripped (not in the attribute allowlist); no script executes. |

## Edge Cases

- **Null/undefined id**: Component enters idle state; no fetch is triggered. MUST not error.
- **id changes during in-flight fetch**: The previous fetch's `AbortSignal` MUST be aborted. With the default native-fetch fetcher (which rejects on abort), this means its response is ignored and only the new `id`'s fetch determines the resulting state (see **abort-on-id-change**). Exception: if the stale fetch had already timed out before `id` changed, its signal is already aborted with the timeout reason, and the cleanup's second `abort()` call cannot change that reason — a fetcher that ignores `AbortSignal` can therefore still deliver the stale id's late success or error and overwrite the new id's state instead of being suppressed.
- **Stale theme ID in storage (web)**: If stored theme ID is no longer in the valid registry, MUST fall back to the default theme without error.
- **Storage quota exceeded or unavailable (web)**: Theme selection still works live; persistence just fails silently. User's session theme remains active until app restart.
- **CSP blocks bootstrap script (web)**: No-flash protection is disabled; SSR paint uses default theme, then hydration applies persisted theme (visible flash). Component still functions.
- **Fetch timeout with no timeout configured**: Uses default timeout (15000ms).
- **Very large markdown content**: Component renders all content; SHOULD NOT paginate or truncate.
- **Markdown with deeply nested lists or tables**: MUST render all nesting levels.
- **Empty string title**: Toolbar displays empty title (no text, but toolbar remains present).
- **Network error with no message**: MUST show error state with a generic error message (e.g., "Failed to load document").

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `id` | `string \| undefined` | `undefined` | (Web only) Document ID to fetch. If undefined, component shows idle state. |
| `fetcher` | `MarkdownFetcher` | `defaultMarkdownFetcher` (`GET /api/content/markdown/:id` through the host app's API forwarder) | (Web only) Optional custom fetcher function; used for testing. Production uses the real API. |
| `timeoutMs` | `number` | `15000` | (Web only) Fetch timeout in milliseconds. |
| `className` | `string` | `undefined` | (Web only) CSS class to forward to the root container element. |
| `nonce` | `string` | `undefined` | (Web only) CSP nonce for the pre-hydration bootstrap script. Required if host app enforces strict CSP. |
| `palette` | `SemanticPalette` | N/A (required) | (Apple only) Semantic color palette to apply to rendered content. |
| `highlighter` | `CodeHighlighter` | `nil` (no highlighting; falls back to monochrome themed monospace) | (Apple only) Optional custom code syntax highlighter; uses default if omitted. |

**Types referenced above:**
- `MarkdownFetcher`: `(id: string, signal: AbortSignal) => Promise<MarkdownDocument>` — given a document id and an abort signal, resolves the fetched document or rejects with an error. **fetch-timeout** and **abort-on-id-change** depend on the fetcher honoring `signal` (rejecting once it is aborted, as the default native-fetch fetcher does); a fetcher that ignores `signal` is not interrupted by an abort and can still resolve, or deliver a stale result, after the component has moved on to a new `id`.
- Document shape (fields the viewer reads): `{ id: string; title: string; content: string }` — `title` renders in the toolbar; `content` is the raw markdown body.
- `SemanticPalette` (Apple): the app-wide semantic color-role palette (e.g. `.primaryText`) — the same type used for theming elsewhere in the app.
- `CodeHighlighter` (Apple): `func highlight(_ code: String, language: String?, palette: SemanticPalette) -> NSAttributedString?`.
- Theme ID set (web): `dark` (default), `light`, `sepia`, `github` — validated against the viewer's theme registry; an unrecognized or stale id falls back to the default.

## Deep Linking

Not applicable: Component fetches by document ID; deep linking to a specific document would be implemented by the host app's URL router passing an `id` prop to the component.

## Localization

Five user-facing strings are hardcoded and should be externalized as localization keys:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `mdv.idle.detail` | No document selected. | Idle state message |
| `mdv.loading.title` | Loading… | Loading state title |
| `mdv.error.title` | Failed to load document | Error state title |
| `mdv.empty.title` | Empty document | Empty state title |
| `mdv.empty.detail` | This document has no content yet. | Empty state detail |

The error detail text shown in the Error state comes from the fetch/network layer, not from a fixed string in this component, and is not part of this key set; a network error with no message MUST still show a generic, localized fallback (see **fetch-error-handling**, Edge Cases). Markdown content itself is localized by the backend providing the content in the appropriate language; the component renders it as-is.

## Accessibility Options

Not applicable: Component renders markdown content with the active palette; it does not respond to system-level accessibility options (e.g., Reduce Motion, Increase Contrast) independently. The host app and palette system determine theme behavior in response to accessibility preferences.

## Feature Flags

Not applicable: No feature flags implemented in source. Component is always enabled; feature control would be implemented by the host app if needed.

## Analytics

Not applicable: No analytics instrumentation in source. Host app or a wrapper can emit analytics events based on user interactions (e.g., theme selection, document loads).

## Privacy

**Data collected**: Theme preference (ID string, e.g., "dark" or "light") — web only, where the component owns the selection. On Apple, the component receives `palette` from the host and does not itself collect or store anything. No sensitive user data is collected or transmitted on either platform.

**Storage**: On web, the theme ID is persisted to `localStorage`, local-only and never sent to a server. On Apple, persistence (if any) is the host's responsibility — e.g. via `UserDefaults` — since the component only receives an already-resolved `palette`.

**Transmission**: No data is transmitted to analytics or telemetry services by the component.

**Retention**: On web, the theme preference persists until the user clears storage or selects a different theme; no expiry or automatic cleanup. Apple retention is whatever the host implements.

## Logging

Not applicable: No logging instrumented in source. Host app can log component lifecycle events if needed (e.g., fetch start/end, errors).

## Platform Notes

- **SwiftUI**: No SwiftUI-native implementation exists yet; this is guidance for one. A wrapper would expose the same inputs as a view — `content: String`, `palette: SemanticPalette`, and an optional `highlighter` — either by hosting `MarkdownViewerController` via `NSViewControllerRepresentable`/`UIViewControllerRepresentable`, or by reimplementing the render step directly (e.g. `Text(AttributedString(markdown:))`) and refreshing on `.onChange(of: palette)`.

- **Compose**: Start with a Column in a scrollable Box for the toolbar and content area. Toolbar uses Row with title Text and a theme switcher Button. Content is rendered as composable markdown blocks with theme colors applied via CompositionLocal. Consider LazyColumn for very large documents. Apply theme palette via Material theme or custom color scheme.

- **React/Web**: File: `MarkdownViewer.tsx`. Client component that fetches via the `useMarkdownDocument` hook (default fetcher: `GET /api/content/markdown/:id`) and renders `MarkdownRenderer` output. Pre-hydration bootstrap script applies the persisted theme to the content root before React hydration (prevents no-flash; needs a CSP `nonce` under a strict `script-src` policy). Chrome (container, toolbar, switcher) uses APT design tokens: container `border border-apt-border bg-apt-bg rounded-xl`; toolbar `bg-apt-surface` background, `text-apt-text text-sm font-medium` text, `px-4 py-3` padding (16px horizontal × 12px vertical). Theme ID persisted to `localStorage`; stale IDs validated against the registry and fall back to the default. The content root carries the viewer-owned `--mdv-*` palette as inline CSS custom properties, kept separate from the apt-* chrome tokens.

- **AppKit / UIKit**: Component is `MarkdownViewerController` (a `PlatformViewController` — `NSViewController` on macOS, `UIViewController` on iOS). Holds a `MarkdownTextPane` and a `MarkdownDocumentRenderer`; re-renders the attributed text on palette change (does not cache) to keep theming synchronized. `palette` is a host-injected property — assigning a new value triggers `refresh()`. Accepts an optional `CodeHighlighter` for syntax-highlighting support. The controller renders `content` directly and has no toolbar, fetch, or theme-persistence code of its own — a host that wants those composes them around it, e.g. persisting the chosen palette id to `UserDefaults`.

- **WinUI 3**: Use RichTextBlock (read-only, formatted text) or RichEditBox (editable, but configure as read-only). Toolbar is a Grid with title TextBlock and ComboBox for theme selection. Theme colors are applied via resource dictionary with semantic color keys. Handle theme changes by updating all relevant brushes and re-applying to the text block. Persist theme selection to ApplicationData.Current.LocalSettings.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/Shared/Markdown/MarkdownViewerController.swift` | unverified |
| web | `packages/web/packages/markdown/src/components/MarkdownViewer.tsx` | unverified |

## Design Decisions

- **Decision**: A pre-hydration bootstrap script runs synchronously before React hydration so the persisted theme is applied before first paint. The script targets its own parent element to isolate its scope.
  **Rationale**: Prevents the visual jarring of loading in the default theme and then switching.
  **Approved**: pending

- **Decision**: Rendered markdown is stored as source text, not cached as an `AttributedString`; the Apple renderer re-renders on every palette change instead.
  **Rationale**: Re-rendering on palette change is cheap enough that caching adds unnecessary complexity and divergence risk, and this keeps the rendered output synchronized with the active palette.
  **Approved**: pending

- **Decision**: Theme selection is persisted locally — in `localStorage` on web, where the component owns it — and not synchronized to a backend user preference. On Apple, the component holds no theme state at all; the host owns the selection via the injected `palette`.
  **Rationale**: Allows independent theme choices across multiple app instances and respects local-first behavior. A host app can implement backend tracking, or its own persistence, separately if desired.
  **Approved**: pending

- **Decision**: Fetch timeouts are configured per component instance (`timeoutMs`), not globally.
  **Rationale**: Different use cases may require different timeout values (e.g., a quick preview vs. a long-form document), so per-instance configuration maximizes flexibility.
  **Approved**: pending

- **Decision**: If theme persistence fails on web (quota exceeded, permissions denied, private mode), the operation fails silently and the component continues working with the theme in memory for the current session.
  **Rationale**: The user's chosen theme still applies live; a persistence failure isn't fatal to the component's function, so nothing is surfaced to the user and no log event is emitted (see Logging).
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.security.content-security-policy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/342ea2ea-fb37-5746-9ccd-e81d3d593996) | passed | Security |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | partial | Security |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy & Data |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | Platform Compliance |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`screen-reader-support`/`keyboard-navigable`/`semantic-markup` rest on the `aria-live`/`aria-busy`/`role="alert"` markup and the native `<select>` theme switcher shown in `MarkdownViewer.tsx`; `dynamic-type-support`, `contrast-ratio`, and `touch-target-size` are `partial` because the requirement is stated but not measured or enforced in the given source; `input-sanitization` and `content-security-policy` rest on the `rehype-sanitize` allowlist and the bootstrap script's `nonce` support in `process-markdown.ts`/`MarkdownViewer.tsx`; `secure-transport` is `partial` because the fetcher calls a relative API path with no TLS enforcement visible from this source; `data-minimization` rests on the Privacy section above; the internationalization checks rest on the Localization key table above; and the platform-compliance checks rest on the APT design tokens and the theme registry/palette system. `separation-of-concerns` is passed on both platform sources: the web `MarkdownViewer.tsx` delegates fetching to `useMarkdownDocument`, rendering to `MarkdownRenderer`, and theme data to `themes/registry`+`palettes`, keeping only fetch-state/theme-persistence wiring and chrome layout in the component itself; the Apple `MarkdownViewerController.swift` delegates markdown rendering to `MarkdownDocumentRenderer` and text display to `MarkdownTextPane`, keeping only palette/content wiring in the controller. `unit-test-coverage` is partial across the two platform entries: no test in this repo imports or renders the web `MarkdownViewer.tsx` (`MarkdownViewerControllerTests.swift` is a name-matched false positive — it tests the unrelated Apple controller), while `MarkdownViewerControllerTests.swift` does genuinely exercise `MarkdownViewerController.swift`, asserting rendered text, non-editability, and re-render-on-content-change through a loaded viewer.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from web (React/TypeScript) and Apple (Swift) sources. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case everywhere they're cited; add a types note (fetcher signature, document shape, theme registry) and a concrete sanitization allowlist; split Apple theme ownership from web's (host-injected `palette` vs. component-owned `localStorage`) across Requirements, Privacy, and Platform Notes, and fix "Preferences" to `UserDefaults`; move the mislabeled SwiftUI bullet to AppKit/UIKit and write a real SwiftUI note; rebuild Compliance as itemized per-check rows instead of one unverifiable `wcag-2.1-aa` line; reformat Design Decisions to Decision/Rationale/Approved and resolve the storage-errors logging contradiction in favor of the source (no logging); make Localization concrete with string keys; add `abort-on-id-change` and `theme-switcher-touch-target` requirements with vectors, plus sanitizer vectors for `javascript:` links and `onerror`; fix the Appearance padding contradiction and move Tailwind classes to the React/Web note; fix the States idle/empty contradiction and note the Error state has no retry; mark `id`/`fetcher`/`timeoutMs` Web-only for platform symmetry; name the fetcher's default endpoint; add discoverability tags and `depends-on`/`related` links to the composed markdown ingredients. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | fetch-timeout/abort-on-id-change qualified: depend on fetcher honoring AbortSignal; mdv-003/mdv-016/edge case/fetcher contract corrected. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
