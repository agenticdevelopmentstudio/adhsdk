---
id: 28c73b3b-5614-4ec7-bf99-60a64aa77350
title: "Document Load Script"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "DocumentLoadScript: an inline script element emitted only in the server's HTML, so a pre-paint script runs at document load and never mounts on a client navigation."
platforms:
  - typescript
  - web
tags:
  - theme
  - appearance
  - hydration
depends-on: []
related:
  - 0f721fc3-0e8f-4a1b-b895-1b1bad370bd0
references: []
approved-by: ""
approved-date: ""
---

# Document Load Script

## Overview

`DocumentLoadScript` is a React client component (`"use client"`) that renders one inline `<script>` element holding the string passed as `code`, but only in the document the server sent. A script that must run before first paint does its job only in that document. A layout React mounts on a client navigation would otherwise create the `<script>` element anyway, where the browser never executes it and React reports "Encountered a script tag while rendering React component". The component therefore renders the script during the server render and during hydration, and renders nothing in any tree that React mounts fresh on the client.

The source's doc comment names the client-side half of the job as belonging to whoever runs then; for the appearance preferences that is `AppearanceScope` (part of the appearance recipe, [adhsdk.ingredient.themes.appearance](cookbook:0f721fc3-0e8f-4a1b-b895-1b1bad370bd0)). The component is exported from the themes package index and from its own subpath (`@adh-sdk/themes/DocumentLoadScript`), and is used by `AdhThemeStyle` (the appearance pre-paint script) and by the site template's `landing-frame.tsx` (the deck script).

## Behavioral Requirements

### Props and output

- **code-prop**: The component MUST accept a single prop, `code`, of type `string`.
- **script-element**: When it renders the script, the component MUST render exactly one `script` element and no wrapper element.
- **code-verbatim**: The `script` element's content MUST be the `code` string exactly as given, inserted as raw markup (the source uses `dangerouslySetInnerHTML` with `__html: code`) and not escaped or transformed.
- **script-no-attributes**: The `script` element MUST carry no attributes (no `src`, `type`, `nonce`, `async` or `defer`); the server markup for `code` equal to `window.__ran = 1` is exactly `<script>window.__ran = 1</script>`.

### Where the script appears

- **server-render-emits-script**: During a server render the component MUST render the `script` element.
- **hydration-emits-script**: During hydration of server HTML the component MUST render the `script` element, so the hydrated node matches the server HTML and React reports no mismatch.
- **client-mount-renders-nothing**: When React mounts the component on the client with no server HTML to hydrate (a client navigation into a layout that contains it), the component MUST render `null`, creating no `script` element and causing React to log no error.
- **leaves-tree-after-hydration**: After hydration completes, the component MUST leave the tree (its client snapshot is `false`), because the browser has already run the script from the server HTML and a retained element would do nothing further. The source states this in its doc comment; no test asserts it.

### State and ordering

- **output-fixed-while-mounted**: The choice between the script and `null` MUST depend only on whether React is rendering the server HTML (server render and hydration) or a fresh client tree; it MUST NOT change while the component stays mounted, other than the single swap from script to `null` when hydration finishes. The mechanism that achieves this is recorded in Design Decisions and Platform Notes.
- **no-state-no-effects**: The component MUST keep no state of its own, run no effect, read no global (no `window`, no `document`) and touch no storage.

### Errors and side effects

- **no-error-surface**: The component MUST NOT throw, validate `code`, or catch errors from the script it emits; whatever the script does when the browser runs it is outside this component.
- **no-side-effects**: The component MUST NOT write files, call the network, start processes, dispatch events or log; its only output is the returned element or `null`.

### Integration requirements

These bind the callers of the component, not the component.

- **trusted-code-only**: Callers MUST pass only trusted, static code; the source states "`code` goes into the page as-is" and performs no sanitisation.
## Appearance

Not applicable — this is a non-visual script emitter, not a visual component. It renders a `script` element, which has no visual surface, or nothing.

## States

Not applicable — this is a non-visual script emitter, not a visual component. The two outputs (script, nothing) are specified under Behavioral Requirements as the result of the snapshot, not as visual states.

## Accessibility

Not applicable — this is a non-visual script emitter, not a visual component. A `script` element is not exposed to assistive technology and nothing here is focusable or labelled.

## Conformance Test Vectors

