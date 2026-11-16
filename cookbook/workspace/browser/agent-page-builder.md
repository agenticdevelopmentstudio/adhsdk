---
id: 8bd94d87-6096-4fb1-82a7-d5f712c2958f
title: "Agent Page Builder (Agent Gatekeeper)"
type: ingredient
version: 0.1.0
status: draft
language: en
created: 2026-11-15
modified: 2026-11-15
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The one fail-closed component that builds everything an agent receives from a web page up from an allowlist, conceals every string as it is added, and renders that single result as the snapshot tree, the text and the HTML the agent views show."
platforms:
  - swift
  - macos
tags:
  - browser
  - agent
  - privacy
  - gatekeeper
  - allowlist
  - snapshot
  - fail-closed
depends-on: []
related: []
references:
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/AgentPage/AgentPage.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/AgentPage/AgentPageAllowlist.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/AgentPage/AgentPageBuilder.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/AgentPage/AgentPageWalker.js (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/AgentPage/AgentPageSource.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/BrowserToolSet.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/BrowserAutomation.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/BrowserAgentPrivacy.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/BrowserSnapshot.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/BrowserSnapshot.js (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/BrowserHistoryTool.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserHiddenItemsStore.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/AgentPageBuilderTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/AgentPageWalkerWebViewTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/AgentGatekeeperRoutingTests.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# Agent Page Builder (Agent Gatekeeper)

## Overview

This component is the one gatekeeper between a web page and an agent. It
decides everything an agent receives from a page: the accessibility-tree
snapshot, the page text, the results of finding elements, the references
that click, type, fill, select and hover resolve, the text a wait condition
is checked against, and — through its string path — page titles, dialog
messages, focused-element descriptions and browsing history. The same
result is what the Agent preview and Agent source views show (see the
Agent Preview and Agent Source Views recipe), so a user in a
privacy-critical situation can check with their own eyes exactly what an
agent is given.

It works in two halves. A walker running in the page's isolated automation
context visits the document and emits a neutral list of nodes: only node
kinds and attributes on an allowlist, never markup it did not construct,
skipping hidden content and anything on the site's "hide from agent" list.
The host side receives that list, re-validates every node and every
attribute against the same allowlist (defined once on the host side and
handed to the walker), applies every privacy setting to each piece as it is
added, and produces one immutable page value. Three renderings come from
that one value: the snapshot tree in today's format, the plain text, and
an HTML document for the views.

The page is *built up*; it is never the live document with parts trimmed
away. Whenever anything is uncertain or fails, content is stripped rather
than let through: an unknown node kind or attribute is dropped, and a
walker error, a timeout, a malformed payload or an unreadable privacy-word
vault yields an empty page carrying a reason. The component always runs —
there is no branch on privacy settings choosing whether to use it; settings
only change what it filters.

The design is new (2026-11-15) and the code does not exist yet; this
recipe is written before it.

## Behavioral Requirements

- **single-gatekeeper**: The component MUST be the only source of page
  content for every agent page read — the snapshot, text and find tools,
  the references click, type, fill, select and hover resolve, and the text
  a wait condition is checked against — for the in-app chats and the
  external tool server alike; no agent-facing tool MUST read page content
  by any other route except the raw-page tools in the situations
  `raw-page-tools-refused-when-filtered` allows.
- **always-runs**: The component MUST run for every agent page read
  whatever the privacy settings are; there MUST be no branch on any
  privacy setting that chooses whether to use it. With every privacy
  feature off it MUST still enforce the allowlist and skip hidden content.
- **built-up-not-trimmed**: The component MUST construct its result only
  from nodes the walker emits and it has re-validated; it MUST NOT copy,
  serialize or pass through any markup, script, style or attribute of the
  live page that it did not itself construct.
- **allowlist-defined-once**: The allowlist of node kinds and per-kind
  attributes MUST be defined once, on the host side, and MUST be passed to
  the walker as an argument of each walk; the walker MUST NOT carry its own
  copy.
- **walker-emits-allowlisted-only**: The walker MUST emit only nodes whose
  kind is on the allowlist it was given and, on each node, only attributes
  the allowlist permits for that kind, and MUST give every emitted node a
  reference.
- **walker-skips-hidden-nodes**: The walker MUST NOT visit a node, or any
  node beneath it, whose computed display is none, whose computed
  visibility is hidden, that carries the `hidden` attribute, or that
  carries `aria-hidden="true"`.
- **user-hidden-items-hidden-from-agent**: Because an item hidden by the
  user's "hide distracting items" list is hidden by a display-none rule,
  the walker MUST NOT visit it either; the agent list MUST be the only way
  to hide something from the agent alone.
- **walker-skips-agent-list**: The walker MUST NOT visit a node, or any
  node beneath it, that matches any enabled agent-list selector for the
  page's site.
- **invalid-exclude-selector-isolated**: An agent-list selector the
  document cannot evaluate MUST exclude nothing on its own, MUST be
  reported in the walk's warnings, and MUST NOT stop any other selector
  from excluding what it matches.
- **scope-within-walk**: A scope argument on the snapshot or text tools
  MUST select a subtree within the gatekeeper's own walk, with agent-list
  exclusion still applied inside it; a scope whose element, or any of its
  ancestors, matches an enabled agent-list selector MUST yield an empty
  root.
- **unknown-kind-dropped-with-subtree**: The component MUST drop a node
  whose kind is not on the allowlist, or that it cannot classify, together
  with its whole subtree.
- **unlisted-attribute-dropped**: The component MUST drop every attribute
  of a node that the allowlist does not permit for that node's kind.
- **href-sanitized**: The component MUST keep a link's `href` only when it
  is an absolute `http` or `https` address after a relative address is
  resolved against the page's address; any other address (including
  `javascript:`, `data:` and anything that does not parse) MUST be dropped.
- **concealed-before-insertion**: The component MUST pass every string —
  node text, value, page title, every attribute value and every `href` —
  through the privacy concealment in force before the node holding it is
  created, so no real privacy word reaches the result in any rendering.
- **hide-images**: When the Hide Images setting is on, the component MUST
  drop every image node; when it is off, an image MUST enter the result
  only as its alternative text, never as an image source.
- **value-kept-only-for-form-controls**: The component MUST keep a node's
  value only for text fields, text areas, selects, checkboxes and radio
  buttons, and MUST never keep the value of a password field. The snapshot
  rendering MUST print the value of a text field, text area or select as
  today's snapshot does (whitespace collapsed, cut at 50 characters, an
  empty value printed as none). An element with the `slider` or
  `spinbutton` role that is not an `input` reaches the component as a text
  field of type `range` or `number` whose value is its `aria-valuenow`, and
  that value MUST be kept and printed the same way.
