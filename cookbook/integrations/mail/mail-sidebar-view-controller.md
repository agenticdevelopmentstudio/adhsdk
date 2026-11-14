---
id: 83a5a5e0-3337-4aff-aef8-40a7393dabfe
title: "Mail Sidebar View Controller"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "AppKit source-list sidebar for the mail window: each account as a group row with its mailboxes beneath, symbol and unread count per row, selection synced with the model."
platforms:
  - swift
  - macos
tags:
  - integrations
  - mail
  - appkit
  - source-list
depends-on:
  - b3edb32d-7473-464b-acfb-c19cdd44e99e
related:
  - 018e4a69-cbeb-4105-8f39-dae3e6f7d8ec
  - 26473390-9629-40f0-ae98-32ccab2fc5da
  - ac5b0100-ea5d-4abf-a9aa-11a477878514
references: []
approved-by: ""
approved-date: ""
---

# Mail Sidebar View Controller

## Overview

The left column of the mail window. It shows a source-list outline: each mail account is a group row labeled with its email address, and that account's mailboxes sit beneath it. A mailbox row carries a symbol, the mailbox title indented by nesting depth, and an unread count when there is one. It owns no mail state: it reads `accounts`, `mailboxes` and `selectedMailbox` from `MailBrowserModel`, and it calls `select(mailbox:)` on it when the user picks a mailbox.

The sidebar reads these fields from `MailBrowserModel` (see the model ingredient for the full type):

| Field | Type | Used for |
|-------|------|----------|
| account `id` | string | Key into `mailboxes`; matched against a mailbox's `accountId`. |
| account `email` | string | Account group row text. |
| mailbox `accountId` | string | Selection matching and the id sent to the model. |
| mailbox `labelId` | optional string | Symbol choice and selection matching; nil is All Mail. |
| mailbox `title` | string | Row text and accessibility label. |
| mailbox `depth` | integer | Row indent. |
| mailbox `unread` | optional integer | Trailing count. |
## Behavioral Requirements

- **single-column-outline**: The sidebar MUST be an outline with one column (identifier `mailbox`) used as the outline column, and no header view.
- **source-list-style**: The outline MUST use the source list style, with group rows that do not float and the default row size style.
- **scroll-container**: The sidebar MUST sit in a scroll view with a vertical scroller and no background drawn.
- **account-groups**: The sidebar MUST show one group row per entry in the model's `accounts`, in the model's order.
- **mailbox-children**: Beneath each account, the sidebar MUST show that account's mailboxes from the model's `mailboxes` keyed by account id, in the model's order, and no mailboxes when the account has no entry.
- **empty-accounts**: When the model has no accounts, the outline MUST have zero rows and the sidebar MUST draw no message.
- **group-expandable-with-children**: An account group row MUST be expandable only when it has at least one mailbox.
- **expand-on-rebuild**: The sidebar MUST expand every account group each time it rebuilds.
- **rebuild-on-model**: The sidebar MUST rebuild its rows, reload the outline and re-apply the selection whenever the model's `mailboxes` or `accounts` changes.
- **main-queue-hop**: The sidebar MUST receive model changes on the main queue.
- **account-row-text**: An account group row MUST show the account's email address in the small system font, semibold, in the secondary label color.
- **account-row-truncation**: An account row MUST truncate its text at the tail when it does not fit.
- **mailbox-row-title**: A mailbox row MUST show the mailbox title, truncated at the tail when it does not fit.
- **mailbox-row-indent**: A mailbox row MUST indent its content from the leading edge by 14 points times the mailbox's nesting depth.
- **mailbox-row-symbol**: A mailbox row MUST show a symbol tinted with the control accent color, chosen by label id: `INBOX` is `tray`, `STARRED` is `star`, `IMPORTANT` is `exclamationmark.circle`, `SENT` is `paperplane`, `DRAFT` is `doc`, no label id (All Mail) is `tray.full`, `SPAM` is `xmark.bin`, `TRASH` is `trash`, and any other label is `tag`. When the system symbol cannot be created, the row falls back to an empty image.
- **mailbox-row-unread-count**: A mailbox row MUST show the unread count, in the small system font and the secondary label color at the trailing end, only when the count is present and greater than zero.
- **unread-count-plain-integer**: The unread count MUST be drawn as the plain decimal integer string, with no number formatter and no locale grouping.
- **mailbox-row-title-yields**: A mailbox row's title MUST give up width before the symbol and the count do.
- **only-mailboxes-selectable**: The sidebar MUST allow selection of mailbox rows only and MUST NOT allow selection of an account group row.
- **selection-to-model**: When the user selects a mailbox row, the sidebar MUST ask the model to select the mailbox with that row's account id and label id.
- **selection-from-model**: When the model's `selectedMailbox` changes, the sidebar MUST select the mailbox row whose account id and label id both match it.
- **selection-no-match**: The sidebar MUST leave the selection unchanged when the model has no selected mailbox or no listed mailbox matches it, or when the matching row has no outline row (for example its group is collapsed).
- **selection-no-op**: The sidebar MUST leave the outline selection alone when the matching row is already the selected row.
- **selection-single**: The sidebar MUST select at most one row, replacing any earlier selection.
- **selection-after-rebuild**: Each rebuild MUST re-apply the model's selection, so the selected row survives a reload.
- **selection-task-unhandled**: The sidebar MUST start the model's `select(mailbox:)` in an unstructured task, MUST NOT wait for it, and MUST NOT handle or swallow its failure itself; errors reach the user through the model's `errorMessage`.
- **selection-echo-guard**: Applying the model's selection to the outline MUST NOT send a selection back to the model.
- **selection-clear-ignored**: When the outline's selection clears, the sidebar MUST NOT call the model.
- **accessibility-identifier**: The outline MUST carry the accessibility identifier `mail.sidebar`.
- **mailbox-accessibility-label**: A mailbox row MUST expose the mailbox title as its accessibility label.
- **model-injection**: The controller MUST be built with a `MailBrowserModel` and MUST NOT support being loaded from a coder.

