---
id: b3edb32d-7473-464b-acfb-c19cdd44e99e
title: "Mail Browser Model"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Main-actor model behind the mail window: mailboxes, paged messages, open message, read marking, sync refresh."
platforms:
  - swift
  - macos
tags:
  - integrations
  - mail
  - view-model
  - gmail
depends-on:
  - fc9671be-170c-436e-9628-892624952191
related:
  - aed9acc9-6340-487b-acfb-b7b13f14e59a
  - 018e4a69-cbeb-4105-8f39-dae3e6f7d8ec
  - 26473390-9629-40f0-ae98-32ccab2fc5da
  - 83a5a5e0-3337-4aff-aef8-40a7393dabfe
  - ac5b0100-ea5d-4abf-a9aa-11a477878514
references: []
approved-by: ""
approved-date: ""
---

# Mail Browser Model

## Overview

`MailBrowserModel` is the state behind the mail window. It holds the accounts, each account's sidebar mailboxes, the selected mailbox's messages a page at a time, and the open message. The source comment says "Every action the window offers goes through here, so this is the tested unit; the view controllers only read it and call it."

It is a `@MainActor` `ObservableObject` built on a `MailClient` given at initialization. A mailbox is a Gmail label, or All Mail (a mailbox with no label id). The model also supplies the display text the list and reader show: the sender name, the list date and the full date. It reads through the client (its sync poll reads only the local store) and marks a message read when it is opened.

## Behavioral Requirements