- **fail-closed-on-walker-failure**: When the walker throws, does not
  finish within its timeout (1500 milliseconds by default), or returns a
  payload that does not decode, the component MUST return an empty page —
  no root — carrying a reason that begins `Agent view unavailable: `, and
  MUST NOT return any page content.
- **fail-closed-on-vault**: When the privacy concealment is unavailable
  (the words cannot be read) or conflicting (a stand-in holds a real
  word), the component MUST return an empty page carrying a reason that
  begins `Agent view unavailable: ` before it reads the payload, even when
  the payload is valid.
- **no-partial-content-on-failure**: On any failure the component MUST
  return the empty page alone and MUST NOT return any part of the page
  built before the failure was found.
- **one-value-three-renderings**: The component MUST produce one
  immutable page value from which the snapshot tree, the text and the
  HTML are all rendered; no rendering MUST read the page or the walker's
  payload on its own.
- **snapshot-tool-contract-unchanged**: The snapshot rendering MUST
  reproduce today's tree format, line for line, for the equivalent tree,
  and MUST honor the existing options — interactive only, depth, scope,
  include URLs, delta — and generation-stamped references; existing tool
  descriptions MUST remain true. As today, a depth of 0 or less MUST mean
  no limit, and the text a generic element collapses to, or a button,
  link, heading, cell or option is named by, MUST be its subtree's text
  concatenated with no separator, as an element's `textContent` is
  (`a<b>b</b>` gives "ab").