## Appearance

- **Corner radius**: Not applicable: the sidebar sets no corner radius; the source list's standard selection look applies.
- **Padding**: In a mailbox row, the symbol and title sit in a horizontal stack with 6 points between them, the stack starts 14 points times depth from the leading edge and ends 6 points from the trailing edge, and it is centered vertically. In an account row, the label starts at the leading edge, keeps at least 4 points from the trailing edge, and is centered vertically.
- **Font**: Account email uses the small system size at semibold weight. Mailbox title uses the default text field font. The unread count uses the small system size at regular weight.
- **Background**: The scroll view draws no background, so the source list's translucent sidebar material shows through. The symbol is tinted with the control accent color.
- **Foreground/Text**: Account email and unread count use the secondary label color. Mailbox title uses the default label color.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: No fixed size. Row height comes from the default row size style of the source list. The sidebar fills its container and shows a vertical scroller.

## States

| State | Appearance change |
|-------|------------------|
| Default | Account groups shown expanded with their mailboxes beneath. |
| Pressed | Not applicable: the sidebar has no pressed styling of its own; the outline's standard row highlight applies. |
| Disabled | Not applicable: the source has no disabled state for the sidebar. |
| Focused | The selected row uses the source list's standard selection look; the source sets no custom focus styling. |
| Loading | Not applicable: the source shows no loading indicator; with no accounts the outline simply has no rows. |
| Empty | With no accounts the outline has no rows; the source draws no empty label. |
| Selected mailbox | The row matching the model's `selectedMailbox` is selected in the outline. |
| Mailbox with unread | The row shows a trailing count in secondary color. |
| Mailbox without unread | The row shows no count when the count is absent or zero. |

## Accessibility

- **role**: The sidebar is a standard outline, so it carries the platform outline role. The source sets no other role.
- **outline-identifier**: The outline's accessibility identifier is `mail.sidebar`.
- **row-label**: A mailbox row's accessibility label is the mailbox title. The unread count is not part of it. The mailbox symbol is created with no accessibility description.
- **keyboard-navigation**: The source adds no key handling; arrow-key navigation, expand and collapse come from the platform outline. Group rows are not selectable, so keyboard selection lands only on mailbox rows.
- **unread-count-announcement**: NEEDS REVIEW: Not implemented in source. The unread count is drawn as visible text but the row's accessibility label is only the title, so a screen reader may not announce it. A screen-reader pass over the mail window would settle whether the label needs the count.
- **account-row-label**: The account group row sets no accessibility label of its own; it exposes the email text of its text field, and the source adds no role or description marking it as an account.
- **tap-target**: The source states no target size; rows use the source list's default row height.
- **contrast**: NEEDS REVIEW: Not implemented in source. Account email and counts use the system secondary label color; whether it meets contrast on the sidebar material in every appearance and selection state needs a contrast measurement.

## Conformance Test Vectors

