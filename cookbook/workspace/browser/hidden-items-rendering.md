---
id: a40e6f97-06c4-4675-9ed7-9619a7c3e707
title: "Hidden Items Rendering"
type: ingredient
version: 0.1.2
status: draft
language: en
created: 2026-11-15
modified: 2026-11-23
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Hides the user list's enabled items on every matching page with one style sheet of display-none rules, put in at document start and kept current on the live page, plus a temporary preview rule set for the picker dialog."
platforms:
  - swift
  - macos
tags:
  - browser
  - privacy
  - hidden-items
  - user-scripts
  - css
depends-on: []
related: []
references:
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserHiddenItemsStyle.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Database/Daemon/Browser/BrowserHiddenItemsStore.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/WebKitBrowserEngine.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/BrowserHiddenImages.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/BrowserHiddenItemsStyleTests.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# Hidden Items Rendering

## Overview

This component makes the user's "Hide distracting items" list take effect
on the page. For the page a browser pane shows, it asks the hidden-items
store for the user list's enabled selectors and puts one style element,
`__adk_hidden_items`, into the page, holding one
`<selector> { display: none !important; }` rule per selector. The style
goes in at document start, so a matching item is never drawn on a fresh
load, and it is re-applied to the live page whenever the store changes and
on every navigation, so toggling an entry in the popover takes effect at
once. Because they are style rules, they also hide matching content the
page adds later, with no observer.

Each rule is added on its own, so one selector the engine rejects is
skipped and never disables the others. Selectors reach the page's script
as a JSON array, never pasted into script text, since a selector is
user-picked data that can contain quotes.

A second, temporary rule set, `__adk_hidden_items_preview`, serves the
picker dialog's "Show page with selected element removed" checkbox: it
hides the element being considered until the dialog closes, without saving
anything.

The engine has a single owner for its user scripts, and this style script
is added there with the others. A side effect is intended: the agent
gatekeeper's walker skips `display: none` content, so whatever the user
hides from themselves is hidden from the agent too.

## Behavioral Requirements

- **user-list-enabled-selectors**: The renderer MUST hide exactly the
  selectors the hidden-items store returns as the user list's enabled
  selectors for the page's address, and MUST NOT render agent-list entries
  (the agent list hides content from the agent, not from the user).
- **single-style-element**: The renderer MUST put its rules in one style
  element with the identifier `__adk_hidden_items`, and MUST replace that
  element's rules, never add a second element, each time it is applied.
- **display-none-rule-per-selector**: The style MUST hold one rule per
  selector, of the form `<selector> { display: none !important; }`.
- **installed-at-document-start**: The style MUST be installed as a user
  script that runs at document start, so matching items are hidden from
  the first paint of a new page load.
- **reapplied-on-change**: When the hidden-items store announces a change,
  the renderer MUST recompute the selectors for each pane's current address
  and apply them to the live page without a reload, so enabling, disabling,
  adding or removing an entry, or flipping the site switch, takes effect
  immediately.
- **reapplied-on-navigation**: On every committed navigation, the renderer
  MUST recompute the selectors for the new address and apply them, so a
  page on another site never keeps the previous site's rules.
- **late-content-hidden**: Content the page adds after the style is
  applied MUST be hidden by the same rules without re-applying them; no
  DOM mutation observer is used.
- **bad-selector-isolated**: A selector the page's style engine rejects
  MUST be skipped on its own; every other selector's rule MUST still take
  effect.
- **selectors-as-json**: Selectors MUST be passed to the page's script as a
  JSON-encoded array and MUST NOT be interpolated into script source, so no
  selector text can end a string or run as script.
- **empty-removes-style**: Applying an empty selector list MUST remove the
  `__adk_hidden_items` element, so the page draws as it is.
- **preview-rule-set**: The engine MUST offer a temporary preview rule set
  that hides a given list of selectors in a separate style element with the
  identifier `__adk_hidden_items_preview`; setting it to none MUST remove
  that element.