- **refs-drive-actions**: Every reference in the result MUST be one that
  click, type, fill, select and hover resolve to the same element.
- **selector-recorded-per-node**: Each node MUST record a selector for its
  element at build time, so a later pick on that node in the Agent preview
  can be mapped back to the page.
- **html-rendering-safe**: The HTML rendering MUST escape every string,
  MUST emit only elements it maps from node kinds, MUST put the node's
  reference on each element it emits as `data-adk-ref`, MUST emit no
  `script` element and no `style` attribute, and MUST render an image as a
  text placeholder holding its alternative text, never as an element with
  a source.
- **unavailable-page-renders-reason**: An unavailable page MUST render as
  its reason alone — one paragraph in the HTML, the reason as the text and
  as the tool result.
- **unavailable-reason-is-the-result**: When the page is unavailable, the
  snapshot, text and find tools MUST return its reason as their result,
  not an error that could lead a caller to retry against the raw page.
- **string-path**: The component's string path MUST return a string
  unchanged when agent privacy is off, concealed with the privacy words
  when it is on, and empty when the vault is unavailable or conflicting.
- **raw-page-tools-refused-when-filtered**: The screenshot, click-at and
  evaluate tools, which see the page without the gatekeeper, MUST be
  refused when agent privacy is on or when the page's site has any enabled
  agent-list entry; the agent-list refusal MUST say "This site has items
  hidden from the agent, so tools that see the raw page are refused here."
- **raw-page-tools-allowed-when-unfiltered**: With agent privacy off and no
  enabled agent-list entry for the site, the screenshot, click-at and
  evaluate tools MUST NOT be refused by this component.
- **console-refused-under-privacy**: The console tool MUST be refused
  while agent privacy is on, with the sentence "Agent Privacy is on for
  this browser pane, so console output is not shared."
- **wait-for-uses-agent-text**: A wait condition on text MUST be evaluated
  against the result's text, never the live document, so text present only
  in excluded or hidden content never satisfies it.
- **find-uses-agent-page**: The find tool MUST search the result's text and
  return references from the result.
- **titles-dialogs-focus-through-string-path**: Page titles in the pane
  list and in action replies, script dialog messages, and the
  focused-element description in action replies MUST pass through the
  string path; a focused element whose reference is not in the current
  result MUST be omitted from the reply.
- **history-through-string-path**: Every title and address the history
  tool returns MUST pass through the string path.

## Appearance

Not applicable — this is a page-building and rendering component, not a
visual component; how its HTML looks on screen is the Agent Preview and
Agent Source Views recipe's concern.

## States

Not applicable — this is a page-building and rendering component, not a
visual component. It holds no state between calls: each read walks the
page anew and builds a fresh value.

## Accessibility

