---
id: 8b187d98-795b-4a9d-9441-e7b8629fefe4
title: "Element Picker"
type: ingredient
version: 0.1.0
status: draft
language: en
created: 2026-11-15
modified: 2026-11-15
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Lets the user pick page items to hide: an address-bar button and popover listing a site's hidden items, a selecting mode whose script runs in its own isolated content world and computes This item / All items like it selectors with @medv/finder, and a movable confirm dialog with a live preview."
platforms:
  - swift
  - macos
tags:
  - browser
  - privacy
  - hidden-items
  - element-picker
  - selectors
  - content-world
  - popover
  - dialog
depends-on: []
related: []
references:
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserElementPicker.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserElementPicker.js (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/vendor/finder.js (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserSelectingMode.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserPickDialogController.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserHiddenItemsPopover.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserHiddenItemsStore.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/BrowserAddressBarControls.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/WebBrowserPaneViewController.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/WebKitBrowserEngine.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/BrowserElementPickerTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/BrowserElementPickerWebViewTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/BrowserSelectingModeTests.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# Element Picker

## Overview

This component is how the user picks page items to hide. It has four
parts that work as one:

1. **The address-bar button** sits at the trailing end of the address box
   on every site, with the tooltip "Hide distracting items". It opens a
   popover anchored to it.
2. **The popover** shows, for the site showing, a checkbox **Hide
   distracting items** bound to the site switch, a button **Select
   distracting items to hide**, a divider, and the site's list of hidden
   items: each row a checkbox that enables or disables the entry and the
   entry's label, under a header with a **−** button that removes the
   selected row.
3. **Selecting mode** starts from that button. The popover closes, the
   address-bar button turns into a stop icon ("Stop selecting"), and a
   picker script, run in its own isolated content world
   (`adk-element-picker`), outlines the element under the pointer and
   swallows the page's clicks. A click posts the element's candidate
   selectors to the `adkitchenPicker` message handler. The stop button or
   Esc ends the mode.
4. **The pick dialog** is a movable modal window, opened when a pick
   arrives, while selecting mode pauses:

   ```
   ( This item | All items like it )
   [ ] Show page with selected element removed
   Remove this from view?                 [Cancel] [OK]
   ```

   The checkbox hides the chosen scope's selector live through the
   rendering component's preview rule set. OK saves an entry; Cancel saves
   nothing; either way selecting mode resumes.

Selectors come from @medv/finder (MIT, vendored as one file). **This item**
is finder's shortest unique selector for the element. **All items like it**
is a looser selector built from the element's tag and its stable-looking
class names, with random-looking classes and ids rejected, together with
how many elements it matches; it is refused as a choice when it would match
too much of the page.

The picker serves both lists. This recipe describes it with the user list
("Hide distracting items"); the agent list's entry point and wording are
the hide-from-agent recipe's, and they reuse this component with the list
set to agent. The first time the picker is used, a one-time notice says
that items which load again, such as ads, can reappear.

## Behavioral Requirements

- **address-bar-button**: Every browser pane MUST show a button at the
  trailing end of the address box, on every site, with the tooltip "Hide
  distracting items" and the accessibility identifier `browser.hide-items`;
  clicking it while not selecting MUST open the hidden-items popover
  anchored to it.
- **popover-contents**: The popover MUST show, in order: a checkbox "Hide
  distracting items" bound to the user list's site switch for the page's
  default site pattern; a button "Select distracting items to hide"; a
  divider; and a table of the user list's items for the page, each row a
  checkbox showing and setting the entry's enabled state and the entry's
  label; with a header **−** button (tooltip "Remove Selected Item") that
  removes the selected row and is disabled when no row is selected.
- **popover-changes-apply-immediately**: Toggling the site checkbox or a
  row's checkbox, or removing a row, MUST write the change to the
  hidden-items store at once, so the page re-renders without a reload.
- **popover-transient**: The popover MUST close when the user clicks
  outside it.
- **select-enters-selecting-mode**: The popover's select button MUST close
  the popover and start selecting mode on that pane.
- **stop-icon-while-selecting**: While selecting, the address-bar button
  MUST show a stop icon with the tooltip "Stop selecting", and MUST show
  its normal icon and tooltip again when selecting ends.
- **stop-ends-selecting**: Clicking the stop button, or pressing Esc while
  selecting, MUST end selecting mode.
- **isolated-content-world**: The picker script and the vendored finder
  MUST run in a content world of their own named `adk-element-picker`,
  never the page's world or the automation world, so the page's scripts
  cannot see, call or replace them.
- **outline-under-pointer**: While selecting, the element under the
  pointer MUST be outlined, and the outline MUST follow the pointer.
- **page-clicks-swallowed**: While selecting, a click on the page MUST NOT
  reach the page: no link is followed, no button acts, no page handler
  runs for it.
- **pick-posts-candidates**: A click while selecting MUST post one message
  to the handler named `adkitchenPicker`, of kind `pick`, carrying the
  This item selector, the All items like it selector, the number of
  elements the looser selector matches, the number of elements on the
  page, the label, and the element's reference when it has one.
- **escape-posts-cancel**: Esc pressed in the page while selecting MUST post
  a message of kind `cancel`, which ends selecting mode as the stop button
  does.
- **this-item-unique**: The This item selector MUST match exactly one
  element in the page at pick time, the picked one.
- **all-like-it-stable-classes**: The All items like it selector MUST be
  built from the element's tag and class names only, MUST NOT use ids, and
  MUST NOT use any class name that looks generated: one containing three
  or more digits in a row, one made of six or more letters and digits
  only, one with a `-` or `_` followed by five or more hexadecimal
  characters, or one with a `-` or `_` followed by five or more letters and
  digits that mix both (a CSS-in-JS hash such as `css-1x2y3z`).
- **all-like-it-absent-when-same**: When the looser selector is the same as
  the This item selector (the same text, or it matches only the picked
  element), or cannot be computed, the pick MUST carry no All items like it
  selector.
- **pick-without-selector-refused**: A pick with no This item selector
  (finder failed or threw, for instance inside a shadow root, an SVG `use`
  or a frame) MUST be refused with a beep: no dialog opens and selecting
  mode continues.
- **loose-selector-disabled**: The All items like it choice MUST be
  disabled, with the tooltip "Matches too much of the page", when there is
  no looser selector or when it matches more than half of the page's
  elements.
- **label-format**: The label MUST be the element's lowercase tag name, a
  space, and the first 60 characters of its trimmed text in double quotes,
  where the text is the element's visible text, else its `alt`, else its
  `aria-label`; an element with none of them gets the tag name alone.
- **pick-pauses-and-opens-dialog**: An accepted pick MUST pause selecting
  mode (no outline, no further picks) and open the pick dialog for it.
- **dialog-movable-modal**: The pick dialog MUST be a modal window of its
  own that the user can drag off the page, not a sheet attached to the
  window.
- **dialog-default-scope**: The dialog MUST open with This item chosen.
- **dialog-preview-live**: The "Show page with selected element removed"
  checkbox MUST, while on, hide the currently chosen scope's selector on
  the live page through the preview rule set, MUST follow a change of
  scope at once, and MUST be cleared when the dialog closes, however it
  closes.
- **dialog-ok-saves**: OK MUST add one entry to the picker's list with the
  chosen scope's selector, that scope, the pick's label, enabled, and the
  site pattern derived from the page's address by the shared default rule.
- **dialog-cancel-saves-nothing**: Cancel, or Esc in the dialog, MUST save
  nothing.
- **resume-after-dialog**: After OK or Cancel, selecting mode MUST resume
  on the same page, so the user can pick another item.
- **navigation-ends-selecting**: A committed navigation, a tab switch, or
  closing the tab or pane while selecting or while the dialog is open MUST
  end selecting mode, close the dialog without saving, clear the preview
  rule set, and remove the picker's outline, listeners and message handler.
- **stop-cleans-up**: Ending selecting mode for any reason MUST remove the
  outline and the picker's listeners from the page, remove the
  `adkitchenPicker` handler, and clear the preview rule set, leaving the
  page as it was before selecting began apart from saved entries.
- **one-selecting-mode-per-pane**: Each pane MUST own at most one selecting
  mode at a time; starting it again while it runs MUST NOT install a
  second picker.
- **first-use-notice**: The first time selecting mode starts, the picker
  MUST show a one-time informational notice "Items that load again (such as
  ads) can reappear.", and MUST record that it was shown in the global
  setting `browser.hidden_items.notice_shown` so it never shows again.
- **list-parameter**: The popover, selecting mode and dialog MUST take the
  list they write to as a parameter, so the same component serves the user
  list and the agent list; with the user list they use the wording given
  here.
- **every-button-has-tooltip**: Every button this component adds (address
  bar button, popover select button, header −) MUST carry a tooltip.

## Appearance

- **Address-bar button**: a borderless symbol button inside the trailing
  end of the address box, symbol `eye.slash`; while selecting, `stop.circle`
  tinted with the system accent color.
- **Popover**: `.transient` behavior, anchored below the button; native
  checkbox, push button, separator, and a single-column table with a
  checkbox per row and the label in the row's text; a small `−` header
  button above the table. Sizes are the builder's.
- **Outline**: a 2-point outline in the system accent color drawn by the
  picker world around the element under the pointer, plus a faint fill;
  it is an overlay element owned by the picker, positioned over the
  target, never a style written onto the page's own element.
- **Dialog**: a small titled window with a segmented control (This item |
  All items like it), a checkbox, the question text, and Cancel / OK
  buttons with OK as the default button.

## States

| State | Button | Page | Dialog |
|-------|--------|------|--------|
| idle | `eye.slash`, "Hide distracting items" | as rendered | none |
| selecting | `stop.circle`, "Stop selecting" | outline follows pointer; clicks swallowed | none |
| dialog | `stop.circle`, "Stop selecting" | outline gone; picks paused; preview rule set as the checkbox says | open |

Transitions: idle → selecting (popover select button); selecting → dialog
(accepted pick); dialog → selecting (OK or Cancel); selecting or dialog →
idle (stop button, Esc while selecting, `cancel` message, navigation, tab
switch or close).

## Accessibility

- The address-bar button has the accessibility identifier
  `browser.hide-items`, and its accessibility label follows its tooltip
  ("Hide distracting items", or "Stop selecting" while selecting).
- The popover's controls are native controls with their visible titles as
  labels; each row's checkbox is labelled with the entry's label.
- Esc ends selecting mode without a pointer, and the dialog is fully
  usable from the keyboard (Return for OK, Esc for Cancel).
- Selecting an element itself needs a pointer; there is no keyboard
  traversal of page elements (a builder's choice, see Design Decisions).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| element-picker-001 | pick-posts-candidates | Decode `{"kind":"pick","thisItem":"#a","allLikeIt":"div.card","allLikeItCount":3,"pageElementCount":100,"label":"div \"Hi\"","ref":null}` | A candidate with every field set as given |
| element-picker-002 | pick-without-selector-refused | Deliver a `pick` with `thisItem` null | No dialog; the pick callback is not called; a beep; state stays selecting |
| element-picker-003 | loose-selector-disabled | Candidate with `allLikeItCount` 80 and `pageElementCount` 100 | All items like it disabled, tooltip "Matches too much of the page" |
| element-picker-004 | loose-selector-disabled | Candidate with `allLikeIt` null | All items like it disabled |
| element-picker-005 | all-like-it-stable-classes | In a webview, pick `<div class="css-1x2y3z ad-card">` among other divs | `allLikeIt` is `div.ad-card` |
| element-picker-006 | all-like-it-stable-classes | Pick `<span id="promo" class="a8f3k2q9 x_9f8e7d">` | `allLikeIt` uses neither the id nor either class (null, or `span` alone if it differs from This item) |
| element-picker-007 | this-item-unique | Pick any element in a fixture page | `document.querySelectorAll(thisItem).length` is 1 and is the picked element |
| element-picker-008 | isolated-content-world | Start the picker; a page-world script reads `window.__adkFinder` and the picker's globals | All `undefined` |
| element-picker-009 | page-clicks-swallowed | Selecting; click a link and a button with an `onclick` | No navigation; the page handler does not run; one `pick` message |
| element-picker-010 | label-format | Pick `<div>   Sponsored stories about … (100 chars) </div>`; pick `<img alt="Logo">`; pick an empty `<hr>` | `div "Sponsored stories about …"` cut at 60 characters; `img "Logo"`; `hr` |
| element-picker-011 | stop-icon-while-selecting, select-enters-selecting-mode | Press the popover's select button | Popover closed; button symbol `stop.circle`, tooltip "Stop selecting" |
| element-picker-012 | stop-ends-selecting, escape-posts-cancel | Selecting; press Esc | State idle; button `eye.slash`, "Hide distracting items" |
| element-picker-013 | pick-pauses-and-opens-dialog, dialog-default-scope | Selecting; accepted pick | State dialog; This item chosen |
| element-picker-014 | dialog-ok-saves | On `https://example.com/a`, OK with This item `#x`, label `div "Ad"` | Store has one user entry: site `example.com/*`, selector `#x`, scope this item, label `div "Ad"`, enabled |
| element-picker-015 | dialog-cancel-saves-nothing, resume-after-dialog | Cancel the dialog | Store unchanged; state selecting |
| element-picker-016 | dialog-preview-live | Check the preview box with This item `#x`, switch to All items like it `div.ad`, then OK | Preview rule set `["#x"]`, then `["div.ad"]`, then none; the saved entry is `div.ad` |
| element-picker-017 | navigation-ends-selecting, stop-cleans-up | Open the dialog with the preview on; the pane commits a navigation | Dialog closed; nothing saved; state idle; preview rule set none; handler removed |
| element-picker-018 | popover-contents, popover-changes-apply-immediately | Two user entries on `example.com/*`; open the popover; uncheck one row | Two rows with labels; the store entry is disabled; the page shows that item again |
| element-picker-019 | popover-contents | Open the popover with no row selected; select a row; press − | − disabled, then enabled; the entry is removed |
| element-picker-020 | first-use-notice | Start selecting mode for the first time, end it, start it again | The notice once; `browser.hidden_items.notice_shown` true; no notice the second time |
| element-picker-021 | one-selecting-mode-per-pane | Start selecting twice on one pane | One picker installed; one message per click |
| element-picker-022 | list-parameter | Run the dialog with the agent list | OK writes an agent-list entry, not a user-list one |
| element-picker-023 | address-bar-button, every-button-has-tooltip | Open a pane on any site; read the address box's trailing button, then open the popover | Button id `browser.hide-items`, tooltip "Hide distracting items", opens the popover; the select button and − carry tooltips |
| element-picker-024 | popover-transient | Open the popover; click on the page | The popover closes |
| element-picker-025 | outline-under-pointer | Selecting; move the pointer from one element to another | The outline covers the first element, then the second |
| element-picker-026 | all-like-it-absent-when-same | Pick `<div class="only">`, the page's only element with that class and tag | `allLikeIt` is null |
| element-picker-027 | dialog-movable-modal | Open the dialog; drag its title bar | The dialog is its own window (not a sheet) and moves; the browser window stays put |

## Edge Cases

- **Null and empty input**: A pick with no This item selector is refused
  (MUST, see `pick-without-selector-refused`). A page with no address
  saves entries with site `*`, as the shared default rule says. An empty
  list shows the popover with an empty table.
- **Boundary values**: An All items like it selector matching exactly half
  of the page's elements is allowed; one more is not (MUST, see
  `loose-selector-disabled`). A selector that matches `body` or `html`
  counts every element and is therefore refused. A label is cut at 60
  characters.
- **Concurrent access**: The page may change between the click and OK;
  the selectors saved are those computed at click time. Two panes may
  each run selecting mode; they share the store, and each pane's popover
  shows the store's current list.
- **Error states**: If the picker script fails to install (the page went
  away, or WebKit refuses the evaluation), selecting mode does not start,
  the button stays in its idle state, and the failure is logged. Finder
  throwing for one element refuses that pick only.
- **Offline or disconnected state**: Not applicable — the picker works on
  the page in memory and a local store.
- **Missing file or unreachable server**: Not applicable — the store's
  concern.
- **Cancellation and timeouts**: Every exit path (stop, Esc, `cancel`,
  navigation, tab switch, close) goes through one end routine that
  removes the outline, listeners and handler and clears the preview (MUST,
  see `stop-cleans-up`).
- **Frames and shadow roots**: The picker runs in the main frame. An
  element inside a cross-origin frame cannot be reached; clicking the frame
  picks the frame element itself. An element inside a shadow root may get
  no unique document selector and is then refused.
- **Pages that re-render**: An item the page rebuilds under new class
  names may escape its selector and reappear; that is what the first-use
  notice warns of.

## Configuration

- `browser.hidden_items.notice_shown` (`UserSettings.browserHiddenItemsNoticeShown`,
  global only, default false): whether the first-use notice has been shown.

## Deep Linking

Not applicable: this component defines no URL scheme, route, or navigable
destination.

## Localization

User-facing strings: "Hide distracting items", "Select distracting items
to hide", "Remove Selected Item", "Stop selecting", "This item", "All
items like it", "Show page with selected element removed", "Remove this
from view?", "Matches too much of the page", "Cancel", "OK", "Items that
load again (such as ads) can reappear.". All go through the app's
localized-string mechanism. Labels are page text and are shown as they
are.

## Accessibility Options

- **Reduce Motion**: the outline moves without animation.
- **Increase Contrast**: the outline uses a heavier stroke and no fill.

## Feature Flags

Not applicable: this component contains no feature-flag or remote-config
check.

## Analytics

Not applicable: this component emits no analytics or telemetry event.

## Privacy

- **Data collected**: a selector and a label of at most 60 characters of
  the picked element's text, stored locally in the hidden-items store; the
  label can hold page text and is never sent anywhere.
- **Exposure to the page**: none from the picker. Its script, finder and
  outline live in the `adk-element-picker` world (MUST, see
  `isolated-content-world`); the page cannot read the picks. The page can
  observe that its clicks stop arriving while selecting.
- **Agent exposure**: none; the picker sends nothing to any agent.

## Logging

Selecting mode logs start, end (with the reason: stop, Esc, navigation,
tab switch, close) and refused picks, with the page's host. Selectors and
labels are not logged.

## Platform Notes

- **SwiftUI**: Not applicable as a home; the popover and dialog are AppKit,
  matching the address bar they belong to.
- **AppKit / UIKit**: Built as follows, all under
  `macOS/Features/BrowserPane/HiddenItems/`:
  - `BrowserElementPicker` (`@MainActor final class`, `NSObject`,
    `WKScriptMessageHandler`) with `contentWorldName = "adk-element-picker"`,
    `messageHandlerName = "adkitchenPicker"`,
    `init(webView:list:onPick:onCancel:)`, `start() async throws`,
    `pause()`, `resume()`, `stop()`. `start` adds the handler for
    `WKContentWorld.world(name:)` and evaluates `vendor/finder.js` (exposed
    as `__adkFinder`) and `BrowserElementPicker.js` in that world; both are
    bundled resources, as `BrowserSnapshot.js` is.
  - `BrowserPickCandidate` (`Decodable`, `Sendable`) with `kind`,
    `thisItem`, `allLikeIt`, `allLikeItCount`, `pageElementCount`, `label`,
    `ref`, and `allLikeItAllowed` (`allLikeIt != nil &&
    allLikeItCount <= pageElementCount / 2`).
  - `BrowserSelectingMode` (`@MainActor final class`) with
    `State { idle, selecting, dialog(BrowserPickCandidate) }`,
    `init(engine:store:list:button:settings:presentDialog:presentNotice:)`
    (`button` is the address box's `BrowserHideItemsButton`, which keeps
    the symbol it shows; the presenters default to the real dialog and
    notice and are injected by tests), `begin()`, `end(_ reason:)` (the
    reason is what the log names); a local key monitor catches Esc while
    selecting, in the pane's window only. `WebBrowserPaneViewController`
    owns one, made for a WebKit engine on first use (any other engine
    beeps), and ends it on navigation commit, tab switch, tab close, engine
    replacement or rebuild, and pane discard.
  - `BrowserPickDialogController`: an `NSWindow` run with
    `NSApp.runModal(for:)`. The preview is applied with
    `WebKitBrowserEngine.setPreviewHiddenSelectors(_:)` before the modal
    loop and from the checkbox action inside it; WebKit keeps running in
    the modal panel run-loop mode. OK and Cancel end the loop with
    `stopModal`; selecting mode ending under the dialog (navigation, say)
    arrives in a WebKit callback, where only `abortModal` works, and saves
    nothing. The dialog runs on the run loop's next pass
    (`performOnNextRunLoopPass`, a `CFRunLoopPerformBlock`), out of the
    script-message callback the pick arrived in; never from
    `DispatchQueue.main.async`, whose block the modal loop would hold, and
    with it every MainActor task. Each picker start waits for the previous
    one; a mode ended before its start runs installs nothing, one ended
    during it stops the picker afterwards, and `start()` re-checks
    `isRunning` after each evaluation.
  - `BrowserHiddenItemsPopover(list:store:url:onSelect:)`, an `NSPopover`
    with `.transient` behavior; the trailing button is added to
    `BrowserAddressBox` in `BrowserAddressBarControls.swift`.
  - `BrowserHiddenItemsPopover` is the `NSViewController` that owns its
    `NSPopover`; it reads and writes the store through `perform` and
    reloads on `didChangeNotification`.
  - The notice is an informational `NSAlert`, run as a sheet on the pane's
    window; `browser.hidden_items.notice_shown` is written to the global
    layer before it shows.
- **Compose**: An Android `WebView` has no named content worlds; inject the
  picker with `evaluateJavascript` under a random global name and post
  through `WebMessageListener`, accepting that the page shares the world.
- **React/Web**: As a browser extension, the picker is a content script
  (its own isolated world) messaging the extension's background; the
  dialog is a draggable in-page overlay inside a closed shadow root.
- **WinUI 3**: WebView2 runs scripts in the page's world unless an
  extension is used; post picks with `chrome.webview.postMessage`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserElementPicker.swift` | planned |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserElementPicker.js` | planned |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/vendor/finder.js` | planned |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserSelectingMode.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserPickDialogController.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserHiddenItemsPopover.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/BrowserSelectingModeTests.swift` | unverified |

## Design Decisions

**Decision**: our own injected script with @medv/finder, not WebKit's
targeted-element API.
**Rationale**: Safari's Distraction Control uses `_WKTargetedElementInfo`
and `adjustVisibility`, which are private API and would be rejected from
the Mac App Store; they also only hide visually, and the agent list needs
selectors of our own anyway. Finder is MIT, about 1.5 kB, and gives the
shortest unique selector with pluggable filters.
**Approved**: pending

**Decision**: two scopes, This item and All items like it, with no
specificity slider.
**Rationale**: Arc's "Zap this" / "Zap all related" model is
understandable without knowing CSS; uBlock's depth and specificity sliders
are too technical, and This item alone is fragile and tedious.
**Approved**: pending

**Decision**: a pick applies site-wide, under the page's host pattern.
**Rationale**: Safari and uBlock both save per host; the same distraction
appears on every page of a site.
**Approved**: pending

**Decision**: the picker runs in its own content world, not the automation
world.
**Rationale**: The page must not see or interfere with the picker, and the
automation world belongs to the agent's tools; a world per purpose keeps
either from breaking the other (`separation-of-concerns`).
**Approved**: pending

**Decision**: the dialog is a movable modal window, not a sheet.
**Rationale**: A sheet covers the top of the page, which is often where the
picked item is; uBlock's dialog is draggable for the same reason.
**Approved**: pending

**Decision**: the looser selector is refused above half of the page's
elements.
**Rationale**: A selector like `div` would blank the page; half is a simple
cut that never refuses a real "items like it" (cards, ads, rows) on a page
of any size.
**Approved**: pending

**Decision**: no keyboard traversal for choosing an element.
**Rationale**: Builder's choice. Every prior picker is pointer-driven; the
saved entries are fully manageable from the keyboard in the popover.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|

Notes: no compliance checks have been run; the code does not exist yet.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 0.1.0 | 2026-11-15 | Mike Fullerton | Initial creation (design-first, from the more privacy features design) |
