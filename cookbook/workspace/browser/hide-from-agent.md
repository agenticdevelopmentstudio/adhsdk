---
id: 6cb13be9-e38c-496b-8326-5d1fdccfe778
title: "Hide From Agent"
type: ingredient
version: 0.1.7
status: draft
language: en
created: 2026-11-15
modified: 2026-11-23
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A privacy-toolbar button whose menu enters the element picker's selecting mode on the agent list, on the live page or in the Agent preview (where a pick maps a node's ref back to its recorded selector), and opens a popover listing and toggling the site's agent-list entries."
platforms:
  - swift
  - macos
tags:
  - browser
  - privacy
  - hidden-items
  - agent
  - element-picker
depends-on: []
related: []
references:
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserHideFromAgentButton.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserSelectingMode.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserElementPicker.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserPickDialogController.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserHiddenItemsPopover.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Database/Daemon/Browser/BrowserHiddenItemsStore.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/AgentViews/BrowserAgentPreviewViewController.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/AgentPage/AgentPage.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/WebBrowserPaneViewController.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/BrowserHideFromAgentTests.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# Hide From Agent

## Overview

This component lets the user hide parts of a page from the agent alone. It
is the agent list's entry point to the element picker, and adds nothing to
the picker but where it starts, which list it writes, and how a pick is
read in the Agent preview.

A button in the privacy toolbar, **Hide elements from agent**, opens a menu
of two items:

- **Select Items to Hide from the Agent** enters the element picker's
  selecting mode with the list set to agent. The pick dialog asks "Hide
  this from the agent?"; OK adds an agent-list entry.
- **Hidden from the Agent…** opens the element picker's popover for the
  agent list, which lists the site's agent-list entries to toggle and
  remove. It has no site switch: the agent list is always in force.

Selecting works in two of the pane's views:

- **Website**: the picker runs on the live page exactly as for the user
  list.
- **Agent preview**: the picker runs in the preview webview, in the same
  `adk-element-picker` isolated world. The preview's HTML is built by the
  agent gatekeeper and carries each node's ref as `data-adk-ref`; a pick
  there reads that ref and saves the selector the gatekeeper recorded for
  the ref when it built the page, never a selector computed against the
  preview's own markup. A pick on an element with no ref is refused.

An agent-list entry changes only what the agent receives: the gatekeeper
does not visit nodes matching enabled agent-list entries for the site, so
they are absent from every page-reading tool and from both agent views.
The user still sees the item on the page.

The preview keeps page JavaScript off. The picker world must still run
there; whether WebKit runs isolated-world scripts with content JavaScript
disabled is checked in the verification run and recorded below.

Hide from Agent is the last button in the privacy toolbar's Agents group, styled like the group's items: "Hide from Agent ▾", and "Hide from Agent: Selecting" in green while its selecting mode runs.

Right-clicking a page adds, below WebKit's items: Hide Distracting Item (live page only), Hide Item from Agents (live page and Agent preview, while the agent can see the browser), and on text Replace Private Word…, which opens the Secrets window on that word's row, made if it has none, once the window is unlocked, or brings the open window forward with it (`BrowserMenuWebView`, `WebBrowserPaneViewController+ContextMenu`).

## Behavioral Requirements

- **toolbar-button**: The privacy toolbar MUST show a button with the
  symbol `person.crop.circle.badge.xmark`, the tooltip "Hide elements from
  agent" and the accessibility identifier `browser.hide-from-agent`.
- **button-menu**: Clicking the button MUST show a menu with exactly two
  items, "Select Items to Hide from the Agent" and "Hidden from the
  Agent…", in that order.
- **select-writes-agent-list**: "Select Items to Hide from the Agent" MUST
  start the element picker's selecting mode with the list set to agent, so
  every entry it saves is an agent-list entry and none is a user-list
  entry.
- **agent-dialog-wording**: The pick dialog started from this button MUST
  ask "Hide this from the agent?"; its scopes, preview checkbox and buttons
  MUST be the element picker's.
- **list-popover**: "Hidden from the Agent…" MUST open the element picker's
  popover for the agent list, anchored to the button, listing the site's
  agent-list entries with their enabled checkboxes and the − remove
  button, and with no site switch checkbox.
- **popover-toggle**: A click on the toolbar button while its "Hidden from
  the Agent…" popover is open MUST close the popover and show neither the
  menu nor the popover again; the element picker's address-bar button
  behaves the same for its own popover.
