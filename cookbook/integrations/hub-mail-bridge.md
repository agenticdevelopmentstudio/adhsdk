---
id: e12914f0-3a3b-4fb7-ac0c-6332de37de4f
title: "Hub Mail Bridge"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Answers the mail RPC (MailRequest / MailResponse) from the hub-sourced mail mirror, so the macOS mail browser, Email App and settings panel read hub mail through the same MailClient they use for the direct Gmail worker."
platforms:
  - swift
  - macos
tags:
  - integrations
  - mail
  - hub
  - adapter
depends-on:
  - a6442464-e17d-451e-b47a-3be23a2dc753
  - fc9671be-170c-436e-9628-892624952191
related:
  - aed9acc9-6340-487b-acfb-b7b13f14e59a
  - b3edb32d-7473-464b-acfb-c19cdd44e99e
references: []
approved-by: ""
approved-date: ""
---

# Hub Mail Bridge

## Overview

The macOS mail UI (the mail browser, the Email Desktop App and the Integrations settings panel) talks to mail through one seam: a `MailClient` built over a transport that carries an encoded `MailRequest` ([adhsdk.ingredient.integrations.service.mail-rpc](cookbook:fc9671be-170c-436e-9628-892624952191)) and brings back a `MailResponse`. The direct Gmail worker answers that RPC inside `temporald`. `HubMailBridge` answers the same RPC from the hub mail mirror ([adhsdk.ingredient.integrations.hub-mail](cookbook:a6442464-e17d-451e-b47a-3be23a2dc753)) instead, so the host switches a window between hub and direct mail by handing it a different `MailClient`, and none of the UI changes.

It lives in its own macOS-only framework, `AgenticDeveloperHubSDKHubMailBridge` (`HubMailBridge/`), because it is the one place that needs both sides: the mail RPC types from the macOS-only `AgenticDeveloperHubSDKIntegrations` and the hub mirror from the multi-platform `AgenticDeveloperHubSDKHubMail`. Neither of those links the other. iOS reads `HubMailStore` directly and never links this.

What it does with each request:

- **Mailbox reads** (accounts, labels, messages, one message, a thread) are answered from `HubMailStore`, mapped into the RPC's types.
- **Label writes** (modify labels, move) go to the hub's `modify_labels` integration action, and the hub's worker applies them in Gmail. The bridge then writes the same change into the local mirror, because the hub action leaves the hub's own row as it is until the worker's next sync.
- **Sync now** runs a pull.
- **Administration** (the OAuth client, signing accounts in and out, sync settings) is refused: on the hub path those are managed on the hub.

## Behavioral Requirements

