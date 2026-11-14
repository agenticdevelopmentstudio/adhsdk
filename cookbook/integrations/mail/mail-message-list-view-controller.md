---
id: 26473390-9629-40f0-ae98-32ccab2fc5da
title: "Mail Message List View Controller"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "AppKit view controller for the mail window's message list: one row per message, unread in bold, empty and loading label, selection sync, next page on last row."
platforms:
  - swift
  - macos
tags:
  - mail
  - list
  - appkit
  - pagination
depends-on:
  - b3edb32d-7473-464b-acfb-c19cdd44e99e
related:
  - 018e4a69-cbeb-4105-8f39-dae3e6f7d8ec
references: []
approved-by: ""
approved-date: ""
---

# Mail Message List View Controller

## Overview

The middle column of the mail window. It shows the selected mailbox's messages as a single-column table with no header. Each row carries the sender, the date, the subject and a snippet, and an unread message is drawn in bold with an accent dot. It owns no mail state: it reads `messages`, `selectedMessageId`, `loading` and `hasMore` from `MailBrowserModel`, and it calls `select(messageId:)` and `loadMore()` on it. Reaching the last row loads the next page.

## Behavioral Requirements

- **single-column-table**: The list MUST be a table with one column (identifier `message`), no header view, a fixed row height of 68 points, and automatic row heights disabled.
- **inset-style**: The table MUST use the inset table style.
- **row-count**: The list MUST show one row per entry in the model's `messages`, in the model's order.
- **reload-on-messages**: The list MUST reload its rows, re-apply the selection and refresh the empty label whenever the model's `messages` changes.
- **main-queue-hop**: UI updates from model changes MUST run on the main actor. The source delivers them through a main-queue hop, so the table reloads one hop after the model changes; see **stale-row-guard**.
- **row-sender**: A row MUST show the sender as the display name from the `from` header, or the bare address when the header has no name.
- **row-date**: A row MUST show the date as the time for a message sent today, the abbreviated month and day for a message from earlier this year, and the year, abbreviated month and day for an older message. "Today" and "this year" use the current calendar and time zone.
- **row-date-unparsed**: A row MUST show the original date text when it cannot be parsed as an ISO 8601 date.
- **row-subject**: A row MUST show the message subject, or the text `(no subject)` when the subject is empty.
- **row-snippet**: A row MUST show the message snippet in the small system font and the secondary label color.
- **row-truncation**: The sender, subject and snippet MUST each truncate at the tail when they do not fit on one line.
- **row-date-priority**: The date MUST NOT be compressed in favor of the sender; the sender MUST give up width first.
- **unread-dot**: A row MUST show an 8 by 8 point accent-colored dot for an unread message and MUST hide it for a read message.
- **unread-weight**: A row MUST draw the sender in bold and the subject in semibold when the message is unread, and both in regular weight when it is read.
- **unread-definition**: A message MUST count as unread when its labels contain `UNREAD`.
- **row-reuse**: The list MUST reuse row views through the `MessageRow` identifier and MUST rebuild a row's content from the message each time the row is shown.
- **row-accessibility-label**: A row MUST expose the accessibility label made of the sender, a comma and a space, and the subject.
- **load-more-on-last-row**: When the table requests the view for the last row and the model reports `hasMore`, the list MUST ask the model to load the next page. The trigger is the request for that row's view, not its becoming visible, so a prefetch or resize that creates the view also triggers it.
- **stale-row-guard**: The list MUST return no view for a row index the current `messages` no longer contains.
- **empty-label**: The list MUST show a centered secondary-color label when `messages` is empty and MUST hide it otherwise.
- **empty-label-text**: The empty label MUST read `Loading…` while the model is loading and `No messages` otherwise.
- **loading-refresh**: The list MUST refresh the empty label whenever the model's `loading` changes.
- **selection-to-model**: When the user selects a row, the list MUST ask the model to select that row's message id, and when the selection clears it MUST ask the model to select no message.
- **selection-from-model**: When the model's `selectedMessageId` changes, the list MUST select the row of the message with that id, or clear the selection when no listed message has it.
- **selection-single**: The list MUST select at most one row, replacing any earlier selection.
- **selection-echo-guard**: Applying the model's selection to the table MUST NOT send a selection back to the model.
- **selection-no-op**: The list MUST leave the table selection alone when the model's selected row already matches it.
- **selection-out-of-range**: When the table reports a selected row index outside `messages`, the list MUST ask the model to select no message.
- **accessibility-identifier**: The table MUST carry the accessibility identifier `mail.messages`.
- **model-injection**: The controller MUST be built with a `MailBrowserModel` and MUST NOT support being loaded from a coder. The source enforces this at run time: `init(coder:)` calls `fatalError`; it is not marked unavailable at compile time.