- **popover-select-wording**: The agent popover's select button MUST read
  "Select items to hide from the agent" and start the same selecting mode
  as the menu item.
- **one-selecting-mode**: A pane MUST run at most one selecting mode across
  both lists; starting agent selecting while user selecting runs (or the
  reverse) MUST end the running one first.
- **stop-while-selecting**: While agent selecting runs, the toolbar button
  MUST act as its stop control (tooltip "Stop selecting"), and Esc MUST end
  it, as for the user list.
- **website-mode-live-page**: In the Website view, the picker MUST run on
  the live page and save the selector the picker computes there.
- **preview-mode-in-preview**: In the Agent preview view, the picker MUST
  run in the preview webview's `adk-element-picker` world, not on the live
  page.
- **preview-pick-maps-ref**: A pick in the Agent preview MUST read the
  clicked element's `data-adk-ref` (or that of its nearest ancestor that has
  one) and save the selector recorded for that ref in the agent page the
  preview is showing, with that node's label.
- **preview-pick-saves-under-live-site**: A pick in the Agent preview MUST
  save its entry under the live page's site, never under the address the
  agent page carries, which is concealed and may be a stand-in host.
- **preview-pick-without-ref-refused**: A pick in the Agent preview on an
  element with no ref, or whose ref has no node in the shown agent page,
  MUST be refused with a beep; no dialog opens and selecting continues.
- **preview-page-js-stays-off**: Selecting in the Agent preview MUST NOT
  turn on page JavaScript in the preview; only the picker world may run.
- **preview-loads-stay-blocked**: Selecting in the Agent preview MUST NOT
  lift the preview's block on network loads.
- **preview-dialog-preview**: In the Agent preview, the dialog's "Show page
  with selected element removed" MUST hide the chosen node in the preview
  webview, not on the live page.
- **ok-removes-from-agent**: After OK, the gatekeeper's next build of the
  page MUST omit the nodes the new entry matches, and an open Agent
  preview or Agent source view MUST refresh and no longer show them.
- **user-view-unaffected**: An agent-list entry MUST NOT hide anything from
  the user: the live page MUST carry no `__adk_hidden_items` rule for it.
- **disabled-entry-not-applied**: An agent-list entry the user unchecks in
  the popover MUST stop being applied by the gatekeeper at its next build,
  and the agent views MUST refresh to show the node again.
- **raw-tools-refused-with-entries**: While the site has enabled agent-list
  entries, the raw-page tools (`browser_screenshot`, `browser_click_at`,
  `browser_evaluate`) MUST be refused for that site's pages, as the
  gatekeeper's rules require; this component's entries are what trigger
  that.
- **navigation-ends-selecting**: A committed navigation, a switch between
  Website and Agent preview, a tab switch, or closing the tab or pane MUST
  end agent selecting and close the dialog without saving.
- **hostless-page-disabled**: On a page with no host (`file:`, `about:`,
  `data:`, or no address) the toolbar button MUST be disabled, keeping its
  tooltip, except as the stop control while agent selecting runs, and
  starting agent selecting there MUST beep and start nothing, since an
  entry there could only be saved for every site.
- **popover-closes-with-page**: The "Hidden from the Agent…" popover MUST
  close on a committed navigation, a front-page change, a tab switch and
  pane discard, as the element picker's popover does.
- **every-button-has-tooltip**: The toolbar button MUST carry a tooltip.

## Appearance

- **Toolbar button**: a symbol button in the privacy toolbar beside the
  agent view control, symbol `person.crop.circle.badge.xmark`; while agent
  selecting runs, `stop.circle` tinted with the system accent color.
- **Menu**: a standard `NSMenu` popped up from the button.
- **Popover and dialog**: the element picker's, with the agent wording.

## States

| State | Button | Where the picker runs |
|-------|--------|-----------------------|
| idle | `person.crop.circle.badge.xmark`, "Hide elements from agent" | nowhere |
| selecting (Website) | `stop.circle`, "Stop selecting" | live page, `adk-element-picker` world |
| selecting (Agent preview) | `stop.circle`, "Stop selecting" | preview webview, `adk-element-picker` world |
| dialog | `stop.circle`, "Stop selecting" | paused |

Transitions are the element picker's; switching the pane's view while
selecting returns to idle.

