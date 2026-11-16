---
id: 497f5d5f-e95b-473e-8798-cbe62ebcc425
title: "History Panel and Window"
type: ingredient
version: 0.1.2
status: draft
language: en
created: 2026-11-15
modified: 2026-11-16
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A reusable browser History panel (a filter field over a list of visits, with remove, clear-all and open) on a list model that shows recent visits or searches them, and the standalone History window that hosts it in a projects-window-shaped shelf."
platforms:
  - swift
  - macos
tags:
  - browser
  - history
  - privacy
  - filter
  - search
  - window
depends-on: []
related: []
references:
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/History/BrowserHistoryListModel.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/History/BrowserHistoryPanelViewController.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/History/BrowserHistoryWindowController.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/BrowserHistoryStore.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/WebBrowserWindowsFeature.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/WebBrowserPaneViewController.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/BrowserHistoryListModelTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/BrowserHistoryRecordingTests.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# History Panel and Window

## Overview

This component is how a user sees and prunes the pages the browser has
remembered. It has three parts, layered so the lower ones know nothing of
the higher ones. The **list model** sits on the browser's history store and
holds the visits currently listed: with an empty filter it lists the most
recent visits, newest first; with a filter it lists the visits whose title
or address contains the trimmed filter text; when the filter changes faster
than the store answers, only the latest filter's answer is ever shown. It
also removes chosen visits and clears all history. The **History panel** is
a reusable view over one list model: a filter field above a list styled
like the Settings sidebar, each row showing a visit's title, address and
when it happened, a remove button for the selected visits, a Clear History
button that asks first, and opening a visit by double-click or Return
through a callback its host supplies. The panel knows nothing of the window
that hosts it, so any host (a window, a shelf, a popover) can embed it. The
**History window** is one such host: a single window with a fixed
identifier, shaped like the projects window — a shelf with a bar of panel
buttons across its top holding one button, History, and the panel beneath
— opened from the Browser menu's Show History command, which opens a
chosen visit in a browser. Visits reach the store only through the
browser's recording gate, which records nothing while a pane is in private
browsing, so private browsing never appears here.

## Behavioral Requirements

- **empty-filter-lists-recent**: The list model MUST, when its filter is
  empty, list the store's most recent visits, newest first.
- **filter-searches-title-and-address**: The list model MUST, when its
  filter is not empty, list exactly the visits whose title or address
  contains the filter text, newest first.
- **filter-is-trimmed**: The list model MUST trim leading and trailing
  whitespace from the filter before using it, so a filter with surrounding
  spaces lists the same visits as the bare text, and a filter of only
  whitespace lists recent visits as an empty filter does.
- **list-is-bounded-by-page-size**: The list model MUST list at most its
  page size of visits for both recent and filtered results; the page size
  defaults to 200 and is set when the model is created.
- **latest-filter-wins**: The list model MUST coalesce reloads so that when
  the filter changes again before an earlier reload has answered, the
  visits it ends up listing are those for the latest filter, and an earlier
  filter's answer MUST NOT replace a later one's.
- **remove-deletes-from-store**: The list model MUST, when asked to remove
  a set of visits, delete each of them from the store and then reload, so
  the removed visits are gone from both the store and the list.
- **clear-all-empties-store**: The list model MUST, when asked to clear
  all, delete every visit from the store and then reload, leaving the list
  empty.
- **change-is-announced**: The list model MUST notify its observer each
  time the visits it lists change, after reloading, removing or clearing.
- **reloads-on-store-change**: The list model MUST reload whenever its
  history store announces a successful write (a pane recording a visit,
  another list removing or clearing), so a visit recorded while the panel
  is open appears; the store MUST announce every write that succeeded. The
  panel MUST also reload each time it appears, so its times are current.
- **store-work-off-ui-thread**: The list model MUST perform every store
  read and write off the UI thread and publish the resulting visits on the
  UI thread, so a slow store never blocks the interface.
- **panel-filter-drives-model**: The History panel MUST show a filter field
  with the placeholder "Filter History" above its list, and MUST set the
  list model's filter to the field's text as the user types, without
  waiting for Return.