Not applicable — this is a page-building and rendering component, not a
visual component. (It *reads* the page's accessibility semantics — labels,
landmarks, headings — to build its result.)

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| agent-page-builder-001 | unknown-kind-dropped-with-subtree, built-up-not-trimmed | Payload with a node of kind `iframe` holding a text child "inner secret" | Neither the node nor "inner secret" appears in the snapshot tree, text or HTML |
| agent-page-builder-002 | unlisted-attribute-dropped | Link node with attributes `onclick="steal()"` and `href="https://a.example/"` | The link keeps only `href`; "steal" appears in no rendering |
| agent-page-builder-003 | href-sanitized, concealed-before-insertion | Privacy words {Acme}; three links: `javascript:alert(1)`, `data:text/html,x`, `/p?u=Acme` on page `https://site.example/` | The first two links carry no address; the third's address is `https://site.example/p?u=` followed by the stand-in, with no "Acme" |
| agent-page-builder-004 | concealed-before-insertion | Privacy words {Acme}; "Acme" in a heading, a text field value, the page title, an `aria-label` and a `title` attribute | "Acme" appears nowhere in the snapshot tree, the text or the HTML; the stand-in appears in each place |
| agent-page-builder-005 | value-kept-only-for-form-controls | A text field with value "hello", a password field with value "hunter2", a button with value "go", a text area with value "private notes" | The text field shows "hello" and the text area "private notes"; "hunter2" and the button's value appear in no rendering |
| agent-page-builder-006 | hide-images | Hide Images on; an image with alt "Logo" | No image node and no "Logo" in any rendering |
| agent-page-builder-007 | hide-images, html-rendering-safe | Hide Images off; an image with alt "Logo" and a source attribute | The HTML shows a placeholder reading "[image: Logo]"; no source address appears anywhere |
| agent-page-builder-008 | fail-closed-on-walker-failure, no-partial-content-on-failure | Payload bytes `{` | Empty page; reason begins `Agent view unavailable: `; no root |
| agent-page-builder-009 | fail-closed-on-walker-failure | The walker reports an error | Empty page with a reason beginning `Agent view unavailable: ` |
| agent-page-builder-010 | fail-closed-on-walker-failure | Walk of a large page with a timeout of 0 milliseconds | Empty page with a reason beginning `Agent view unavailable: ` |
| agent-page-builder-011 | fail-closed-on-vault | Privacy unavailable; a valid payload | Empty page, reason set, no root |
| agent-page-builder-012 | fail-closed-on-vault | Privacy conflicting; a valid payload | Empty page, reason set, no root |
| agent-page-builder-013 | html-rendering-safe | Text node `<script>x</script>` and a node whose page element had a `style` attribute | The HTML contains `&lt;script&gt;x&lt;/script&gt;`, no `<script` element and no `style=` attribute; every emitted element has `data-adk-ref` |
| agent-page-builder-014 | snapshot-tool-contract-unchanged | A fixture payload and the equivalent legacy snapshot tree | The snapshot rendering's lines equal the legacy renderer's lines for that tree, with and without include URLs, with depth unset, 0 and -1; the fixture holds a text area value, inline text split across two text nodes, a slider and a spinbutton |
| agent-page-builder-015 | always-runs | Privacy off; a payload with an unknown kind | The unknown node is still dropped |
| agent-page-builder-016 | walker-skips-hidden-nodes | Live page with four elements hidden by display none, visibility hidden, the `hidden` attribute and `aria-hidden="true"` | None of the four appears in the result |
| agent-page-builder-017 | walker-skips-agent-list | Agent list for the site holds `.ad`; the page has a `.ad` element with a child paragraph | Neither the element nor its paragraph appears |
| agent-page-builder-018 | user-hidden-items-hidden-from-agent | The user list hides `#promo`, the agent list is empty | `#promo` does not appear in the result |
| agent-page-builder-019 | scope-within-walk | Agent list holds `#side`; snapshot scoped to a reference inside `#side` | The result has an empty root |
| agent-page-builder-020 | invalid-exclude-selector-isolated | Agent list holds `::bad(` and `.ad` | `.ad` elements are still excluded; the walk's warnings name `::bad(`; the walk succeeds |
| agent-page-builder-021 | refs-drive-actions | Take a reference for a button from the result and click it | The click succeeds on that button |
| agent-page-builder-022 | single-gatekeeper, one-value-three-renderings | A spy page source; call the snapshot, text and find tools once each | Each tool requests exactly one page from the source; none reads the page another way |
| agent-page-builder-023 | raw-page-tools-refused-when-filtered | Privacy off; the site has one enabled agent-list entry; call screenshot, click-at, evaluate | Each is refused with the agent-list sentence |
| agent-page-builder-024 | raw-page-tools-refused-when-filtered | Privacy on; no agent-list entries; call screenshot | Refused |
| agent-page-builder-025 | raw-page-tools-allowed-when-unfiltered | Privacy off; no enabled agent-list entries; call screenshot | Not refused by the gatekeeper |
| agent-page-builder-026 | console-refused-under-privacy | Privacy on; call the console tool | Refused with the console sentence |
| agent-page-builder-027 | wait-for-uses-agent-text | Text "Ready" exists only inside an agent-list-excluded element; wait for text "Ready" | The wait times out |
| agent-page-builder-028 | find-uses-agent-page | Find "Buy" where one "Buy" button is excluded and one is not | Only the visible button's reference is returned |
| agent-page-builder-029 | titles-dialogs-focus-through-string-path | Privacy words {Acme}; page title "Acme Home"; an alert "Hi Acme"; list panes, then click a button that raises the alert | Neither the pane list nor the reply contains "Acme" |
| agent-page-builder-030 | titles-dialogs-focus-through-string-path | An action moves focus into an agent-list-excluded element | The reply has no focused-element description |
| agent-page-builder-031 | history-through-string-path | Privacy words {Acme}; history holds a visit titled "Acme" | The history tool's reply contains the stand-in, not "Acme" |
| agent-page-builder-032 | string-path | The string "Acme" through the string path with privacy off, on with {Acme}, unavailable, conflicting | "Acme"; the stand-in; ""; "" |
| agent-page-builder-033 | unavailable-page-renders-reason, unavailable-reason-is-the-result | An unavailable page; render HTML; call the snapshot tool | The HTML is one paragraph with the reason; the tool returns the reason as its result, not an error |
| agent-page-builder-034 | allowlist-defined-once, walker-emits-allowlisted-only | Walk a page with an allowlist that omits `table` | No table, row or cell node is emitted |
| agent-page-builder-035 | selector-recorded-per-node | Build a page with a link | The link's node records a selector that matches exactly that link in the document |
| agent-page-builder-036 | snapshot-tool-contract-unchanged | Depth option 0, then -3, on a page three levels deep | Each rendering equals the one with no depth option |
| agent-page-builder-037 | value-kept-only-for-form-controls | A text area labelled "Notes" with value "Line one" newline "   line two" | The snapshot prints `textbox "Notes"` with `[value="Line one line two"]`; the HTML text area holds the value |
| agent-page-builder-038 | snapshot-tool-contract-unchanged | A paragraph with text children "a" and "b"; a button with text "Sign" and a text child "in" | The snapshot prints `text: ab` and `button "Signin"` |
| agent-page-builder-039 | value-kept-only-for-form-controls | A text field of type `range` named "Volume" with value "40" and one of type `number` labelled "Count" with value "3" | The snapshot prints `slider "Volume"` with `[value="40"]` and `spinbutton "Count"` with `[value="3"]` |
## Edge Cases