## Appearance

- **Corner radius**: The unread dot is a layer-backed 8 by 8 point view with a corner radius of 4, a circle. No other corner radius is set.
- **Padding**: Inside a row, the dot sits 2 points from the leading edge, the sender and the text below it sit 16 points from the leading edge, the sender sits 6 points from the top, the dot is vertically centered on the sender, the date's first baseline aligns with the sender's first baseline, the date sits 6 points from the trailing edge, the sender keeps at least 8 points from the date, the subject and snippet keep at least 6 points from the trailing edge, and the subject and snippet each sit 2 points below the line above.
- **Font**: Sender and subject use the regular system size; the sender is bold and the subject semibold when unread, and both regular when read. Date and snippet use the small system size.
- **Background**: The table style is inset; the cell and table backgrounds are the system defaults. The dot is the control accent color.
- **Foreground/Text**: Sender and subject use the default label color. Date and snippet use the secondary label color. The empty label uses the secondary label color.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: Row height is fixed at 68 points. The list fills its container on all four edges and shows a vertical scroller.

## States

| State | Appearance change |
|-------|------------------|
| Default | Rows shown, empty label hidden. |
| Pressed | Not applicable: the list has no pressed styling of its own; the table's standard row highlight applies. |
| Disabled | Not applicable: the source has no disabled state for the list. |
| Focused | The selected row uses the table's standard selection look; the source sets no custom focus styling. |
| Loading | With no messages, the centered label reads `Loading…`. With messages present the label is hidden and rows stay visible. |
| Empty | With no messages and not loading, the centered label reads `No messages`. |
| Unread row | Accent dot visible, sender bold, subject semibold. |
| Read row | Dot hidden, sender and subject regular. |
| Selected row | The row matching the model's `selectedMessageId` is selected in the table. |

## Accessibility

- **role**: The list is a standard table, so it carries the platform table role. The source sets no other role.
- **table-identifier**: The table's accessibility identifier is `mail.messages`.
- **row-label**: Each row's accessibility label is the sender and subject joined by a comma and a space. The date, snippet and unread state are not part of it.
- **keyboard-navigation**: The source adds no key handling; keyboard navigation of rows comes from the platform table.
- **unread-state-announcement**: NEEDS REVIEW: Not implemented in source. A row shows unread state only through the dot and the font weight, and the accessibility label does not carry it. A screen-reader pass over the mail window would settle whether the label needs an unread marker.
- **tap-target**: Each row is 68 points tall and spans the table width; the source states no further target size.
- **contrast**: NEEDS REVIEW: Not implemented in source. The colors are system label, secondary label and accent colors; whether the secondary-color date and snippet meet contrast on every selection and appearance state needs a contrast measurement.

## Conformance Test Vectors