The view controller has no test of its own. The model it reads has tests in `MailBrowserModelTests`, notably `mailboxesFollowGmailsOrderAndSkipAttributeLabels`, which asserts depths of `0, 0, 0, 0, 1, 0, 0` and an inbox unread count of 3; the rows below that name no test are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mail-sidebar-001 | account-groups, mailbox-children | Two accounts, the first with Inbox and Sent, the second with Inbox | Two group rows, with two mailbox rows under the first and one under the second. |
| mail-sidebar-002 | mailbox-children | An account whose id has no entry in `mailboxes` | Its group row shows with no children. |
| mail-sidebar-003 | expand-on-rebuild, rebuild-on-model | The model's `accounts` changes | The outline reloads and every group is expanded. |
| mail-sidebar-004 | account-row-text | Account email `me@example.com` | Group row text reads `me@example.com`, small system font, semibold, secondary color. |
| mail-sidebar-005 | mailbox-row-symbol | Label ids `INBOX`, `STARRED`, `IMPORTANT`, `SENT`, `DRAFT`, nil, `SPAM`, `TRASH`, `Label_9` | Symbols `tray`, `star`, `exclamationmark.circle`, `paperplane`, `doc`, `tray.full`, `xmark.bin`, `trash`, `tag`. |
| mail-sidebar-006 | mailbox-row-indent | Mailbox with depth 1 (the nested `Work/Clients` label from `mailboxesFollowGmailsOrderAndSkipAttributeLabels`) | Row content starts 14 points from the leading edge. |
| mail-sidebar-007 | mailbox-row-indent | Mailbox with depth 0 | Row content starts at the leading edge. |
| mail-sidebar-008 | mailbox-row-unread-count | Mailbox with unread 3 | A trailing label reads `3`. |
| mail-sidebar-009 | mailbox-row-unread-count | Mailbox with unread 0 | No count label. |
| mail-sidebar-010 | mailbox-row-unread-count | Mailbox with unread nil (All Mail) | No count label. |
| mail-sidebar-011 | only-mailboxes-selectable | User clicks an account group row | The selection does not change and the model is not called. |
| mail-sidebar-012 | selection-to-model | User clicks the Sent row of account `a1` | The model's `select(mailbox:)` is called with account id `a1` and label id `SENT`. |
| mail-sidebar-013 | selection-from-model, selection-echo-guard | The model sets `selectedMailbox` to account `a1`, label `INBOX` | The Inbox row of `a1` is selected and `select(mailbox:)` is not called by the sidebar. |
| mail-sidebar-014 | selection-from-model | Two accounts both have an Inbox; the model selects the second account's Inbox | The second account's Inbox row is selected, not the first. |
| mail-sidebar-015 | selection-from-model | The model selects All Mail (label id nil) | The All Mail row is selected. |
| mail-sidebar-016 | selection-no-match | The model's `selectedMailbox` is nil | The outline selection is unchanged. |
| mail-sidebar-017 | selection-no-match | The model selects a mailbox that is not listed | The outline selection is unchanged. |
| mail-sidebar-018 | selection-no-op | The model sets `selectedMailbox` to the row already selected | No selection call reaches the outline. |
| mail-sidebar-019 | selection-clear-ignored | The outline selection clears | The model is not called. |
| mail-sidebar-020 | accessibility-identifier | Inspect the outline | Identifier is `mail.sidebar`. |
| mail-sidebar-021 | mailbox-accessibility-label | Mailbox titled `Inbox` | Row accessibility label is `Inbox`. |
| mail-sidebar-022 | single-column-outline, source-list-style | Inspect the outline | One column `mailbox`, no header, source list style, group rows do not float. |
| mail-sidebar-023 | model-injection | Build the controller from a coder | The process stops with the fatal error `init(coder:) has not been implemented`. |
| mail-sidebar-024 | selection-single | Inbox row selected; the model selects the Sent row | Only the Sent row is selected. |
| mail-sidebar-025 | mailbox-row-title-yields | A mailbox with a long title and unread 12 in a narrow sidebar | The title truncates at the tail; the symbol and the `12` count stay fully visible. |
| mail-sidebar-026 | account-row-truncation | Account email longer than the sidebar width | The group row text truncates at the tail. |
| mail-sidebar-027 | main-queue-hop | The model publishes `accounts` from a background queue | The rebuild runs on the main queue. |
| mail-sidebar-028 | selection-after-rebuild | Inbox of `a1` is selected, then the model's `mailboxes` changes | After the reload the Inbox row of `a1` is selected again. |
| mail-sidebar-029 | empty-accounts | The model has no accounts | The outline has zero rows and no message is drawn. |
| mail-sidebar-030 | group-expandable-with-children | One account with no mailboxes and one with Inbox | The first group row is not expandable; the second is. |
| mail-sidebar-031 | unread-count-plain-integer | Mailbox with unread 1234 | The count label reads `1234`. |
| mail-sidebar-032 | selection-task-unhandled | The model's `select(mailbox:)` fails and sets `errorMessage` | The sidebar shows no error itself and the model's `errorMessage` is set. |
## Edge Cases

