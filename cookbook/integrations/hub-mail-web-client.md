---
id: 6b0f3c52-8e47-4d1a-9a35-2f7c1d9e4a60
title: "Hub Mail Web Client"
type: ingredient
version: 1.2.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-16
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

A web app (its Email App and its desktop-style Email shell) shows the same hub-synced Gmail the macOS and iOS apps read from their local mirror ([adhsdk.ingredient.integrations.hub-mail](cookbook:a6442464-e17d-451e-b47a-3be23a2dc753)). The web app keeps no local database, so it does not run a second sync engine: `createHubMailClient` reads the hub API directly and holds what it read in memory for the life of the page.

It is the package `@adh-sdk/hub-mail` (`packages/web/packages/hub-mail/`). It has no runtime dependencies. The host injects one function, `fetchJson(path)`, that resolves a backend path (`/v1/sync/pull?…`, `/v1/integrations/connections?…`) to parsed JSON with the caller's bearer token, so the package never reads tokens, storage or a base URL itself. A host that already has an authed fetch (such as `@adh-sdk/auth`'s `authedJson`) passes it in.

What it does:

- **Accounts** come from `GET /v1/integrations/connections`, paged with `starting_after` until `has_more` is false, keeping the caller's Gmail message connections (`provider` `gmail`, `service_type` `messages`). Each account carries the connection id, a display address, its status and its last error. `accounts()` is not cached: every call refetches the connection list.
- **Messages** come from `GET /v1/sync/pull`. The client pages from no cursor until `has_more` is false, keeps only the two Gmail resources (`integration.integration_email_messages` and `integration.integration_email_labels`), applies each upsert and delete to its snapshot, and remembers the cursor. A later `refresh()` pulls only what changed since.
- **One message** is the snapshot's row for that connection and id, with its full body.

It answers the same three reads the iOS Email App asks of `MailClient` (`accounts`, `messages(account)`, `message(account, id)`), with the same field names the Desktop Email App renders, so the web Email App mirrors the native one.

The public surface, as `createHubMailClient(options)` returns it (types in `types.ts`):

```ts
createHubMailClient(options: { fetchJson: FetchJson; pageSize?: number }): HubMailClient

interface HubMailClient {
  accounts(): Promise<HubMailAccount[]>
  messages(account: string, limit?: number): Promise<HubMailMessageSummary[]>
  message(account: string, id: string): Promise<HubMailMessage | null>
  refresh(): Promise<void>
  reset(): void
}
```

`limit` is a positional argument. `HubMailAccount` is `{ id, email, status, lastError }`; `HubMailMessageSummary` is the field list under **message-summary-fields**; `HubMailMessage` adds `bodyText` and `bodyHtml`.
## Behavioral Requirements

- **injected-fetch**: The client MUST make every request through the injected `fetchJson(path)` and MUST NOT read tokens, storage, cookies or a base URL itself.
- **accounts-from-connections**: `accounts()` MUST read `/v1/integrations/connections?limit=100`, then each following page with `starting_after=<last id>` while `has_more` is true, and return one account per connection whose `provider` is `gmail` and `service_type` is `messages`, in the order the hub returned them.
- **account-fields**: An account's `id` MUST be the connection id, its `email` MUST be the connection's `username`, else its `display_name`, else its id, where an empty `username` or `display_name` counts as missing and falls through to the next option; `status` MUST be the connection's, and `lastError` its `last_error` (null when absent).
- **pull-until-done**: The first read of messages MUST page `/v1/sync/pull?limit=500` with no cursor, then `/v1/sync/pull?cursor=<c>&limit=500` passing each response's `cursor` to the next request, until a response has `has_more` false.
- **resource-filter**: Changes for any resource other than the two Gmail resources MUST be ignored, and their cursor still advances.
- **apply-changes**: An `upsert` MUST replace the row with that id in that resource's table of the snapshot; a `delete` MUST remove it. Each resource has its own table, so a message id and a label id never collide. Changes MUST be applied in the order received.
- **live-rows-only**: A message row whose `deleted_at` is set or whose `is_deleted` is true MUST NOT be returned.
- **one-pull-at-a-time**: Concurrent reads that need a pull MUST share one in-flight pull rather than start a second.
- **refresh-delta**: `refresh()` MUST pull from the remembered cursor, not from empty, and resolve when `has_more` is false. A `refresh()` that arrives while a pull is in flight MUST join that pull rather than start another.
- **accounts-uncached**: `accounts()` MUST fetch the connection list on every call.
- **cursor-expired**: A pull answered with HTTP 410 MUST clear the snapshot and cursor and pull again once from an empty cursor. A 410 is recognised by the numeric `status` property that a `fetchJson` rejection carries (see Configuration). If that second pull also fails, including with another 410, the read MUST reject with that error and the client is in **failed**.
- **messages-order**: `messages(account)` MUST return that connection's live messages newest first by `internal_date`, rows with no date last, ties by id descending, at most `limit` (default 50); a `limit` below 1 MUST be treated as 1.
- **message-summary-fields**: Each listed message MUST carry `id`, `account` (the connection id), `threadId`, `from`, `to`, `cc`, `subject`, `snippet`, `date` (the `internal_date`) and `labelIds`, with missing text fields as null and missing lists as empty.
- **message-detail**: `message(account, id)` MUST return the listed fields plus `bodyText` and `bodyHtml`, or null when the snapshot has no live row for that connection and id.
- **errors-propagate**: A failure from `fetchJson` other than 410 MUST reject the read with that error. Pages already applied stay in the snapshot, and the cursor stays at the last applied page, so the next read continues from there.
- **reset**: `reset()` MUST drop the snapshot and cursor, so the next read pulls from empty (a host calls it on sign-out). A pull still in flight when `reset()` runs MUST NOT apply its pages, move the cursor or mark the client pulled, and the next read MUST start a new pull rather than join it.