The model's display helpers have tests in `MailBrowserModelTests`; the view controller has no test of its own, so the rows that name no test are derived from the source. Rows whose input is "Inspect" are inspection-only: a conformance pass checks them by reading the built view, not by a driven event. Mail-list-024 is inspection-only too, because the source traps at run time and a test cannot observe that.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mail-list-001 | row-sender | `from` is `PayPal <service@paypal.com>` (test `senderNameTakesTheDisplayName`) | Sender text is `PayPal`. |
| mail-list-002 | row-sender | `from` is `"Doe, Jane" <jane@example.com>` (same test) | Sender text is `Doe, Jane`. |
| mail-list-003 | row-sender | `from` is `<only@example.com>` (same test) | Sender text is `only@example.com`. |
| mail-list-004 | row-sender | `from` is `plain@example.com` (same test) | Sender text is `plain@example.com`. |
| mail-list-005 | row-date | time zone UTC, now is 2026-11-07 20:00 UTC, message dated 2026-11-07T18:59:24.000Z, locale en_US (test `listDateShowsTimeTodayAndDayOtherwise`) | Date text contains `6:59`. |
| mail-list-006 | row-date | same time zone and now, message dated 2026-03-02T10:00:00.000Z (same test) | Date text is `Mar 2`. |
| mail-list-007 | row-date | same time zone and now, message dated 2024-03-02T10:00:00.000Z (same test) | Date text contains `2024`. |
| mail-list-008 | row-date-unparsed | Message date text is `not a date` | Date text is `not a date`. |
| mail-list-009 | row-subject | Message subject is the empty string | Subject text is `(no subject)`. |
| mail-list-010 | unread-dot, unread-weight, unread-definition | Message labels contain `UNREAD` | Dot visible, sender bold, subject semibold. |
| mail-list-011 | unread-dot, unread-weight | Message labels do not contain `UNREAD` | Dot hidden, sender and subject regular. |
| mail-list-012 | row-accessibility-label | Sender `PayPal`, subject `Receipt` | Row accessibility label is `PayPal, Receipt`. |
| mail-list-013 | load-more-on-last-row | Five messages, `hasMore` is true, row 4 is shown | The model's `loadMore()` is called once. |
| mail-list-014 | load-more-on-last-row | Five messages, `hasMore` is false, row 4 is shown | `loadMore()` is not called. |
| mail-list-015 | stale-row-guard | Table asks for row 3 after `messages` shrank to two entries | No view is returned and nothing is loaded. |
| mail-list-016 | empty-label, empty-label-text | `messages` empty, `loading` true | Label visible and reads `Loading…`. |
| mail-list-017 | empty-label, empty-label-text | `messages` empty, `loading` false | Label visible and reads `No messages`. |
| mail-list-018 | empty-label | `messages` has one entry | Label hidden. |
| mail-list-019 | selection-to-model | User clicks row 1 of three | The model's `select(messageId:)` is called with row 1's id. |
| mail-list-020 | selection-from-model, selection-echo-guard | Model sets `selectedMessageId` to the id of row 2 | Row 2 is selected and the model receives no `select(messageId:)` call from the list. |
| mail-list-021 | selection-from-model | Model sets `selectedMessageId` to an id not in `messages` | The table selection clears. |
| mail-list-022 | accessibility-identifier | Inspect the table | Identifier is `mail.messages`. |
| mail-list-023 | single-column-table | Inspect the table | One column `message`, no header, row height 68. |
| mail-list-024 | model-injection | Inspect the controller's coder initializer (inspection-only) | `init(coder:)` calls `fatalError("init(coder:) has not been implemented")`; the only working initializer takes a `MailBrowserModel`. |
| mail-list-025 | inset-style | Inspect the table | Table style is inset. |
| mail-list-026 | row-count, reload-on-messages | Model `messages` changes from two entries to four | The table has four rows in the model's order, the selection is re-applied and the empty label is refreshed. |
| mail-list-027 | main-queue-hop | Model `messages` changes from a background thread | The reload and every view update run on the main actor. |
| mail-list-028 | row-snippet | Message snippet is `Your receipt` | Snippet text is `Your receipt` in the small system font and the secondary label color. |
| mail-list-029 | row-truncation, row-date-priority | Sender, subject and snippet are longer than the row is wide | Each shows on one line cut at the tail with an ellipsis; the date stays whole and the sender shrinks first. |
| mail-list-030 | row-reuse | Show row 0, scroll it out, then show row 3 in the reused view | The view has the `MessageRow` identifier and shows row 3's sender, date, subject, snippet, dot and weights with nothing left from row 0. |
| mail-list-031 | loading-refresh | `messages` empty, `loading` changes from true to false | Label text changes from `Loading…` to `No messages`. |
| mail-list-032 | selection-single | Select row 1, then row 2 | Only row 2 is selected. |
| mail-list-033 | selection-no-op | Model selects the id of the row already selected | The table selection is not touched. |
| mail-list-034 | selection-out-of-range | Table reports selected row 7 with three messages | The model's `select(messageId:)` is called with no message. |