The test beside the source is `DocumentLoadScript.test.tsx` in the themes package `__tests__` folder; vectors 001 to 003 derive from its three tests by name. Vectors 004 to 009 derive from the source and its doc comment and are tested in the same file.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| document-load-script-001 | server-render-emits-script, script-element, code-verbatim, script-no-attributes | `DocumentLoadScript.test.tsx` "is in the server HTML": `renderToString` of the component with `code` equal to `window.__ran = 1` | the string is exactly `<script>window.__ran = 1</script>` |
| document-load-script-002 | client-mount-renders-nothing | `DocumentLoadScript.test.tsx` "renders nothing on a client mount, so React never warns about it": client `render` of the component with a spy on `console.error` | the container has no `script` element and the spy was not called |
| document-load-script-003 | hydration-emits-script | `DocumentLoadScript.test.tsx` "hydrates the server node without a mismatch": server HTML from `renderToString` placed in a host element, then `hydrateRoot` of the same component with a spy on `console.error` | hydration finishes and the spy was not called |
| document-load-script-004 | code-verbatim | server render with `code` equal to `if (a < b && c) { x = "1" }` | the markup holds that text unescaped inside the `script` element, with no `&lt;`, `&amp;` or `&quot;` |
| document-load-script-005 | code-verbatim, no-error-surface | server render with `code` equal to the empty string | one empty `script` element is rendered and nothing throws |
| document-load-script-006 | trusted-code-only (documents the hazard, not desired behavior) | server render with `code` equal to `</script><b>x</b>` | the markup contains the closing tag text as given, ending the script element early; this vector records a known hazard that callers must avoid, and a conforming component does not guard against it |
| document-load-script-007 | leaves-tree-after-hydration, output-fixed-while-mounted | hydrate server HTML, then let React finish and commit the client snapshot | the component renders `null`; the `script` element is no longer in its tree |
| document-load-script-008 | script-no-attributes | server render with any `code` | the opening tag is exactly `<script>` with no attributes |
| document-load-script-009 | no-side-effects, no-state-no-effects | render on the client with `window.addEventListener`, `document.addEventListener`, `dispatchEvent`, `localStorage`, `sessionStorage` and `console` spied | no `addEventListener` or `dispatchEvent` call is made, no `localStorage` or `sessionStorage` access occurs, and no `console` method is called |

## Edge Cases

- **Empty `code`**: the component MUST render an empty `script` element in the server HTML and nothing on the client; it does not validate `code`.
- **`code` containing the closing script tag**: the string goes into the page as-is, so the browser ends the element at that text; this component MUST NOT escape it; callers must not pass untrusted text (see the trusted-code-only integration requirement).
- **Null or non-string `code`**: the prop type is `string`, enforced only by TypeScript; the source adds no runtime check, so the result for a non-string value is whatever React does with it and is not specified here.
- **Client navigation into a layout that contains the component**: MUST render `null` and MUST NOT make React log the script-tag warning; this is the reason the component exists.
- **Hydration**: MUST render the script so the hydrated node matches the server HTML; after hydration the element MUST leave the tree.
- **Concurrent access**: no special handling; the component holds no shared state and runs inside React's render on the single JavaScript thread.
- **Offline or disconnected state**: not applicable; the component makes no network request. Whether the script it emitted ran is a property of the document load, not of this component.
- **Script failure**: if the emitted code throws in the browser, nothing in this component observes or reports it; the failure is the script's own.
- **Client-only app with no server HTML**: the component never emits the script, so a page that relies on it must receive the script from a server render, as the doc comment states.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `code` | `string` | required | Trusted, static JavaScript source placed unescaped inside the `script` element |

Fixed behavior: the server snapshot is `true`, the client snapshot is `false`, and the subscription is a no-op. There are no environment variables, settings keys or injected dependencies.

## Deep Linking

Not applicable: the component reads no URL and registers no routes.

## Localization

Not applicable: the component renders no user-facing text and has no strings of its own; the `code` it emits is supplied by the caller.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the component animates nothing. |
| Increase Contrast | Not applicable: the component has no visual output. |
| Differentiate Without Color | Not applicable: the component has no visual output. |

## Feature Flags

Not applicable: the component reads no feature flag.

## Analytics

Not applicable: the component emits no analytics events.

## Privacy

- **Data collected**: none.
- **Storage**: none; the component reads and writes no storage.
- **Transmission**: none; the component makes no network request. The emitted `code` is sent to the browser as part of the page.
- **Retention**: not applicable; nothing is kept.