- **panel-rows-show-visit**: The History panel MUST show one row per listed
  visit, in the model's order, each showing the visit's title, its address,
  and when it happened as a relative time.
- **panel-sidebar-list-style**: The History panel MUST present its filter
  field and list in the style of the Settings sidebar: a search field over
  a source-style list.
- **panel-remove-selected**: The History panel MUST provide a remove
  button, with the tooltip "Remove Selected Visits", that asks the list
  model to remove the visits selected in the list.
- **panel-clear-confirms**: The History panel MUST provide a Clear
  History… button, with the tooltip "Clear All History", that asks for
  confirmation before anything is removed; it MUST ask the list model to
  clear all only when the user confirms, and MUST remove nothing when the
  user cancels.
- **panel-opens-visit**: The History panel MUST, on Return, pass the
  address of every selected visit, in list order, to the open callback its
  host supplied; on a double-click of a selected row it MUST do the same,
  and on a double-click of a row outside the selection it MUST pass that
  row's visit alone. It MUST do nothing else to open them.
- **panel-every-button-has-tooltip**: The History panel MUST give every
  button it shows a tooltip.
- **panel-no-inline-help**: The History panel MUST NOT show inline help or
  empty-state text; an empty list (no history, or nothing matching the
  filter) MUST show as an empty list.
- **panel-independent-of-host**: The History panel MUST depend only on the
  list model and the open callback it is given, and MUST NOT reference the
  History window, a shelf, or any other host, so it can be embedded by any
  host.
- **window-hosts-panel-in-shelf**: The History window MUST host the History
  panel inside a shelf shaped like the projects window's: a bar of panel
  buttons across the top holding one button, "History", with the History
  panel beneath it as the shown panel.
- **window-is-single**: The History window MUST be a single window with a
  fixed window identifier: showing it while it is already open MUST bring
  that window up rather than create a second, and it MUST save and restore
  its frame and visibility under that identifier as the app's other single
  windows do.
- **window-opened-from-browser-menu**: The Browser menu's Show History
  command MUST show the History window, and MUST stay enabled whether or
  not the key window has a browser pane, while the host has given the
  window a history store; with none it MUST be disabled.
- **window-opens-visit-in-browser**: The History window MUST open a visit
  the panel hands it in the focused browser pane of the frontmost other
  window (the window that was key before the History window) as a new tab
  when such a pane exists, and in a new browser window when none does.
- **recording-gated-on-setting**: The browser MUST record a visit only
  when the Record history setting is on and the pane is not in private
  browsing.
- **private-browsing-never-records**: The browser MUST NOT record any visit
  while a pane is in private browsing, even when the Record history setting
  is on, so no visit made in private browsing ever reaches the store or
  this panel.

## Appearance

- **Corner radius**: The History window's shelf is a bordered card with a
  `12pt` corner radius, as the projects window's shelf is. Not applicable
  to the panel itself, which draws no card of its own.
- **Padding**: The panel's filter field and list follow the Settings
  sidebar's spacing; the shelf follows the projects window's shelf (panel
  bar across the top, the panel host beneath). Exact values are the
  builder's, matched to those two components.
- **Font**: A row's title in the list's primary text role, its address and
  relative time in a secondary text role, resolved by the active theme's
  typography rather than fixed sizes.
- **Background**: The panel and the shelf card fill with the
  `windowBackground` palette role.
- **Foreground/Text**: Title rows use the primary text role; address and
  time use `secondaryText`; a selected row uses the list's selection
  colors.
- **Border**: The shelf card strokes with the `outline` palette role, as
  the projects window's shelf does. The panel draws no border of its own.
- **Shadow**: Not applicable — neither the panel nor the window draws or
  configures a shadow beyond the window's system default.
- **Min/Max size**: The window is resizable; its minimum and default sizes
  are the builder's, large enough to show the filter field, the two header
  buttons and several rows without clipping.

## States