## Appearance

Not applicable: a headless data client with no UI.

## States

- **empty**: no pull has run; the first read starts one.
- **pulling**: a pull is in flight; reads wait on it.
- **ready**: the snapshot reflects the hub as of the remembered cursor.
- **failed**: the last pull rejected; the snapshot keeps whatever pages were applied before the failure, with the cursor of the last applied page, and the next read retries from there.

## Accessibility

Not applicable: a headless data client with no UI.

## Conformance Test Vectors

| id | input | expected |
|---|---|---|
| hmw-001 | connections: one `gmail`/`messages`, one `github`/`repos` | `accounts()` returns only the Gmail one |
| hmw-002 | connection with `username` "a@x.com" | account `email` is "a@x.com" |
| hmw-003 | connection with empty `username`, `display_name` "Work" | account `email` is "Work" |
| hmw-004 | pull page 1 `has_more: true, cursor: "c1"`, page 2 `has_more: false` | two requests; the first is `/v1/sync/pull?limit=500`, the second has `cursor=c1` |
| hmw-005 | change for `notes.notes` | ignored |
| hmw-006 | upsert then delete of the same id | the message is absent |
| hmw-007 | messages dated 2026-11-01 and 2026-11-03, one undated | order: 11-03, 11-01, undated |
| hmw-008 | row with `is_deleted: true` | not listed |
| hmw-009 | two `messages()` calls before the first pull resolves | one pull request |
| hmw-010 | `refresh()` after a pull that ended with cursor "c9" | request has `cursor=c9` |
| hmw-011 | pull answered 410 | snapshot cleared, pull restarts from empty |
| hmw-012 | `message("conn", "missing")` | null |
| hmw-013 | `fetchJson` rejects with a 500 error on page 2 of a pull | the read rejects; page 1's changes stay applied and the cursor is page 1's |
| hmw-014 | connections page 1 `has_more: true` ending at `g1`, page 2 `has_more: false` | two requests, the second with `starting_after=g1`; both Gmail accounts returned in order |
| hmw-015 | pull answered 410, and the restart is answered 410 too | the read rejects with that error; the snapshot is empty and the client is in failed |
| hmw-016 | `reset()` after a completed pull, then `messages()` | the snapshot is empty and the request has no `cursor` |
| hmw-017 | 3 live messages, `messages(account, 2)` | the 2 newest |
| hmw-018 | `messages(account, 0)` | one message, the newest |
| hmw-019 | `message("conn", id)` for a live row with `body_text` and `body_html` | `bodyText` and `bodyHtml` carry them |
| hmw-020 | two messages with equal `internal_date` and ids "a" and "b" | "b" lists before "a" |
| hmw-021 | `accounts()` called twice | two connection-list requests |
| hmw-022 | `refresh()` called while a pull is in flight | one pull request; both calls resolve when it does |
| hmw-023 | `reset()` while a pull is in flight, its page then resolves, then `messages()` | the late page is not applied; a second pull request with no `cursor` is sent |
## Edge Cases

- A connection with no messages yet lists with no messages, not an error.
- A message row for a connection the caller no longer has stays in the snapshot but is never listed, because messages are always read by account.
- A pull that ends mid-way with an error keeps the changes already applied and the cursor of the last applied page, so the retry continues from there.
- Two equal `internal_date` values order by id descending.