- **main-actor-isolation**: The model MUST be isolated to the main actor.
- **injected-client**: The model MUST send every service call through the `MailClient` given at initialization.
- **page-size-default**: The model MUST use `MailMessageFilter.defaultLimit` as the page size when none is given at initialization.
- **published-state**: The model MUST publish `accounts`, `mailboxes`, `selectedMailbox`, `messages`, `hasMore`, `selectedMessageId`, `openedMessage`, `loading` and `errorMessage`, and MUST allow them to be set only from inside the model.
- **reload-provider-status**: `reload` MUST read the provider status from the client before reading accounts.
- **reload-accounts-only-when-configured**: `reload` MUST read the account list only when the provider status reports `configured` as true, and MUST set `accounts` to empty otherwise.
- **reload-mailboxes-per-account**: `reload` MUST read the labels of every loaded account and replace `mailboxes` with one list per account id.
- **reload-loading-flag**: `loading` MUST be true from the start of `reload` until it returns, including when it fails.
- **reload-failure-reported**: When the status, account or label read fails during `reload`, the model MUST set `errorMessage` to the failure's `localizedDescription` and MUST still continue to the selection step.
- **reload-keeps-valid-selection**: When `selectedMailbox` still matches a mailbox after `reload`, the model MUST keep it and MUST reload its first page without closing the open message (the open message still closes when the refreshed list lacks it, as `#requirements/first-page-drops-missing-selection` says).
- **reload-default-selection**: When nothing is selected, or the selection no longer matches a mailbox, `reload` MUST select the first account's Inbox, or its first mailbox when it has no Inbox, or All Mail when that account has no mailboxes loaded.
- **reload-no-accounts**: When `reload` finds no accounts and nothing valid is selected, the model MUST set `selectedMailbox` to nil and MUST clear the list and the open message.
- **mailbox-order**: The mailboxes for an account MUST be ordered Inbox, Starred, Important, Sent, Drafts, then All Mail, then user labels, then Spam, then Trash.
- **mailbox-system-present-only**: A system mailbox MUST appear only when the account's labels include its id.
- **mailbox-all-mail**: All Mail MUST always appear, with a nil label id, the title "All Mail", depth 0 and a nil unread count.
- **mailbox-attribute-labels-omitted**: Labels that are neither one of the seven system mailboxes nor of type "user" (for example `UNREAD`, `CATEGORY_*`, `CHAT`) MUST NOT appear as mailboxes.
- **mailbox-user-sorted**: User labels MUST be sorted ascending by name using localized standard comparison.
- **mailbox-nested-title**: A user label's title MUST be the last part of its name split on "/", and its depth MUST be the number of parts minus one.
- **mailbox-duplicate-label**: When two labels share an id, the model MUST use the first one for the system mailbox lookup.
- **mailbox-unread-count**: A system or user mailbox MUST carry its label's `messagesUnread` as its unread count.
- **select-mailbox-first-page**: `select(mailbox:)` MUST set `selectedMailbox`, empty the list, close the open message and load the mailbox's first page.
- **select-mailbox-noop**: `select(mailbox:)` MUST do nothing when the mailbox is already selected and the list is not empty.
- **select-mailbox-reselect-empty**: `select(mailbox:)` MUST reload when the mailbox is already selected and the list is empty.
- **all-mail-no-label-filter**: Listing All Mail MUST send a message filter with no labels.
- **mailbox-label-filter**: Listing any other mailbox MUST send a message filter with that mailbox's label id as its only label.
- **filter-account**: Every list request MUST name the selected mailbox's account id.
- **first-page-limit**: A first page loaded by selecting a mailbox MUST request `pageSize` messages.
- **refresh-keeps-row-count**: A first page loaded by `reload` while `selectedMailbox` still matches a mailbox MUST request the larger of `pageSize` and the number of messages showing.
- **first-page-replaces**: A loaded first page MUST replace `messages`, `nextCursor` and `hasMore`, with `hasMore` true only when the page has a next cursor.
- **first-page-drops-missing-selection**: When the open message's id is not in a refreshed list, the model MUST close the open message.
- **first-page-failure**: When the first page fails, the model MUST set `errorMessage` to the failure's `localizedDescription`.
- **stale-list-dropped**: A page, or a page failure, that answers a list replaced since the request began MUST be discarded without changing the model.
- **load-more-appends**: `loadMore` MUST request the page named by the stored cursor and append its messages to `messages`.
- **load-more-dedupes**: `loadMore` MUST NOT append a message whose id is already in `messages`.
- **load-more-cursor**: After `loadMore`, `hasMore` MUST be true only when the page has a next cursor.
- **load-more-noop**: `loadMore` MUST do nothing when `hasMore` is false, when a `loadMore` is already running, when no mailbox is selected, when there is no cursor, or when no account in `accounts` has the selected mailbox's account id.
- **load-more-failure**: When the next page fails and the list is unchanged, `loadMore` MUST set `errorMessage` to the failure's `localizedDescription`.
- **select-message-noop**: `select(messageId:)` MUST do nothing when the id equals `selectedMessageId`.
- **select-message-clears-open**: `select(messageId:)` MUST set `selectedMessageId` and set `openedMessage` to nil before loading.
- **select-message-load**: `select(messageId:)` MUST load the full message from the client for the listed message's account and set `openedMessage` to it.
- **select-message-account-by-email**: `select(messageId:)` MUST find the account by matching the listed message's account email, and MUST fall back to the selected account when none matches.
- **select-message-unlisted**: `select(messageId:)` MUST leave `openedMessage` nil, and MUST NOT call the client, when the id is nil, is not in `messages`, or no account can be found for the listed message.
- **select-message-failure**: When the message load fails and the selection has not changed, the model MUST set `errorMessage` to the failure's `localizedDescription`.
- **stale-message-dropped**: A message, or a message failure, that answers a selection replaced since the request began MUST be discarded without changing the model.
- **mark-read-on-open**: When the opened message carries the `UNREAD` label, the model MUST send a modify-labels request for that message that removes `UNREAD` and adds nothing.
- **mark-read-no-request-when-read**: When the opened message does not carry `UNREAD`, the model MUST NOT send a modify-labels request.
- **mark-read-updates-copies**: After marking read, the model MUST copy the returned labels and label names onto the matching message in `messages` and onto `openedMessage`.
- **mark-read-lowers-counts**: After marking read, the model MUST lower by one the unread count of each of the account's mailboxes whose label id is among the opened message's labels.
- **unread-count-floor**: A lowered unread count MUST NOT go below zero.
- **unread-count-nil-untouched**: A mailbox with a nil label id (All Mail) or a nil unread count MUST be left unchanged when counts are lowered.
- **mark-read-superseded**: A modify-labels answer that arrives after another message was opened MUST still be copied onto the matching message in `messages` and lowered into the counts, and MUST be copied onto `openedMessage` only when that is the same message. A failure of that request MUST still set `errorMessage`, because the mark-read call carries no generation check.
- **mark-read-failure**: When the modify-labels request fails, the model MUST set `errorMessage` to the failure's `localizedDescription` and MUST keep the message open.
- **refresh-if-synced**: `refreshIfSynced` MUST call `reload` when any account's `lastSyncAt`, or the set of account ids, differs from the values recorded by the last `reload`.
- **refresh-if-synced-unchanged**: `refreshIfSynced` MUST NOT call `reload` when every account's `lastSyncAt` and the set of account ids match the recorded values.
- **refresh-if-synced-local-only**: `refreshIfSynced` MUST read only the account list from the client.
- **refresh-if-synced-silent**: When reading the accounts fails, `refreshIfSynced` MUST return without setting `errorMessage`.
- **dismiss-error**: `dismissError` MUST set `errorMessage` to nil without making a service call.
- **selected-account**: `selectedAccount` MUST return the account whose id equals the selected mailbox's account id, or nil when none matches.
- **sender-name**: `senderName` MUST return the display name before the last "<", trimmed of whitespace and surrounding double quotes.
- **sender-name-address-only**: `senderName` MUST return the address inside the angle brackets when the display name is empty, and the trimmed input when it has no "<".
- **sender-name-unclosed**: `senderName` MUST return the text after the last "<" with ">" and spaces trimmed from both ends when the display name before it is empty, whether or not a closing bracket follows.
- **list-date-today**: `listDate` MUST show only the hour and minute for a date on the same calendar day as now.
- **list-date-this-year**: `listDate` MUST show the abbreviated month and day for a date in the same year as now but a different day.
- **list-date-older**: `listDate` MUST show the year, abbreviated month and day for a date in a different year from now (earlier or later).
- **list-date-locale**: `listDate` MUST format with the calendar's time zone and the given locale.
- **date-parse-fractional**: The date helpers MUST accept ISO 8601 text with or without fractional seconds.
- **date-unparseable**: `listDate` and `fullDate` MUST return the input text unchanged when it is not ISO 8601.
- **full-date**: `fullDate` MUST return the complete date with the short time (`Date.FormatStyle` date `.complete`, time `.shortened`). It takes no locale or calendar and uses the current ones, so unlike `listDate` it cannot be tested deterministically.
- **is-unread**: `isUnread` MUST be true only when the message's labels contain `UNREAD`.