- **Null and empty input**: An empty document yields a page with a
  document root and no children (MUST, `built-up-not-trimmed`). A missing
  payload with no error is a malformed payload and yields the unavailable
  page (MUST, `fail-closed-on-walker-failure`). An empty string through the
  string path stays empty.
- **Boundary values**: A depth option of 0 or less is no limit, as in
  today's snapshot (MUST, `snapshot-tool-contract-unchanged`); a very
  large page is bounded by the walker's timeout, after which the page is
  unavailable, never truncated (MUST, `no-partial-content-on-failure`). An
  `href` with only a fragment resolves against the page address and is
  kept only if the result is `http`/`https`.
- **Concurrent access**: The builder is a value with no mutable state;
  concurrent builds from any thread MUST be independent. The walker runs
  on the page's main thread through the browser engine; two walks of one
  page each produce their own reference generation, as snapshots do today.
- **Error states**: Every error — walker error, timeout, undecodable
  payload, unreadable or conflicting privacy words — collapses to the one
  unavailable page with a reason beginning `Agent view unavailable: `
  (MUST, `fail-closed-on-walker-failure`, `fail-closed-on-vault`). An
  invalid agent-list selector is not an error: it is a warning and the
  walk continues (MUST, `invalid-exclude-selector-isolated`).
- **Offline or disconnected state**: Not applicable — the component reads
  only the already-loaded document and the local agent list; it makes no
  network request.
- **Missing file or unreachable server**: The agent list's store missing
  or unopened means no exclusions are applied, as when the list is empty;
  the walker script missing from the bundle is a walker error and yields
  the unavailable page.
- **Cancellation and timeouts**: The walker stops after its timeout
  (default 1500 milliseconds) and the page is unavailable (MUST,
  `fail-closed-on-walker-failure`). A navigation during a walk makes its
  references stale under the existing generation rule.
- **Privacy words change mid-read**: The concealment in force when the
  build starts conceals the whole result; the tool reply is concealed
  again with the words of the moment it returns, as replies are today.