## Configuration

| name | default | meaning |
|---|---|---|
| `fetchJson` | required | resolves a backend path to parsed JSON with the caller's token; rejects with an `Error` carrying a numeric `status` on HTTP failure |
| `pageSize` | 500 | the `limit` sent to `/v1/sync/pull` (the hub clamps it to 1..1000) |

Wire mapping from a `/v1/sync/pull` message row's `data` columns to the fields a message carries:

| column | field |
|---|---|
| `connection_id` | `account` (ties the row to its connection) |
| `thread_id` | `threadId` |
| `from_address` | `from` |
| `to_addresses` | `to` |
| `cc_addresses` | `cc` |
| `subject`, `snippet` | `subject`, `snippet` |
| `internal_date` | `date` |
| `label_ids` | `labelIds` |
| `body_text`, `body_html` | `bodyText`, `bodyHtml` (detail only) |
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
- **React/Web**: Source: `packages/web/packages/hub-mail/src/` (`hub-mail-client.ts`, `snapshot.ts`, `types.ts`). The host builds one client per signed-in session with `createHubMailClient({ fetchJson })` and hands it to the web Email App. The host's `fetchJson` adds any base-URL prefix its proxy needs and the stored bearer token.
- **WinUI 3**: A Windows host keeps a local mirror rather than reading this client: it pulls `/v1/sync/pull` into a local store and reads through a `MailClient`-shaped seam, as [adhsdk.ingredient.integrations.hub-mail-bridge](cookbook:e12914f0-3a3b-4fb7-ac0c-6332de37de4f) does on Apple. Only a WebView2-hosted web build would use this client, unchanged, with its own `fetchJson`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/hub-mail/src/` | confirmed (1.2.0) |

## Design Decisions

**Decision**: No local database in the browser.
**Rationale**: The web app reads through the hub API and keeps no local store, so there is no second sync engine. An in-memory snapshot built from `/v1/sync/pull` is that read: it lasts as long as the page and is never persisted.
**Approved**: pending

**Decision**: `/v1/sync/pull` rather than a per-connection listing.
**Rationale**: The hub's connection-data route does not serve email messages, and the sync pull already returns the caller's Gmail rows owner-scoped, with deletes. Pulling everything and filtering client-side costs more on the first read, but uses a route that exists and is the same contract the native mirrors follow.
**Approved**: pending

**Decision**: Accounts from `/v1/integrations/connections`.
**Rationale**: The connection list carries the address, status and last error the accounts list shows. The native bridge derives the address from sent mail because its mirror has no connection table; the web client has the real list one request away.
**Approved**: pending

**Decision**: Injected fetch.
**Rationale**: The client takes `fetchJson` rather than importing an auth package, so it sits in the lowest tier with no dependencies and works in any host's auth (dependency injection).
**Approved**: pending

**Decision**: Use the hub's `/v1` surface.
**Rationale**: The hub's `/v1` routes are its stable public API (the signup form in `@adh-sdk/ui` moved to them too). With a customer token, `/v1/integrations/connections` returns the caller's own connections; how the hub routes that request is the hub's concern, not the client's.
**Approved**: pending

**Decision**: Snake_case wire types, mapped once to camelCase.
**Rationale**: The `/v1` routes answer snake_case envelopes (`has_more`, `sync_version`, `service_type`) and a list envelope (`object: "list"`, `data`, `has_more`) for connections. The package's wire types say so, and the mapping to the camelCase `HubMail*` types happens once, in the client. A row's `data` keeps the backend's snake_case column names, exactly as the native projection reads them.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |

The wire client, the snapshot and the types are separate modules, and the fetch is injected; `hub-mail-client.test.ts` covers the client. It reads only the caller's own rows, which the hub scopes by owner, and stores no data at rest in the browser.

## Change History
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.0 | 2026-11-16 | Mike Fullerton | reset() abandons a pull in flight (hmw-023) |
| 1.1.2 | 2026-11-14 | Mike Fullerton | Made failure and second-410 behavior match source, added interface and wire-mapping, caching and join-in-flight rules, split the /v1 decision, genericized app names, and added test vectors hmw-015 to hmw-022. |
| 1.1.1 | 2026-11-14 | Mike Fullerton | Decision triples, compliance checks and WinUI 3 guidance |
| 1.1.0 | 2026-11-14 | Mike Fullerton | Reads the hub's /v1 routes: sync pull and paged connections, snake_case wire types |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