## Appearance

Not applicable: the model draws nothing. The source comment says "the view controllers only read it and call it", so `MailBrowserViewController`, `MailSidebarViewController`, `MailMessageListViewController` and `MailReaderViewController` own layout, type and color. The model supplies only data and strings.

- **Corner radius**: Not applicable: no visual element.
- **Padding**: Not applicable: no visual element.
- **Font**: Not applicable: no visual element.
- **Background**: Not applicable: no visual element.
- **Foreground/Text**: Not applicable: no visual element.
- **Border**: Not applicable: no visual element.
- **Shadow**: Not applicable: no visual element.
- **Min/Max size**: Not applicable: no visual element.

## States

| State | Appearance change |
|-------|------------------|
| Default | Not applicable: the model has no appearance. Data state: `accounts` and `messages` are empty, `selectedMailbox` and `selectedMessageId` are nil, `hasMore` and `loading` are false and `errorMessage` is nil. |
| Pressed | Not applicable: the model is not a control. |
| Disabled | Not applicable: the model has no disabled state. |
| Focused | Not applicable: the model takes no focus. |
| Loading | `loading` is true for the length of `reload` only. `select(mailbox:)`, `loadMore` and `select(messageId:)` do not set it. |
| Error | `errorMessage` holds the latest failure's `localizedDescription` until `dismissError` or the next failure replaces it; a later success does not clear it. |
| No accounts | `accounts` is empty, `selectedMailbox` is nil and the list and open message are empty. |
| Mailbox selected | `selectedMailbox` is set and `messages` holds the loaded pages; `hasMore` is true while a next cursor exists. |
| Message open | `selectedMessageId` is set; `openedMessage` is nil until the full message loads. |

## Accessibility

Not applicable: the model is not a visual or interactive element, so it has no role, label, focus or tap target. Accessibility belongs to the four view controllers. The model supplies only the strings they present.