- **Excluded ancestor of focus or scope**: See `scope-within-walk` and
  `titles-dialogs-focus-through-string-path` — content under an excluded
  ancestor never reaches the agent by either path.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `allowlist` | node kinds plus per-kind attribute sets | the standard allowlist (Design Decisions) | What may enter the result; passed to the walker each walk. |
| `privacy` | agent privacy state (off, enabled with words, unavailable, conflicting) | the pane's Agent Privacy | Drives concealment and the fail-closed vault rule. |
| `hideImages` | boolean | the Hide Images setting | Drops image nodes when on. |
| `excludeSelectors` | list of selectors | the site's enabled agent-list entries; empty with no store | Subtrees the walker never visits. |
| `scope` | reference or selector | none | Subtree of the walk to render. |
| `interactiveOnly`, `depth`, `includeURLs`, `delta` | as today's snapshot options | as today | Unchanged snapshot options. |
| `timeoutMs` | integer milliseconds | 1500 | Walker deadline. |

## Deep Linking

Not applicable: this component defines no URL scheme, route or navigable
destination.

## Localization

The unavailable reasons and refusal sentences are agent-facing English
sentences, as every existing tool reply and refusal is; they are not
user-interface strings and are not localized. The reason's
`Agent view unavailable: ` prefix is a contract and MUST NOT be
translated.

## Accessibility Options

Not applicable: this component renders nothing and reads no accessibility
display setting.

## Feature Flags

Not applicable: this component has no feature flag, and by
`always-runs` it MUST NOT be placed behind one.

## Analytics

Not applicable: this component emits no analytics or telemetry event.

## Privacy

This component *is* the privacy boundary between a page and an agent.
What crosses it: allowlisted node kinds, allowlisted attributes, sanitized
`http`/`https` addresses, and form values except passwords — each string
concealed with the pane's privacy words before it is added. What never
crosses it: markup, scripts, styles, image data or sources, hidden content,
agent-list content, password values, and — on any failure — anything at
all. It stores nothing: each result lives for one tool call or one view
refresh. The one accepted failure is over-stripping.

## Logging

The design specifies no logging. Any log line added later MUST carry only
reasons, counts or selector warnings, never a page string, since a log a
model can read would be a route around the gatekeeper.

## Platform Notes

- **SwiftUI**: Nothing here is view code; the builder imports Foundation
  only, and the page source needs WebKit. A SwiftUI host uses both
  unchanged.
- **Compose**: Run the walker with `WebView.evaluateJavascript` in a
  `WebViewCompat.addDocumentStartJavaScript` isolated script; decode with
  kotlinx.serialization into the same payload shape; build the page in a
  pure Kotlin object holding the allowlist; HTML-escape with
  `TextUtils.htmlEncode`.
- **React/Web**: In an extension context, run the walker as a content
  script in an isolated world (`chrome.scripting.executeScript` with
  `world: "ISOLATED"`), passing the allowlist as `args`; build and
  escape on the extension side, never with `innerHTML` of page content.
- **AppKit / UIKit**: The reference home. `AgentPageBuilder` (a `Sendable`
  struct: `build(payload:error:) -> AgentPage`, `conceal(_:)`) is pure
  Swift; `AgentPageSource` (`@MainActor`) runs `AgentPageWalker.js` with
  `WKWebView.callAsyncJavaScript(_:arguments:in:contentWorld:)` in
  `BrowserSnapshotRuntime.world` (the `adkitchen.automation` content
  world), passing `AgentPageAllowlist.standard` JSON-encoded as an
  argument, the agent-list selectors from
  `BrowserHiddenItemsStore.enabledSelectors(list: .agent, for:)`, and the
  timeout. Concealment is `BrowserAgentPrivacy.concealing(_:)`, except that
  the string path returns `""` for `.unavailable`/`.conflicting`.
  `BrowserToolSet` routes `browser_snapshot`, `browser_text`,
  `browser_find`, `browser_wait_for` text and the action-reply titles
  through it; `rawPageRefusal(pane:)` gates `browser_screenshot`,
  `browser_click_at` and `browser_evaluate`; `BrowserAutomation` routes
  dialog messages and the focused-element description. Same code under
  UIKit's `WKWebView`.