| State | Appearance change |
|-------|------------------|
| Recent (empty filter) | The list shows the most recent visits, newest first. |
| Filtered | The list shows only visits whose title or address contains the trimmed filter, newest first. |
| Empty | The list shows no rows and no text — no "No history" label or other empty-state message. |
| Row selected | The row draws in the list's selection colors; the remove button acts on the selection. |
| Nothing selected | The remove button removes nothing when pressed (whether it also draws disabled is the builder's choice — see Design Decisions). |
| Confirming clear | A confirmation sheet is shown over the window that hosts the panel; nothing has been removed yet. |
| Loading | Not applicable: no loading indicator is shown; the list keeps its previous rows until the latest reload answers and then replaces them. |
| Window already open | Show History brings the existing window up; no second window appears. |

## Accessibility

- **Role/trait**: The filter field is a search field; the list is a table
  of selectable rows; the remove and Clear History… buttons are buttons.
- **Label requirements**: The remove button, which shows only a glyph,
  carries the accessibility label "Remove Selected Visits", matching its
  tooltip; Clear History… carries its title. Each row's accessible text is
  the visit's title, address and relative time.
- **Announce state changes**: Not specified by the design; a reload
  replaces the table's rows, which the platform's table announces as it
  does for any reload.
- **Keyboard / assistive-technology navigation**: The filter field and the
  list are both reachable by the keyboard; arrow keys move the selection,
  and Return opens the selected visit (see `panel-opens-visit`).
- **Minimum tap target**: Not applicable — a pointer-driven desktop
  surface; the buttons use the platform's standard small control size.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| history-panel-001 | empty-filter-lists-recent, change-is-announced | Store holds three visits; model created with an empty filter; reload | The model lists all three, newest first; its observer is notified |
| history-panel-002 | filter-searches-title-and-address | Visits titled "Kitchen" at `https://a.example`, titled "Other" at `https://kit.example`, and titled "Other" at `https://b.example`; set the filter to "kit" | The model lists the first two only, newest first |
| history-panel-003 | filter-is-trimmed | Same store; set the filter to "  kit " | Same visits as filter "kit" |
| history-panel-004 | filter-is-trimmed, empty-filter-lists-recent | Set the filter to "   " | The model lists recent visits, as with an empty filter |
| history-panel-005 | list-is-bounded-by-page-size | Store holds five visits; model created with page size 2 | The model lists the two newest visits only |
| history-panel-006 | latest-filter-wins | Set the filter to "a", then to "ab", without waiting for the first reload | The model ends up listing the visits matching "ab"; the "a" answer never replaces them |
| history-panel-007 | remove-deletes-from-store, change-is-announced | Store holds three visits; remove one by id | The store's count drops by one; the model no longer lists it; the observer is notified |
| history-panel-008 | clear-all-empties-store | Store holds three visits; clear all | The store's count is 0; the model lists nothing |
| history-panel-009 | store-work-off-ui-thread | Reload, remove and clear all from the UI thread | Each store call runs off the UI thread; the visits are published and the observer notified on the UI thread |
| history-panel-010 | panel-filter-drives-model | Panel loaded; type "ki" into the filter field without pressing Return | The field's placeholder is "Filter History"; the model's filter is "ki" |
| history-panel-011 | panel-rows-show-visit | Model lists two visits | The list shows two rows in the model's order, each with title, address and a relative time |
| history-panel-012 | panel-sidebar-list-style | Panel loaded | A search field sits above a source-style list, as in the Settings sidebar |
| history-panel-013 | panel-remove-selected | Select two rows; press the remove button | The model is asked to remove exactly those two visits; the button's tooltip is "Remove Selected Visits" |
| history-panel-014 | panel-clear-confirms | Press Clear History…; confirm | A confirmation is shown first; after confirming, the model clears all; the button's tooltip is "Clear All History" |
| history-panel-015 | panel-clear-confirms | Press Clear History…; cancel | No visit is removed |
| history-panel-016 | panel-opens-visit | Double-click a row; separately, select a row and press Return | Each time the open callback receives that visit's address, once |
| history-panel-017 | panel-every-button-has-tooltip | Panel loaded | Every button in the panel has a non-empty tooltip |
| history-panel-018 | panel-no-inline-help | Empty store; and a filter that matches nothing | The list is empty and no help or empty-state text is shown |
| history-panel-019 | panel-independent-of-host | Create the panel with a model and an open callback, outside any window | It loads and works; it references no window or shelf type |
| history-panel-020 | window-hosts-panel-in-shelf | Show the History window | A shelf with a panel bar holding one "History" button, with the History panel beneath |
| history-panel-021 | window-is-single | Show the History window twice | One window exists with the fixed identifier; its frame and visibility are saved under it and restored on the next launch |
| history-panel-022 | window-opened-from-browser-menu | Key window has no browser pane; choose Browser › Show History | The command is enabled and the History window is shown |
| history-panel-023 | window-opens-visit-in-browser | Open a visit from the window while the frontmost other window has a focused browser pane | The visit opens as a new tab in that pane |
| history-panel-024 | window-opens-visit-in-browser | Open a visit from the window while no browser pane exists | The visit opens in a new browser window |
| history-panel-025 | recording-gated-on-setting | Record history on, pane not private; navigate | One visit is recorded |
| history-panel-026 | recording-gated-on-setting | Record history off, pane not private; navigate | No visit is recorded |
| history-panel-027 | private-browsing-never-records | Record history on, pane in private browsing; navigate | No visit is recorded; the panel lists nothing new |
| history-panel-028 | reloads-on-store-change | List model on a store showing two visits; record a third visit through the store | The model reloads and lists three visits, newest first |
| history-panel-029 | panel-opens-visit | Select rows 0 and 2 of three; press Return | The open callback receives row 0's address, then row 2's |
| history-panel-030 | panel-opens-visit | Rows 0 and 1 selected; double-click row 2 | The open callback receives row 2's address only |

## Edge Cases

- **Null and empty input**: An empty or whitespace-only filter lists recent
  visits (MUST, see `filter-is-trimmed`, history-panel-004). An empty store
  lists nothing and shows no empty-state text (MUST, see
  `panel-no-inline-help`). Removing an empty selection removes nothing.
- **Boundary values**: Results never exceed the page size, recent or
  filtered (MUST, see `list-is-bounded-by-page-size`). A filter containing
  the store's LIKE wildcards (`%`, `_`) or its escape (`\`) matches those
  characters literally, because the store escapes them.
- **Concurrent access**: Rapid typing issues overlapping reloads; only the
  latest filter's answer is shown (MUST, see `latest-filter-wins`). Debug
  builds may run several app copies sharing one history file; the store's
  one-writer WAL pool serializes their writes, and each copy's list shows
  the store as of its last reload. Within one copy, every write to the
  store reloads the list (MUST, see `reloads-on-store-change`), so a visit
  recorded while the panel is open appears without reopening it.
- **Error states**: A store read or write that throws leaves the listed
  visits as they were; how the failure is reported is the builder's (see
  Design Decisions). No error leaves a visit shown as removed when it was
  not.
