---
id: 6ea605aa-9248-46d4-9532-82185388749b
title: Markdown Preview
domain: adhsdk://recipes/markdown-preview
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A React component that fetches and renders GitHub-flavored markdown content
  with syntax highlighting, theme support, and timeout-aware error handling.
platforms:
- typescript
- web
tags:
- markdown
- preview
- fetch
- search
depends-on:
- adhsdk://recipes/markdown-renderer
- adhsdk://recipes/button
- adhsdk://recipes/markdown-reading-palette
related:
- adhsdk://recipes/markdown-preview-header
- adhsdk://recipes/markdown-viewer
references: []
approved-by: ''
approved-date: ''
---

# Markdown Preview

## Overview

Markdown Preview is a presentational component that fetches full markdown content for a document via HTTP, renders it using GitHub-flavored markdown with Shiki syntax highlighting, applies a reading theme palette, and manages loading, empty, and error states. It is designed for integration into a search or discovery interface where users select a document and its content appears in a preview panel.

## Behavioral Requirements

- **content-url**: Component MUST construct a full-content URL from the injected `SearchSource` configuration and the provided `PaperSearchHit`, following the template pattern `endpoints.content` (defaulting to `DEFAULT_CONTENT_ENDPOINT`, `/public/users/:slug/papers/:route`, when `endpoints.content` is not supplied) with URL-encoded slug and route placeholders.
- **render-markdown-content**: Component MUST render fetched markdown content using `MarkdownRenderer` from `@adh-sdk/markdown` — the same GitHub-flavored, Shiki-highlighted, rehype-sanitized pipeline documented at adhsdk://recipes/markdown-renderer.
- **apply-reading-theme**: Component MUST apply the reading theme palette to the rendered content by setting `data-mdv-theme`, `data-mdv-shiki-variant`, and CSS custom properties on the root container.
- **show-loading-state**: Component MUST display a loading state with the text "Loading paper…" and MUST mark the state container with `aria-live="polite"` and `aria-busy="true"`.
- **show-empty-state**: Component MUST display a distinct empty state (title: "Empty paper", detail: "This paper has no content yet.") when the fetch succeeds but the content body is empty or whitespace-only.
- **show-error-state**: Component MUST display an error state (title: "Failed to load paper") with the error message and MUST mark the container with `role="alert"` when the fetch fails.
- **handle-timeout**: Component MUST time out a request that exceeds the `timeoutMs` prop (default 15s), transitioning to the error state with a message indicating the timeout duration in seconds.
- **provide-retry-capability**: Component MUST include a clickable Retry button in the error state that re-runs the fetch without requiring component remount or prop change.
- **abort-on-change**: Component MUST abort any in-flight fetch request when the component unmounts or when a different document is selected (change in `hit.author.slug`, `hit.publicRoute`, or `source.baseUrl`).
- **distinguish-timeout-from-other-errors**: Component MUST show a distinct message for a request that timed out versus one that failed for another reason (HTTP, network, or JSON-parse error).
- **handle-non-ok-http-status**: Component MUST reject the fetch and transition to the error state when the HTTP response status is not 2xx, with an error message that includes the status code (e.g., "Failed to load paper (HTTP 404).").
- **stable-refetch-dependencies**: Component MUST NOT re-run the content fetch when the injected `SearchSource` is recreated with equivalent values; a new fetch MUST occur only when `slug`, `route`, `baseUrl`, `endpoints.content`, or `timeoutMs` changes to a new value. A `fetchInit` value change (e.g., updated auth headers) does NOT by itself trigger a refetch — the next fetch triggered by one of the dependencies above picks up the current `fetchInit`.

## Appearance

- **Container**: Root `div` with class `adh-mv-content`, transparent background (content is rendered inside).
- **Reading palette**: Applied via inline `style` attribute with CSS custom properties from `READING_THEME.palette` (colors, spacing, typography defined by theme).
- **State container**: Nested `div` with class `adh-mv-state` or `adh-mv-state--error` (on error), centered or stacked layout.
- **State title**: `p` with class `adh-mv-state-title` (if shown).
- **State detail**: `p` with class `adh-mv-state-detail` (loading, empty, or error message text).
- **Retry button**: Built from `Button` component (variant: "outline", size: "sm"), placed below error detail with `className="mt-3"`.
- **Markdown body**: Rendered by `MarkdownRenderer` (no wrapper div or title; body only).