## Accessibility

- The toolbar button has the accessibility identifier
  `browser.hide-from-agent`, and its accessibility label follows its
  tooltip.
- The menu, popover and dialog are native controls and fully usable from
  the keyboard; Esc ends selecting.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hide-from-agent-001 | toolbar-button, button-menu | Show a pane's privacy toolbar; click the button | Tooltip "Hide elements from agent", id `browser.hide-from-agent`; a menu with "Select Items to Hide from the Agent" and "Hidden from the Agent…" |
| hide-from-agent-002 | select-writes-agent-list, agent-dialog-wording, website-mode-live-page | Website view on `https://example.com/`; choose Select…; pick `#secret`; OK | Dialog asked "Hide this from the agent?"; the store has an agent entry `#secret` on `example.com/*` and no user entry |
| hide-from-agent-003 | preview-pick-maps-ref, preview-mode-in-preview | Agent preview of a page whose agent page records ref `r12` with selector `main > p.note`; pick the preview element with `data-adk-ref="r12"`; OK | The saved agent entry's selector equals `page.node(ref: "r12")!.selector`, `main > p.note` |
| hide-from-agent-004 | preview-pick-maps-ref | Same preview; pick a `<b>` without a ref inside the `r12` element | The entry is saved with `r12`'s selector |
| hide-from-agent-005 | preview-pick-without-ref-refused | Pick a preview element with no ref and no ref'd ancestor; then one with ref `r999` absent from the page | Both refused with a beep; no dialog; selecting continues |
| hide-from-agent-006 | ok-removes-from-agent | After vector 003, read the preview HTML, the Agent source and `browser_snapshot` | None contains the `r12` node or its text |
| hide-from-agent-007 | user-view-unaffected | After vector 002, read the live page | No `__adk_hidden_items` rule for `#secret`; `#secret` is displayed |
| hide-from-agent-008 | list-popover, popover-select-wording | Choose "Hidden from the Agent…" with two agent entries on the site | A popover of two rows with checkboxes and −; no site switch; select button "Select items to hide from the agent" |
| hide-from-agent-009 | disabled-entry-not-applied | Uncheck the `#secret` row | The next snapshot and the refreshed preview include `#secret`'s content |
| hide-from-agent-010 | preview-page-js-stays-off, preview-loads-stay-blocked | Agent selecting in the preview of a page with an inline script and a remote image | The page script does not run; no network load is made; the picker works |
| hide-from-agent-011 | one-selecting-mode | Start user selecting from the address bar, then agent selecting from the toolbar | The user mode ends; only the agent picker is installed |
| hide-from-agent-012 | navigation-ends-selecting | Agent selecting with the dialog open; switch the view from Agent preview to Website | Dialog closed; nothing saved; idle |
| hide-from-agent-013 | raw-tools-refused-with-entries | After vector 002, call `browser_screenshot` on the page | Refused, naming the site's agent-list entries as the reason |
| hide-from-agent-014 | stop-while-selecting, every-button-has-tooltip | Start agent selecting; read the toolbar button; press Esc | Symbol `stop.circle`, tooltip "Stop selecting"; after Esc, idle with tooltip "Hide elements from agent" |
| hide-from-agent-015 | preview-dialog-preview | Agent preview; pick ref `r12`; check "Show page with selected element removed" | The `r12` node is hidden in the preview webview; the live page is unchanged |
| hide-from-agent-016 | preview-pick-saves-under-live-site | Agent preview of `https://example.com/a` with URL concealing on; pick ref `r12`; OK | The new agent-list entry's site is `example.com`, not the concealed stand-in host |
| hide-from-agent-017 | hostless-page-disabled | Open a `file:` page in a pane; read the toolbar button; then open `https://example.com/` | Disabled with tooltip "Hide elements from agent" on the `file:` page; enabled on the site |
| hide-from-agent-018 | popover-closes-with-page | Open "Hidden from the Agent…"; navigate the pane | The popover closes |

## Edge Cases

- **Null and empty input**: A preview pick with no ref is refused (MUST,
  see `preview-pick-without-ref-refused`). An empty agent page (the
  gatekeeper failed closed) has no refs, so every pick in its preview is
  refused; the user can pick in the Website view instead.