## Conformance Test Vectors

Test names are the Swift Testing functions in `MailBrowserModelTests`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mail-browser-001 | reload-default-selection, first-page-replaces, mailbox-label-filter | One account `a1` with labels INBOX, SENT, UNREAD; messages m1 (INBOX) and m2 (SENT); call `reload` (test `reloadSelectsTheFirstAccountsInboxAndListsIt`) | `selectedMailbox` is account `a1` with label `INBOX`; `messages` ids are m1; `hasMore` is false |
| mail-browser-002 | reload-no-accounts, reload-accounts-only-when-configured | No accounts; call `reload` (test `withNoAccountsNothingIsSelected`) | `selectedMailbox` is nil; `messages` is empty; `errorMessage` is nil |
| mail-browser-003 | all-mail-no-label-filter, select-mailbox-first-page | After `reload`, select the mailbox with label id nil (test `allMailListsWithoutALabelFilter`) | `messages` ids are m1, m2; the last list request has no labels |
| mail-browser-004 | load-more-appends, load-more-cursor, load-more-noop, first-page-limit | Five messages, page size 2; `reload`, then `loadMore` three times (test `pagesAppendUntilTheLast`) | After `reload` ids are m1, m2 and `hasMore` is true; after two calls ids are m1 to m5 and `hasMore` is false; the third call sends no request, so three list requests were sent in all |
| mail-browser-005 | select-mailbox-first-page | Open m1, then select the SENT mailbox (test `switchingMailboxesReplacesTheListAndClosesTheMessage`) | `messages` ids are m2; `selectedMessageId` and `openedMessage` are nil |
| mail-browser-006 | stale-list-dropped | Hold the All Mail list request, select SENT, then release the held request (test `aPageForAnEarlierMailboxIsDropped`) | `selectedMailbox` is SENT; `messages` ids are m2 |
| mail-browser-007 | first-page-failure, dismiss-error | The list request fails with "store unavailable"; `reload`, then `dismissError` (test `aFailedListBecomesTheErrorMessage`) | `errorMessage` is "store unavailable", then nil after `dismissError` |
| mail-browser-008 | select-message-load | `reload`, then `select(messageId: "m1")` (test `openingAMessageLoadsItsBody`) | Before: the listed message has no body text; after: `openedMessage` body text is "body m1" |
| mail-browser-009 | mark-read-on-open, mark-read-updates-copies, mark-read-lowers-counts | m1 labeled INBOX and UNREAD, Inbox unread 2; open m1 (test `openingAnUnreadMessageMarksItReadAndLowersTheCount`) | A modify-labels request removes UNREAD from m1; `isUnread` is false for the listed and opened copies; the Inbox unread count is 1 |
| mail-browser-010 | mark-read-no-request-when-read | m1 labeled INBOX only; open m1 (test `openingAReadMessageChangesNoLabels`) | No modify-labels request is sent |
| mail-browser-011 | refresh-if-synced, refresh-if-synced-unchanged, refresh-if-synced-local-only | Store gains m0; `refreshIfSynced` with an unchanged `lastSyncAt`; then `lastSyncAt` becomes "2026-11-07T12:00:00.000Z" and `refreshIfSynced` again (test `aFinishedSyncReloadsTheList`) | First call: ids stay m1. Second call: ids are m0, m1 |
| mail-browser-012 | reload-keeps-valid-selection, refresh-keeps-row-count | Open m1, change `lastSyncAt`, call `refreshIfSynced` (test `aRefreshKeepsTheOpenMessage`) | `selectedMessageId` is m1 and `openedMessage` id is m1; the refresh list request's limit equals max(pageSize, rows showing) |
| mail-browser-013 | mailbox-order, mailbox-attribute-labels-omitted, mailbox-nested-title, mailbox-user-sorted, mailbox-unread-count | Labels TRASH, Label_2 "Work/Clients" (user), UNREAD, CATEGORY_UPDATES, SENT, INBOX (3 unread), Label_1 "Work" (user), SPAM (test `mailboxesFollowGmailsOrderAndSkipAttributeLabels`) | Titles are Inbox, Sent, All Mail, Work, Clients, Spam, Trash; depths are 0, 0, 0, 0, 1, 0, 0; Inbox unread is 3 |
| mail-browser-014 | sender-name, sender-name-address-only | "PayPal <service@paypal.com>", "\"Doe, Jane\" <jane@example.com>", "<only@example.com>", "plain@example.com" (test `senderNameTakesTheDisplayName`) | "PayPal", "Doe, Jane", "only@example.com", "plain@example.com" |
| mail-browser-015 | list-date-today, list-date-this-year, list-date-older, list-date-locale, date-parse-fractional | UTC, locale en_US, now 2026-11-07T20:00:00Z; dates 2026-11-07T18:59:24.000Z, 2026-03-02T10:00:00.000Z, 2024-03-02T10:00:00.000Z (test `listDateShowsTimeTodayAndDayOtherwise`) | Today contains "6:59"; this year equals "Mar 2"; older equals "Mar 2, 2024" |
| mail-browser-016 | date-unparseable | `listDate("not a date")` and `fullDate("not a date")` | Both return "not a date" |
| mail-browser-017 | select-mailbox-noop | Account `a1`, `reload` done with messages m1, m2 showing and m1 open; call `select(mailbox:)` with `MailboxID(accountId: "a1", labelId: "INBOX")` again | No list request is sent; `selectedMessageId` is still m1 and `openedMessage` id is m1 |
| mail-browser-018 | load-more-dedupes | Page size 2; `reload` lists m1, m2 with next cursor "c1"; the request with cursor "c1" returns m2, m3 and no next cursor; call `loadMore` | `messages` ids are m1, m2, m3; `hasMore` is false |
| mail-browser-019 | mailbox-system-present-only, mailbox-all-mail | `mailboxes(for: "a1", labels: [UNREAD])` where UNREAD has type "system" | Exactly one row: labelId nil, title "All Mail", depth 0, unread nil |
| mail-browser-020 | refresh-if-synced-silent | `reload` done; `accounts()` then throws "offline"; call `refreshIfSynced` | `errorMessage` is nil; no list request and no labels request is sent after the failure |
| mail-browser-021 | select-message-unlisted | `reload` lists m1, m2; call `select(messageId: "zz")` | `selectedMessageId` is "zz"; `openedMessage` is nil; no `message` request is sent |
| mail-browser-022 | unread-count-floor, unread-count-nil-untouched | Account `a1`; INBOX label with `messagesUnread` 0; m1 labeled INBOX and UNREAD; `reload`, then `select(messageId: "m1")` | Inbox `unread` is 0; the All Mail row's `unread` is nil |
| mail-browser-023 | mark-read-failure | m1 labeled INBOX and UNREAD; the modify-labels request throws "denied"; `reload`, then `select(messageId: "m1")` | `errorMessage` is "denied"; `openedMessage` id is m1 |
| mail-browser-024 | select-message-account-by-email | Account `a1` (email "a1@example.com") has the selected mailbox; m1 has `account` "other@example.com"; `select(messageId: "m1")` | The `message` request names account `a1` and `openedMessage` id is m1 |
| mail-browser-025 | select-message-clears-open | m1 open; hold the `message` request for m2; call `select(messageId: "m2")` | While held: `selectedMessageId` is m2 and `openedMessage` is nil; after release: `openedMessage` id is m2 |
| mail-browser-026 | sender-name-unclosed | `senderName("<only@example.com")` | "only@example.com" |
| mail-browser-027 | mark-read-superseded | m1 labeled INBOX and UNREAD, Inbox unread 2; m2 already read; hold the modify-labels request for m1; open m1, then open m2, then release the request | The listed m1 no longer has UNREAD; `openedMessage` id is m2; Inbox unread is 1 |
| mail-browser-028 | full-date | `fullDate("2026-11-07T18:59:24.000Z")` | Equals `date.formatted(date: .complete, time: .shortened)` for that date in the current locale; no fixed text is asserted |