## States

| State | Appearance change | Trigger |
|-------|------------------|---------|
| Loading | State container shown with "Loading paper…" text, aria-busy="true" | Initial mount or refetch |
| Ready | Markdown content rendered via MarkdownRenderer | Content fetch succeeds and body is non-empty |
| Empty | State container shown with "Empty paper" title and detail text | Content fetch succeeds but body is empty or whitespace-only |
| Error | State container (role="alert") shown with error title, error message, and a Retry button below it | Fetch fails (timeout, HTTP error, network error, JSON parse error) |

## Accessibility

- **Role**: The root container carries no explicit ARIA role; the error state container is marked with `role="alert"` to announce failures to screen readers.
- **Live region**: The loading state container is marked with `aria-live="polite"` and `aria-busy="true"` to announce the loading phase. The empty state has no live-region marking — its arrival is not announced.
- **Label**: The error detail text serves as the accessible error message; the Retry button's accessible name comes from its visible text content, "Retry".
- **Markdown rendering**: Content is rendered by `MarkdownRenderer` (adhsdk://recipes/markdown-renderer), which applies semantic HTML (headings, lists, code blocks) and ensures proper color contrast via the theme palette.
- **Keyboard interaction**: The Retry button is keyboard-accessible (Tab, Enter/Space to activate), per `Button`'s own recipe (adhsdk://recipes/button).
- **Minimum tap target**: The Retry button is a `Button` with `size="sm"` (28px tall) and no ancestor `--adh-button-min-height` override. Per Button's own recipe, `sm` clears the WCAG 2.2 SC 2.5.8 (Target Size Minimum, AA) 24×24 CSS px floor but falls below the Apple HIG 44×44pt / Material 48×48dp guidance unless a surface sets that override; this component sets none.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|----|----|----|
| mp-001 | content-url, stable-refetch-dependencies | hit with slug="alice-wonder", publicRoute="paper-001", source with endpoints.content="/:slug/:route" and baseUrl="https://api.example.com" | Fetch request to `https://api.example.com/alice-wonder/paper-001` (URL-encoded); slug and route are percent-encoded if they contain special characters |
| mp-002 | render-markdown-content | Fetched JSON response `{ "content": "# Title\n\nBody text." }` | MarkdownRenderer is called with content "# Title\n\nBody text."; rendered output appears in DOM |
| mp-003 | apply-reading-theme | Component mounted with MarkdownRenderer output | Root div has data-mdv-theme, data-mdv-shiki-variant attributes; CSS custom properties from READING_THEME.palette are applied as inline style |
| mp-004 | show-loading-state | Initial render before fetch completes | Div with class "adh-mv-state" is visible, contains p with text "Loading paper…", aria-live="polite" and aria-busy="true" are set |
| mp-005 | show-empty-state | Fetch returns `{ "content": "" }` or `{ "content": "   " }` | Div with class "adh-mv-state" shows title "Empty paper" and detail "This paper has no content yet." |
| mp-006 | show-error-state | Fetch fails with HTTP 404 | Div with class "adh-mv-state adh-mv-state--error" is visible with role="alert", title "Failed to load paper", detail "Failed to load paper (HTTP 404)." |
| mp-007 | handle-timeout | timeoutMs=5000, fetch stalls > 5000ms | Request is aborted at the timeout; component shows error state with message "Timed out loading paper after 5s." |
| mp-008 | distinguish-timeout-from-other-errors | timeoutMs=5000, fetch rejects immediately with a network error (not a timeout) | Error state shows the network error's own message, never the "Timed out loading paper after …" wording |
| mp-009 | provide-retry-capability | Component in error state, user clicks Retry button | The same request is re-issued for the same hit and source, without remounting; component returns to loading state |
| mp-010 | abort-on-change | hit.author.slug changes from "alice" to "bob" during error state | In-flight fetch is aborted (if any); new fetch is initiated for the new slug; component transitions through loading state for the new document |
| mp-011 | handle-non-ok-http-status | Fetch returns HTTP 500 | Error state is shown with message "Failed to load paper (HTTP 500)." |
| mp-012 | stable-refetch-dependencies | source prop is recreated each render (new object, same values); hit stays the same | Fetch does not re-run — no new request is issued while slug, route, baseUrl, endpoints.content, and timeoutMs stay the same |

## Edge Cases

- **Empty content after trim**: If fetched content is all whitespace, `content.trim()` evaluates to falsy; component shows empty state (not error).
- **Fetch succeeds but JSON missing content key**: Response is `{}` or has no `content` field; code defaults to empty string (`body.content ?? ''`); empty state is shown.
- **Network error during fetch**: `.catch()` catches the error; if `!active` is true (unmount race), error is dropped silently; otherwise error state is shown with original error message.
- **Unmount during fetch**: `active` flag is set to false in the cleanup function; `.then()` and `.catch()` check `!active` and drop results silently; no state update occurs after unmount.
- **Re-select same document during error state**: User clicks Retry; `reloadToken` increments, triggering re-fetch; same URL is fetched again.
- **Controller abort vs. timeout abort**: `AbortSignal.any([controller.signal, AbortSignal.timeout(timeoutMs)])` combines both; timeout produces a `DOMException` with `name === 'TimeoutError'`, which is distinct from controller.abort() (checked via `controller.signal.aborted`).
- **Non-JSON response body**: If `res.json()` throws, the promise is rejected with an `Error`; `.catch()` catches it and shows that error's own `message` (e.g., a `SyntaxError` from a malformed body). The generic "Failed to load paper." fallback is unreachable from this path — it only applies to a thrown non-`Error` value, which `res.json()` never produces.
- **Very short timeout renders "0s"**: The timeout message rounds `timeoutMs / 1000` with no minimum clamp, so a `timeoutMs` under 500 renders "Timed out loading paper after 0s." — an accurate but rough message the component does not correct.
- **Null or missing hit properties**: Component assumes `hit.author.slug` and `hit.publicRoute` exist and are strings; no null checks are present in source; passing undefined/null will result in invalid URLs or fetch failure.
- **Very large content**: MarkdownRenderer and rehype-sanitize process the full content; no streaming or chunking is performed.
- **Custom endpoint template**: If `source.endpoints.content` is provided, it overrides the default (`DEFAULT_CONTENT_ENDPOINT`, `/public/users/:slug/papers/:route`); template must include `:slug` and `:route` placeholders or they will not be replaced.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hit` | `PaperSearchHit` | — | Required. The selected document metadata including `author.slug` and `publicRoute`. |
| `source` | `SearchSource` | — | Required. Injected scope configuration with `baseUrl`, `endpoints.content` (defaults to `DEFAULT_CONTENT_ENDPOINT`, `/public/users/:slug/papers/:route`, when omitted), and `fetchInit`. |
| `timeoutMs` | `number` | `DEFAULT_TIMEOUT_MS` (15000) | Fetch timeout in milliseconds. Passed to `AbortSignal.timeout()`. |

## Deep Linking

Not applicable: This component is a preview body within a search/discovery interface and does not itself handle deep linking. The host application (preview dock or search surface) manages navigation and URL construction.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `markdownPreview.loading.detail` | "Loading paper…" | Loading state detail text |
| `markdownPreview.empty.title` | "Empty paper" | Empty state title |
| `markdownPreview.empty.detail` | "This paper has no content yet." | Empty state detail |
| `markdownPreview.error.title` | "Failed to load paper" | Error state title |
| `markdownPreview.error.detail` | (dynamic) | Error state detail: either the timeout message or the underlying error's message |
| `markdownPreview.retry.label` | "Retry" | Retry button label |

Note: Strings are hardcoded in the component; no i18n framework is integrated. Localization would require extracting strings to a message catalog and applying a translation layer.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: This component does not animate. The state transitions (loading → ready/empty/error) are instantaneous DOM swaps, not CSS animations or transitions. |
| Increase Contrast | Applied by the reading theme palette (READING_THEME.palette includes contrast-optimized colors); no component-specific handling is needed. |
| Differentiate Without Color | Applied by the reading theme palette and MarkdownRenderer output (semantic HTML markup does not rely on color alone). |

## Feature Flags

Not applicable: No feature flags are defined or checked within this component. The component is always enabled once rendered by its host.

## Analytics

Not applicable: No analytics events are emitted or tracked by this component. Event tracking (if needed) would be implemented by the host search/discovery interface.

## Privacy

- **Data collected**: None. This component does not collect user data.
- **Storage**: None. The fetched content is held in React state for rendering only.
- **Transmission**: The component fetches content via HTTP(S) from the injected `source.baseUrl`. Transmission is governed by the host application's endpoint configuration and network layer (e.g., auth headers in `source.fetchInit`).
- **Retention**: Content is not persisted; it is discarded when the component unmounts or when a different document is selected.

## Logging

Not applicable: No logging or console output is performed by this component. Debug logging (if needed) would be added by wrapping the fetch logic or inspecting browser DevTools.

## Platform Notes

- **TypeScript/Web (source)**: Implemented in `MarkdownPreview.tsx` using React hooks (`useState`, `useEffect`, `useCallback`, `useRef`). Fetch is performed via the native `fetch` API, combining an owned `AbortController` with `AbortSignal.timeout()` via `AbortSignal.any()` (requires modern browsers) so `handle-timeout` and `abort-on-change` share one signal; the caught `DOMException`'s `name === 'TimeoutError'` distinguishes a timeout from the controller's own abort. `stable-refetch-dependencies` is implemented by reading `source` through a ref (`sourceRef`), updated every render, while the fetch effect's dependency list holds only `slug`, `route`, `baseUrl`, `endpoints.content`, and `timeoutMs` — so `fetchInit` changes are visible to the next fetch without forcing one. An `active` flag set to `false` in the effect cleanup silently drops a `.then()`/`.catch()` result that resolves after unmount or after a new fetch has started. `READING_THEME` (`apply-reading-theme`) is computed once at module scope from `getThemeById(DEFAULT_THEME_ID)`, since the reading theme does not vary per instance or per render. Content rendering is delegated to `MarkdownRenderer` from `@adh-sdk/markdown` (rehype-sanitized GitHub-flavored markdown with Shiki syntax highlighting). State machine (loading → ready/empty/error) is managed via `useState`. Retry is implemented by incrementing a `reloadToken` state value to force the fetch effect to re-run for the same document.
- **SwiftUI**: Implement as an async view that fetches content via `URLSession`, catching `URLError` and checking `.code == .timedOut` to distinguish a timeout from other failures (mirrors `distinguish-timeout-from-other-errors`). Use `@State` to manage the four-phase state machine (loading, ready, empty, error). Render markdown via the Apple-platform `MarkdownRenderer` (adhsdk://recipes/markdown-renderer), which produces `NSAttributedString` with semantic palette styling and injected syntax highlighting. Apply theme colors via SwiftUI environment values (`.preferredColorScheme`, custom `EnvironmentKey`). Implement retry via a button that re-triggers the async fetch task.
- **Compose**: Implement as a Composable that manages state via `remember` and collects content via `LaunchedEffect` with `URLConnection` or OkHttp client. Define a timeout via `withTimeoutOrNull()` or HTTP client configuration. Render markdown via a custom Composable using an Android markdown rendering library (e.g., Markwon). Apply Material 3 theme colors via `MaterialTheme.colorScheme`. State transitions (loading ↔ ready/empty/error) via `when` expression.
- **AppKit / UIKit**: Implement as a `UIViewController` (iOS) or `NSViewController` (macOS) that fetches via `URLSession` with `URLSessionConfiguration.default.timeoutIntervalForRequest`. Manage state via `@Published` properties (if using Combine) or properties with KVO. Render markdown via `WKWebView` loaded with an HTML wrapper or a native markdown library. Apply theme colors by assigning the palette's `UIColor`/`NSColor` values directly to view properties (`backgroundColor`, `textColor`) — not `UIAppearance`, which sets type-wide proxy defaults rather than a single instance's colors. Implement retry via a UIButton/NSButton target-action or Combine button publisher.
- **WinUI 3**: Implement as a User Control (`<UserControl>` XAML) with code-behind or `ViewModel` (MVVM). Fetch via `HttpClient` from `System.Net.Http`, setting its `Timeout` property (a `TimeSpan`, not a `TimeoutInMilliseconds` member — `HttpClient` has none). Manage state via `INotifyPropertyChanged` properties (loading, content, empty, error). Render markdown via a `RichTextBlock` built from `Run`/`Span` elements with formatting applied through their own properties (`FontWeight`, `FontStyle`, `Foreground`) — there is no `TextFormatting` type. Apply theme colors via `ThemeResource` references to the default Windows theme palette (light/dark mode automatic). Implement retry via a `Button` with `Click` event handler that re-runs the fetch logic.

## Design Decisions

**Decision**: Compute the reading theme palette once at module scope rather than per render.
**Rationale**: The reading theme is static for any given instance of the component and does not depend on props or runtime state, so computing it once at module load time (not in render) avoids redundant theme lookups and `getThemeById()` calls. The theme applies to all instances of the component created in the same session.
**Approved**: pending

**Decision**: Read `source` through a ref (`sourceRef`) inside the fetch effect instead of listing `source` itself as a dependency.
**Rationale**: If `source` is a new object each render (same values, different reference), a naive effect dependency on `source` would re-fetch on every render. `sourceRef` reads the latest `source` value inside the effect while the effect's own dependency list holds only the stable primitive values (slug, route, baseUrl, contentTemplate, timeoutMs) — a common React pattern for a "read-only" dependency that should not by itself trigger a re-run.
**Approved**: pending

**Decision**: Share one abort path between unmount and document re-selection.
**Rationale**: Both cases benefit from aborting in-flight requests via the same `AbortController`. An `active` flag distinguishes them: unmount sets `active = false` and drops the result silently; a re-select (different slug/route/baseUrl) triggers a new effect and starts a new fetch. Shared cleanup logic keeps the implementation simple.
**Approved**: pending

**Decision**: Keep the empty state separate from the error state.
**Rationale**: Empty content (successful fetch, empty body) is distinct from error (failed fetch, network/timeout/server error). This distinction helps users understand whether the paper truly has no content or whether there was a technical problem (recoverable via Retry).
**Approved**: pending

**Decision**: Make `timeoutMs` a prop with a 15s default rather than a fixed constant.
**Rationale**: The 15s default mirrors adhsdk://recipes/markdown-viewer's own default timeout. Allowing `timeoutMs` as a prop enables callers to adjust based on network conditions or use-case SLAs without modifying the component.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | failed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best-practices |

Statuses rest on the source as documented above: the theme palette is applied as CSS custom properties whose actual color values live in `markdown-reading-palette` (adhsdk://recipes/markdown-reading-palette), outside this component, grounding `contrast-ratio` as partial; the Accessibility section's aria-live/aria-busy loading announcement and role="alert" error announcement ground `screen-reader-support` as partial, since the empty-state transition has no live-region marking; the Retry button's delegation to `Button`'s own recipe (adhsdk://recipes/button) grounds `keyboard-navigable` as passed and `touch-target-size` as failed (size="sm" with no `--adh-button-min-height` override, per that recipe's own default); `MarkdownRenderer`'s semantic HTML output and this component's own `role="alert"`/`aria-live`/`aria-busy` attributes ground `semantic-markup` as passed; and the Localization section's six hardcoded strings with no i18n framework integrated ground both internationalization checks as failed. `separation-of-concerns` passes: this component owns only fetch/state-machine logic, delegating URL construction inputs to the injected `SearchSource`, content rendering to `MarkdownRenderer`, and error/retry chrome to `Button`, each an independent module. `unit-test-coverage` fails: no test file anywhere in the repository references `MarkdownPreview` (the fetch/state-machine logic has no dedicated suite). Security, Privacy and Data, and User Safety are omitted: the component collects no user data, performs no logging, and does not itself render links (see Privacy and Logging above).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Fixed content-url default: endpoints.content defaults to DEFAULT_CONTENT_ENDPOINT (/public/users/:slug/papers/:route), not /:slug/:route; updated Configuration and edge case. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case, restated React-internal mechanics as observable behavior and moved them into the TypeScript Platform Note, corrected wrong SwiftUI/AppKit-UIKit/WinUI 3 API names, fixed the States/Accessibility role and tap-target claims, deduplicated the timeout test vectors, made the non-JSON edge case deterministic, cited markdown-renderer and markdown-viewer for the previously unsourced claims, reformatted Design Decisions to the three-line form, rebuilt Compliance as a linked table with partial/failed statuses backed by evidence, added tags/depends-on/related, and assigned Localization string keys |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