- **Boundary values**: A ref whose recorded selector is empty cannot be
  saved and is refused like a missing ref. A click on blank space in the
  preview lands on the document root, whose ref the preview puts on
  `<body>`; that pick is refused too, since saving it would hide the whole
  page from the agent. In the Website view a pick of the page's root, or
  a recorded selector that names only `html`/`body`, is refused the same
  way (element picker's `this-item-not-root`). The "All items like it" scope in
  the preview uses the looser selector the gatekeeper recorded for the ref
  if it recorded one, and is disabled otherwise. The gatekeeper records no
  looser selector today, so in the preview it is always disabled.
- **Pages with no host**: On a `file:`, `about:` or `data:` page the
  button is disabled with its tooltip kept, and nothing is saved, since an
  entry's site would be `*` and hide the item from the agent everywhere
  (MUST, see `hostless-page-disabled`).
- **Agent source view**: The source view is text, with no elements to
  pick; "Select Items to Hide from the Agent" there beeps and starts
  nothing.
- **Concurrent access**: The preview may be rebuilt (navigation, setting
  change) between the click and OK; the selector saved is the one recorded
  in the agent page that was showing at click time.
- **Error states**: If the picker world cannot run in the preview (see the
  Design Decisions finding), selecting in the preview reports it with a
  beep and a logged reason, and selecting in the Website view still works.
  A picker that fails to start in either view beeps and ends selecting.
  Selecting distracting items for the user's own list starts only in the
  Website view; under an agent view it beeps and starts nothing.
- **Offline or disconnected state**: Not applicable — the preview loads
  nothing from the network by design, and the store is local.
- **Missing file or unreachable server**: Not applicable — the store's
  concern.
- **Cancellation and timeouts**: The element picker's single end routine
  applies.
- **Content the user also hid**: A node in the user list is not displayed,
  so the gatekeeper already omits it and it has no ref in the preview;
  there is nothing to pick.

## Configuration

Not applicable: this component has no options of its own. The agent list
lives in the hidden-items store, and the first-use notice setting is the
element picker's.

## Deep Linking

Not applicable: this component defines no URL scheme, route, or navigable
destination.

## Localization

User-facing strings: "Hide elements from agent", "Select Items to Hide
from the Agent", "Hidden from the Agent…", "Select items to hide from the
agent", "Hide this from the agent?", "Stop selecting". All go through the
app's localized-string mechanism.

## Accessibility Options

Not applicable: this component reads no accessibility display setting
beyond the element picker's.

## Feature Flags

Not applicable: this component contains no feature-flag or remote-config
check.

## Analytics

Not applicable: this component emits no analytics or telemetry event.

## Privacy

- **Data collected**: agent-list entries (selector and a label of page
  text), stored locally; nothing is sent anywhere.
- **Agent exposure**: the purpose of the component. Content matching an
  enabled agent-list entry never reaches the agent (MUST, see
  `ok-removes-from-agent`), and its presence also refuses the raw-page
  tools for the site (MUST, see `raw-tools-refused-with-entries`).
- **Preview safety**: picking in the preview never enables page scripts or
  network loads (MUST, see `preview-page-js-stays-off`,
  `preview-loads-stay-blocked`), so the preview still shows only what the
  gatekeeper put in.

## Logging

Agent selecting logs start, end (with the reason) and refused picks with
the page's host and the view (Website or Agent preview). Selectors, refs'
content and labels are not logged.

## Platform Notes

- **SwiftUI**: Not applicable — AppKit, like the privacy toolbar it sits
  in.
- **AppKit / UIKit**: `BrowserHideFromAgentButton` in
  `macOS/Features/BrowserPane/HiddenItems/BrowserHideFromAgentButton.swift`
  is the address box's `BrowserHideItemsButton` with the agent's symbol,
  tooltip and identifier; `WebBrowserPaneViewController` puts it in the
  privacy strip's row before the Agent view control. Its menu starts the
  pane's one `BrowserSelectingMode` with `list: .agent` (and, in the Agent
  preview, `preview:` the `BrowserAgentPreviewViewController`, through the
  `BrowserAgentPickSurface` protocol), or shows
  `BrowserHiddenItemsPopover(list: .agent, …)`. A preview pick's `ref` is
  resolved against the preview's `shownPage` with `AgentPage.node(ref:)`
  and the entry takes `AgentNode.selector`
  (`BrowserSelectingMode.mapPreviewPick`); the entry's site comes from
  the engine's URL, not `AgentPage.url`, which is the concealed address
  (a commit ends selecting, so the engine's URL is the page the preview was
  built from). The dialog's preview hides
  `[data-adk-ref="…"]` with the element picker's preview style, evaluated
  in the picker world. The preview keeps
  `WKWebpagePreferences.allowsContentJavaScript = false`; the picker is
  installed with `evaluateJavaScript(_:in:in:)` in its world, and because
  `loadHTMLString` replaces the document on every rebuild, the preview's
  `onPageLoad` (its `didFinish`) installs it again. The popover toggle: a
  transient `NSPopover` closes on the mouse-down, before the button's
  action runs, so `popoverWillClose` records the event number of the
  mouse-down on its anchor that closed it (`noteClosing(by:)`), and
  `closesOnAnchorClick(_:)` treats only the mouse-up carrying that same
  event number as the toggle; any other click clears the record and opens
  the popover.