## Edge Cases

- **Empty list**: With no messages the table has zero rows and the centered label shows (MUST). Covered by mail-list-016 and mail-list-017.
- **Row asked for after the list shrank**: The table reloads one main-queue hop after the list changes, so a layout pass in between can ask for a row that no longer exists; the list MUST return no view for it, as its source comment explains. Covered by mail-list-015.
- **Empty subject**: A message with an empty subject MUST show `(no subject)` (mail-list-009).
- **Unparseable date**: A date the model cannot parse MUST show as the original text (mail-list-008).
- **Selected id not listed**: When the selected id is not in `messages`, or is nil, the list MUST clear the table selection (mail-list-021).
- **Selection echo**: The list MUST suppress the selection callback while it applies the model's selection, so the model is not called back (mail-list-020).
- **Selection out of range**: In the selection callback, a selected row index outside `messages` MUST be sent to the model as no message (mail-list-034).
- **Repeated last-row display**: The list calls `loadMore()` every time the last row is shown while `hasMore` is true and does not guard against repeats itself; the model's `loadMore()` is a no-op while a page is loading and on the last page. The list SHOULD keep relying on that guard.
- **Load-more failure**: The list does nothing on a failed page load; the model sets `errorMessage`, and this controller shows no error of its own. The error is surfaced elsewhere in the mail window.
- **Boundary, one message**: With a single message, that row is both first and last, so showing it loads the next page when `hasMore` is true.
- **Concurrent access**: The controller and its model are main-actor isolated; model changes arrive on the main queue, and page loads run in unstructured tasks that call the main-actor model. The model drops pages answering an older list, so a late page cannot change the list under the user.
- **Offline or disconnected**: Not applicable to this controller: it makes no network call; it only displays what the model holds. Failures reach the user through the model's `errorMessage`.
- **Long text**: Long sender, subject and snippet text MUST truncate at the tail rather than wrap.

## Configuration

The controller takes only a `MailBrowserModel` at construction. Row height 68, the single column and the inset style are fixed in the source.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| model | `MailBrowserModel` | required | The only constructor input. |

## Deep Linking

Not applicable: the controller registers no URL scheme and handles no link; the source has no deep-link code.

| Platform | URL Pattern |
|----------|-------------|
| Apple | none |
| Android | none |
| Web | none |

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (literal) | No messages | Empty label when not loading |
| none (literal) | Loading… | Empty label while loading |
| none (literal) | (no subject) | Subject shown for an empty subject |

The strings are literals in code, not keys in a string catalog. Dates are formatted with the current locale and calendar by the model.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the controller runs no animation. |
| Increase Contrast | Not applicable: the controller sets no contrast-specific values; the system colors adapt on their own. |
| Differentiate Without Color | The unread state shows by both the accent dot and the bold font weight, so it does not rely on color alone. |

## Feature Flags

Not applicable: the source has no flag check.

| Flag Key | Default | Description |
|----------|---------|-------------|
| none | n/a | The controller reads no flag. |

## Analytics

Not applicable: the source emits no analytics event.

| Event | Properties | When |
|-------|-----------|------|
| none | n/a | The controller emits nothing. |

## Privacy

- **Data collected**: None by this controller. It displays sender, subject, snippet and date of mail the model already holds.
- **Storage**: None. The controller keeps no copy beyond the table's visible rows.
- **Transmission**: None. It makes no network call.
- **Retention**: None.

## Logging

Not applicable: the source writes no log lines.

| Event | Level | Message |
|-------|-------|---------|
| none | n/a | The controller logs nothing. |

## Platform Notes