- **preview-independent**: The preview rule set MUST NOT change the
  hidden-items store or the `__adk_hidden_items` element, and setting or
  clearing it MUST leave the saved list's rules as they were.
- **single-owner-of-user-scripts**: The style user script MUST be added in
  the engine's single user-script owner together with every other user
  script, so rebuilding the user-script list for any reason keeps the
  hidden-items style in it.
- **user-hidden-hidden-from-agent**: Items hidden by this style MUST also be
  absent from what the agent receives, by way of the gatekeeper skipping
  `display: none` content; this renderer MUST NOT add any exception that
  keeps user-hidden content visible to the agent.

## Appearance

Not applicable — this component draws nothing of its own; it removes
matching page elements from layout.

## States

Not applicable — this is a page-styling component, not a visual
component. Its only state is the selector list last applied and the
preview list, both held by the engine.

## Accessibility

Not applicable — this is a page-styling component, not a visual component.
`display: none` removes an item from the page's accessibility tree as well
as from view, which is the intent.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hidden-items-rendering-001 | display-none-rule-per-selector | Build the CSS for `["a.ad", "#promo"]` | Two rules: `a.ad { display: none !important; }` and `#promo { display: none !important; }` |
| hidden-items-rendering-002 | selectors-as-json | Build the apply script for `["x\"]); alert(1)//"]` | The script carries the selector as a JSON-escaped string inside a JSON array; the raw quote never closes a string in the script source |
| hidden-items-rendering-003 | empty-removes-style | Build the apply script for `[]`; run it on a page that has the style | The element with id `__adk_hidden_items` is removed |
| hidden-items-rendering-004 | single-style-element | Apply `[".a"]`, then `[".b"]` to the same page | One `__adk_hidden_items` element, holding only the `.b` rule |
| hidden-items-rendering-005 | bad-selector-isolated | Apply `["::not-a-selector((", ".ad"]` | `.ad` elements are hidden; the bad selector is skipped and no error stops the script |
| hidden-items-rendering-006 | installed-at-document-start, user-list-enabled-selectors | User entry `.ad` enabled on `example.com/*`; load `https://example.com/` | The style is installed at document start and `.ad` elements are never drawn |
| hidden-items-rendering-007 | user-list-enabled-selectors | Agent-list entry `#secret` on `example.com/*` and no user entries; load `https://example.com/` | No `__adk_hidden_items` rules; `#secret` is drawn |
| hidden-items-rendering-008 | reapplied-on-change | Page `https://example.com/` showing with `.ad` hidden; disable the entry in the store | `.ad` elements reappear without a reload; re-enabling hides them again |
| hidden-items-rendering-009 | reapplied-on-change | Same page; turn the user site switch for `example.com/*` off | Every user-list rule is gone from the live page; entries remain in the store |
| hidden-items-rendering-010 | reapplied-on-navigation | `.ad` hidden on `example.com/*`; navigate the pane to `https://other.com/` | No `example.com` rules on `other.com` |
| hidden-items-rendering-011 | late-content-hidden | With `.ad` hidden, the page inserts a new `.ad` element after load | The new element is not displayed, with no re-apply |
| hidden-items-rendering-012 | preview-rule-set, preview-independent | Set the preview selectors to `["#x"]`, then to none | `#x` hidden in `__adk_hidden_items_preview`, then that element removed; the store and `__adk_hidden_items` unchanged throughout |
| hidden-items-rendering-013 | single-owner-of-user-scripts | With `.ad` hidden, toggle another user script (the activation shield or Hide Images), which rebuilds the user-script list; load a new page | The hidden-items style is still installed at document start |
| hidden-items-rendering-014 | user-hidden-hidden-from-agent | User entry `.ad` enabled; take an agent snapshot of the page | No content from `.ad` elements in the snapshot |
| hidden-items-rendering-015 | reapplied-on-navigation | Start a navigation to `b.com` with `.b-ad` hidden there; change the store while the navigation's read runs | The navigation reads again and the new document starts with the `.b-ad` rule, not the previous site's |
| hidden-items-rendering-016 | reapplied-on-navigation | `preparedHiddenItemSelectors` with three superseded reads, then a final unchecked read that fails | The final read is called with generation checking off, and the answer is `[]`, not nil (the previous site's rules are not kept) |

## Edge Cases

- **Null and empty input**: An empty selector list removes the style
  element (MUST, see `empty-removes-style`). A pane with no address gets
  only entries whose site is `*`, as the store answers.
- **Boundary values**: A selector the engine rejects is skipped alone
  (MUST, see `bad-selector-isolated`); a selector containing quotes,
  braces or a closing script tag is carried as JSON data (MUST, see
  `selectors-as-json`).
- **Concurrent access**: The store answers off the main thread; its answer
  is applied on the main thread. When a change and a navigation race, the
  last selectors computed for the pane's current address are the ones that
  stand: a store-change refresh that supersedes the navigation's read
  makes the navigation read again, and after three superseded reads a
  last read that nothing can supersede decides; if that read fails the
  new document starts with no user-list rules, so it never starts on the
  old site's rules.
- **Error states**: If the store cannot be read, the renderer leaves the
  page as the last applied rules drew it and logs the failure; a failure
  here never shows content to the agent, which goes through its own
  fail-closed gatekeeper.
- **Offline or disconnected state**: Not applicable — the renderer reads a
  local store and styles the page in memory.
- **Missing file or unreachable server**: Not applicable — handled by the
  store.
- **Cancellation and timeouts**: A live apply that fails (the page went
  away mid-evaluation) is dropped; the next navigation's document-start
  script installs the current rules.
- **Items that re-render often**: Ads and other content a page rebuilds
  under new class names may escape a "this item" selector and reappear; the
  picker shows a one-time notice saying so.
- **Frames**: Whether the style also goes into subframes is a builder's
  choice (see Design Decisions).

## Configuration

Not applicable: the renderer has no options of its own. What it hides is
the user list in the hidden-items store, and the per-site switch there
turns it off.

## Deep Linking

Not applicable: this component defines no URL scheme, route, or navigable
destination.

## Localization

Not applicable: this component produces no user-facing text.

## Accessibility Options

Not applicable: this component reads no accessibility display setting.

## Feature Flags

Not applicable: this component contains no feature-flag or remote-config
check.

## Analytics

Not applicable: this component emits no analytics or telemetry event.

## Privacy

- **Data collected**: none; the renderer reads selectors from the store
  and writes them into the page showing.
- **Exposure to the page**: the page's own scripts can see the
  `__adk_hidden_items` element and so learn which selectors the user hides
  on that site. That is the cost of a style the page's style engine
  applies; the selectors were picked from that same page.
- **Agent exposure**: user-hidden content is absent from what the agent
  receives (MUST, see `user-hidden-hidden-from-agent`).

## Logging

A failed read of the store is logged by the engine with the pane's
address host; no selector text is logged.

## Platform Notes

- **SwiftUI**: Not applicable — the renderer is WebKit user-script work
  owned by the engine, not a view.
- **AppKit / UIKit**: Planned as `enum BrowserHiddenItemsStyle` in
  `macOS/Features/BrowserPane/HiddenItems/BrowserHiddenItemsStyle.swift`,
  with `styleElementID = "__adk_hidden_items"`, `css(selectors:)`,
  `installScript(selectors:)` and `applyScript(selectors:)`, beside
  `BrowserHiddenImages`, whose pattern it follows: a `WKUserScript` at
  `.atDocumentStart` plus an `evaluateJavaScript` apply to the live page.
  The script is added in `WebKitBrowserEngine.installUserScripts()`, the
  only place user scripts are added or removed
  (`WKUserContentController` can only remove all of them). The engine
  re-runs it on `BrowserHiddenItemsStore.didChangeNotification` and in
  `webView(_:didCommit:)`, and also reads the selectors for a main-frame
  navigation's destination in its policy decision, before the new
  document starts, so the document-start script already carries that
  address's rules (WebKit injects document-start scripts in the web
  process before the commit reaches the delegate); a navigation that fails
  provisionally puts the committed address's rules back. Reads go through
  the store's `perform` off the main thread, and a generation counter
  keeps only the last read asked for; a read answers `HiddenItemsRead`
  (`selectors`, `superseded`, `failed`), and awaits the store with
  `BrowserHiddenItemsStore.currentStore()`, never blocking on it, since an
  engine made at launch reads before the store's open is done. The
  navigation read in the policy decision (`prepareHiddenItems`, through
  `preparedHiddenItemSelectors`) reads again when a store-change refresh
  supersedes it, since that refresh read the page being left, up to
  `hiddenItemsPrepareAttempts` (3) times. When every one of those is
  superseded and the engine is not torn down, one last read runs with
  `checkingGeneration: false`, which claims no generation and cannot be
  superseded; if it fails the document starts with no rules (`[]`), never
  the previous site's. Teardown, or a read inside the loop that fails
  outright, keeps the current rules. When a page's Content Security
  Policy refuses inline styles the element gets no sheet, so the rules go
  in an adopted constructed sheet instead (which `style-src` does not
  govern) and the element stays as the marker. Each rule goes in through its own
  `CSSStyleSheet.insertRule` in a `try`/`catch`, after a
  `CSS.supports('selector(…)')` check. The preview rule set is
  `WebKitBrowserEngine.setPreviewHiddenSelectors(_ selectors: [String]?)`,
  `nil` removing it.
