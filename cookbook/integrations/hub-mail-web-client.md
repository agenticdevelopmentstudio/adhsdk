---
id: 6b0f3c52-8e47-4d1a-9a35-2f7c1d9e4a60
title: "Hub Mail Web Client"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Reads a signed-in customer's hub-synced Gmail in the browser: lists their mail connections and pages the hub's /sync/pull into an in-memory, per-session snapshot, answering accounts, messages and one message with no local database."
platforms:
  - typescript
  - web
tags:
  - integrations
  - mail
  - hub
  - web
depends-on:
  - a6442464-e17d-451e-b47a-3be23a2dc753
related:
  - e12914f0-3a3b-4fb7-ac0c-6332de37de4f
references: []
approved-by: ""
approved-date: ""
---

# Hub Mail Web Client

## Overview

A web app in the Temporal family (whatsnow.today's `/email` and the Email Desktop App on `/desktop`) shows the same hub-synced Gmail the macOS and iOS apps read from their local mirror ([adhsdk.ingredient.integrations.hub-mail](cookbook:a6442464-e17d-451e-b47a-3be23a2dc753)). The web app keeps no local database, so it does not run a second sync engine: `createHubMailClient` reads the hub API directly and holds what it read in memory for the life of the page.

It is the package `@adh-sdk/hub-mail` (`packages/web/packages/hub-mail/`). It has no runtime dependencies. The host injects one function, `fetchJson(path)`, that resolves a backend path (`/sync/pull?…`, `/integrations/me/connections`) to parsed JSON with the caller's bearer token, so the package never reads tokens, storage or a base URL itself. A host that already has an authed fetch (whatsnow's `adh-auth`, or `@adh-sdk/auth`'s `authedJson`) passes it in.

What it does:

- **Accounts** come from `GET /integrations/me/connections`, keeping the caller's Gmail message connections (`provider` `gmail`, `serviceType` `messages`). Each account carries the connection id, a display address, its status and its last error.
- **Messages** come from `GET /sync/pull`. The client pages from an empty cursor until `hasMore` is false, keeps only the two Gmail resources (`integration.integration_email_messages` and `integration.integration_email_labels`), applies each upsert and delete to its snapshot, and remembers the cursor. A later `refresh()` pulls only what changed since.
- **One message** is the snapshot's row for that connection and id, with its full body.

It answers the same three reads the iOS Email App asks of `MailClient` (`accounts`, `messages(account)`, `message(account, id)`), with the same field names the Desktop Email App renders, so the web Email App mirrors the native one.

## Behavioral Requirements

- **injected-fetch**: The client MUST make every request through the injected `fetchJson(path)` and MUST NOT read tokens, storage, cookies or a base URL itself.
- **accounts-from-connections**: `accounts()` MUST call `/integrations/me/connections` once per call and return one account per connection whose `provider` is `gmail` and `serviceType` is `messages`, in the order the hub returned them.
- **account-fields**: An account's `id` MUST be the connection id, its `email` MUST be the connection's `username`, else its `displayName`, else its id; `status` and `lastError` MUST be the connection's (`lastError` null when absent).
- **pull-until-done**: The first read of messages MUST page `/sync/pull?cursor=<c>&limit=500`, starting from an empty cursor, passing each response's `cursor` to the next request, until a response has `hasMore` false.
- **resource-filter**: Changes for any resource other than the two Gmail resources MUST be ignored, and their cursor still advances.
- **apply-changes**: An `upsert` MUST replace the snapshot row with that id; a `delete` MUST remove it. Changes MUST be applied in the order received.
- **live-rows-only**: A message row whose `deleted_at` is set or whose `is_deleted` is true MUST NOT be returned.
- **one-pull-at-a-time**: Concurrent reads that need a pull MUST share one in-flight pull rather than start a second.
- **refresh-delta**: `refresh()` MUST pull from the remembered cursor, not from empty, and resolve when `hasMore` is false.
- **cursor-expired**: A pull answered with HTTP 410 MUST clear the snapshot and cursor and pull again once from an empty cursor.
- **messages-order**: `messages(account)` MUST return that connection's live messages newest first by `internal_date`, rows with no date last, ties by id descending, at most `limit` (default 50).
- **message-summary-fields**: Each listed message MUST carry `id`, `account` (the connection id), `threadId`, `from`, `to`, `cc`, `subject`, `snippet`, `date` (the `internal_date`) and `labelIds`, with missing text fields as null and missing lists as empty.
- **message-detail**: `message(account, id)` MUST return the listed fields plus `bodyText` and `bodyHtml`, or null when the snapshot has no live row for that connection and id.
- **errors-propagate**: A failure from `fetchJson` other than 410 MUST reject the read with that error and leave the snapshot and cursor as they were.
- **reset**: `reset()` MUST drop the snapshot and cursor, so the next read pulls from empty (a host calls it on sign-out).

## Appearance

Not applicable: a headless data client with no UI.

## States

- **empty**: no pull has run; the first read starts one.
- **pulling**: a pull is in flight; reads wait on it.
- **ready**: the snapshot reflects the hub as of the remembered cursor.
- **failed**: the last pull rejected; the snapshot holds what it held before, and the next read retries.

## Accessibility

Not applicable: a headless data client with no UI.

## Conformance Test Vectors

| id | input | expected |
|---|---|---|
| hmw-001 | connections: one `gmail`/`messages`, one `github`/`repos` | `accounts()` returns only the Gmail one |
| hmw-002 | connection with `username` "a@x.com" | account `email` is "a@x.com" |
| hmw-003 | connection with empty `username`, `displayName` "Work" | account `email` is "Work" |
| hmw-004 | pull page 1 `hasMore: true, cursor: "c1"`, page 2 `hasMore: false` | two requests; the second has `cursor=c1` |
| hmw-005 | change for `notes.notes` | ignored |
| hmw-006 | upsert then delete of the same id | the message is absent |
| hmw-007 | messages dated 2026-11-01 and 2026-11-03, one undated | order: 11-03, 11-01, undated |
| hmw-008 | row with `is_deleted: true` | not listed |
| hmw-009 | two `messages()` calls before the first pull resolves | one pull request |
| hmw-010 | `refresh()` after a pull that ended with cursor "c9" | request has `cursor=c9` |
| hmw-011 | pull answered 410 | snapshot cleared, pull restarts from empty |
| hmw-012 | `message("conn", "missing")` | null |
| hmw-013 | `fetchJson` rejects with a 500 error | the read rejects; the earlier snapshot is kept |

## Edge Cases

- A connection with no messages yet lists with no messages, not an error.
- A message row for a connection the caller no longer has stays in the snapshot but is never listed, because messages are always read by account.
- A pull that ends mid-way with an error keeps the changes already applied and the cursor of the last applied page, so the retry continues from there.
- `limit` below 1 is treated as 1.

## Configuration

| name | default | meaning |
|---|---|---|
| `fetchJson` | required | resolves a backend path to parsed JSON with the caller's token; rejects with an `Error` carrying a numeric `status` on HTTP failure |
| `pageSize` | 500 | the `limit` sent to `/sync/pull` (the hub clamps it to 1..1000) |

## Deep Linking

Not applicable: the client has no routes; the host's `/email` route owns linking.

## Localization

Not applicable: the client returns data, never user-facing text.

## Accessibility Options

Not applicable: a headless data client with no UI.

## Feature Flags

None.

## Analytics

None. The client records no events.

## Privacy

Mail stays in page memory only: nothing is written to `localStorage`, `sessionStorage`, IndexedDB or cookies, and closing the tab discards it. `reset()` drops it on sign-out.

## Logging

None. Errors reach the caller as rejected promises.

## Platform Notes

- **SwiftUI**: Not applicable: Apple apps read the local mirror through `HubMailStore` and [adhsdk.ingredient.integrations.hub-mail-bridge](cookbook:e12914f0-3a3b-4fb7-ac0c-6332de37de4f).
- **AppKit / UIKit**: Not applicable, for the same reason.
- **Compose**: Not applicable: an Android client keeps a local mirror, as iOS does.
- **React/Web**: Source: `packages/web/packages/hub-mail/src/` (`hub-mail-client.ts`, `snapshot.ts`, `types.ts`). The host builds one client per signed-in session with `createHubMailClient({ fetchJson })` and hands it to the web Email App. whatsnow's `fetchJson` prefixes `/api` (its Next rewrite forwards to the backend with no prefix) and adds the stored bearer token.
- **WinUI 3**: Not applicable until a Windows host exists; it would keep a local mirror.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/hub-mail/src/` | confirmed (1.0.0) |

## Design Decisions

- **No local database in the browser.** The plan settles that the web app reads through the hub API and keeps no local store, so there is no second sync engine. An in-memory snapshot built from `/sync/pull` is that read: it lasts as long as the page and is never persisted.
- **`/sync/pull` rather than a per-connection listing.** The hub's connection-data route does not serve email messages, and `/sync/pull` already returns the caller's Gmail rows owner-scoped, with deletes. Pulling everything and filtering client-side costs more on the first read, but uses a route that exists and is the same contract the native mirrors follow.
- **Accounts from `/integrations/me/connections`.** The connection list carries the address, status and last error the accounts list shows. The native bridge derives the address from sent mail because its mirror has no connection table; the web client has the real list one request away.
- **Injected fetch.** The client takes `fetchJson` rather than importing an auth package, so it sits in the lowest tier with no dependencies and works in any host's auth (dependency injection).
- **Legacy paths, camelCase envelope.** `/sync/pull` and `/integrations/me/connections` answer camelCase envelopes; a row's `data` keeps the backend's snake_case column names, exactly as the native projection reads them.

## Compliance

Reads only the caller's own rows, which the hub scopes by owner. No data is stored at rest in the browser.

## Change History
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