- **WinUI 3**: Run the walker with WebView2's
  `CoreWebView2.ExecuteScriptAsync` from a script added with
  `AddScriptToExecuteOnDocumentCreatedAsync`, passing the allowlist as a
  JSON argument; decode with `System.Text.Json`; build with
  `WebUtility.HtmlEncode` for every string.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/AgentPage/AgentPage.swift` | planned |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/AgentPage/AgentPageAllowlist.swift` | planned |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/AgentPage/AgentPageBuilder.swift` | planned |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/AgentPage/AgentPageWalker.js` | planned |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/AgentPage/AgentPageSource.swift` | planned |

## Design Decisions

**Decision**: The standard allowlist's node kinds are document, landmark,
heading, paragraph, text, list, list item, link, button, text field, text
area, checkbox, radio, select, option, table, row, cell, image and label.
Attributes: `aria-label` and `title` on every kind; `href` on links; `alt`
on images; `placeholder`, `name` and `type` on text fields and text areas;
`name` on selects, checkboxes and radios; `level` on headings.
**Rationale**: The spec's list (text, headings, paragraphs, lists, links,
buttons, form controls with labels and values, tables, images as alt text,
landmarks) made concrete; the spec allows tighter.
**Approved**: pending

**Decision**: To reproduce today's tree format line for line, a landmark
carries its landmark role (main, navigation, banner, contentinfo,
complementary, search, form, region, article) and nodes carry the legacy
states (checked, disabled, expanded, selected, pressed, required) as
allowlisted values from fixed vocabularies; a value outside the vocabulary
is dropped. The walker sends them as the attributes `role` (on a landmark)
and `states` (space-separated, on any node); the allowlist's JSON carries
both vocabularies as `landmarkRoles` and `states`.
**Rationale**: `snapshot-tool-contract-unchanged` needs the roles and
states the legacy renderer prints; fixed vocabularies keep them from
carrying page text. This is beyond the spec's attribute list and needs the
owner's check.
**Approved**: pending

**Decision**: The string path returns `""` for unavailable and conflicting
privacy, where `BrowserAgentPrivacy.concealing` returns `"(concealed)"`.
**Rationale**: The plan's contract; an empty string carries nothing, and
those states already close the pane to tools.
**Approved**: pending

**Decision**: HTML mapping: landmark → `section` (or `nav`/`main`/`header`/
`footer` by role), heading → `h1`–`h6` by level, paragraph → `p`, list →
`ul`, list item → `li`, link → `a` with the sanitized `href`, button →
`button`, text field → `input` (disabled), text area → `textarea`
(disabled, holding its value), checkbox/radio → `input` of that type (disabled), select →
`select` (disabled), option → `option`, table/row/cell → `table`/`tr`/`td`,
label → `label`, image → `<span class="adk-image">[image: alt]</span>`,
text → escaped character data. One fixed stylesheet of the builder's own
in the head is allowed; no `style` attribute.
**Rationale**: Every element is one the builder chooses; controls are
disabled so the preview cannot submit anything.
**Approved**: pending

**Decision**: The old full-page walk in `BrowserSnapshot.js` is removed or
reduced to what non-agent callers still need; the snapshot tool no longer
uses it.
**Rationale**: Two walkers would be two routes from page to agent.
**Approved**: pending

**Decision**: Text rendering uses the main landmark when there is one,
else the whole page, so the text tool's description ("its main region,
else the whole body") stays true.
**Rationale**: `snapshot-tool-contract-unchanged`.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | pending | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | pending | Best Practices |
| [adc.check.best-practices.good-test-properties](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9144e220-ad70-51db-ba81-cdb0cc1b66c8) | pending | Best Practices |

Notes: design-first; every check is pending until the code exists. The
plan's tests are `AgentPageBuilderTests` (builder, pure),
`AgentPageWalkerWebViewTests` (an offscreen web view with fixed HTML) and
`AgentGatekeeperRoutingTests` (stub engine and privacy).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 0.1.0 | 2026-11-15 | Mike Fullerton | Initial creation (design-first, from the more privacy features design) |
