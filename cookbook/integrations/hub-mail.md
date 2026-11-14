---
id: a6442464-e17d-451e-b47a-3be23a2dc753
title: "Hub Mail"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Hub-sourced mail on Apple platforms: a local mirror of the hub's Gmail tables pulled through the sync engine, typed reads over it, sign-out purge, and sending through the hub's integration action."
platforms:
  - swift
  - macos
  - ios
tags:
  - integrations
  - mail
  - sync
  - hub
depends-on:
  - 6edbc7b8-b533-4cca-b62d-74b92ce3f650
  - 355a8f54-aee5-45cd-a28d-12c3b7a3085c
  - 14ca2162-b5ec-48bb-95a0-90577e7c9810
related:
  - b3edb32d-7473-464b-acfb-c19cdd44e99e
references: []
approved-by: ""
approved-date: ""
---

# Hub Mail

## Overview

Hub Mail is how an app reads mail the ADH hub already synced from Gmail, without talking to Gmail itself. The hub's Gmail worker fills two owner-scoped tables, `integration.integration_email_messages` and `integration.integration_email_labels`, and enrolls them for app sync. `AgenticDeveloperHubSDKHubMail` pulls them through the [sync engine](cookbook:355a8f54-aee5-45cd-a28d-12c3b7a3085c) and the [hub sync transport](cookbook:6edbc7b8-b533-4cca-b62d-74b92ce3f650) into a local SQLite mirror of its own, then answers typed questions over it: which connections and labels there are, a page of messages under a label, one message, one thread. Sending goes the other way, through the hub's `send` integration action, so the hub's worker talks to Gmail.

It is a separate store from the direct macOS Gmail worker in `AgenticDeveloperHubSDKIntegrations`, by design: the two never share tables, so either can be removed without touching the other. It builds for macOS and iOS; the iOS app has no Gmail code at all and reads only through this.

Four types make it up:

- `HubMailProjection`, a `SyncMirrorProjection` that keeps the two resources in typed tables (`hub_email_messages`, `hub_email_labels`).
- `HubMailStore`, the read API over those tables.
- `HubMailSync`, which wires the projection, a `GRDBSyncStore` and a `SyncEngine` over one database and exposes sync-now and sign-out.
- `HubMailSender`, which sends a message through the hub client's generated `APIProtocol`.

## Behavioral Requirements

- **claims-two-resources**: The projection MUST claim exactly `integration.integration_email_messages` and `integration.integration_email_labels`.
- **typed-columns**: The projection MUST store each backend column under its own name in a typed column, keep JSON array and object columns (`to_addresses`, `cc_addresses`, `label_ids`, `attachments`, `color`) as JSON text, and keep `sync_version` and `deleted_at` for the store.
- **upsert-revives**: An upsert MUST replace the row's columns, take the change's sync version and clear `deleted_at`, so a deleted row that comes back is live again.
- **soft-delete**: A delete MUST keep the row as a tombstone with `deleted_at` set, and take the delete's sync version when it has one.
- **live-rows-only**: Every read MUST skip rows with `deleted_at` set or `is_deleted` true; the backend's worker sets `is_deleted` on mail Gmail removed.
- **truncate-own-tables**: Truncate MUST empty only the tables of the resources it is given.
- **connections**: `connections()` MUST return the distinct connection ids that have live messages or labels, sorted.
- **labels-by-connection**: `labels(connectionId:)` MUST return that connection's live labels, system labels first, then by name.
- **messages-newest-first**: `messages(...)` MUST return live messages newest first by `internal_date`, then by id descending, optionally narrowed to one connection and to messages whose `label_ids` contain one label.
- **keyset-paging**: A page MUST hold at most `limit` messages (clamped to 1...500) and a `next` cursor that is non-nil exactly when more messages follow; passing it back MUST return the messages after the last one, with no repeats or gaps while the rows do not change.
- **thread-oldest-first**: `thread(connectionId:threadId:)` MUST return the thread's live messages oldest first.
- **pull-only**: `HubMailSync` MUST register both resources as pull-only with the sync store, because the hub refuses pushes to worker-owned tables, and MUST pass both as the engine's `hostResources` so no other enrolled table is mirrored.
- **sign-out-purges**: `signOut()` MUST pause the engine, purge every mirrored row, cursor and outbox entry for the departing identity, then resume.
- **send-action**: `HubMailSender.send` MUST post the `send` action for the connection with `to`, `cc`, `bcc`, `subject`, `bodyText` and `bodyHtml`, and return the result's `ok`, `externalId`, `deduped` and `error`.
- **send-errors**: A non-200 answer MUST throw `HubMailSendError.rejected(statusCode:)`.

## Appearance

Not applicable: these types draw nothing. The app's mail browser renders what the store returns.

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
| Empty | Before the first pull every read returns nothing. |
| Synced | Reads return the mirrored rows. |
| Signed out | `signOut` leaves the tables empty until the next identity's first pull. |

## Accessibility