## Logging

Not applicable: the component makes no log calls. React's own console error, which this component exists to avoid, is not emitted by it.

## Platform Notes

- **SwiftUI**: There is no document load, server HTML or hydration, so there is nothing to port directly. The nearest equivalent of work that must run before first draw is code in the `App` initializer or `onAppear` guarded to run once; an inline script string has no counterpart, and the client-navigation hazard does not exist because views are never rendered from HTML.
- **Compose**: There is no document and no script element. Run once-only startup work with `LaunchedEffect(Unit)` or in `Application.onCreate` before the first composition; a conditional that renders nothing on re-entry maps to a plain `if` around the composable, with no hydration concern.
- **React/Web**: The source is `packages/web/packages/themes/src/DocumentLoadScript.tsx`, a `"use client"` module re-exported from `packages/web/packages/themes/src/index.ts` and published as the subpath `@adh-sdk/themes/DocumentLoadScript`. It uses `useSyncExternalStore` with a constant no-op `subscribe`, a client snapshot of `false` and a server snapshot of `true`, and `dangerouslySetInnerHTML` for the script body. Its test is `src/__tests__/DocumentLoadScript.test.tsx` (Vitest, Testing Library, `renderToString` and `hydrateRoot`).
- **AppKit / UIKit**: There is no HTML document. Pre-first-paint work belongs in `application(_:didFinishLaunchingWithOptions:)` or `applicationDidFinishLaunching(_:)`. If a `WKWebView` hosts web content, the equivalent of an inline pre-paint script is a `WKUserScript` with injection time `.atDocumentStart`, added to the web view's `WKUserContentController`; it runs once per document load and is not part of any view tree.
- **WinUI 3**: There is no HTML or hydration, so the component has no direct control. Work that must run before first render belongs in `App.OnLaunched` before `Window.Activate()`, or in the page constructor before the first layout. For a `WebView2` host, the equivalent is `CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(code)`, which runs the string at document creation in every navigation, so it needs no server-only guard; keep `code` trusted and static as the source requires. In XAML, the once-only guard is a `bool` field on the page or a `Loaded` handler that unsubscribes itself.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| ios | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| web | `packages/web/packages/themes/src/DocumentLoadScript.tsx` | confirmed (1.0.2) |

## Design Decisions

**Decision**: Render the script only when the server snapshot is in use (server render and hydration), and render `null` on a fresh client mount.
**Rationale**: The source comment explains that a script element created by a client mount never executes and makes React log "Encountered a script tag while rendering React component"; the pre-paint job only works in the document the server sent.
**Approved**: pending

**Decision**: Use `useSyncExternalStore` with a constant no-op subscription (server snapshot `true`, client snapshot `false`) instead of `useEffect` and state.
**Rationale**: Inferred from the source: its server snapshot is used for hydration, so the hydrated node matches the server HTML, while the client snapshot makes a fresh mount render nothing, and no effect or state is needed. An effect-and-state version would render the script on the first client render and then remove it.
**Approved**: pending

**Decision**: Insert `code` as raw HTML with no sanitising, and require trusted, static code.
**Rationale**: The source comment states "Trusted, static code only"; the callers pass constants and generated pre-paint scripts, and escaping would change the script text the browser runs.
**Approved**: pending

**Decision**: Leave the client-side half of the job to another module.
**Rationale**: The source comment says it belongs to whoever runs then, and names `AppearanceScope` for the appearance preferences; this component owns only the document-load half.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | security |

The component keeps one concern: it decides whether the script element exists and leaves the script's content, the appearance logic and the client-side follow-up to its callers and to `AppearanceScope`, so separation of concerns passes. `DocumentLoadScript.test.tsx` covers the server markup, the client mount with no React error, and hydration without a mismatch, which are the component's three paths, so those are covered. Vectors 004 to 009 are covered in the same file, so unit-test coverage passes. The `code` prop is inserted unescaped and the source documents this as a trusted-callers-only contract rather than checking it, so input sanitization is partial.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (DocumentLoadScript.test.tsx, 9 of 9 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Recast the mechanism requirements as behavior, moved trusted-code-only to integration requirements, made leaves-tree-after-hydration a MUST, rewrote vector 009, marked unit-test coverage partial and linked the appearance recipe. |