- **No accounts**: With no accounts the outline has zero rows and no message is drawn (empty-accounts; mail-sidebar-029).
- **Account with no mailboxes**: The group row shows with no children and is not expandable (mail-sidebar-002, mail-sidebar-030; group-expandable-with-children).
- **Unread zero or absent**: A count of zero or nil MUST draw no count label (mail-sidebar-009, mail-sidebar-010).
- **Unknown label**: A label id with no symbol of its own MUST show the tag symbol (mail-sidebar-005).
- **Deep nesting**: Indentation grows by 14 points per depth level with no upper bound in the source, so a deep label can push its title off the row; the title truncates at the tail.
- **Selection not listed**: When the selected mailbox is nil or not in the list, the sidebar MUST leave the outline selection alone rather than clear it (mail-sidebar-016, mail-sidebar-017).
- **Selection echo**: The sidebar MUST suppress the selection callback while it applies the model's selection (mail-sidebar-013).
- **Selection cleared by the outline**: A cleared outline selection sends nothing to the model, so the model keeps its selected mailbox (mail-sidebar-019).
- **Rebuild resets expansion**: The source tracks no expansion state, and each rebuild expands every group again (expand-on-rebuild), so a group the user collapsed re-expands the next time accounts or mailboxes change.
- **Selection after rebuild**: Rebuilding re-applies the model's selection, so the selected row survives a reload (selection-after-rebuild; mail-sidebar-028).
- **Selection task**: Selecting a mailbox starts an unstructured task that awaits the model; the sidebar does not wait for it or handle its failure. Errors reach the user through the model's `errorMessage`, not through this controller (selection-task-unhandled; mail-sidebar-032).
- **Concurrent access**: The controller and its model are main-actor isolated; model changes arrive on the main queue, and the selection call runs in a task that awaits the main-actor model.
- **Offline or disconnected**: Not applicable to this controller: it makes no network call and only displays what the model holds.

## Configuration

The controller takes only a `MailBrowserModel` at construction and exposes no options. The column identifier, source list style, indent of 14 points per depth and the symbol table are fixed in the source.

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
| none (model data) | Mailbox title | Mailbox row title, supplied by the model |
| none (model data) | Account email | Account group row text, supplied by the model |

The controller has no literal user-facing text of its own: titles and addresses come from the model. The unread count is formatted as a plain integer string with no locale formatting.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the controller runs no animation of its own. |
| Increase Contrast | Not applicable: the controller sets no contrast-specific values; the system colors adapt on their own. |
| Differentiate Without Color | The sidebar uses color only for the accent tint on mailbox symbols; each symbol is also a distinct shape, and the selected row is shown by the source list's standard selection look. |

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

- **Data collected**: None by this controller. It displays account email addresses and mailbox names the model already holds.
- **Storage**: None. The controller keeps no copy beyond its row nodes, which are rebuilt on each change.
- **Transmission**: None. It makes no network call.
- **Retention**: None.

## Logging

Not applicable: the source writes no log lines.

| Event | Level | Message |
|-------|-------|---------|
| none | n/a | The controller logs nothing. |

## Platform Notes