Not applicable: no visual or interactive element.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hub-mail-001 | typed-columns, upsert-revives | Upsert a message with `to_addresses` `["a@x"]`, `label_ids` `["INBOX"]` | `message(id:)` returns it with `to == ["a@x"]`, `labelIds == ["INBOX"]` |
| hub-mail-002 | soft-delete, live-rows-only | Delete it with version 7 | `message(id:)` is nil; the projection's sync version is 7 |
| hub-mail-003 | upsert-revives | Upsert it again | `message(id:)` returns it |
| hub-mail-004 | live-rows-only | Upsert a message with `is_deleted` true | It is in no read |
| hub-mail-005 | messages-newest-first, keyset-paging | Five messages, limit 2 | Pages of 2, 2, 1, newest first; the last page's `next` is nil |
| hub-mail-006 | messages-newest-first | Label filter `INBOX` over messages labelled `INBOX` and `SENT` | Only the `INBOX` messages |
| hub-mail-007 | labels-by-connection | A user label "Alpha" and the system label "INBOX" | `INBOX` first |
| hub-mail-008 | thread-oldest-first | Three messages in one thread | Oldest first |
| hub-mail-009 | connections | Messages on two connections | Both ids, sorted |
| hub-mail-010 | pull-only, sign-out-purges | A scripted pull of one message and one label through `HubMailSync`, then `signOut` | After sync both read back; after sign-out, none |
| hub-mail-011 | send-action | A fake client answering ok with external id `g1` | The input names the connection and `send`, carries the fields, and the result is ok with `g1` |
| hub-mail-012 | send-errors | The fake client answers 401 | `HubMailSendError.rejected(statusCode: 401)` |

## Edge Cases

- A message with no `internal_date` sorts after every dated message, and pages by id among its peers.
- A JSON column that arrives as a string (already encoded) is stored as that string; one that arrives as an array or object is encoded.
- A change for a column the projection does not know is ignored, so a new backend column does not break an old client.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| database | `BoundedDatabase` | required | The SQLite file the mirror and the sync bookkeeping live in, apart from any direct-Gmail database. |
| transport | `any SyncTransport` | required | Usually `ADHSyncTransport(api:)`; tests pass a scripted one. |
| deviceId | `String` | required | The engine's device id. |
| client | `any APIProtocol` | required | The hub client the sender posts through. |

## Deep Linking

Not applicable: no URL is handled.

## Localization

Not applicable: no user-facing text.

## Accessibility Options

Not applicable: no visual element.

## Feature Flags

Not applicable: the app decides whether to read from the hub or from the direct worker; these types read no flag.

## Analytics

Not applicable: no event is recorded.

## Privacy

- **Data collected**: The signed-in user's mail as the hub holds it: addresses, subjects, snippets, bodies, label names and attachment metadata.
- **Storage**: A local SQLite file the host chooses, in its own container.
- **Transmission**: Pulled from the hub over HTTPS with the user's token; sends go to the hub's action route.
- **Retention**: Until the hub deletes the row or the user signs out, when `signOut` purges every row.

## Logging

Not applicable: these types log nothing; sync failures surface as engine events.

## Platform Notes

- **SwiftUI**: Source platform for macOS and iOS: `packages/apple/AgenticDeveloperHubSDK/HubMail/`, one framework built for both, over GRDB and `BoundedDatabase`. A SwiftUI or UIKit screen reads `HubMailStore` after each `pulledBatch` event.
- **Compose**: Mirror with Room or SQLDelight tables of the same columns, filled by the Kotlin sync engine; page with the same `(internal_date, id)` keyset. Send through the hub client's action call.
- **React/Web**: No local mirror: the web app reads the same two tables through the hub API and sends through the same action route.
- **AppKit / UIKit**: The macOS mail browser reads through an adapter that turns these records into the Integrations framework's mail types, so the same browser shows hub or direct mail.
- **WinUI 3**: Mirror with `Microsoft.Data.Sqlite` tables of the same columns; page with the same keyset; send through the hub client.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/HubMail/` | confirmed (1.0.0) |
| ios | `packages/apple/AgenticDeveloperHubSDK/HubMail/` | confirmed (1.0.0) |

## Design Decisions

**Decision**: The hub mirror is a separate store and framework from the direct Gmail worker.
**Rationale**: The direct path stays until the owner decides its fate, and keeping the two apart means removing either touches nothing in the other. It also lets iOS link hub mail without the macOS-only Integrations framework.
**Approved**: pending

**Decision**: Typed tables through a projection rather than the sync store's generic JSON mirror.
**Rationale**: Mail is read by connection, label, thread and date, and typed columns with indexes answer those directly instead of through JSON expressions on every row.
**Approved**: pending

**Decision**: Keyset paging on `(internal_date, id)`.
**Rationale**: A mailbox is large and grows at the top while the user scrolls; a keyset cursor neither repeats nor skips when new mail arrives, where an offset would.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |

Every vector has a named test in `AgenticDeveloperHubSDKHubMailTests`. Only the two email resources are mirrored, and sign-out purges them.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
