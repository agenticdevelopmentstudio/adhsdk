---
id: a3e87176-5845-43ff-9041-af53437d605d
title: "Monitored Sites"
type: ingredient
version: 2.0.0
status: review
language: en
created: 2026-09-24
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A data client for the Status Sites monitoring domain: generic-CRUD groups, sites, and endpoints over /api/v1/monitoring/*, the 1:M group-to-site-to-endpoint model, owner/workspace scoping, and the field renames each mapper performs."
platforms:
  - typescript
  - web
tags:
  - hub
  - monitoring
  - site-groups
  - sites
  - endpoints
  - workspace
  - crud
  - api
depends-on: []
related: []
references:
  - packages/web/packages/data/src/monitored-sites/monitored-sites.ts (adhsdk)
  - packages/web/packages/data/src/monitored-sites/wire.ts (adhsdk)
  - packages/web/packages/data/src/monitored-sites/index.ts (adhsdk)
  - packages/web/packages/data/src/monitored-sites/__tests__/monitored-sites.test.ts (adhsdk)
  - packages/web/packages/data/src/http.ts (adhsdk)
  - packages/web/packages/data/src/client-helpers.ts (adhsdk)
  - packages/web/packages/auth/src/client.ts (adhsdk)
approved-by: ""
approved-date: ""
---

# Monitored Sites

## Overview

This is the client for the Status Sites monitoring domain: groups, sites, and endpoints, backed by
the /v1 monitoring surface: `/api/v1/monitoring/site_groups`, `/api/v1/monitoring/sites`, and
`/api/v1/monitoring/endpoints`. The model matches the database, not an earlier prototype: a site
belongs to exactly one group (`sites.site_group_id`, `NOT NULL`, FK `ON DELETE CASCADE`) and an
endpoint belongs to exactly one site (same cascade) — a strict 1:M chain, not the prototype's
many-to-many `groupIds[]`. The whole chain is owner-scoped server-side, with an optional
`workspace` parameter on every operation that re-pins it to a workspace's owning principal. This
logic holds the snake_case backend row and request-body shapes (a group row, a site row, an endpoint row, and
their create/put bodies), three mappers from row to caller-facing view, the caller-facing create
and update body shapes for each entity, the fixed set of valid endpoint kinds, and twelve
operations — list/create/update/delete for each of the three entities — each a thin request
builder over a shared authenticated request client. It is a headless **logic** module — no visual
surface — consumed today by the Dashboards (Site Monitoring) feature, so this recipe marks
Appearance, States, and Accessibility not applicable and carries the runtime contract entirely in
Behavioral Requirements, per the non-UI component guidance this recipe was authored under.

## Behavioral Requirements
**Mappers**

- **site-group-view-shape**: the group mapper MUST map a snake_case group row to a group view carrying
  `id`, `slug`, `name`, `retentionDays` (from `retention_days`), `createdAt` (from `created`), and
  `updatedAt` (from `updated`), converting both unix-second timestamps to ISO strings.
- **site-view-renames-group-id**: the site mapper MUST copy a site row's `site_group_id` field into the
  site view's `groupId`; `id`, `slug` and `name` MUST be copied unchanged, and `created` and `updated`
  MUST become ISO-string `createdAt` and `updatedAt`.
- **endpoint-view-shape**: the endpoint mapper MUST map a snake_case endpoint row to an endpoint view
  carrying `id`, `siteId` (`site_id`), `url`, `kind`, `expectedStatus` (`expected_status`),
  `checkIntervalSeconds` (`check_interval_seconds`), `isActive` (`is_active`), `createdAt` and
  `updatedAt` (from the unix-second `created` and `updated`).

**Groups**

- **group-list-request**: the list-groups operation MUST read `GET /api/v1/monitoring/site_groups`,
  with the `workspace` query only when that option is given, through the shared paging helper, which
  adds `limit` and `starting_after` and keeps requesting pages while the response says `has_more`.
- **group-list-sorted-by-name**: the list-groups operation MUST return the mapped group views sorted by
  `name` via a locale-aware comparison, without mutating the array the request returned.
- **group-create-request**: the create-group operation MUST send `POST /api/v1/monitoring/site_groups`
  (plus the workspace query) with a body built by the body-compaction helper from `{ name, slug,
  retention_days }`, dropping `retention_days` from the JSON payload when the caller omits
  `retentionDays`, and MUST return the mapped group view.
- **group-update-request**: the update-group operation MUST send `POST
  /api/v1/monitoring/site_groups/<encoded id>` (plus the workspace query) with a compacted patch of `{
  name, slug, retention_days }`, and MUST return the mapped group view.
- **group-delete-request**: the delete-group operation MUST send `DELETE
  /api/v1/monitoring/site_groups/<encoded id>` (plus the workspace query), discarding any response
  body, and MUST resolve with no value.
- **group-delete-cascades**: deleting a group MUST cascade at the database level (`FK ON DELETE
  CASCADE`) to remove every site in that group and every endpoint of those sites; this client issues
  one `DELETE` request and performs no separate cleanup call of its own.

**Sites**

- **site-belongs-to-exactly-one-group**: a site view MUST carry exactly one `groupId` as a required
  field — the single group this site belongs to (1:M; required) — and this client models no
  many-to-many group membership.
- **site-list-request**: the list-sites operation MUST read `GET /api/v1/monitoring/sites` (plus the
  workspace query) through the shared paging helper, draining every page.
- **site-list-sorted-by-name**: the list-sites operation MUST return the mapped site views sorted by
  `name`.
- **site-list-single-request-only**: the list-sites operation MUST NOT request the site-groups
  collection or perform any client-side intersection against group membership. An earlier
  implementation did both — a second round-trip, plus a silent-hiding bug, since a capped groups list
  dropped sites whose group fell past the cap even though the server still monitors them; the current
  form reads only the sites collection.
- **site-create-request**: the create-site operation MUST send `POST /api/v1/monitoring/sites` (plus
  the workspace query) with a body of exactly `{ name, slug, site_group_id: <the given groupId> }`,
  sent without passing through the body-compaction helper — all three fields are required, so none can
  be absent.
- **site-update-request**: the update-site operation MUST send `POST /api/v1/monitoring/sites/<encoded
  id>` (plus the workspace query) with a compacted patch of `{ name, slug, site_group_id: <the given
  groupId> }` built from the optional update fields.
- **site-delete-request**: the delete-site operation MUST send `DELETE
  /api/v1/monitoring/sites/<encoded id>` (plus the workspace query), discarding the body, and MUST
  resolve with no value.
- **site-delete-cascades**: deleting a site MUST cascade at the database level to remove every endpoint
  that belongs to it.

**Endpoints**

- **endpoint-list-request**: the list-endpoints operation MUST read `GET /api/v1/monitoring/endpoints`
  (plus the workspace query) through the shared paging helper. The /v1 collection declares no
  `site_id` filter, so no site parameter is sent.
- **endpoint-list-double-filtered**: the list-endpoints operation MUST filter the mapped rows
  client-side to `e.siteId === siteId`. This is the only site narrowing; the server scopes the
  response by owner, not by site.
- **endpoint-list-sorted-by-url**: the list-endpoints operation MUST return the filtered rows sorted by
  `url`.
- **endpoint-create-request**: the create-endpoint operation MUST send `POST
  /api/v1/monitoring/endpoints` (plus the workspace query) with a compacted body of `{ site_id, url,
  kind, expected_status, check_interval_seconds, is_active }`, where `site_id` comes from the
  operation's own `siteId` parameter, not from the caller-supplied body.
- **endpoint-update-request**: the update-endpoint operation MUST send `POST
  /api/v1/monitoring/endpoints/<encoded id>` (plus the workspace query) with a compacted patch of `{
  url, kind, expected_status, check_interval_seconds, is_active }`; `site_id` MUST NOT appear in this
  patch, so this operation cannot reparent an endpoint to a different site.
- **endpoint-delete-request**: the delete-endpoint operation MUST send `DELETE
  /api/v1/monitoring/endpoints/<encoded id>` (plus the workspace query), discarding the body, and MUST
  resolve with no value.
- **endpoint-kind-passthrough**: the create- and update-endpoint operations MUST send the
  caller's `kind` value to the backend as given; the body's `kind` field is typed as an
  unconstrained string and neither operation narrows it against the fixed set of valid endpoint
  kinds (`http`, `tcp`, `icmp`), so a caller can submit an unknown kind such as `ssh` with no
  client-side signal.

**Cross-cutting**

- **every-write-url-encodes-identifiers**: every group, site, and endpoint `id` interpolated into a URL
  path segment MUST be percent-encoded; every `workspace` value MUST likewise be encoded, by the shared
  query builder every operation uses.
- **optional-fields-omitted-not-nulled**: the body-compaction helper MUST drop only absent-valued keys
  from a write body before it is serialized, preserving any explicit `null` a caller supplies — `null`
  is preserved, as an explicit "clear this column" — though no create/update body field in this module
  accepts `null` itself, so this only matters if a caller bypasses the declared shapes.
- **no-client-side-cache**: the twelve operations MUST NOT cache or memoize a response; every write
  issues exactly one HTTP request, and every list issues one request per page until the response
  stops reporting `has_more` (aside from the inherited `401` refresh-and-retry described below).
- **module-holds-no-mutable-state**: the only persistent values this logic holds are the three
  fixed path-string constants and the fixed set of valid endpoint kinds, all read-only; no shared
  mutable state exists for concurrent calls to race on.

### Security

Monitored-sites configuration is not credential data, but every operation is owner/workspace-scoped, so
this recipe carries a dedicated security subsection per the cookbook's cross-cutting authorization
guidance.

- **owner-scoping-server-side**: every operation MUST be owner-scoped server-side: groups by the
  caller's user id; sites and endpoints inherit the user id and owner from their parent at
  create/reparent time.
- **workspace-param-repins-owner**: the optional `workspace` parameter, when supplied, MUST be sent as
  `?workspace=<slug>` on every operation, which pins the operation to the workspace's owning principal
  instead of the caller's own scope; list operations under a workspace MUST return only that
  principal's rows, and item update/delete under a workspace MUST resolve an org-owned row another
  member created.
- **auth-delegated-to-shared-client**: every network call in this module MUST go through the shared
  authenticated request client; this module MUST NOT read, store, or attach a bearer token itself.
- **session-refresh-waterfall**: a `401` response to any call in this module MUST trigger exactly one
  token refresh and one retried request, inherited unconditionally from that shared client; a second
  `401` on the retried request MUST propagate as a thrown typed HTTP error with `status: 401`. This
  module defines no refresh or retry logic of its own.
- **errors-carry-status-and-code**: any non-2xx response other than an unresolved `401` MUST cause the
  call to throw a typed HTTP error, carrying the response's HTTP status and, when the body supplies
  one, a machine-readable `code`.
- **no-conflict-friendly-mapping**: no operation in this module calls the shared conflict-friendly-error
  helper to translate a `409` "already exists" backend error into an entity-named friendly message; a
  duplicate group/site/endpoint slug MUST propagate as the raw error message the backend supplied.

## Appearance

Not applicable — this is a data-access client for the Status Sites monitoring domain, not a visual
component.

## States

Not applicable — this is a data-access client for the Status Sites monitoring domain, not a visual
component; any loading/error/empty visual state is owned by the presentation layer that consumes it.

## Accessibility

Not applicable — this is a data-access client for the Status Sites monitoring domain, not a visual
component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hub-domain-monitored-sites-001 | site-view-renames-group-id | The site mapper applied to a site row `{ id:"s1", slug:"site", name:"Site", site_group_id:"g1", created:1700000000, updated:1700000060 }` | Resolves to a site view with `groupId: "g1"`; `createdAt`/`updatedAt` are the ISO strings of the unix-second timestamps |
| hub-domain-monitored-sites-002 | site-group-view-shape | The group mapper applied to a group row `{ id:"g1", slug:"grp", name:"Grp", retention_days:30, created:1700000000, updated:1700000000 }` | Resolves to a group view with `retentionDays: 30` |
| hub-domain-monitored-sites-003 | endpoint-view-shape | The endpoint mapper applied to an endpoint row `{ id:"e1", site_id:"s1", url:"https://x", kind:"http", expected_status:200, check_interval_seconds:60, is_active:true, created:1700000000, updated:1700000000 }` | Resolves to an endpoint view with `siteId: "s1"`, `expectedStatus: 200`, `checkIntervalSeconds: 60` and `isActive: true` |
| hub-domain-monitored-sites-004 | site-group-view-shape | Same input as 002 | `id`, `slug`, `name` are copied unchanged; `createdAt`/`updatedAt` are the ISO strings of `created`/`updated` |
| hub-domain-monitored-sites-005 | group-list-request | The list-groups operation called with `{ workspace: "acme" }` against a stub GET | The first request is `GET /api/v1/monitoring/site_groups` with query `workspace=acme` (plus the `limit=100` page size) |
| hub-domain-monitored-sites-006 | group-list-sorted-by-name | Stub returns rows named `"Zebra"`, `"Apple"` | The list-groups operation resolves in the order `["Apple", "Zebra"]` |
| hub-domain-monitored-sites-007 | group-create-request | The create-group operation called with `{ name: "Grp", slug: "grp" }` (no `retentionDays`) | `POST /api/v1/monitoring/site_groups` body is `{"name":"Grp","slug":"grp"}` with no `retention_days` key |
| hub-domain-monitored-sites-008 | group-update-request | The update-group operation called with id `"g1"` and `{ retentionDays: 14 }` | `POST /api/v1/monitoring/site_groups/g1` body is `{"retention_days":14}` only |
| hub-domain-monitored-sites-009 | group-delete-request | The delete-group operation called with id `"g1"` | `DELETE /api/v1/monitoring/site_groups/g1`; resolves to no value |
| hub-domain-monitored-sites-010 | site-list-single-request-only | The list-sites operation called with `{ workspace: "acme" }` | One page request is issued (the stub reports no `has_more`), to `GET /api/v1/monitoring/sites` with `workspace=acme`; no request to `/api/v1/monitoring/site_groups` occurs |
| hub-domain-monitored-sites-011 | site-create-request | The create-site operation called with `{ name: "Site", slug: "site", groupId: "g1" }` | `POST /api/v1/monitoring/sites` body is `{"name":"Site","slug":"site","site_group_id":"g1"}` |
| hub-domain-monitored-sites-012 | site-update-request | The update-site operation called with id `"s1"` and `{ groupId: "g2" }` | `POST /api/v1/monitoring/sites/s1` body is `{"site_group_id":"g2"}` only |
| hub-domain-monitored-sites-013 | site-delete-request | The delete-site operation called with id `"s1"` | `DELETE /api/v1/monitoring/sites/s1`; resolves to no value |
| hub-domain-monitored-sites-014 | site-belongs-to-exactly-one-group | A create-site body that omits `groupId` | Does not type-check: `CreateSiteBody.groupId` is a required field. The constraint is compile-time only; there is no runtime guard |
| hub-domain-monitored-sites-015 | endpoint-list-request | The list-endpoints operation called with site id `"s1"` and `{ workspace: "acme" }` | Request is `GET /api/v1/monitoring/endpoints` with `workspace=acme` (plus `limit=100`); no `siteId` query parameter is sent, because the collection has no `site_id` filter |
| hub-domain-monitored-sites-016 | endpoint-list-double-filtered | Stub `GET /api/v1/monitoring/endpoints` returns one row with `site_id: "s1"` and one with `site_id: "other"` | The list-endpoints operation for `"s1"` resolves to only the `s1` row: the client-side filter is the only narrowing, since the server has no `site_id` filter |
| hub-domain-monitored-sites-017 | endpoint-list-sorted-by-url | Stub returns endpoints with `url` `"https://z"`, `"https://a"` | The list-endpoints operation resolves in the order `["https://a", "https://z"]` |
| hub-domain-monitored-sites-018 | endpoint-create-request | The create-endpoint operation called with site id `"s1"` and `{ url: "https://x", kind: "http" }` | `POST /api/v1/monitoring/endpoints` body is `{"site_id":"s1","url":"https://x","kind":"http"}` (no `expected_status`/`check_interval_seconds`/`is_active` keys) |
| hub-domain-monitored-sites-019 | endpoint-update-request | The update-endpoint operation called with id `"e1"` and `{ isActive: false }` | `POST /api/v1/monitoring/endpoints/e1` body is `{"is_active":false}` only, and never includes a `site_id` key regardless of what the caller passes |
| hub-domain-monitored-sites-020 | endpoint-delete-request | The delete-endpoint operation called with id `"e1"` | `DELETE /api/v1/monitoring/endpoints/e1`; resolves to no value |
| hub-domain-monitored-sites-021 | endpoint-kind-passthrough | The create-endpoint operation called with site id `"s1"` and `{ url: "https://x", kind: "ssh" }` | The call resolves normally (the request is sent with `kind: "ssh"` verbatim); no client-side error is thrown despite `"ssh"` not being one of the valid kinds |
| hub-domain-monitored-sites-022 | session-refresh-waterfall | Any operation's first response is `401`; the token-refresh step resolves a new token | The request is retried once with the new token; a `401` on that retry throws a typed HTTP error with `status: 401` |
| hub-domain-monitored-sites-023 | errors-carry-status-and-code | Backend responds `409` to the create-group operation with body `{ error: { message: "slug already exists", code: "duplicate_slug" } }` | The thrown error has `status: 409` and `code: "duplicate_slug"`, with the conflict-friendly-error helper never invoked, so the message is exactly the backend's |
| hub-domain-monitored-sites-024 | no-client-side-cache | Two sequential calls to the list-groups operation with `{ workspace: "acme" }` | Two separate HTTP requests are issued; the second call does not reuse the first response |

## Edge Cases

- **Null and empty input — `workspace`**: not checked client-side in any of the twelve operations. The
  `workspace` option is optional and may be absent; an empty string is silently omitted from the
  query, since the shared scoping helper only passes a truthy `workspace` through. This is a MUST per the observed source; no validation exists.
- **Null and empty input — required create fields**: the create-group, create-site, and create-endpoint
  operations perform no client-side check that `name`/`slug`/`url` are non-empty; an empty string is
  sent to the backend unchanged, since the body-compaction helper only drops absent values, never an
  empty string. MUST behave this way per source.
- **Boundary values — `retentionDays`/`expectedStatus`/`checkIntervalSeconds`**: none of these numeric
  fields has a client-side minimum, maximum, or integer check; whatever number the caller supplies
  (including negative, zero, or non-integer) is sent to the backend unchanged. MUST behave this way per
  source — no declared closed set constrains these fields, unlike `kind`.
- **Boundary values — large collections**: the list-groups, list-sites, and list-endpoints operations
  accept no pagination, cursor, or limit parameter from the caller; the shared paging helper fetches
  `limit=100` pages, advancing `starting_after` while the response reports `has_more`, so a workspace
  with more than one page of groups, sites, or endpoints still receives the complete list, at the cost
  of one request per page. A page that reports `has_more` but whose last row has no id throws rather
  than looping.
- **Concurrent access — module state**: this module holds no shared mutable state between calls (only
  the three read-only path constants and the fixed set of valid endpoint kinds), so there is nothing for
  two concurrent calls to race on within the module itself.
- **Concurrent access — competing writes**: two concurrent update-site/update-group/update-endpoint calls
  for the same `id` follow ordinary last-write-wins `POST` update semantics — last response received wins, with no client-side
  sequencing, optimistic-lock check, or `updatedAt`-based conflict detection in this recipe.
- **Concurrent access — reparent then list**: calling the update-site operation to move a site to a new
  group and then immediately calling the list-sites/list-endpoints operations issues independent
  requests with no client-side cache to invalidate; the second request's freshness depends entirely on
  the backend having committed the first, which this module does not wait on beyond the first request's
  own response.
- **Error states — non-2xx response**: every non-`401` failure and every unresolved `401` throws a
  typed HTTP error carrying the HTTP status and optional code (`errors-carry-status-and-code`); nothing
  in this recipe catches or swallows that error.
- **Error states — `204` on a declared-void write**: the delete-group, delete-site, and delete-endpoint
  operations discard the response body and do not special-case `204`, so a `204` response resolves
  normally; this differs from operations that decode a JSON body, which treat `204` as an error — none
  of the create or update operations can receive a bodiless `204`, since decoding a response treats that
  as an error regardless of caller intent.
- **Offline or disconnected state**: none of the twelve operations catches a network-level connection
  failure; a connectivity loss mid-call propagates as an unhandled asynchronous rejection out of this
  module to the caller, with no retry, queuing, or offline-specific handling anywhere in this recipe.
- **No timeout**: no operation sets a deadline or cancellation signal; a reachable-but-unresponsive
  backend leaves the call pending until the underlying transport's own limit, if any.
- **No cancellation**: no operation accepts a cancellation-signal parameter, so a caller cannot cancel
  an in-flight request through this module.
- **No retry beyond the `401` waterfall**: every write issues exactly one request and every list one request per page (plus, on a `401`, the
  single inherited refresh-and-retry); nothing in this recipe retries a network failure or a non-`401`
  error status.
- **Stale module doc comment**: this module's own top-of-file comment states "the client-side narrowing
  in listSites()/listEndpoints() stays as defense-in-depth," but the list-sites operation's
  implementation performs no such filter — it maps and sorts the response with no owner/workspace
  narrowing of its own; only the list-endpoints operation retains a client-side filter (on `siteId`, per
  `endpoint-list-double-filtered`), and there it is the only site narrowing, not defense-in-depth. This is recorded as an observed discrepancy between the source's
  comment and its code in Design Decisions, not smoothed over.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `workspace` (every operation) | string (caller parameter, optional) | omitted → caller's own owner scope | Percent-encoded and appended as `?workspace=<slug>` by the shared query builder (omitted when empty); pins the operation to a workspace's owning principal instead of the caller's own scope. |
| body (create-group) | `{ name, slug, retentionDays? }` | none — required except `retentionDays` | Sent through the body-compaction helper as the `POST` body, with `retention_days` on the wire. |
| body (update-group) | all fields optional | none — required argument, fields individually optional | Sent through the body-compaction helper as the `POST` body to the item URL. |
| body (create-site) | `{ name, slug, groupId }`, all required | none — required | Sent verbatim (renamed to `site_group_id`) as the `POST` body; not passed through the body-compaction helper. |
| body (update-site) | all fields optional | none — required argument, fields individually optional | Sent through the body-compaction helper (renamed to `site_group_id`) as the `POST` body to the item URL. |
| `siteId` (list-endpoints, create-endpoint) | string (caller parameter, required) | none | Identifies the parent site; not sent on the list-endpoints operation (the /v1 collection has no site filter, so it only drives the client-side filter) and sent as the `site_id` body field on the create-endpoint operation. |
| body (create-endpoint) | `{ url, kind, expectedStatus?, checkIntervalSeconds?, isActive? }` | none — `url`/`kind` required, rest optional | Sent through the body-compaction helper as the `POST` body, with `site_id` added from the operation's own parameter. |
| body (update-endpoint) | all fields optional | none — required argument, fields individually optional | Sent through the body-compaction helper as the `POST` body to the item URL; carries no `site_id` field. |
| valid endpoint kinds | fixed set (`"http"`, `"tcp"`, `"icmp"`) | fixed | The declared set of valid `kind` values; not consulted by the create-endpoint/update-endpoint operations (`endpoint-kind-passthrough`). |
| the three route paths | fixed path strings | fixed | `/api/v1/monitoring/site_groups`, `/api/v1/monitoring/sites`, `/api/v1/monitoring/endpoints`; not injectable or configurable. |

## Deep Linking

Not applicable: this logic registers no URL scheme, route, or navigation target of its own; it is a
data client consumed by a separate presentation layer (the Dashboards feature) that owns any
deep-linking concern.

## Localization

Not applicable: this logic authors no user-facing string of its own — the source contains no thrown
error with an English message anywhere in this recipe (unlike some sibling clients' own validation
errors). Every error message a caller can observe from this module originates in the backend's response
body and is extracted by the shared authenticated request client, not authored here.

## Accessibility Options

Not applicable: this logic renders no UI and responds to none of Reduce Motion, Increase Contrast, or
Differentiate Without Color.

## Feature Flags

Not applicable: the source contains no feature-flag or gating check of any kind; the fixed set of valid
endpoint kinds is a fixed domain vocabulary, not a flag.

## Analytics

Not applicable: the source contains no analytics or event-emission call.

## Privacy

- **Data collected**: this module originates no data of its own; it reads and writes monitoring
  configuration records — group/site names and slugs, retention windows, and endpoint URLs, kinds, and
  check intervals. These are infrastructure-monitoring configuration records, not end-user PII.
- **Storage**: none. Every operation is a stateless per-call request builder (`no-client-side-cache`,
  `module-holds-no-mutable-state`); nothing is held in memory or on disk beyond the lifetime of a single
  call.
- **Transmission**: yes. Every call carries a bearer credential attached by the shared authenticated
  request client, not by this module; whatever transport security the deployment provides is outside
  the scope of this recipe.
- **Retention**: none. Nothing this module handles is retained after the response it produced is
  returned to the caller.

## Logging

Not applicable: this logic contains no logging call of any kind.

## Platform Notes

- **React/Web** (source platform): `packages/web/packages/data/src/monitored-sites/monitored-sites.ts`
  and `wire.ts` hold the client, re-exported by `index.ts` as `@adh-sdk/data/monitored-sites`;
  every function is built on `authedJson`/`authedRequest` (from `../http`, re-exporting
  `@adh-sdk/auth/client`) and `compact`/`enc`/`sortByText` (from
  `../client-helpers`), with `listAllV1`, `withV1Query` and `unixToIso` from the auth package's `v1.ts`
  paging and query helpers. The Dashboards feature (`packages/web/packages/features/dashboards/src/*`) is the
  one current consumer.
- **SwiftUI**: model `SiteGroupView`/`SiteView`/`EndpointView` (and the create/update body shapes) as
  `Codable, Hashable, Sendable` structs, mirroring the sibling Hub domain recipes' models pattern, and the
  twelve functions as `async throws` calls on an `actor` or `@MainActor final class`, with a dedicated
  error type carrying the HTTP status and optional machine code in place of `AuthHttpError`. `ENDPOINT_KINDS`
  becomes a `CaseIterable` `enum` — and, unlike the TypeScript source, a Swift port SHOULD use that enum as
  the `kind` parameter's type rather than a bare `String`, which would close the `endpoint-kind-passthrough`
  gap at compile time rather than reproducing it.
- **AppKit / UIKit**: no direct UI dependency exists in this module; a macOS/iOS Dashboards feature would
  consume the ported client through an injected data-source protocol, the same pattern other Hub domain
  recipes' data sources already use, rather than calling `URLSession` from the view layer.
- **Compose**: model the three wire rows and the six body shapes as Kotlin `data class`es annotated
  `@Serializable`, and the twelve functions as `suspend fun`s on a class built on Ktor or OkHttp, with a
  sealed error type carrying the HTTP status and optional code; model `ENDPOINT_KINDS` as a Kotlin `enum
  class`.
- **WinUI 3**: a .NET port would model `GroupRow`/`SiteRow`/`EndpointRow` and the six body shapes as
  `record`s attributed for `System.Text.Json`, and the twelve functions as `Task<T>`-returning methods on a
  class built on `HttpClient`, attaching `Authorization: Bearer <token>` the way this module's
  `authedFetch` does and refreshing on a `401` the same one-retry way, defining a `MonitoredSitesApiException`
  (status, code) parallel to `AuthHttpError`. Represent `ENDPOINT_KINDS` as a C# `enum EndpointKind { Http,
  Tcp, Icmp }` with a `[JsonConverter]` for the lowercase wire strings, and prefer exposing the endpoint
  list to a bound UI (e.g. a `DataGrid`/`ItemsRepeater`) through an `ObservableCollection<EndpointView>`
  populated after each `Task` completes, rather than a raw array, since WinUI 3's data-binding idiom
  expects change notification a plain `List<T>` does not provide — this is the platform with the least
  existing prior art in this repo for the refresh-and-retry contract, so the WinUI 3 port would need to
  build the equivalent of `authedFetch` itself, not only the twelve request builders.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/data/src/monitored-sites/` | confirmed (2.0.0) |

## Design Decisions

**Decision**: `createSite` builds its body as a plain object literal (`{ name, slug, site_group_id:
body.groupId }`) rather than passing it through `compact()`, even though `createGroup` and
`createEndpoint` both do.
**Rationale**: `CreateSiteBody`'s three fields are all required (unlike `CreateGroupBody.retentionDays`
or `CreateEndpointBody`'s optional fields), so `compact()` would be a no-op here; the source omits the
call rather than applying it unconditionally for consistency.
Platform scope: Web — this is a detail of this platform's own implementation of the body-compaction
helper, not a behavior a port needs to reproduce beyond the observable request body.
**Approved**: pending

**Decision**: the module's own top-of-file comment states "the client-side narrowing in
`listSites()`/`listEndpoints()` stays as defense-in-depth," but `listSites`'s current implementation
performs no owner/workspace filter — only a `sortByText` by name.
**Rationale**: `listSites`'s own inline comment explains the server now owner-scopes `sites` identically
to `site_groups`, and the earlier client-side intersection (against the groups list) was removed
specifically because it round-tripped an extra request and hid rows whose group fell past a capped groups list; the top-of-file
comment appears to predate that refactor and was not updated to drop the `listSites()` half of its claim.
This recipe records the code as it actually behaves — no client-side owner narrowing in `listSites` — per
the source-fidelity guideline's requirement to describe the code as it is rather than as a stale comment
describes it.
**Approved**: pending

**Decision**: `listEndpoints` sends no site filter and narrows by `siteId` on the client, over the whole
endpoints collection.
**Rationale**: the /v1 endpoints collection declares no `site_id` filter, so the only way to return one
site's endpoints is to page the full owner-scoped collection through the shared paging helper and filter
the mapped rows; every operation builds its URL through the same `scoped()`/`withV1Query` helper, so the
workspace pin is uniform. A port reproduces the request and the client-side filter, not the helper names.
**Approved**: pending

**Decision**: endpoint `kind` is not validated client-side against the fixed set of valid endpoint kinds before create or update; an unknown kind is sent to the backend as given.

**Rationale**: a shared value-narrowing helper exists for exactly this purpose but neither operation calls it, and whether the backend rejects an unknown kind is not visible in this checkout; closing the gap would take narrowing `kind` through that helper (or a union type) in both operations.

**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.security.server-side-authorization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90e085e3-5112-5c02-9c10-4a2e324eeca1) | passed | Security |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | partial | Access Patterns |
| [adc.check.access-patterns.pagination-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/e29ce31a-67cb-5690-b2ca-b1065ccdaf1a) | partial | Access Patterns |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | failed | Reliability |

`separation-of-concerns` passes: `monitored-sites.ts`/`wire.ts` contain zero UI or presentation code —
both files are the public data-domain surface consumed by the separate Dashboards presentation layer.
`unit-test-coverage` is `partial`: `monitored-sites.test.ts` covers vectors 001-013 and 015-024 (the three mappers and all twelve operations, with only `fetch` stubbed). Vector 014 (`site-belongs-to-exactly-one-group`) is skipped: it is a compile-time type constraint on `CreateSiteBody.groupId`, which vitest does not type-check and the source does not guard at runtime. `explicit-error-handling` passes: nothing in this file swallows an
error — every failure either throws `AuthHttpError` (via the shared `authedFetch`) or propagates
unmodified. `server-side-authorization` passes: the module contains no client-side permission check of any
kind, per `owner-scoping-server-side`, deferring owner/workspace scoping entirely to the backend.
`error-response-handling` is `partial`: every call exposes a status and optional code for the caller to
branch on, but no function in this file offers per-code handling of its own (no `rethrowConflict`, no
`isNotFound`/`isConflict` branch) — every failure surfaces as the generic `AuthHttpError` propagation.
`pagination-support` is `partial`: `listGroups`, `listSites`, and `listEndpoints` all go
through `listAllV1`, which pages with `limit`/`starting_after` while `has_more`, so no row is silently
dropped; the callers still get no incremental paging or cursor control. `graceful-degradation`
fails: unlike a sibling client's documented fallback constant, this module offers no fallback of any kind
when a call fails — every failure is an unhandled rejection with no degraded-but-functional path.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 2.0.0 | 2026-11-14 | Mike Fullerton | Wire text brought up to the /v1 client: v1 URLs, POST updates, snake_case bodies, paged lists, no endpoint site filter |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Design Decisions keep the Decision / Rationale / Approved triple; each decision's platform line is folded into its rationale. |
| 1.2.0 | 2026-10-04 | Mike Fullerton | Resolve open-question markers against the code; restate unimplemented behavior as current behavior with pending Decisions. |
| 1.1.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to adh/hub/. |
| 1.0.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.0.0 | 2026-09-24 | Mike Fullerton | Initial creation |