- **one-entry-point**: `respond(to:)` MUST answer every `MailRequest` with a `MailResponse` and never throw; a failure becomes `.failure(message)`, and a missing account, message or thread becomes `.notFound(message)`.
- **client-transport**: `client` MUST be a `MailClient` whose transport decodes the request with `JSONDecoder`, answers it with `respond(to:)` and encodes the response with `JSONEncoder`, the same coding the daemon transport uses.
- **provider-configured**: `providerStatus` MUST answer configured with no client id, because the OAuth client is the hub's, not the app's.
- **admin-refused**: `importOAuthClient`, `removeProvider`, `signIn`, `cancelSignIn`, `removeAccount` and `updateSettings` MUST answer `.failure` saying Gmail accounts are managed on the hub, and change nothing.
- **accounts-from-connections**: `listAccounts` MUST answer one account per connection in `HubMailStore.connections()`, in that order, with the connection id as `id`, status active, default sync settings, and no last sync or error.
- **account-address**: An account's `email` MUST be the address of the `from` of its newest live message labelled `SENT` (the part inside `<…>` when there is one), lowercased; with no such message it MUST be the connection id.
- **account-lookup**: An `account` argument MUST match a connection by id, else by its derived address ignoring case; no match MUST answer `.notFound("unknown account: …")`.
- **labels-mapped**: `listLabels` MUST answer the connection's labels in the store's order, each with the provider label id as `id` and its name, type, parent name and counts.
- **label-resolution**: A label argument MUST resolve to a provider label id by exact id, else by exact (case-sensitive) name, among the connection's labels, without duplicates; any other value MUST answer `.failure("unknown label: …")`.
- **messages-filtered**: `listMessages` MUST answer the connection's live messages newest first, narrowed to those carrying every label in `labels`, at least one label in `anyLabels` when it is non-empty, and an `internal_date` within `since`...`until` (inclusive) when given, a page of at most the filter's clamped `limit`.
- **opaque-cursor**: `nextCursor` MUST be set exactly when more messages follow, as an opaque string that the same filter takes back as `cursor` to continue; a cursor that does not decode MUST answer `.failure("bad cursor")`.
- **any-labels-applied**: The page MUST set `appliedAnyLabels` when `anyLabels` resolved to at least one label.
- **query-refused**: A filter with a non-blank `query` MUST answer `.failure` saying search is not available for mail read through the hub, because the mirror cannot run Gmail's search syntax and a local text match would silently misread it.
- **bodies-on-request**: Message bodies MUST be included only when asked: always for `getMessage`, per `includeBodies` for `listMessages` and `getThread`. The text body is `body_text` unless it is blank, then the HTML body read as text.
- **message-mapping**: A message MUST map with the hub row id as `id`, the provider id as `gmailId`, the thread id (empty when missing), the account's address, `from` (empty when missing), recipients, label ids and their names (a label with no known name keeps its id), subject and snippet (empty when missing, the snippet's HTML entities decoded), `internal_date` as `date` (empty when missing), the class from `MailClassifier.classify(labelIds:)`, and the attachment references decoded from the attachments JSON (none when it does not decode).
- **message-lookup**: A message id MUST match a live message of the connection by hub row id, else by provider id; no match MUST answer `.notFound("unknown message: …")`.
- **thread-lookup**: `getThread` MUST take a thread id, or a message id standing for that message's thread, and answer the thread's live messages oldest first with the thread id as `id`; neither MUST answer `.notFound("unknown thread: …")`.
- **modify-through-hub**: `modifyLabels` MUST resolve every message and label first, then post one `modify_labels` action for the connection with the messages' provider ids and the resolved add and remove ids, then write the same change into the mirror, and answer the messages as they now stand, in request order. With nothing to add or remove it MUST post nothing and answer the messages unchanged.
- **move-through-hub**: `moveMessages` MUST add `destination` and remove every label in `from`, where a `nil` `from` means INBOX, or nothing when the destination is INBOX. A destination that is also in `from` MUST answer `.failure`. Only messages the move changes MUST be written, in one action; every message MUST get a result naming, by label name, what was added and removed.
- **write-failure**: When the hub refuses a label write or answers not ok, the bridge MUST answer `.failure` with the hub's reason and leave the mirror unchanged.
- **mirror-write**: Writing a label change into the mirror MUST keep each row's sync version, so the next pull of that row from the hub replaces it.
- **sync-now**: `syncNow` MUST run one pull through the hub sync, for any account argument, and answer `.ok`.

## Appearance

Not applicable: the bridge draws nothing. The mail browser renders what it answers.

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
| Empty mirror | Accounts and labels are empty lists; every account lookup is not found. |
| Synced | Reads answer from the mirrored rows. |
| Label write pending | Between the action and the worker's next sync, the mirror holds the bridge's own write. |

## Accessibility

Not applicable: no visual or interactive element.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hub-mail-bridge-001 | provider-configured | `providerStatus` | configured, no client id |
| hub-mail-bridge-002 | admin-refused | `signIn`, `removeAccount`, `updateSettings`, `importOAuthClient` | each `.failure`; the mirror is unchanged |
| hub-mail-bridge-003 | accounts-from-connections, account-address | Connection `c1` with a SENT message from `Me <Me@X.com>`, connection `c2` with none | accounts `c1` (`me@x.com`) and `c2` (`c2`), active |
| hub-mail-bridge-004 | account-lookup | `listLabels` for `ME@x.com`, then for `nobody` | the labels of `c1`; then not found |
| hub-mail-bridge-005 | labels-mapped | Labels `INBOX` (system) and `Label_1` "Work" | `INBOX`, then `Label_1` named "Work" |
| hub-mail-bridge-006 | messages-filtered, label-resolution | Filter `labels: ["Work"]` over messages with and without `Label_1` | only the `Label_1` messages |
| hub-mail-bridge-007 | messages-filtered, any-labels-applied | `anyLabels: ["INBOX", "SENT"]` | messages carrying either, `appliedAnyLabels` true |
| hub-mail-bridge-008 | messages-filtered | `since`/`until` around one of three dates | only that message |
| hub-mail-bridge-009 | opaque-cursor | Three messages, limit 2, then the cursor back | 2 then 1, the second page's cursor nil |
| hub-mail-bridge-010 | opaque-cursor | Cursor `"zzz"` | `.failure("bad cursor")` |
| hub-mail-bridge-011 | query-refused | `query: "from:a"` | `.failure`; `query: "  "` lists normally |
| hub-mail-bridge-012 | label-resolution | `labels: ["Nope"]` | `.failure("unknown label: Nope")` |
| hub-mail-bridge-013 | bodies-on-request, message-mapping | `getMessage` by provider id for a message with only an HTML body | the hub row id, the provider id, the label names, the HTML read as text |
| hub-mail-bridge-014 | bodies-on-request | `listMessages` without `includeBodies` | no bodies |
| hub-mail-bridge-015 | thread-lookup | `getThread` by a message id of a three-message thread | the three, oldest first, `id` the thread id |
| hub-mail-bridge-016 | modify-through-hub, mirror-write | Add "Work", remove `INBOX` on one message | one write with the provider id, `["Label_1"]`, `["INBOX"]`; the answer and a re-read show the new labels; the row's sync version is unchanged |
| hub-mail-bridge-017 | modify-through-hub | Nothing to add or remove | no write; the message unchanged |
| hub-mail-bridge-018 | move-through-hub | Move two messages, one already in "Work" and out of INBOX, to "Work" | one write for the other message only; results name `Work` added and `INBOX` removed for it, nothing for the first |
| hub-mail-bridge-019 | move-through-hub | Move to INBOX from `["INBOX"]` | `.failure` |
| hub-mail-bridge-020 | write-failure | The writer throws | `.failure` with its message; the mirror unchanged |
| hub-mail-bridge-021 | sync-now | `syncNow(account: nil)` | the pull ran once; `.ok` |
| hub-mail-bridge-022 | client-transport | `MailClient` from `client` calls `accounts()` | the same accounts as `listAccounts` |