- **Offline or disconnected state**: Not applicable — the history store is
  a local file; listing, filtering, removing and clearing need no network.
  Opening a visit hands an address to a browser, which handles its own
  connectivity.
- **Missing file or unreachable server**: If the history file cannot be
  opened, there is no store to build a list model on, and the host does not
  offer the panel; the store creates its file when it is first opened.
- **Cancellation and timeouts**: A superseded reload's answer is discarded
  (see `latest-filter-wins`). Every store statement runs under the store's
  own deadline, so a wedged file fails a call rather than hanging the
  panel.
- **Private browsing**: A private pane records nothing (MUST, see
  `private-browsing-never-records`), so the panel cannot list a private
  visit. Turning private browsing off does not back-fill visits made while
  it was on.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `store` (list model) | history store | none — required | The store the model reads and writes. |
| `pageSize` (list model) | integer | 200 | The most visits listed, recent or filtered. |
| `filter` (list model) | string | empty | The filter text; trimmed before use. |
| `open` (panel) | callback taking an address | none — required | What the host does to open a visit. |
| Window identifier (window) | string | `web-history` | The fixed identifier the window saves and restores its frame and visibility under. |
| Record history (`browserRecordsHistory`) | boolean setting | on | Whether non-private panes record visits; shown under Privacy and Security › History. |
| Keep visits for (`browserHistoryRetention`) | setting | unchanged | How long visits are kept; shown under Privacy and Security › History. |
| Private browsing (`browserPrivateBrowsing`) | boolean setting | off | While on for a pane, that pane records nothing. |