Vectors 016 to 028 are derived from the source behavior; the test file has no test for them.

## Edge Cases

- **Empty account list (MUST)**: With no accounts, `reload` clears the list and the open message and sets `selectedMailbox` to nil (`withNoAccountsNothingIsSelected`).
- **Provider not configured (MUST)**: When the status says `configured` is false, `reload` sets `accounts` to empty and reads no labels.
- **Label read fails partway (MAY, known debt)**: Current behavior: a failure on any account's labels abandons the whole mailboxes assignment, so `mailboxes` keeps its earlier value, `errorMessage` is set and `reload` still goes on to the selection step. A previously valid selection is therefore kept and its first page reloaded. A fix should assign `mailboxes` per account as each read succeeds, so one failure does not discard the others; a port may do that instead of copying the abandonment.
- **Accounts replaced on a failed reload (MAY, known debt)**: Current behavior: `accounts` and the recorded sync values are assigned before the labels are read, so a label failure leaves new accounts beside old mailboxes. A fix should assign `accounts`, the recorded sync values and `mailboxes` together after every read succeeds, so a port can repair this rather than copy it.
- **Selection no longer exists (MUST)**: When the selected mailbox is gone after a reload, the first account's Inbox is selected, or its first mailbox when it has no Inbox.
- **Empty first page (MUST)**: A mailbox with no messages gives an empty `messages`, `hasMore` false and no error.
- **Boundary page size (MUST)**: A page with no next cursor sets `hasMore` to false and further `loadMore` calls send no request (`pagesAppendUntilTheLast`).
- **Refresh row count (MUST)**: A refresh asks for the larger of `pageSize` and the rows showing, so the list does not shrink; the cursor then comes from that single larger request.
- **Concurrent selections (MUST)**: A list or message answer for a superseded selection is dropped through the generation counters (`aPageForAnEarlierMailboxIsDropped`). Because the check applies to failures too, a superseded failure never reaches `errorMessage`. The mark-read request is the exception: it has no generation check (see `mark-read-superseded`).
- **Concurrent load more (MUST)**: A second `loadMore` while one is running does nothing.
- **Load more across a refresh (MUST)**: Refreshing or switching the list while `loadMore` is running discards that page, because the list generation has changed.
- **Open message leaves the list (MUST)**: When a refresh no longer contains the open message, the message closes.
- **Message opened from another account (MUST)**: A listed message's account email that matches no account falls back to the selected mailbox's account.
- **Mark read when messages disagree (MUST)**: The copies in `messages` and `openedMessage` take the labels returned by the service, not the locally computed ones.
- **Mark read after another message opened (MUST)**: The labels and the lowered unread counts still apply to the message that was marked, but `openedMessage` keeps the newer message, and a failure of the superseded request still sets `errorMessage`.
- **Unread counts drift (SHOULD)**: Local count changes are an estimate. The next `reload` replaces them with the service's counts.
- **Full date has no injectable locale (MUST)**: `fullDate` always uses the current locale and calendar and the source has no test seam for it, so tests assert only the unparseable path.
- **Unparseable date (MUST)**: `listDate` and `fullDate` return the input text rather than failing.
- **Sender header without a closing bracket (MUST)** (`sender-name-unclosed`): When the display name before the last "<" is empty, `senderName` uses the text after it with ">" and spaces trimmed from both ends.
- **Offline or store unavailable (MUST)**: Every client failure surfaces as `errorMessage`, and the model keeps its previous data, except that selecting a mailbox has already emptied the list and closed the open message before its first page is requested. There is no retry and no backoff; the user's next action or the next sync poll tries again. The one exception is the sync poll, which swallows an account-read failure.
- **Error cleared (MUST NOT)**: A successful call does not clear `errorMessage`; only `dismissError` does.
- **Concurrent access (MUST)**: The model is main-actor isolated, so state changes are serialized. Overlap is possible only across `await` points, which the generation counters and the `loadMore` flag guard.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `client` | `MailClient` | required | The service every call goes through |
| `pageSize` | `Int` | `MailMessageFilter.defaultLimit` | Messages requested per page |