- **SwiftUI**: Start from a `List` with the `.sidebar` style and a `Section` per account whose header is the email, with a `Label` per mailbox (symbol and title) and a `.badge` for the unread count. A selection binding of the mailbox id replaces the manual echo guard, and `.selectionDisabled` on headers matches the group rows. Indent by depth with `.padding(.leading)` or nest the rows in `OutlineGroup`.
- **Compose**: Start from a `LazyColumn` with a header item per account and an item per mailbox, a leading `Icon`, a title `Text` with `maxLines = 1` and `TextOverflow.Ellipsis`, and a trailing count `Text`. Indent with `Modifier.padding(start = 14.dp * depth)`, highlight the row matching the selected id, and set `Modifier.semantics` with `contentDescription` to the title. Header items take no click handler, so they are not selectable.
- **React/Web**: Start from a `role="tree"` with a `role="group"` per account and `role="treeitem"` mailboxes carrying `aria-selected`, with `aria-label` set to the title. Truncate with CSS `text-overflow: ellipsis`, indent with a depth custom property, and render the count in a span beside the title. Account headers are plain non-focusable elements.
- **AppKit / UIKit**: The source is the implementation recorded for this recipe in `index.json`: an `NSViewController` that is its own `NSOutlineViewDataSource` and delegate, with a private class `Node` because the outline tracks items by identity, a private `NSTableCellView` subclass for the mailbox row, and Combine sinks on the model's published properties. Its specific pieces are `isGroupItem` for accounts, `shouldSelectItem` limiting selection to mailboxes, and the `applyingSelection` flag around programmatic selection. On UIKit the equivalent is a `UICollectionView` with a sidebar list configuration, `UICollectionViewDiffableDataSource` with section snapshots (headers as expandable parents), and cell registrations for rows.
- **WinUI 3**: Use a `TreeView` (or `NavigationView` with `MenuItemsSource`) bound to a collection of account nodes whose `Children` are mailbox nodes, with `SelectionMode="Single"`. Use an `ItemTemplate` per level through a `TreeViewItemTemplateSelector`: the account template is a `TextBlock` with `FontSize="12"`, `FontWeight="SemiBold"`, `Foreground="{ThemeResource TextFillColorSecondaryBrush}"` and `TextTrimming="CharacterEllipsis"`, and the mailbox template is a `Grid` with an `Auto` column for a `FontIcon` or `SymbolIcon` filled with `AccentFillColorDefaultBrush`, a `*` column for a trimmed `TextBlock` title, and an `Auto` column for the unread count `TextBlock` whose `Visibility` is bound to count greater than zero. Indent by depth with `Margin` on the template (14 epx times depth) or by nesting nodes, and set `IsExpanded="True"` on each account node. Disable selection of account nodes by handling `ItemInvoked` and ignoring them, or by using `NavigationViewItemHeader` for accounts in `NavigationView`. Set `AutomationProperties.Name` on the mailbox template to the title for Narrator. `TreeViewItem` supplies the `PointerOver`, `Pressed` and `Selected` visual states, and arrow keys expand, collapse and move selection.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Integrations/Mail/MailSidebarViewController.swift` | unverified |
| ios | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The controller reads and calls the model only; it holds no mail state and no networking.
**Rationale**: The model's actions are the tested unit, so the sidebar only displays its published `accounts`, `mailboxes` and `selectedMailbox` and calls `select(mailbox:)`.
**Approved**: pending

**Decision**: Outline rows are instances of a private class, not values.
**Rationale**: The source comment states the outline tracks items by identity, so each rebuild creates new node objects and reloads the outline.
**Approved**: pending

**Decision**: A flag, `applyingSelection`, silences the selection callback while the model's selection is applied.
**Rationale**: Without it, applying the model's selection would call `select(mailbox:)` back and loop between outline and model; the source comment states the change is not sent back.
**Approved**: pending

**Decision**: Selection is matched on account id and label id, not on mailbox identity.
**Rationale**: Two accounts can each have a mailbox with the same label id, such as `INBOX`, so the label id alone would select the wrong row; All Mail has a nil label id and still matches by account.
**Approved**: pending

**Decision**: When the model's selection matches no row, the sidebar leaves the outline selection as it is.
**Rationale**: The source returns early rather than clearing the selection; this keeps the previous row highlighted until the model selects a listed mailbox, which is intended, observable behavior that implementations copy.
**Approved**: pending

**Decision**: Each rebuild expands all account groups, discarding any collapse by the user.
**Rationale**: The source expands every root after each reload and tracks no expansion state, so a group the user collapsed re-expands when the model changes. This is intended behavior of the sidebar, so every port copies it.
**Approved**: pending

**Decision**: Mailbox rows indent by 14 points times depth inside the cell, not through the outline's own indentation.
**Rationale**: Mailboxes are one outline level below accounts, and the model supplies a depth for nested labels, so the cell draws the extra indent itself.
**Approved**: pending

**Decision**: Mailbox symbols are chosen by a fixed switch on label id with a tag as the fallback.
**Rationale**: System labels have a known symbol and every user label shares the tag, so no symbol is stored in the model.
**Approved**: pending

**Decision**: The view controller has no test of its own; coverage comes from the model's tests of mailbox ordering, depth and unread counts.
**Rationale**: `MailBrowserModelTests` covers the data the sidebar displays, and no test builds this view controller.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | accessibility |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | failed | internationalization |

The controller only displays model state and forwards one call, so separation of concerns passes. Unit-test coverage is partial: the model's mailbox building has tests, while the controller and its cells have none. Screen-reader support is partial because mailbox rows have a title label but no unread count and the account group sets no label of its own. Keyboard navigation passes through the native outline, with no custom handling. It uses `NSOutlineView` in the source list style with system fonts and colors, so native controls pass. Locale-aware formatting fails because the unread count is built with plain string interpolation, not a number formatter.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