## Deep Linking

Not applicable: the window is opened only by the Browser menu's Show
History command and by window restoration; the design defines no URL or
route for it.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| — | "Filter History" | Placeholder of the panel's filter field |
| — | "Remove Selected Visits" | Tooltip and accessibility label of the remove button |
| — | "Clear History…" | Title of the clear-all button |
| — | "Clear All History" | Tooltip of the clear-all button |
| — | "History" | The shelf's panel button and the window's title |
| — | "Show History" | The Browser menu command that opens the window |

The relative "when" of each row is formatted by the platform's relative
date formatter in the user's locale. The confirmation's wording is the
builder's.

## Accessibility Options

- **Reduce Motion**: Not applicable — the panel and window define no
  animation of their own.
- **Increase Contrast**: Not applicable — every color is a semantic palette
  role; contrast handling belongs to the theme.
- **Differentiate Without Color**: Not applicable — rows differ by text,
  not color; selection uses the platform list's selection drawing.

## Feature Flags

Not applicable: the panel and window are always available; recording is
governed by settings (see Configuration), not feature flags.

## Analytics

Not applicable: no analytics or telemetry event is emitted.

## Privacy

- **Data collected**: The addresses and titles of pages visited in
  non-private browser panes, with the time of each visit, recorded only
  while Record history is on. Nothing is recorded while a pane is in
  private browsing (`private-browsing-never-records`).
- **Storage**: The browser history store's own local SQLite file, separate
  from the project database so it can be cleared or deleted wholesale. The
  list model holds at most one page of visits in memory.
- **Transmission**: None — the panel and window send nothing anywhere.
  Which agents may read history is a separate setting and tool, outside
  this component.
- **Retention**: As long as the Keep visits for setting allows, until the
  user removes visits or clears all here; removal and Clear History delete
  from the store, not just from the list.

## Logging

Not applicable: the design specifies no logging; a store failure's
reporting is the builder's choice (see Design Decisions).

## Platform Notes