- **Compose**: An Android `WebView` has no document-start user script;
  use `WebViewCompat.addDocumentStartJavaScript` from AndroidX WebKit, and
  `evaluateJavascript` for the live apply, passing selectors through a JSON
  string.
- **React/Web**: As a browser extension, a content script at
  `document_start` builds the same style element; `CSSStyleSheet.insertRule`
  per rule gives the same isolation.
- **WinUI 3**: WebView2's `AddScriptToExecuteOnDocumentCreatedAsync` for
  the document-start script and `ExecuteScriptAsync` for the live apply,
  with selectors serialized by `System.Text.Json`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserHiddenItemsStyle.swift` | planned |
| macos | `packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/BrowserHiddenItemsStyleTests.swift` | unverified |

## Design Decisions

**Decision**: one style element of `display: none !important` rules, not a
script that removes or hides matching nodes.
**Rationale**: Style rules apply to content added later with no observer,
and turning an entry off restores the element exactly; `!important`
outranks the page's own styles. This mirrors Hide Images
(`BrowserHiddenImages`), keeping one pattern for page styling (`dry`).
**Approved**: pending

**Decision**: each rule is inserted on its own, guarded, rather than set as
one block of text.
**Rationale**: In one text block, a selector the engine rejects can drop
the rule around it; inserting rules one by one confines a bad selector to
its own rule.
**Approved**: pending

**Decision**: the style goes into every frame, as Hide Images' does.
**Rationale**: Builder's choice. A distracting item can sit in a same- or
cross-site frame; site matching is decided once for the pane's address,
and frames follow it.
**Approved**: pending

**Decision**: the style runs in the page's content world.
**Rationale**: Builder's choice. A style element is drawn wherever it is
added, so the world only decides which scripts can touch it; the page
world matches Hide Images. The selectors were picked from the page itself,
so the page learns nothing new from them.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|

Notes: no compliance checks have been run; the code does not exist yet.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 0.1.2 | 2026-11-23 | Mike Fullerton | The hidden-items store moved to the database tier (Database/Daemon/Browser). Launch-time reads await currentStore(). |
| 0.1.1 | 2026-11-16 | Mike Fullerton | Navigation read retries when superseded, then a final unsuperseded read; failing that the document starts with no rules. |
| 0.1.0 | 2026-11-15 | Mike Fullerton | Initial creation (design-first, from the more privacy features design) |