- **SwiftUI**: Start from a `List` with a selection binding to the selected message id, a row view per message, `.onAppear` on the last row to request the next page, and an overlay `Text` for the empty and loading label. The selection binding replaces the manual echo guard; bold weight follows `.fontWeight` on the unread flag.
- **Compose**: Start from a `LazyColumn` with `items` keyed by message id, a selected-row highlight from the model's selected id, a `LaunchedEffect` keyed on the last index to request more, and a centered `Text` for the empty and loading label. Truncation is `maxLines = 1` with `TextOverflow.Ellipsis`, and the accessibility label is `Modifier.semantics` with `contentDescription`.
- **React/Web**: Start from a `role="listbox"` list (or a table with row selection) of options with `aria-selected`, an `IntersectionObserver` on the last row to request the next page, and a `role="status"` element for the empty and loading text. Truncation is CSS `text-overflow: ellipsis`, and the row label is `aria-label`.
- **AppKit / UIKit**: The source is `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Integrations/Mail/MailMessageListViewController.swift`: an `NSViewController` that is its own `NSTableViewDataSource` and delegate, with a private `NSTableCellView` subclass for the row and Combine sinks on the model's published properties. Its specific pieces are the echo-guard flag around programmatic selection and the row-count guard in the view-for-row method. On UIKit the equivalent is a `UITableView` with a diffable data source and a custom cell, and `willDisplay` on the last index to request more.
- **WinUI 3**: Use a `ListView` with `SelectionMode="Single"`, `ItemsSource` bound to an `ObservableCollection` of message view models, `SelectedItem` two-way bound to the selected message, and an `ItemTemplate` holding a `Grid` with two columns (sender and date) over two single-line rows (subject and snippet). Set `TextTrimming="CharacterEllipsis"` on the sender, subject and snippet, and keep the date column `Auto` width so the sender column absorbs the squeeze. Draw the unread dot as an 8 by 8 `Ellipse` with `Visibility` bound to unread and the `SystemAccentColor` brush; set `FontWeight` to `Bold` and `SemiBold` through the unread flag. Use `ItemsStackPanel` virtualization with an `ISupportIncrementalLoading` collection (or the `ContainerContentChanging` event) to load the next page when the last item is realized. Put a `TextBlock` in a centered `Grid` cell for the empty and loading text, and set `AutomationProperties.Name` on the item template to the sender and subject for Narrator. `ListViewItem` supplies the `PointerOver`, `Pressed` and `Selected` visual states, and arrow keys, Home and End come from the control. Match the 68 epx row height with `MinHeight` and `MaxHeight` on the item container.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Integrations/Mail/MailMessageListViewController.swift` | unverified |
| ios | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The controller reads and calls the model only; it holds no mail state and no networking.
**Rationale**: The model's own comment says every action goes through it, so it is the tested unit and the view controllers only read it and call it.
**Approved**: pending

**Decision**: Row height is fixed at 68 points and automatic row heights are off.
**Rationale**: The row is always three fixed lines of two fonts, and tail truncation keeps its height constant, so measuring is not needed.
**Approved**: pending

**Decision**: The list guards against a row index the model's `messages` no longer has.
**Rationale**: The source comment states the table reloads a main-queue hop after the list changes, so a layout pass in between can ask for a row the shrunk list no longer has.
**Approved**: pending

**Decision**: A flag, `applyingSelection`, silences the selection callback while the model's selection is applied.
**Rationale**: Without it, applying the model's selection would call `select(messageId:)` back and loop between table and model.
**Approved**: pending

**Decision**: Next-page loading is triggered from the last row's view creation, with no guard in the controller.
**Rationale**: The model's `loadMore()` is a no-op while a page loads and on the last page, so repeated calls cost nothing. The trigger fires when the row view is requested, so it depends on the table asking for the last row. The SHOULD on keeping that reliance is a default: a controller-side guard would duplicate the model's flag, and a platform whose list control re-requests rows more often might add its own.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | internationalization |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.performance.lazy-loading](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/93049d53-e8e2-5ea3-8a3a-9eb07e60d0e2) | passed | performance |

The controller only displays model state and forwards two calls, so separation of concerns passes. Unit-test coverage is partial: the model's helpers and paging have tests, while the controller and its row view have none. Screen-reader support is partial because rows have a label of sender and subject but no unread state. Keyboard navigation passes through the native table, with no custom handling. String externalization fails because the empty-label text and the no-subject text are code literals. It uses `NSTableView` with system fonts and colors, and it requests pages as the last row appears.

Known gaps: the empty-label and no-subject strings are code literals with no string catalog, and the view controller has no test of its own; coverage comes from the model's tests of its display helpers and paging.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