- **macOS (AppKit)**: The list model is
  `@MainActor public final class BrowserHistoryListModel` with
  `init(store: BrowserHistoryStore, pageSize: Int = 200)`,
  `private(set) var visits: [BrowserVisit]`, `var filter: String`,
  `func reload() async`, `func remove(_ ids: [Int64]) async`,
  `func clearAll() async` and `var onChange: (() -> Void)?`. It calls the
  store's `recent(limit:)` and `search(_:limit:)`, `remove(visit:)` and
  `removeAll()`, all inside `BrowserHistoryStore.perform(_:)`, which runs
  them off the main actor (`store-work-off-ui-thread`). It observes
  `BrowserHistoryStore.didChangeNotification` (object: its store, queue
  main), which the store posts after every write that succeeded, on the
  writing thread, and schedules a reload on it. The store's `recent` and
  `search` also take `excludingLocalFiles` (SQL `url NOT LIKE 'file:%'`
  before the limit), which only the agent's history tool passes. The panel is
  `public final class BrowserHistoryPanelViewController: NSViewController`
  with `init(model:open: @escaping (URL) -> Void)`; it styles its filter
  field and source list after `TopicListViewController` (the Settings
  sidebar, which hosts its search field in the list's header accessory),
  shows rows in an `NSTableView` (reloading the model in
  `viewWillAppear`; Return calls `openSelected()`, which opens every
  selected visit, as a double-click on a selected row does), and confirms
  Clear History… with an
  `NSAlert` sheet on the hosting window. Tooltips are `toolTip` on each
  `NSButton`. The window is
  `public final class BrowserHistoryWindowController: SingleWindowController`
  with `public static let windowID = "web-history"` and
  `public static func show()` and `public static var canShow` (a store is
  set), which the Browser menu's Show History is enabled by; its shelf follows
  `ProjectShelfViewController` (a `ThemedBox` card with an `IconTabBar` of
  panel buttons across the top, one item "History"), and
  `SingleWindowController` saves and restores frame and visibility under
  the window id. `WebBrowserWindowsFeature` registers the window id and the
  Show History command. Opening a visit uses the focused browser pane of
  the frontmost visible window other than History (a
  `WebBrowserWindowController`'s pane, or the `ComposableTabsWindowController`
  pane holding the first responder) as a new tab, otherwise
  `WebBrowserWindowController.openNew`.
  The recording gate is one function,
  `recordsHistory(globalRecords:paneIsPrivate:) -> Bool` returning
  `globalRecords && !paneIsPrivate`, on `WebBrowserPaneViewController` or a
  small `BrowserHistoryRecordingPolicy`; every record call goes through it.
- **SwiftUI**: Model the list model as an `@Observable` class; bind a
  `.searchable` or `TextField` to `filter` and cancel the previous reload
  `Task` on each change to get `latest-filter-wins`. Show rows in a
  `List(selection:)` with the sidebar list style, `.help` for tooltips, a
  `.confirmationDialog` for Clear History…, and `.onSubmit` /
  `.contextMenu(primaryAction:)` for opening. The window is a
  `Window(id:)` scene, which is single by construction.
- **Compose / Windows**: The same split applies: a view model exposing the
  listed visits as observable state with a cancellable reload per filter
  change, a list view taking that model and an open callback, and a
  single-instance window hosting it. Every button carries a tooltip
  (`TooltipBox` / `ToolTipService.ToolTip`).

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/History/BrowserHistoryListModel.swift` | planned |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/History/BrowserHistoryPanelViewController.swift` | planned |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/History/BrowserHistoryWindowController.swift` | planned |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/History/` | unverified |

## Design Decisions

**Decision**: The panel takes a list model and an open callback and nothing
else; the window composes it.
**Rationale**: The design makes the panel reusable and keeps hosting it in
the projects window's shelf open for later (a non-goal now). A panel that
knows its window could not be dropped into another host without change.
**Approved**: pending

**Decision**: The list model, not the panel, owns filtering, trimming and
reload coalescing.
**Rationale**: It keeps the behavior testable without a view (the plan's
model tests) and lets any host reuse the same rules.
**Approved**: pending

**Decision**: Coalescing is the builder's to implement — a generation
counter checked when a reload answers, or cancelling the previous reload
task — so long as `latest-filter-wins` holds.
**Rationale**: Both satisfy the requirement; the design names only the
outcome.
**Approved**: pending

**Decision**: Whether the remove button draws disabled when nothing is
selected, the exact SF Symbols, the window's default and minimum sizes,
and the confirmation sheet's wording are the builder's.
**Rationale**: The design leaves symbols and dialog sizes to the builder
and specifies only the buttons, their tooltips and that clearing confirms.
**Approved**: pending

**Decision**: How a store failure is reported (a log line, an alert, or
leaving the list unchanged) is the builder's, provided the list never shows
a visit as removed when it was not.
**Rationale**: The design does not specify error presentation.
**Approved**: pending

**Decision**: The recording gate is one pure function of the Record
history setting and the pane's private browsing state, and every record
call goes through it.
**Rationale**: One code path means private browsing cannot be bypassed by
a second record call that forgot to check it, and the gate is testable on
its own.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | pending | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | pending | Best Practices |
| [adc.check.best-practices.good-test-properties](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9144e220-ad70-51db-ba81-cdb0cc1b66c8) | pending | Best Practices |

Notes: design-first — no code exists yet, so every check is pending until
the implementation is written and confirmed against this recipe.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 0.1.2 | 2026-11-16 | Mike Fullerton | List reloads on every store write and on appearing; Return and double-click open every selected visit; local files excluded for the agent. |
| 0.1.1 | 2026-11-15 | Mike Fullerton | A visit opens in the frontmost other window's focused browser pane |
| 0.1.0 | 2026-11-15 | Mike Fullerton | Initial creation (design-first, from the more privacy features design) |