## Edge Cases

- A `from` with no angle brackets is used whole, trimmed and lowercased.
- Two connections that derive the same address both list; a lookup by that address takes the first in connection order, and a lookup by id is always exact.
- A message id that matches no live row is not found; the bridge cannot read Gmail directly, so a message the hub has not synced is not reachable.
- A label change written into the mirror is replaced by the hub's row on the next pull that carries it; until the worker syncs, a pull that carries an older copy of the row puts the old labels back.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| store | `HubMailStore` | required | The mirror the bridge reads and writes label changes into. |
| writeLabels | `@Sendable (HubMailLabelWrite) async throws -> Void` | required | Posts one `modify_labels` action; production passes `HubMailSender.modifyLabels`. |
| syncNow | `@Sendable () async -> Void` | required | Runs one pull; production passes `HubMailSync.syncNow`. |

## Deep Linking

Not applicable: no URL is handled.

## Localization

Not applicable: failure messages are the RPC's developer-facing reasons, in English like the direct service's.

## Accessibility Options

Not applicable: no visual element.

## Feature Flags

Not applicable: the host chooses between the bridge's client and the daemon's.

## Analytics

Not applicable: no event is recorded.

## Privacy

- **Data collected**: None of its own: it reads the hub mail mirror and passes label changes to the hub.
- **Storage**: Writes label changes into the mirror the host already keeps.
- **Transmission**: Label writes go to the hub's action route through the host's hub client.
- **Retention**: Not applicable: it keeps nothing.

## Logging

Not applicable: the bridge logs nothing; failures are answered to the caller.

## Platform Notes

- **SwiftUI**: Not applicable: iOS reads `HubMailStore` directly and has no mail RPC to answer.
- **AppKit / UIKit**: Source platform: `packages/apple/AgenticDeveloperHubSDK/HubMailBridge/`, macOS only. The host builds `HubMailBridge(store:writeLabels:syncNow:)` once per signed-in hub session and hands `bridge.client` to `MailBrowserViewController(client:)` and the settings panel in place of the daemon's client.
- **Compose**: Not applicable: an Android client reads its mirror directly, as iOS does.
- **React/Web**: Not applicable: the web app reads the hub API directly and has no local RPC.
- **WinUI 3**: Not applicable until a Windows host shares one mail UI between two sources; it would follow this shape.

## Design Decisions

**Decision**: Answer the existing mail RPC rather than give the UI a second, hub-shaped API.
**Rationale**: The mail browser, Email App and settings panel already speak `MailClient`; one adapter at the transport seam switches all three, and the UI keeps one code path while the direct worker still exists.
**Approved**: pending

**Decision**: A separate macOS framework rather than putting the bridge in Integrations or HubMail.
**Rationale**: Integrations is macOS-only and HubMail builds for iOS; either holding the bridge would make one link the other. A third framework keeps both deletable on their own, which matters while the owner decides the direct path's fate.
**Approved**: pending

**Decision**: Write label changes into the mirror after the hub accepts them.
**Rationale**: The hub's action changes Gmail but not the hub's row, so without a local write the browser would show the old labels until the worker's next sync and the next pull. Keeping the sync version lets that pull replace the local write.
**Approved**: pending

**Decision**: Refuse search instead of matching text locally.
**Rationale**: Callers send Gmail search syntax (`from:`, `label:`, quoted phrases); a substring match would answer something different with no sign that it did.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |

Every vector has a named test in `AgenticDeveloperHubSDKHubMailBridgeTests`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