## Deep Linking

Not applicable: the model has no URL handling. Selection is held in `selectedMailbox` and `selectedMessageId` and is not addressable from outside.

## Localization

The source does not localize its strings: the system mailbox titles are fixed English text, and the model never passes them through a localization table. Dates are formatted for the locale given to `listDate`, and `fullDate` uses the current locale.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none) | Inbox | System mailbox title |
| (none) | Starred | System mailbox title |
| (none) | Important | System mailbox title |
| (none) | Sent | System mailbox title |
| (none) | Drafts | System mailbox title |
| (none) | All Mail | Mailbox title with no label |
| (none) | Spam | System mailbox title |
| (none) | Trash | System mailbox title |

## Accessibility Options

Not applicable: the model draws nothing and animates nothing, so Reduce Motion, Increase Contrast and Differentiate Without Color do not reach it. The view controllers own those responses.

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: no animation. |
| Increase Contrast | Not applicable: no color. |
| Differentiate Without Color | Not applicable: no color. |

## Feature Flags

Not applicable: the source reads no feature flag.

## Analytics

Not applicable: the source records no analytics event.

## Privacy

- **Data collected**: Message headers and bodies, sender and account email addresses, and label names, read through the client. The model adds nothing.
- **Storage**: In memory only, for the life of the model. Persistence is the client's concern. The source comment says a sync poll "Reads only the local store, never Gmail".
- **Transmission**: The model sends no data itself. Opening an unread message sends a modify-labels request through the client, which changes the message's labels.
- **Retention**: Until the model is released or the list is cleared, replaced or reloaded.