- **Compose**: An Android `WebView` cannot run one script with page
  JavaScript off; render the preview natively from the agent page instead
  and pick nodes by their ref directly.
- **React/Web**: Render the preview in a sandboxed iframe without
  `allow-scripts`, with the picker in the parent document reading
  `data-adk-ref` through the iframe's DOM.
- **WinUI 3**: WebView2 with `IsScriptEnabled = false` blocks every
  script; as with Compose, pick from a native rendering of the agent page.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/BrowserAddressBarControls.swift` | confirmed (0.1.6) |
| macos | `packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/BrowserHideFromAgentTests.swift` | confirmed (0.1.6) |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserHideFromAgentButton.swift` | confirmed (0.1.6) |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/BrowserMenuWebView.swift` | confirmed (0.1.6) |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/WebBrowserPaneViewController+ContextMenu.swift` | confirmed (0.1.6) |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/BrowserWebView.swift` | confirmed (0.1.6) |

## Design Decisions

**Decision**: the agent list reuses the element picker whole, with the list
as a parameter.
**Rationale**: One picker, popover and dialog for both lists keeps their
behavior identical and fixes once (`dry`); only the entry point, list and
wording differ.
**Approved**: pending

**Decision**: a preview pick saves the selector the gatekeeper recorded for
the node's ref, not one computed in the preview.
**Rationale**: The preview's markup is the gatekeeper's own construction,
not the page's; a selector computed against it would not match the live
DOM the gatekeeper walks. The ref ties the preview node to the live
element the walker saw.
**Approved**: pending

**Decision**: the agent popover has no site switch.
**Rationale**: Turning the whole agent list off for a site would be a
one-click leak; entries are disabled one at a time, deliberately.
**Approved**: pending

**Decision**: the picker world runs in the preview while page JavaScript
stays off.
**Rationale**: The preview must show only what the gatekeeper put in, so
page scripts stay off; the picker lives in its own world and needs none of
them. WebKit documents `allowsContentJavaScript` as turning off the
page's own scripts only, leaving scripts the app evaluates in a content
world running, so the implementation installs the picker with
`evaluateJavaScript(_:in:in:)` and leaves the preference off. Finding (to
be recorded from the verification run): whether the picker does run in the
preview with page JavaScript off. If it does not, the preview enables only
the picker world, never page scripts.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|

Notes: no compliance checks have been run.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 0.1.7 | 2026-11-23 | Mike Fullerton | The hidden-items store moved to the database tier (Database/Daemon/Browser). |
| 0.1.6 | 2026-11-18 | Mike Fullerton | Replace Private Word… opens the Secrets window on the word. |
| 0.1.5 | 2026-11-18 | Mike Fullerton | Context menu: Hide Distracting Item, Hide Item from Agents, Replace Private Word. |
| 0.1.4 | 2026-11-18 | Mike Fullerton | Hide from Agent sits in the privacy toolbar's Agents group, styled like its items. |
| 0.1.3 | 2026-11-16 | Mike Fullerton | Review fix: a body or html entry withholds the whole page. |
| 0.1.2 | 2026-11-16 | Mike Fullerton | Button disabled on hostless pages with its tooltip kept; popover closes with the page. |
| 0.1.1 | 2026-11-16 | Mike Fullerton | A preview pick saves under the live page's site, never the concealed AgentPage address. |
| 0.1.0 | 2026-11-15 | Mike Fullerton | Initial creation (design-first, from the more privacy features design) |
