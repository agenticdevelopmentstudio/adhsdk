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