## Logging

Not applicable: the source writes no log. Failures become `errorMessage` and `refreshIfSynced` drops its failure silently.

## Platform Notes

- **SwiftUI**: Translation note. A SwiftUI view can observe the model directly as an `@ObservedObject` or `@StateObject`, and the display-text helpers are static, so a port may move them into a separate formatter unit.
- **Compose**: Translate to a `ViewModel` exposing a `StateFlow` of one immutable state class, with actions as `suspend` functions on `viewModelScope`. Keep the two generation counters and the `loadMore` flag, because coroutines can overlap. Page with Paging 3 or a manual cursor list. Format dates with `java.time.format.DateTimeFormatter` and a locale.
- **React/Web**: Translate to a hook or store with async actions. Browser code is single-threaded, so keep the generation counters to drop stale responses (an `AbortController` can replace them for fetches). Use `Intl.DateTimeFormat` for the three list-date shapes and for the full date.
- **AppKit / UIKit**: Source platform. The source is `macOS/Features/Integrations/Mail/MailBrowserModel.swift`. It is a `@MainActor` `ObservableObject` with `@Published` properties that have private setters, uses Swift concurrency (`async` functions and `defer`), and has pure `static` helpers for display text. The date helper takes `now`, a `Calendar` and a `Locale` so tests are repeatable; it formats with `Date.FormatStyle`, and parses with `Date.ISO8601FormatStyle`. Tests use Swift Testing with a scripted `MailClient`. Reuse the model unchanged and bind with Combine sinks on the `@Published` properties. The source's view controllers subscribe this way: a source list for the sidebar, a table for messages with a load-more trigger near the end, and a reader.
- **WinUI 3**: Implement as a view-model class (a C# class using CommunityToolkit.Mvvm `ObservableObject` with `[ObservableProperty]` and `AsyncRelayCommand` actions). Bind the sidebar to a `TreeView` through `x:Bind` in `OneWay` mode, using each mailbox's depth as indent, or flatten it into a `ListView` with an `ItemTemplate` whose left margin is `Depth` times a fixed step. Bind messages to a `ListView` with `ItemsSource` set to an `ObservableCollection`, and call the load-more command from `IncrementalLoadingTrigger` or an `ISupportIncrementalLoading` collection, using `HasMore` as the guard. Bind `SelectedItem` one way to the model and send changes through the select command, because the model decides what a selection means. Marshal each await back with `DispatcherQueue.TryEnqueue`, which stands in for main-actor isolation, and keep the two generation integers to drop stale results. Show `ErrorMessage` in an `InfoBar` with `IsOpen` bound to a non-empty value and its `CloseButtonClick` calling dismiss. Drive `loading` with a `ProgressRing`. Format the list date with `DateTimeFormatter` or `DateTimeOffset.ToString` using the current culture, and keep the mailbox titles as fixed English text, as the source does.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Integrations/Mail/MailBrowserModel.swift` | unverified |
| ios | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Every list and message answer is guarded by a generation counter (`listGeneration`, `messageGeneration`) rather than cancelling the request.
**Rationale**: The source comment says the counter is bumped "whenever the list is replaced, so a page answering an older selection is dropped." The model never cancels a request; it ignores the stale answer when it arrives. The trade-off: a cancelled request needs a cancellation path through the client and the transport, while an ignored answer costs only a wasted round trip and keeps the model independent of how the client works. A port with cheap cancellation may cancel too, but it must still guard against a late answer.
**Approved**: pending

**Decision**: A refresh keeps as many rows as were showing and does not clear the list or the open message.
**Rationale**: The source comment says "A refresh keeps as many rows as were showing, so the list does not shrink under the user." A sync therefore does not disturb reading. The trade-off: the refresh request grows with the list, and a refresh keeps the old row count instead of returning to one page.
**Approved**: pending

**Decision**: The selected mailbox is held by identity only (`MailboxID`), not as a `Mailbox`.
**Rationale**: The source comment says this is "so a reload that changes counts keeps it." Counts change whenever a sync brings new mail. Holding the whole `Mailbox` would make every count change look like a different selection and drop the list and the open message.
**Approved**: pending

**Decision**: The sync poll reads only the account list and compares `lastSyncAt` values, and swallows its own failure.
**Rationale**: The source comment says it "Reads only the local store, never Gmail", so polling is cheap. A poll failure is not shown to the user, which differs from every other action, and the next poll tries again. The trade-off: a silent poll never interrupts the reader with an error for a background check, at the cost that a persistently failing store is invisible until the user acts.
**Approved**: pending

**Decision**: Unread counts are lowered locally when a message is marked read, for every mailbox whose label the message carries (including user labels and Starred), and are left to the next sync to correct.
**Rationale**: The source comment says this keeps counts "in step with a read made here, until the next sync brings Gmail's own counts." It is an estimate, and the decrement applies to the labels of the message as loaded, before the read.
**Approved**: pending

**Decision**: `loading` covers `reload` only.
**Rationale**: Mailbox switches, paging and opening a message do not set it, so a view that shows progress for those needs its own signal. Setting it for paging or opening would flash a progress indicator for small, frequent actions, but the cost is that a view wanting one must track its own signal.
**Approved**: pending

**Decision**: Errors are only ever set, never cleared by a later success, and failures during `reload` do not stop it from choosing a selection.
**Rationale**: `errorMessage` stays until `dismissError`, so a failure is not hidden by the next success. Continuing after a failure lets a transient label error still show the list.
**Approved**: pending

**Decision**: The status, account and label reads of `reload` share one error path; the first failure abandons the rest of that step.
**Rationale**: The source wraps status, accounts and labels in one `do` block, so a failure leaves `mailboxes` unchanged while `accounts` may already be new. This is technical debt that affects behavior, recorded here so a port does not smooth it over.
**Approved**: pending

**Decision**: The sender name, the list date, the full date and the unread test stay in the model as static functions instead of a separate formatter.
**Rationale**: They are pure and hold no state, so they test without a client, and keeping them beside the model gives the view controllers one import. The cost is that the model has two concerns; a port may move them into their own unit without changing behavior.
**Approved**: pending

**Decision**: System mailbox titles are fixed English strings.
**Rationale**: The source holds a private table and does not localize it. A port that localizes them changes a visible string, so every port keeps the English titles unless the owner approves a change. Fixed titles keep the sidebar identical across ports, at the cost of the failed no-hardcoded-strings check.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.access-patterns.pagination-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/e29ce31a-67cb-5690-b2ca-b1065ccdaf1a) | passed | Access Patterns |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | passed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

The model holds all state and every action while the view controllers only read it and call it, so separation of concerns passes. Unit test coverage is partial: the tests cover loading, paging, stale answers, opening, read marking, sync refresh, mailbox order, sender names and the list date, but not `loadMore` failures, `fullDate`, the account fallback, the unparseable date path or the unread floor. Error handling is partial because every failure is surfaced as `errorMessage` except the sync poll, which drops its failure with no signal. Pagination passes through the cursor, the `hasMore` flag and the de-duplicating append. Locale-aware formatting passes because the date helpers format through `Date.FormatStyle` with a locale and calendar. Hardcoded strings fail because the system mailbox titles and "All Mail" are fixed English text in the model.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
