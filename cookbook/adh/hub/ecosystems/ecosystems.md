---
id: 201572ee-2e0f-4839-94f5-252f8044c4bf
title: "Ecosystems"
type: ingredient
version: 2.1.0
status: review
language: en
created: 2026-09-24
modified: 2026-11-22
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Ecosystems (\"Products\") domain logic: listing, creating, renaming, and deleting a reverse-domain-identified product row, its child ecosystems and settings, and its feature-provisioning catalog, unified by the rdid slug/address contract."
platforms:
  - swift
  - macos
  - ios
  - typescript
  - web
tags:
  - hub
  - ecosystems
  - products
  - rdid
  - slug
depends-on: []
related:
  - 3ea9329e-5acc-4c43-b5ce-bb8c50570104
references: []
approved-by: ""
approved-date: ""
---

# Ecosystems

## Overview

The Ecosystems ingredient is the Ecosystems ("Products") domain of the hub: the
non-UI logic that lists, creates, renames, and deletes an *ecosystem* - a
reverse-domain-identified (rdid) product row that can itself own child
ecosystems, and that other domains (applications, buckets, customers) hang
off of. Two independent, source-of-truth reference implementations model the
identical contract from opposite ends of one system; this ingredient covers both
together, and Platform Notes describes how each
realizes it.

Both implementations model the same backend fact: an ecosystem's public
identity is a *stored, mutable* rdid (`id` / `identifier`), but the row's
*own* address is *derived* from `(parent chain, slug)` - `slug` is the one
field a create or a rename actually supplies, and the two names for the same
value can drift (a handle renamed by the OTHER route - a generic identifier
rename - leaves the slug column behind). Every behavior below that looks
like string manipulation (deriving an identifier prefix, extracting an
address's last segment) exists to keep a caller on the correct side of that
distinction.

One reference implementation also owns a feature picker's data (the catalog
of addable ecosystem features, including "Coming soon" unbuilt ones, what an
ecosystem is provisioned with, what it may not add, adding a batch, and
removing a batch dependents first), the pure requirement rules over that
catalog, a feature manager that answers every surface's "what does this
ecosystem hold" question from one list, and the hub-data ecosystem
resolution that picks where a workspace's Notes, Research, Documents,
Integrations, Planning and Storage live; the other has no counterpart for
any of it in these sources.

## Behavioral Requirements

### Ecosystem record

- **ecosystem-model-shape**: An ecosystem record MUST carry `id`, `slug`,
  `name`, an optional `description`, an optional `region`, an optional
  primary domain, optional `createdAt`/`updatedAt` timestamps, `isDefault`,
  an optional `isInfrastructure` flag, an optional `parentId`, and an
  optional `canManage` flag.
- **ecosystem-decode-default-fallback**: Building an ecosystem record from a
  server payload MUST treat a missing `isDefault` field as `false` rather
  than failing to parse.
- **ecosystem-identifier-prefix**: An ecosystem's identifier prefix MUST be
  everything up to and including the last `.` in its id (e.g. `"org.acme."`
  for `"org.acme.shop"`), and MUST be `""` when the id contains no `.`.
- **ecosystem-is-manageable**: Whether an ecosystem is manageable MUST equal
  its `canManage` flag, treating an absent flag (the server omits it for the
  caller's own ecosystems) as manageable - only an explicit `false` blocks
  descending into it.
- **ecosystem-create-input-defaults**: Creating an ecosystem MUST default
  `region` and the primary domain to `""` when the caller omits them.
- **ecosystem-update-input-shape**: Updating an ecosystem MUST accept every
  field (`slug`, `name`, `description`, `region`, primary domain) as
  optional, so a caller can patch a subset.
- **address-leaf-extraction**: Extracting an address's leaf segment from an
  identifier MUST return everything after the last `.` - a pure string
  slice with no rdid-grammar validation, deliberately mirroring the
  backend's own leaf extraction character for character.
- **to-ecosystem-field-mapping**: Mapping a stored ecosystem row into the
  ecosystem record MUST map the row's id to both the record's id and
  identifier, its slug to slug, its nullable description/region columns to
  `""` when absent, its primary-domain column to the record's domain field
  (`""` when absent), and MUST include `canManage` in the result only when
  the row itself defines it, and likewise `type` only when the row defines
  it, never as an explicit absent-marker value.
- **ecosystem-type-values**: The web ecosystem record's optional type MUST
  be one of `workspace`, `persona`, `personal`, `organization`, `container`,
  or `product`, and MUST be absent when the backend predates the column.
- **hub-data-ecosystem-predicate**: An ecosystem MUST count as a hub-data
  ecosystem exactly when its type is `personal` or `organization`, and a
  row with no type MUST NOT count as one. The predicate MUST accept the wire
  row and the mapped record alike, and MUST answer false for an absent row.
  Hub-data ecosystems have a fixed name and slug and can be neither deleted
  nor given sub-ecosystems or a feature picker.

### Data access boundary

- **ecosystems-data-source-contract**: The ecosystems data-access boundary
  MUST expose exactly: list, children-of-a-parent, get-by-id,
  infrastructure-id, identifier-exists, create, update, and delete
  operations, each of which may fail.
- **ecosystems-list-includes-defaults**: The list operation's own contract
  MUST hold that it includes default rows - hiding `isDefault` rows is the
  root listing's job, not the data-access boundary's.

### Root listing and rail navigation

- **root-level-hides-defaults**: The root listing MUST filter out every
  `ecosystem.isDefault == true` row before building items.
- **root-level-shape**: The root listing MUST have id `"ecosystems"`, title
  `"Products"`, empty message `"No products yet."`, and a create action
  titled `"New Product"` that presents the create form for a new, parentless
  ecosystem.
- **root-level-errors-wrap**: Fetching the root listing MUST surface any
  failure from the underlying list call as a domain error rather than
  letting through whatever error shape the call itself raised.
- **ecosystem-item-shape**: An ecosystem's rail item MUST use the
  ecosystem's id as both its id and sublabel, the ecosystem's name as its
  label, and a shipping-box icon.
- **child-by-id-not-found-is-empty**: Resolving an ecosystem by id for the
  rail MUST return an empty result when that resolution reports not-found,
  and MUST surface any other failure as a domain error.
- **child-manageability-gate-first**: Descending into an ecosystem MUST
  check whether it is manageable BEFORE resolving any topic - an
  unmanageable ecosystem MUST return a notice detail (id
  `"ecosystem:<id>:not-manageable"`, the fixed not-manageable title and
  message) regardless of what path segment follows.
- **not-manageable-copy**: The not-manageable notice's title MUST be
  `"You don't have admin access to this ecosystem"` and its message MUST be
  `"Viewing an ecosystem's contents needs organization admin access"`
  followed by the character U+2014 (a spaced dash) and `"ask one of the
  organization's admins."`
- **topics-level-shape**: With no further path segment, descending into an
  ecosystem MUST return a list with id `"ecosystem-topics"`, title equal to
  the ecosystem's name, and items built from the topic set in the order the
  caller supplied it - the rail MUST NOT impose a fixed topic order of its
  own.
- **topic-dispatch-by-entry-id**: With a topic-id path segment, descending
  into an ecosystem MUST look up the matching topic by its entry id and
  return an empty result when none matches, else delegate to that topic.

### Topic composition

- **topic-entry-to-item**: A topic entry converted to a rail item MUST carry
  its id, label, sublabel equal to its description, icon, divider-after
  flag, and its destination (defaulting to a list).
- **topic-group-level-shape**: With no further path segment, a topic group
  MUST return a list with id `"ecosystem-group:<entry id>"`, title equal to
  the entry's label, and its children mapped to items; with a segment, it
  MUST delegate to the matching child by entry id or return an empty result.
- **notice-topic-detail-shape**: A notice topic MUST always return a detail
  view with id `"ecosystem:<ecosystem id>:<entry id>"`, title equal to the
  entry's label, and the fixed message it was constructed with - it MUST
  NOT branch on the remaining path.

### Creating an ecosystem

- **create-form-fields**: The create form MUST define exactly three fields,
  in order: `name` (text, required), `slug` (text, required, matching the
  slug pattern, with the associated validation message), `description`
  (text area, optional, at least 3 lines).
- **create-form-slug-lowercased**: The save action MUST lowercase the
  submitted slug before deriving the identifier or probing for existence,
  independent of the field validator's own pattern check.
- **create-form-slug-max-length**: The save action MUST reject the save
  with a validation error reading `"Slug must be 64 characters or fewer."`
  when the lowercased slug exceeds 64 characters.
- **create-form-prefix-resolution**: The save action MUST use the parent
  ecosystem's id as the address prefix when a parent was supplied at
  construction, and MUST otherwise resolve the caller's infrastructure id
  for the prefix, surfacing any failure from that resolution as a domain
  error.
- **create-form-identifier-derivation**: The derived identifier MUST be
  exactly `"<prefix>.<slug>"`.
- **create-form-duplicate-probe**: Before creating, the save action MUST
  probe whether the derived identifier already exists and reject the save
  with a validation error reading `Identifier "<identifier>" is already in
  use.` when it does, without ever issuing the create call.
- **create-form-conflict-mapping**: A conflict raised by the create call
  MUST be re-surfaced as a validation error reading `An ecosystem with
  identifier "<identifier>" already exists.`; any other failure MUST be
  surfaced as a domain error.
- **create-body-shape**: Creating an ecosystem over the wire MUST send the
  identifier as `id` and the address's last segment (never the whole dotted
  identifier) as `slug`, plus `name`, `description`, `region`, and the
  primary domain.
- **create-scoping-url**: A create request MUST scope to a parent when one
  is given, else to a workspace when one is given, else use the bare base
  route; a given parent MUST win when both are supplied.
- **create-conflict-mapping**: A create request that fails with an error
  whose message contains "already exists" (case-insensitive; the backend's
  uniqueness conflict) MUST be surfaced with the message `An ecosystem with
  identifier "<identifier>" already exists.`; any other failure MUST be
  rethrown unchanged. The create makes no duplicate pre-read.

### Ecosystem settings

- **settings-form-fields**: The settings form MUST define, in order: `name`
  (text), `slug` (text, matching the slug pattern), `id` (read-only,
  monospaced, labeled `"Identifier"`), `description` (text area), `region`
  (read-only, labeled `"Geographic Region"`).
- **settings-values-region-hardcoded**: The settings form's values MUST
  report `region` as the literal string `"coming soon"` regardless of the
  ecosystem's own region value.
- **settings-save-identifier-derivation**: The save action MUST derive the
  target identifier as the ecosystem's identifier prefix plus the
  lowercased submitted slug, never from the form's read-only `id` field.
- **settings-save-slug-lowercased**: The save action MUST lowercase the
  submitted slug before deriving the identifier, independent of the field
  validator's own pattern check.
- **settings-save-slug-validation**: The save action MUST validate the
  lowercased slug against the slug pattern and reject the save with a
  validation error naming the derived identifier and describing the
  allowed character set when it fails.
- **settings-save-excludes-region**: The update the save action sends MUST
  carry only `slug`, `name`, and `description` - it MUST NOT set `region`
  or the primary domain, even though the form displays a region value.
- **settings-save-conflict-mapping**: A conflict raised by the update call
  MUST be re-surfaced as a validation error reading `Identifier
  "<identifier>" is already in use.`; any other failure MUST be surfaced as
  a domain error.
- **settings-delete-action**: The settings form's delete action MUST be
  titled `"Delete Product"` with the fixed confirmation warning, and MUST
  call the delete operation for the ecosystem's id, surfacing any failure
  as a domain error.

### Reading, listing, and updating an ecosystem over the wire

- **list-hides-defaults-sorted**: The list operation MUST filter out every
  `isDefault === true` row and sort the remainder by name, locale-aware.
- **list-for-workspace-scoped**: Listing scoped to a workspace MUST request
  that workspace's scope and sort by name; it MUST NOT client-filter
  `isDefault`, since the server already excludes both structural defaults
  and the principal's own infrastructure row for this scope.
- **list-children-scoped**: Listing an ecosystem's children MUST request
  that parent's scope and sort by name.
- **get-404-is-null**: Getting an ecosystem by id MUST return `null` when
  the request fails with not-found, and MUST rethrow any other failure
  unchanged.
- **update-slug-sent-on-presence**: Updating an ecosystem MUST send the
  address's last segment as `slug` whenever an identifier is supplied -
  including when the submitted identifier equals the stored id - and MUST
  NOT diff the submitted identifier against the stored id to decide whether
  to send it, because the stored id is the handle, not the address the row
  currently derives to, and the two can disagree on a drifted row.
- **update-omits-unset-fields**: The update's body MUST omit any field the
  caller did not supply (including `slug` when no identifier is supplied)
  entirely, never sending it as an explicit absent-marker value.
- **update-single-write**: An update MUST be exactly one write request - it
  MUST NOT follow up with a second call to rename a handle.
- **update-returns-server-derived-row**: An update's resolved ecosystem
  record MUST reflect the address the server derived from the write, never
  the identifier the caller typed, since a malformed or stale prefix in the
  caller's identifier can derive to a different address than what the
  caller assumed.
- **delete-no-body**: Deleting an ecosystem MUST send a delete request with
  no body and resolve with no value.
- **auth-settings-same-route-with-include**: Reading an ecosystem's auth
  settings MUST be a read of that ecosystem's own route with the
  `auth_settings` include (`include[]=auth_settings`), and updating them MUST
  be a POST to that same route carrying an `auth_settings` body; there is no
  separate auth-settings route.
- **auth-settings-login-allow-list-mapping**: Auth settings read from the
  wire MUST carry `loginAllowedEmails` from `login_allowed_emails`,
  reading an absent field as `null` (every customer may sign in) and keeping
  `[]` (no customer may) distinct from it. An auth-settings patch that sets the
  field MUST send it as `login_allowed_emails`, sending an explicit
  `null` rather than omitting it.

### Child ecosystems

- **child-ecosystems-list-shape**: With no further path segment, descending
  into "child ecosystems" MUST return a list with id
  `"child-ecosystems-list"`, title equal to the entry's label (`"Child
  Ecosystems"`), empty message `"No child ecosystems yet."`, and a create
  action titled `"New Ecosystem"` that presents the create form scoped to
  this ecosystem as parent.
- **child-ecosystems-descend-not-found-empty**: Resolving a child by id
  MUST return an empty result when that resolution reports not-found, and
  MUST surface any other failure as a domain error.
- **child-ecosystems-recurse-via-rail**: Once a child ecosystem resolves,
  its remaining path MUST be delegated back to the same rail rather than
  resolved locally - this is what lets an arbitrarily deep chain of child
  ecosystems reuse the exact same rail (manageability gate, topic dispatch,
  settings, further child ecosystems) at every level.

### Identifier rename and slug ownership

- **identifier-exists-never-404s**: The identifier-existence probe MUST
  return its boolean result directly - it MUST NOT itself fail for an
  identifier that is not taken (a not-found answer means free and yields
  `false`); any other failure MUST be rethrown.
- **identifier-rename-conflict-mapping**: Renaming an identifier MUST
  request the change and MUST surface an error whose message contains
  "already exists" (case-insensitive) with the message `The identifier "<next
  identifier>" is already in use.`; any other failure is rethrown unchanged.
- **identifier-rename-is-not-ecosystems-renaming-route**: The generic,
  entity-agnostic identifier-rename mechanism (shared across
  ecosystem/application/persona/namespace/organization) MUST NOT be used to
  rename an ecosystem's address - the ecosystem update call that carries
  `slug` is the correct route for that, per #requirements/update-slug-sent-on-presence.
- **ecosystem-id-for-slug-ownership-first**: Resolving an ecosystem id for a
  slug MUST first try to resolve the caller's own workspace-scoped default
  for that slug; on any failure other than not-found, it MUST rethrow
  without falling back to a scan; when that resolution finds a row it MUST
  return that row's id; only a not-found (the slug names no workspace) or a
  resolved empty answer (no infrastructure row) MUST license a fallback raw
  scan of the unfiltered base list, returning the first row matching the
  slug, else the first default row, else the first row, else nothing.
- **workspace-default-ecosystem-id-shape**: Resolving the workspace default
  ecosystem id MUST scope the request to the given workspace and to the
  caller's infrastructure row when a workspace is given, else scope to the
  caller's own infrastructure row; it MUST return nothing (never an
  undefined/absent-marker value) when the response is an empty list; and it
  MUST return `canManage` as `true` unless the row explicitly says `false`.
- **hub-data-ecosystem-id-shape**: Resolving a workspace's hub-data ecosystem
  id MUST list the ecosystems scoped to the given workspace, MUST return the
  id of the first row that is a hub-data ecosystem, and MUST return nothing
  (never an undefined/absent-marker value) when no row is one.
- **list-pages-all-rows**: Every list read of the ecosystems route (the
  unfiltered list, the workspace-scoped list, the children list, the
  infrastructure and hub-data lookups, and the slug fallback scan) MUST read
  every page and return the rows of all pages as one list.

### Workspace default resolution (query state)

- **workspace-default-hook-always-enabled**: The workspace-default-ecosystem
  query MUST NOT be disabled on the workspace slug being defined - it MUST
  always run, resolving the caller's own row when no slug is given.
- **workspace-default-hook-query-key**: The query's cache key MUST include
  the tenant id and the workspace slug (or an explicit absent marker when
  none is given), so the cache entry is scoped per tenant and per slug.
- **workspace-default-hook-shared-client**: The query MUST use one
  module-scoped shared query client explicitly rather than a client from
  ambient context, so the cache entry is shared platform-wide across every
  mounting host.
- **workspace-default-hook-result-shape**: The query's result MUST expose
  the resolved ecosystem id (or nothing), `canManage` (defaulting to
  `true`), whether the last read failed (including a background re-read
  behind an answer still in hand), whether the read failed and there is no
  answer at all (false when a failed re-read sits behind a cached answer,
  which it MUST keep), whether no answer has arrived yet (distinct from a
  resolved-but-empty answer), and whether a read is currently in flight
  (true on a cached mount that is re-reading, where nothing is pending).
- **workspace-default-hook-no-retry**: The query MUST be configured not to
  retry automatically on failure.

### Invitations topic data

- **eco-invitations-keys-namespaced-by-rdid**: Every cache key for the
  Invitations topic MUST include the ecosystem's rdid as its second
  element, so two ecosystems' Invitations caches never collide.
- **eco-invitations-list-hooks-map-rows**: The requests, pending-users, and
  invites list queries MUST fetch from the matching Invitations endpoint
  for the ecosystem and map every row through the shared row mappers
  before returning them.
- **eco-invitations-notes-history-gated-on-subject**: The row-notes and
  row-history queries MUST be disabled while no subject id is given -
  neither query may run for an empty subject id.
- **eco-invitations-save-notes-invalidates-notes-and-history**: Saving
  notes, on success, MUST invalidate both the matching notes cache entry
  and the matching history cache entry for the same subject.
- **eco-invitations-send-invalidates-pending-and-invites**: Sending
  invitations, on success, MUST invalidate both the pending-users cache
  entry and the invites cache entry for the ecosystem.
- **eco-invitations-add-pending-invalidates-pending**: Adding pending
  users, on success, MUST invalidate the pending-users cache entry.
- **eco-invitations-delete-row-dispatch**: Deleting an Invitations row MUST
  select the matching delete endpoint by the row's kind, and on success
  MUST invalidate exactly the one list cache entry matching that same kind.

### Feature provisioning - catalog and state

- **features-bespoke-route**: Every feature-picker call MUST target its own
  dedicated route, never the generic ecosystems create/read/update/delete
  base, because provisioning a feature has side effects on the server (its
  storage, child ecosystem, and roles are created when the feature is added
  and at no other time).
- **features-path-segments-encoded**: Listing, provisioning, and removing
  MUST URL-encode the ecosystem identifier (an rdid or opaque id) and the
  feature key before placing them in the path.
- **features-catalog-order-preserved**: Fetching the feature catalog MUST
  return the response's feature list unchanged, in the backend's own order
  - the client MUST NOT sort or filter it.
- **features-catalog-entry-shape**: A catalog entry MUST carry a stable key
  (what a provisioned row is keyed by), a label, a description, a
  subscription tier, and the optional flags for whether it has a feature
  site and whether it is coming soon. It MAY also carry the catalog keys it
  requires, the sets contribution (a permission flag and typed limits, mapped
  from the wire's set entries), the ecosystem types allowed to hold it, the
  ecosystem types that get it automatically with no owner opt-in, and the
  key of the feature it comes with. A wire field the backend omits MUST stay
  absent on the record, never become an explicit absent-marker value.
- **features-catalog-wire-mapping**: Mapping a catalog wire row MUST read
  `subscription_tier` as the subscription tier, `feature_site` as the
  feature-site flag, `coming_soon` as the coming-soon flag,
  `requires_features` as the required keys, `allowed_in` as the allowed
  ecosystem types, `automatic_in` as the automatic ecosystem types,
  `included_with` as the key of the feature it comes with, and `set_entries`
  as the sets contribution.
- **features-catalog-and-list-paged**: Fetching the catalog and listing an
  ecosystem's provisioned features MUST each read every page of their route,
  advancing by the last row's key (the catalog's `key`, the provisioned
  list's `feature_key`), and MUST return the rows of all pages as one list.
- **features-included-with**: A feature that comes with another (a catalog
  entry whose included-with key is set) is still a feature of its own on the
  server, but it MUST NOT be offered to the owner as a separate choice:
  adding its parent adds it and removing its parent removes it.
- **features-subscription-tier-open-string**: A feature's subscription tier
  MUST be treated as an open, unconstrained value rather than a closed set,
  so a tier the backend adds later renders instead of failing to parse; the
  client MUST only display it, never branch on it.
- **features-coming-soon-passthrough**: A catalog entry marked coming-soon
  MUST be returned like any other entry - the client MUST NOT filter it
  out; it is listed so the owner can see it is coming, shown under "Coming
  soon" with its checkbox disabled, and the backend refuses to provision
  it.
- **features-list-all-states**: Listing an ecosystem's provisioned features
  MUST return every feature in every state (provisioning, active, removed)
  unfiltered - callers filter.
- **features-provisioned-shape**: A provisioned feature MUST carry its
  feature key, state, when it was provisioned, who provisioned it (or
  nothing), and when it was last updated. The last-updated value MUST be an
  ISO timestamp, converted from the wire's UNIX seconds when the wire sends a
  number and passed through when it sends a string.
- **features-state-readings**: The one provisioned list MUST be read two ways
  by named helpers rather than re-filtered by each reader: the keys the
  ecosystem HAS (every state except removed, provisioning included, so a
  feature still being built is not offered for adding twice) and the keys it
  can be NAVIGATED into (active only, since a provisioning feature can have
  stopped partway).
- **features-availability-read**: Reading what an ecosystem may not add MUST
  request the ecosystem's features route with the availability include and a
  limit of 1, and MUST return the list of unavailable features (each a key
  and the sentence saying why), or an empty list when the response carries
  none.
- **features-availability-query**: The availability query MUST be disabled
  while the ecosystem id is nothing, undefined, or empty, MUST be keyed by
  the ecosystem id under an availability marker, MUST use the same
  30-minute freshness window as the catalog, and MUST NOT be invalidated by a
  provision or a removal, because availability is a property of what the
  ecosystem is, not of what it holds.

### Feature provisioning - mutating and caching

- **features-provision-one-request**: Provisioning a batch of features
  MUST send exactly one request carrying the whole batch of keys, never one
  request per key.
- **features-provision-returns-full-list**: Provisioning MUST resolve to
  the ecosystem's full provisioned list after the add, not only the added
  rows.
- **features-remove-single-delete**: Removing one feature MUST send one
  delete request with no body and resolve with no value.
- **features-remove-404-is-success**: Removing a feature MUST resolve (not
  fail) when the delete fails with not-found, because the row is already
  gone.
- **features-remove-rethrows-other-errors**: Removing a feature MUST
  rethrow every other failure unchanged, except the feature-required refusal
  below.
- **features-remove-feature-required-error**: A removal refused with an
  auth-client HTTP error carrying a 409 status whose body carries the error code `feature_required` and a
  list of blocking keys (read from `needed_by`, else `neededBy`) MUST be
  rethrown as a typed feature-required error that keeps the server's message,
  exposes the blocking keys, and carries a list of other failed keys that is
  empty by default. A conflict with no such body, or whose error code is any
  other value, MUST be rethrown as the plain error it was.
- **features-query-keys**: The catalog's cache key MUST carry no ecosystem
  id - the catalog is a property of the server build, shared by every
  ecosystem - and the provisioned-features cache key MUST include the
  ecosystem id (or an explicit empty marker).
- **features-catalog-stale-time**: The feature catalog MUST be considered
  fresh for 30 minutes (1,800,000 ms), so opening the picker again within
  that window does not refetch it.
- **features-provisioned-query-gated**: The provisioned-features query MUST
  be disabled while the ecosystem id is nothing, undefined, or empty.
- **features-hooks-context-client**: The feature queries and mutations MUST
  use the shared query client from ambient context - unlike the
  workspace-default-ecosystem query, which uses the module singleton
  explicitly.
- **features-provision-writes-cache-then-invalidates**: Provisioning, on
  success, MUST first write the returned full list into the
  provisioned-features cache entry and then invalidate that same entry, so
  a dependent view redraws on the same tick and still picks up a concurrent
  session's changes.
- **features-remove-hook-invalidates**: Removing one feature, on success,
  MUST invalidate the provisioned-features cache entry and MUST NOT write
  to the cache directly (the delete returns no list).
- **features-apply-adds-first**: Applying a batch of feature changes MUST
  await the single add request before issuing any removal, so a failed
  removal never costs the owner the features just added; a failed add MUST
  reject the whole change before any removal is sent.
- **features-apply-skips-empty-add**: Applying a batch of feature changes
  MUST NOT send an add request when there is nothing to add.
- **features-apply-removals-all-settled**: Applying a batch of feature
  changes MUST issue one removal per key to remove, run the removals of a
  level concurrently, and wait for all of a level before sending the next, so
  one rejected removal MUST NOT prevent the others, in its level or a later
  one, from being attempted.
- **features-apply-removals-dependents-first**: Applying a batch of feature
  changes with more than one key to remove MUST send the removals as levels,
  dependents first (see the removal-levels requirements), and MUST send a
  level only after every removal of the level before it has settled. The
  catalog used for ordering MUST be the listed catalog, read from the cache
  the picker already filled and fetched only when it is not cached or is
  older than the 30-minute freshness window, so a
  listed key whose included feature needs another is ordered before it. A
  batch of one key MUST NOT read the catalog.
- **features-apply-ordering-best-effort**: When the catalog cannot be read for
  ordering, applying the change MUST send every removal as one concurrent
  level rather than failing, because the order is a courtesy and the
  backend's refusal is the enforcement.
- **features-apply-names-failed-keys**: When one or more removals fail with
  an error other than a feature-required refusal, applying the change MUST
  reject with `Couldn't remove: <keys>`, naming the failed keys in the
  caller's removal order, joined by a comma and a space.
- **features-apply-feature-required-rethrown**: When any removal fails with a
  feature-required refusal, applying the change MUST reject with a new
  feature-required error built from the first such failure's message and
  blocking keys, whose other-failures list names every other key that failed
  in the same batch, in removal order, so no second failure is dropped.
- **features-apply-404-removal-succeeds**: A removal that reports
  not-found MUST count as success, so a change whose only removal failures
  are not-found results MUST resolve.
- **features-apply-invalidates-on-settle**: Applying a batch of feature
  changes MUST invalidate the provisioned-features cache entry after it
  settles - on success AND on failure, since a failure partway still
  changed part of the list.
- **features-no-client-dedupe**: Applying a batch of feature changes MUST
  pass the add list through as given and MUST NOT reject a key present in
  both lists; because adds run first, such a key is provisioned and then
  removed. A removal list of more than one key is de-duplicated only for
  ordering, so a repeated key is deleted once and every occurrence reports
  that one outcome.
- **features-mutation-null-id-unguarded**: the feature-provisioning mutations SHOULD
  reject a call whose ecosystem id is absent before any request is sent, or take a
  non-optional id. Today the id is optional and unguarded: a mutation fired before the id
  resolves sends its request to a path segment holding a literal absent-marker rather than
  failing fast on the client. A port SHOULD NOT copy that behavior.

### Feature provisioning - removal ordering

- **removal-levels-dependents-first**: Ordering a batch of removals MUST
  return levels of keys such that no key is required by a key in a later
  level, where requirements are the catalog's required keys followed
  transitively, including through a key that is not in the batch. A key's
  level MUST be one more than the deepest batch key that requires it, and
  zero when no batch key does.
- **removal-levels-independent-keys-share-a-level**: Keys of the batch that do
  not depend on each other MUST land in the same level, in the caller's
  order, and a repeated key MUST appear once.
- **removal-levels-unknown-keys**: A key the catalog does not know MUST be
  treated as requiring nothing, and MUST NOT produce an empty level.
- **removal-levels-terminate-on-cycles**: Ordering MUST terminate when the
  catalog's requirements contain a cycle, rather than recursing forever.

### Feature requirements (pure rules)

- **required-closure**: The required closure of a feature MUST be every
  catalog key that must be on before it can be, that is, its own required
  keys plus theirs transitively, each listed once in discovery order, and
  MUST terminate on a cycle.
- **needed-by**: The features that need a key MUST be the catalog features,
  other than the key itself, that are currently on (by a caller-supplied
  predicate) and whose required closure includes the key. A feature that is
  itself off MUST need nothing, which is what makes turning a key off safe once
  everything that needed it is off too.
- **listed-feature-key**: The listed key of a feature MUST be the feature
  itself, or, for a feature that comes with another, the feature it comes
  with followed to the top, stopping where a chain would repeat.
- **listed-catalog**: The listed catalog MUST omit every feature that comes
  with another and MUST turn what a folded feature requires into its
  parent's requirement, named by the LISTED key of each requirement and never
  naming the parent itself. A listed feature whose resulting requirement set
  is empty and which declared none MUST be returned unchanged.
- **needed-by-message**: The copy for a blocked tick-off MUST be exactly
  `this feature is needed by <labels joined by ", "> features`, shared by
  every surface that explains the refusal, so the in-dialog refusal and the
  backend-race refusal read identically.

### Feature manager

- **feature-holdings-readings**: Reading the provisioned rows into holdings
  MUST produce four sets of feature keys derived from the one list: the
  present keys (every state but removed), the active keys, the provisioning
  keys, and the removed keys.
- **feature-row-state**: A row standing on a list of features MUST be
  `active` when any of its features is active, else `provisioning` when any
  is provisioning, else `hidden`. A row that names no features (a structural
  row such as Settings or Child Ecosystems) MUST always be `active`, so a row
  that stands for a feature is drawn only while the ecosystem holds one of
  its features.
- **feature-row-label**: A row standing on exactly one feature MUST be
  labeled with that feature's catalog label, and MUST fall back to the given
  name when the catalog is absent, does not list the feature, or when the row
  stands on several features or none.
- **feature-unavailable-reason**: The reason a feature cannot be added MUST be
  nothing when the ecosystem already holds it (so its tick stays live for
  unticking), else `Coming soon.` when it is coming soon, else the server's
  per-ecosystem reason for it, else nothing.
- **features-added-with**: The features added together with a key MUST be the
  key itself followed by its required closure, minus every key the ecosystem
  cannot add.
- **feature-manager-one-answer**: The feature manager hook for an ecosystem
  MUST expose the catalog, the listed catalog (nothing until the catalog
  lands), a function mapping a key to its listed key, the raw provisioned
  read, the holdings (nothing until the first read lands), a label lookup
  (the catalog label, else the caller's fallback, else the key itself), the
  apply mutation, the map from key to the reason it cannot be added (empty
  until the read lands), the raw availability read, and a needed-by lookup
  that resolves the key to its listed key and searches the listed catalog.
- **feature-manager-shared-cache**: Every reader of one ecosystem's features
  MUST share one cache entry per ecosystem, so an apply redraws every surface
  on the same tick.

### Hub-data ecosystem resolution (query state)

- **hub-ecosystem-id-prefers-hub-child**: The hub-data ecosystem id for a
  workspace MUST be the workspace's live hub-data child when it resolves,
  else the workspace's default (infrastructure) ecosystem id, else nothing.
- **hub-ecosystem-id-pending-is-undefined**: The hub-data ecosystem id MUST
  be undefined while either answer that it still needs is in flight and
  MUST be nothing (not undefined) once both have settled with no ecosystem.
- **hub-ecosystem-failed-child-falls-back**: A failed hub-child lookup MUST
  fall back to the default ecosystem rather than fail, and the hub-child
  query MUST NOT retry.
- **hub-ecosystem-without-slug**: With no workspace slug the hub-child query
  MUST resolve to nothing without a request.
- **hub-ecosystem-query-key**: The hub-child query's cache key MUST include
  the tenant id and the workspace slug (or an explicit absent marker), and
  the query MUST use the module-scoped shared query client.
- **hub-scope-shape**: The hub scope MUST be the workspace default query's
  result with its ecosystem id replaced by the hub-data ecosystem id, keeping
  the workspace's management flag and error flags, because the hub-data
  child is the same principal's and has no permission rows of its own.
- **hub-scope-pending-covers-both**: The hub scope's pending flag MUST hold
  while the hub-data id is undefined or the workspace read is pending, so a
  caller that shows a "no ecosystem" notice waits for both answers and
  `canManage` is never reported from its default.

## Appearance

Not applicable - this is domain logic (a data-access boundary, a form/rail
model, and API clients), not a visual component. One reference
implementation composes form and rail values that a separate, generic
rendering layer draws; the other returns typed data and query/mutation state
that a separate set of panes render.

## States

Not applicable - this is domain logic, not a visual component. Its
observable "states" are the ordinary async-operation states a caller already
handles generically: in-flight, succeeded, and failed (a thrown domain
error).

## Accessibility

Not applicable - this is domain logic, not a visual component. Every string
this component defines (form field labels, delete-confirmation text, error
messages) is plain text handed to a separate, generic rendering layer, which
owns accessibility presentation.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ecosystems-001 | ecosystem-decode-default-fallback, ecosystem-identifier-prefix | Decode a payload for id `org.acme.shop`, slug `shop`, name `Shop`, with created/updated timestamps but no `isDefault` and no `canManage` field | `isDefault` is `false`; the ecosystem is manageable; the identifier prefix is `"org.acme."` |
| ecosystems-002 | ecosystem-identifier-prefix | The identifier prefix of an ecosystem whose id is `"shop"` (no `.`) | `""` |
| ecosystems-003 | root-level-hides-defaults, root-level-shape | The root listing over three rows: one default row and two ordinary rows (`shop`, `blog`) | Items list only the two ordinary rows (`"org.acme.shop"`, `"org.acme.blog"`); title `"Products"`; empty message `"No products yet."`; create action titled `"New Product"` |
| ecosystems-004 | topics-level-shape | Descending into an ecosystem with three topics registered in order: a storage group topic, the child-ecosystems topic, the settings topic | A list with id `"ecosystem-topics"` and items `["storage","child-ecosystems","settings"]` in that same caller-supplied order |
| ecosystems-005 | child-manageability-gate-first, not-manageable-copy | Descending into an ecosystem whose `canManage` is `false` | A detail view with id `"ecosystem:org.acme.shop:not-manageable"`, the fixed not-manageable title, and the fixed not-manageable message |
| ecosystems-006 | topic-group-level-shape | Descending into the `"storage"` group topic, then its `"all-data"` child | The group's own list, id `"ecosystem-group:storage"`; the child detail carries id `"ecosystem:org.acme.shop:all-data"` |
| ecosystems-007 | topic-dispatch-by-entry-id, child-by-id-not-found-is-empty | Descending into an unknown ecosystem, and into a known ecosystem but an unknown topic | Both resolve to an empty result |
| ecosystems-008 | settings-form-fields, settings-values-region-hardcoded | Opening the settings view for `shop` (description: `"Storefront"`) | Fields in order `["name","slug","id","description","region"]`; values `name="Shop"`, `slug="shop"`, `id="org.acme.shop"`, `description="Storefront"`, `region="coming soon"`; the `id` field is not editable; delete action titled `"Delete Product"` |
| ecosystems-009 | settings-save-identifier-derivation, settings-save-excludes-region | Changing name to `"Web Shop"` and slug to `"web-shop"` in the settings form, then saving | The update call carries id `"org.acme.shop"`, slug `"web-shop"`, name `"Web Shop"`, description `"Storefront"`, and no region value |
| ecosystems-010 | settings-save-conflict-mapping | The update call fails with a conflict while saving a settings change to slug `"blog"` | The save fails with the message `"Identifier \"org.acme.blog\" is already in use."` |
| ecosystems-011 | settings-delete-action | Invoking the settings delete action for `shop` | The delete operation is called for `"org.acme.shop"` |
| ecosystems-012 | child-ecosystems-list-shape, child-ecosystems-recurse-via-rail | Descending `shop → child-ecosystems`, listing one child `shop.eu`, then descending into it and its settings topic | The list has id `"child-ecosystems-list"` and a create action titled `"New Ecosystem"`; the nested settings detail carries id `"ecosystem:org.acme.shop.eu:settings"` |
| ecosystems-013 | create-form-prefix-resolution, create-form-identifier-derivation | Creating a new top-level ecosystem with slug `"shop"` when the caller's infrastructure id is `"org.acme"` | The created identifier is `"org.acme.shop"` with no parent |
| ecosystems-014 | create-form-prefix-resolution | Creating a child ecosystem with slug `"eu"` under a parent whose id is `"org.acme.shop"` | The created identifier is `"org.acme.shop.eu"` with parent `"org.acme.shop"` |
| ecosystems-015 | create-form-slug-max-length, create-form-duplicate-probe, create-form-conflict-mapping | Three create attempts: a 65-character slug; the slug `"taken"` which already exists; the slug `"fresh"` whose create call reports a conflict | Errors respectively: `"Slug must be 64 characters or fewer."`, `"Identifier \"org.acme.taken\" is already in use."`, `"An ecosystem with identifier \"org.acme.fresh\" already exists."`; no create call ever completes |
| ecosystems-016 | create-form-slug-lowercased | Saving a new ecosystem with name `"Shop"`, slug `"SHOP"`, description `"Storefront"` | The create call's slug is `"shop"` and its identifier is `"org.acme.shop"` |
| ecosystems-017 | settings-save-slug-lowercased | Saving a settings change with name `"Shop"`, slug `"SHOP"`, description `"Storefront"` | The update call's id is `"org.acme.shop"` and its slug is `"shop"` |
| ecosystems-018 | root-level-errors-wrap | The list call fails while fetching the root listing | The failure surfaces as a domain error |
| ecosystems-019 | to-ecosystem-field-mapping | Mapping a stored row with id `"com.acme"` and a primary domain of `"acme.com"` | id and identifier both `"com.acme"`; domain `"acme.com"` |
| ecosystems-020 | to-ecosystem-field-mapping | Mapping a stored row whose description, region, and primary domain columns are all null | description, region, and domain are all `""` |
| ecosystems-021 | create-body-shape | Creating an ecosystem with identifier `"ecosystem.fishlamp.adh"` | The sent body has id `"ecosystem.fishlamp.adh"` and slug `"adh"` |
| ecosystems-022 | create-body-shape | Creating an ecosystem with the two-segment identifier `"ecosystem.adh"` | The sent slug is `"adh"` |
| ecosystems-023 | create-scoping-url | Creating a child ecosystem with identifier `"ecosystem.fishlamp.adh.sub"` scoped to parent `"ecosystem.fishlamp.adh"` | The request is scoped to that parent; the sent slug is `"sub"` |
| ecosystems-024 | create-scoping-url | Creating an ecosystem with identifier `"ecosystem.fishlamp.adh"` scoped to workspace `"fishlamp"` | The request is scoped to that workspace |
| ecosystems-025 | update-slug-sent-on-presence, update-single-write | Updating `"ecosystem.fishlamp.adh"` with a new identifier ending `"adh2"` and a new name `"N"` | Exactly one request, addressed to `"ecosystem.fishlamp.adh"`; body carries slug `"adh2"` and name `"N"` |
| ecosystems-026 | update-slug-sent-on-presence | Updating an ecosystem whose submitted identifier equals its stored id (`"ecosystem.fishlamp.adh"`), but whose slug column had drifted to `"chosen"` | The sent slug is `"adh"` (the healing rename); the returned slug is `"adh"` |
| ecosystems-027 | update-omits-unset-fields | Updating `"ecosystem.fishlamp.adh"` with only a new name `"Renamed"`, no identifier | The sent body has no slug field; the name is updated |
| ecosystems-028 | update-returns-server-derived-row | Updating `"ecosystem.fishlamp.adh"` with a malformed identifier `"ecosystem.WRONG.adh2"`; the server echoes back `"ecosystem.fishlamp.adh2"` | The returned id and identifier equal `"ecosystem.fishlamp.adh2"`, never the caller's malformed value |
| ecosystems-029 | workspace-default-ecosystem-id-shape | Resolving the workspace default ecosystem id for workspace `"fishlamp"` with one matching row | The request is scoped to `workspace=fishlamp` and infrastructure; the result carries that row's id and `canManage: true` |
| ecosystems-030 | workspace-default-ecosystem-id-shape | Resolving the workspace default ecosystem id with no workspace given | The request is scoped to the caller's own infrastructure row, with no workspace parameter |
| ecosystems-031 | workspace-default-ecosystem-id-shape | Resolving the workspace default ecosystem id for workspace `"fishlamp"` where the result is an empty list | Resolves to nothing (never an undefined/absent-marker value) |
| ecosystems-032 | workspace-default-ecosystem-id-shape | A row whose `canManage` is explicitly `false` | The result's `canManage` is `false` |
| ecosystems-033 | ecosystem-id-for-slug-ownership-first | Resolving an ecosystem id for slug `"fishlamp"`, where the workspace lookup succeeds on the first call | Exactly one request, scoped to that workspace's infrastructure row |
| ecosystems-034 | ecosystem-id-for-slug-ownership-first | Resolving an ecosystem id for slug `"zed"`, where the workspace lookup reports not-found | Falls back to a raw scan and returns the row whose slug is `"zed"` |
| ecosystems-035 | ecosystem-id-for-slug-ownership-first | Resolving an ecosystem id for slug `"fishlamp"`, where the workspace lookup fails with a permission error | The permission error is rethrown; exactly one request is made, with no fallback scan |
| ecosystems-036 | workspace-default-hook-always-enabled, workspace-default-hook-no-retry | Rendering the workspace-default-ecosystem query with no workspace slug | The query runs immediately (never disabled); it is configured not to retry |
| ecosystems-037 | features-remove-404-is-success | Removing a feature whose delete request fails with not-found | Resolves with no value (treated as success) |
| ecosystems-038 | features-remove-rethrows-other-errors | Removing a feature whose delete request fails with a server error | The failure is rethrown |
| ecosystems-039 | features-remove-single-delete, features-bespoke-route | Removing a feature whose delete request succeeds | One delete request is sent, addressed to that ecosystem and feature key; resolves with no value |
| ecosystems-040 | features-apply-removals-all-settled, features-apply-names-failed-keys, features-apply-skips-empty-add | Applying a change with no adds and three removals, where the middle removal fails with a server error and the other two succeed | Exactly three removal requests are sent, no add request; the change fails, naming only the failed key |
| ecosystems-041 | features-apply-404-removal-succeeds | The same change, but the failing removal reports not-found instead | The change succeeds, with no error |
| ecosystems-042 | features-provision-one-request, features-provision-returns-full-list | Provisioning two feature keys for an ecosystem whose server response lists three provisioned features | Exactly one add request carrying both keys; resolves to the full three-row list |
| ecosystems-043 | features-catalog-order-preserved, features-coming-soon-passthrough | Fetching the catalog, whose server response lists a coming-soon entry after an ordinary one | Resolves in that same order; the coming-soon entry is still present with its flag set |
| ecosystems-044 | features-list-all-states | Listing an ecosystem's features, whose server response includes rows in every state | All rows are returned unfiltered |
| ecosystems-045 | features-provisioned-query-gated, features-query-keys | Rendering the provisioned-features query with no ecosystem id | No request is issued; the cache key carries the empty marker |
| ecosystems-046 | features-provision-writes-cache-then-invalidates | Provisioning one feature key, whose add request resolves with a fresh list | The provisioned-features cache is set to that list immediately on success, then that entry is invalidated |
| ecosystems-047 | features-apply-adds-first, features-apply-invalidates-on-settle | Applying a change with one add and one removal, where the add request fails with a server error | The change fails with that error; no removal request is ever sent; the provisioned-features cache entry is still invalidated |
| ecosystems-048 | features-catalog-stale-time, features-query-keys | Rendering the feature-catalog query twice within 30 minutes | One catalog fetch; the second render is served from cache |
| ecosystems-049 | features-path-segments-encoded | Removing a feature whose ecosystem id and feature key both contain characters needing escaping | Both are percent-encoded in the request path |
| ecosystems-050 | features-remove-hook-invalidates | Removing one feature whose delete request succeeds | The provisioned-features cache entry is invalidated; nothing is written to it directly |
| ecosystems-051 | ecosystem-id-for-slug-ownership-first | Resolving an ecosystem id for slug `"fishlamp"`, where the workspace lookup resolves to an empty result rather than failing | Falls back to the raw scan |
| ecosystems-052 | features-remove-feature-required-error | Removing `users` whose delete fails with a conflict carrying error code `feature_required`, message `"this feature is needed by Client Auth"`, and blocking keys `["signin-apps"]` (test: maps a 409 feature_required response to a typed FeatureRequiredError) | The removal fails with a feature-required error whose message is that message and whose blocking keys are `["signin-apps"]` |
| ecosystems-053 | features-remove-feature-required-error | Removing `widgets` whose delete fails with a conflict that has no structured body (test: leaves a 409 with no feature_required body as a plain error) | The failure is the plain error, not a feature-required error |
| ecosystems-054 | features-apply-feature-required-rethrown | Applying three removals `a`, `b`, `c` where `b` fails with a feature-required refusal and `c` with a server error (test: keeps every other failed key when a FeatureRequiredError is thrown, not just the first) | Three removal requests; the change fails with `b`'s feature-required message; its other-failures list is `["c"]` |
| ecosystems-055 | features-apply-feature-required-rethrown | The same batch where only `b` fails, with the feature-required refusal (test: rethrows a FeatureRequiredError from a removal instead of the generic message) | The change fails as a feature-required error carrying that message, never the `Couldn't remove` text |
| ecosystems-056 | features-apply-removals-dependents-first | Removing `users` and `signin-apps` (which requires `users`) where the `signin-apps` delete is held open (test: sends a dependent's DELETE and lets it settle before the DELETE of what it requires) | Only the `signin-apps` delete is sent until it settles; then the `users` delete is sent; the change succeeds |
| ecosystems-057 | features-apply-removals-dependents-first, listed-catalog | Removing `users` and `applications` where catalog entry `client-auth` requires `users` and comes with `applications` (test: orders by the listed catalog: a key whose included feature needs another goes first) | `applications` is deleted and settles before `users` is deleted |
| ecosystems-058 | features-apply-removals-all-settled | Removing `users` and `signin-apps` where every delete fails with a server error (test: still sends the required key after its dependent failed, and reports both by the usual rules) | Both deletes are still sent, `signin-apps` first; the change fails |
| ecosystems-059 | removal-levels-dependents-first | Ordering `users`, `user-authentication`, `signin-apps` where `user-authentication` requires `users` and `signin-apps` requires both (test: puts dependents before what they require, one level per step) | `[["signin-apps"],["user-authentication"],["users"]]` |
| ecosystems-060 | removal-levels-independent-keys-share-a-level | Ordering `notes`, `signin-apps`, `users` over the same catalog (test: keeps independent keys in one parallel level, in the caller's order) | `[["notes","signin-apps"],["users"]]` |
| ecosystems-061 | removal-levels-dependents-first | Ordering `c`, `a` where `a` requires `b` and `b` requires `c`, `b` not in the batch (test: follows requirements transitively through a key that is not in the batch) | `[["a"],["c"]]` |
| ecosystems-062 | removal-levels-unknown-keys | Ordering `mystery` (not in the catalog) and `users` (test: treats a key the catalog does not know as requiring nothing) | `[["mystery","users"]]` |
| ecosystems-063 | removal-levels-terminate-on-cycles | Ordering `x`, `y` where each requires the other (test: terminates on a cycle) | The call returns, and the levels together hold exactly `x` and `y` |
| ecosystems-064 | workspace-default-hook-result-shape | A cached mount of the workspace-default query after its entry is invalidated, with the re-read held open (test: reports a read in flight on a CACHED mount, where there is nothing pending) | The id is served from cache, pending is false, in-flight is true; once the read lands in-flight is false |
| ecosystems-065 | workspace-default-hook-result-shape | The first read fails, with no earlier answer (test: reports a failed FIRST read as a loading error) | No id; the errored flag and the loading-error flag are both true |
| ecosystems-066 | workspace-default-hook-result-shape | A re-read fails behind an answer already in hand (test: keeps the answer, and no loading error, when a re-read fails behind it) | The id is kept; the errored flag is true; the loading-error flag is false |
| ecosystems-067 | required-closure, needed-by | Catalog `users`, `user-authentication` (requires `users`), `signin-apps` (requires both); the closure of `signin-apps`, and the features needing `users` when all three are on | The closure is `["users","user-authentication"]`; the features needing `users` are `user-authentication` and `signin-apps` |
| ecosystems-068 | listed-feature-key, listed-catalog | Catalog `applications`, `users`, and `client-auth` (requires `users`, comes with `applications`) | The listed key of `client-auth` is `applications`; the listed catalog is `applications` (now requiring `["users"]`) and `users` |
| ecosystems-069 | needed-by-message | Blockers labeled `Applications` and `Notes` | `this feature is needed by Applications, Notes features` |
| ecosystems-070 | feature-row-state, feature-row-label | Holdings with `users` active and `gaming` provisioning; rows standing on `["users"]`, `["gaming"]`, `["notes"]`, and no features | States `active`, `provisioning`, `hidden`, and `active`; the one-feature row for `users` takes the catalog label |
| ecosystems-071 | feature-unavailable-reason, features-added-with | A coming-soon feature the ecosystem does not hold; an unavailable feature it already holds; adding `signin-apps` where `users` cannot be added | Reasons `Coming soon.` and nothing; the keys added with `signin-apps` are `signin-apps` and its other requirements, never `users` |
| ecosystems-072 | hub-data-ecosystem-predicate, hub-data-ecosystem-id-shape | Rows of type `product`, `personal`, and one with no type, listed for workspace `fishlamp` | The predicate is true only for `personal`; the resolved hub-data id is the `personal` row's id; with only the other two rows it resolves to nothing |
| ecosystems-073 | hub-ecosystem-id-prefers-hub-child, hub-ecosystem-failed-child-falls-back | A workspace whose hub-child lookup fails while its default ecosystem is `eco-1` | The hub-data ecosystem id is `eco-1`; with a hub child `hub-1` it is `hub-1`; with neither it is nothing, and it is undefined until both settle |

## Edge Cases

- **Null/empty input**: A slug of `""` after lowercasing - the slug pattern
  requires at least one leading/trailing alphanumeric character, so both
  the field validator's pattern check and the save action's own validation
  reject it before any network call. Resolving the workspace default
  ecosystem id with an empty result list MUST resolve to nothing, never an
  undefined/absent-marker value or a thrown error
  (ecosystems-031); resolving an ecosystem id for a slug then
  falls back to the raw scan, and MUST resolve to nothing only when that
  scan is also empty (ecosystems-051).
- **Boundary/malformed values**: A slug at exactly 64 characters - MUST be
  accepted; at 65 - MUST be rejected with the fixed message
  (ecosystems-015). A non-rdid identifier passed to create/update
  (no `.` at all) - the client MUST pass its whole value through as `slug`
  unmodified via the leaf-extraction fallback, deliberately letting the
  SERVER reject the malformed address rather than fabricating a
  different-looking error client-side.
- **Concurrent access**: Two closely-timed create-form saves for the same
  slug - the client-side existence probe is a courtesy check only; a probe
  that returns "not taken" right before a competing create lands is a real
  race the backend's own unique constraint resolves via a conflict
  response, which both reference implementations map to a friendly "already
  exists" message (create-form-conflict-mapping, create-conflict-mapping)
  - the probe narrows the window, it does not close it. Only the Apple create
  form probes; the web create does no pre-read, since a pre-read cannot see a
  soft-deleted row still holding the key, and relies on the conflict alone.
- **Error states**: Every data-access call that can fail surfaces a typed
  error to its caller - a domain error on one reference implementation
  (never a raw, untyped error reaching a topic or the root listing), an
  error carrying a numeric status on the other. A not-found result is the
  one case multiple call sites treat as a structural, non-error outcome (an
  empty result on the rail; nothing from the get-by-id call) rather than a
  failure to surface.
- **Manageability / authorization**: An ecosystem whose `canManage` is
  explicitly `false` - the rail MUST refuse to resolve ANY topic under it,
  including child-ecosystems and settings, returning only the
  not-manageable notice (child-manageability-gate-first). The other
  reference implementation carries the equivalent `canManage` value through
  its row mapping and workspace-default resolution, but enforcing it
  against a pane is each host's own responsibility - this component only
  reports the flag.
- **Identifier drift (handle vs. derived address)**: A row whose stored
  id/identifier (handle) and slug column have diverged - because something
  renamed the handle without moving the slug (the deprecated generic
  identifier-rename path, or an old ancestor-cascade bug) - derives to a
  DIFFERENT address than its own handle claims. The update call heals this
  specific case: sending the handle's own current value as the new
  identifier is a genuine slug change (matching the stale handle) that a
  naive diff-against-id would have silently skipped
  (#requirements/update-slug-sent-on-presence, ecosystems-026).
- **Feature removal already done**: a removal whose delete request reports
  not-found (a double-click, a stale list, a second tab racing the same
  removal) MUST resolve as success, and inside a batch apply it MUST count
  as a successful removal (ecosystems-037, -041).
- **Feature batch partial failure**: A batch apply whose adds succeed but
  some removals fail with a non-not-found error MUST keep the adds, still
  attempt every other removal (a failed level never stops the next level),
  reject naming only the failed keys, and invalidate the provisioned list
  (ecosystems-040, ecosystems-058). A failed add
  MUST reject before any removal is sent (ecosystems-047);
  whether the backend's batch transaction rolls back whole is the
  backend's contract, which this client relies on and does not verify.
- **Empty feature change**: A batch apply with nothing to add MUST send no
  add request; with nothing to remove it MUST send no removal request and
  resolve. With both empty it sends nothing and still invalidates the
  provisioned list. Provisioning has no such guard: provisioning an empty
  batch MUST still send an add request carrying an empty batch.
- **Already-active or stale feature keys**: provisioning a key that is
  already active is a backend no-op, not a conflict - the client sends it
  unchanged and surfaces whatever the backend answers; a provisioning-state
  row is the picker's concern to show as already taken.
- **Coming-soon feature submitted**: provisioning sends a coming-soon key
  unchanged if a caller supplies one; the backend refuses it and the
  rejection surfaces unchanged to the caller - this client performs no
  client-side refusal.
- **Feature hooks with no ecosystem id**: the provisioned-features query
  MUST NOT fetch while the id is nothing/undefined/empty; the mutations do
  not guard it today, though they SHOULD (see #requirements/features-mutation-null-id-unguarded).
- **Feature removal order**: Removing a key together with a key that requires
  it sends the dependent first and waits for it to settle before the key it
  requires, because the backend refuses removing a key while another active
  feature needs it (ecosystems-056, ecosystems-059). A key the catalog does
  not know is ordered as requiring nothing (ecosystems-062) and a catalog
  with a cycle still terminates (ecosystems-063).
- **Feature removal refused by the backend**: A removal refused because
  another feature still needs the key (a race with a second session) is
  rethrown as a feature-required error that names the blockers, and every
  other failed key of the same batch rides on it rather than being dropped
  (ecosystems-054, ecosystems-055).
- **Included features**: A feature that comes with another is never listed on
  its own, and what it requires is attributed to its parent by listed key, so
  adding or removing the parent cascades over rows the owner can see
  (ecosystems-057, ecosystems-068). The backend refuses removing such a
  feature on its own.
- **Hub-data ecosystem not yet created**: A workspace or backend the move has
  not reached has no hub-data child; the hub-data id falls back to the
  workspace's default ecosystem, and is nothing only when it has neither
  (ecosystems-073).
- **Slug-less hub-data lookup**: With no workspace slug the hub-child query
  resolves to nothing without a request and the default ecosystem answers.
- **Concurrent feature changes**: the removals inside one level of a batch
  apply run in parallel; they touch distinct keys, so their completion order
  does not affect the result, and the list is re-read once on settle. Two
  sessions changing the same ecosystem are reconciled only by the
  post-mutation invalidation re-reading the server's list.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `topics` | ordered list of topic providers | none - required | The ordered set of topics a product's rail exposes; the root listing imposes no fixed order or fixed membership |
| `parent` | an ecosystem, optional | none | When set, the new ecosystem is created as a child of this ecosystem; when absent, the prefix comes from resolving the caller's infrastructure id |
| slug length ceiling | integer constant | `64` | Client-side slug length ceiling enforced before any network call |
| `workspaceSlug` | string, optional | none | Selects the workspace principal's infrastructure row; omitted resolves the caller's own |
| `parent` / `workspace` scoping options | strings, optional | both absent | Scope a create to a parent ecosystem or a workspace's principal; `parent` wins if both are given |
| ecosystems base route | internal constant | fixed | Base route for every generic create/read/update/delete ecosystems call |
| identifiers base route | internal constant | fixed | Base route for rdid rename/availability |
| features base route | internal constant | fixed | Base route for the feature catalog, provisioned list, add and remove |
| `ecosystemId` | string, optional | none - required | The ecosystem (rdid or opaque id) whose features are listed or changed; the list query is disabled while it is falsy |
| `keys` | list of strings | none - required | Catalog keys to add in one batch |
| feature change `{ add, remove }` | lists of strings each | none - required | One picker visit: keys to add (one add request), provisioned keys to remove (one removal request each) |
| catalog freshness window | internal constant | `30 * 60 * 1000` ms | How long the session-wide catalog, and each ecosystem's availability list, is served from cache before a refetch |
| `isOn` | predicate from a feature key to a flag | none - required | Tells the needed-by rule which features are currently on |
| `cannotAdd` | predicate from a feature key to a flag | none - required | Tells the added-with rule which required features the ecosystem cannot add |
| `unavailable` | map from feature key to a reason | empty | The server's per-ecosystem list of features that may not be added |
| hub-child query retry | internal constant | no retry | The hub-data child lookup is read once; a failure falls back to the default ecosystem |

## Deep Linking

Not applicable - this component owns no URL scheme, Android intent filter,
or platform deep-link registration. Rail navigation position is expressed
as a path resolved against the topic tree, which a separate rail-hosting
view (not part of this ingredient) is responsible for turning into or out of
any real deep link. The ecosystems/identifiers HTTP routes are API routes,
not front-end deep links.

## Localization

- **Hardcoded strings (rail-based implementation)**: `"Products"`, `"No
  products yet."`, `"New Product"`, `"Child Ecosystems"`, `"No child
  ecosystems yet."`, `"New Ecosystem"`, `"Settings"`, `"Delete Product"`,
  the delete-confirmation warning ("Deleting a product deletes all the data
  associated with the product, including applications, buckets, and
  users. Do you wish to proceed?"), the not-manageable title/message, the
  slug-too-long message ("Slug must be 64 characters or fewer."), every
  field label (`"Display Name"`, `"Slug"`, `"Identifier"`, `"Description"`,
  `"Geographic Region"`), and every "already in use"/"already exists"
  validation message this ingredient's requirements quote.
- **Hardcoded strings (API-client implementation)**: every thrown-error
  friendly message (the "already exists"/"already in use" conflict
  messages), the batch-apply's `Couldn't remove: <keys>` error, the `Coming soon.`
  unavailable reason, and the blocked tick-off copy `this feature is needed
  by <labels> features`. Catalog
  `label`/`description`/subscription-tier text is served by the backend and
  passed through untranslated.

Neither reference implementation has a lookup table, i18n key, or locale
parameter anywhere in these files - every user-facing string above is fixed
English. This is a plain, honestly-reported fact about the current source,
not a hidden gap (see Compliance).

## Accessibility Options

Not applicable - this component renders no UI and defines no Reduce Motion,
Increase Contrast, or Differentiate-Without-Color behavior. Those act on
whatever UI a host renders around the form/rail values or the
query/mutation results this component returns.

## Feature Flags

Not applicable - no file in either implementation defines or reads a
feature-flag key. Every conditional path (manageability, notFound-as-empty,
slug drift healing, workspace vs. caller scoping) is derived from a model
field, a thrown error's shape, or a caller-supplied option, never from a
flag this component owns.

## Analytics

Not applicable - no file in either implementation emits a client-side
analytics or telemetry event.

## Privacy

- **Data collected**: Ecosystem administrative metadata only - `name`,
  `slug`/`identifier`, `description`, `region`, primary domain, timestamps,
  and the caller's own `canManage` flag. None of these fields are personal
  data about an end user; they describe a product/ecosystem record, not a
  person. Two fields do refer to people: the auth settings' `loginAllowedEmails`, the
  email addresses an owner lists as allowed to sign in, which are contact details; and the
  provisioner principal id on a provisioned feature row, an opaque id. This data layer passes the
  emails through as given (the ecosystem-config form trims and lowercases them before
  saving), and nothing here stores them beyond the in-memory query cache.
- **Storage**: One reference implementation holds no cache of its own -
  every call is a live round-trip to whatever data source the host
  supplies. The other holds results in a shared in-memory query-client
  cache, keyed as documented under each hook/query above; nothing in this
  component writes to durable browser/device storage.
- **Transmission**: All calls travel through the injected data source or
  the shared Bearer-token client (see [adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)); this component itself
  attaches no credentials and reads no cookies.
- **Retention**: One reference implementation retains nothing between
  calls. The other's cache entries persist per their cache key until
  invalidated by the matching mutation (as documented per hook above) or
  garbage-collected by the query library's own cache lifetime; the only
  custom cache settings are the workspace-default and hub-child queries'
  no-retry configuration and the 30-minute freshness window of the feature
  catalog and each ecosystem's availability list, and
  no explicit garbage-collection time is set anywhere. Provisioned feature
  rows carry who provisioned them (a principal id or nothing), held only in
  that in-memory cache.

## Logging

No reference implementation calls a logger, a console-output function, or
any platform logging API. Every failure this component detects is surfaced
to its caller as a thrown domain error; any logging of that failure is the
responsibility of the caller or host application, not of this domain
component.

## Platform Notes

- **SwiftUI / AppKit / UIKit**: This is one of the two reference
  implementations, under
  `packages/apple/AgenticDeveloperHubSDK/Hub/Features/Ecosystems/`. `EcosystemsModule`
  and its topics are `@MainActor` and `Sendable`-safe under Swift 6 strict
  concurrency; the same `FormSpec`/`HTDVDetail` values these topics build
  are rendered by both the macOS `FormSheet`/`FormViewController`
  (`HTDV/Views/macOS/`) and the iOS `FormSheet+UIKit`/
  `FormViewController+UIKit` (`HTDV/Views/iOS/`) presenters, so this domain
  logic is genuinely shared, unmodified, across macOS and iOS - only the
  presenting view layer differs.

  `Ecosystem`/`EcosystemCreate`/`EcosystemUpdate` (`EcosystemsModels.swift`)
  implement the **Ecosystem record** group above and conform to `Codable,
  Hashable, Sendable, Identifiable` (**ecosystem-model-shape**); their
  decode and derived-property behavior is pinned by
  `EcosystemsModuleTests.swift`'s `testDecodesEcosystemWithMissingIsDefault`
  (**ecosystem-decode-default-fallback**, **ecosystem-identifier-prefix**).

  `EcosystemsDataSource` (`EcosystemsDataSource.swift`) is the injected
  `AnyObject, Sendable` protocol implementing the **Data access boundary**
  group, exposing `list()`, `children(of:)`, `get(id:)`,
  `infrastructureID()`, `identifierExists(_:)`, `create(_:parentID:)`,
  `update(id:_:)`, `delete(id:)`, every one `async throws`.

  `EcosystemsModule` (`EcosystemsModule.swift`) is the top-level
  `HTDVDataSource` implementing the **Root listing and rail navigation**
  group (`rootLevel()`, `item(for:)`, `child(for:)`), pinned by
  `testRootLevelListsProductsWithoutDefaultRows`,
  `testDataSourceFailuresSurfaceAsHubError`,
  `testNotManageableProductShowsNotice`,
  `testProductChildIsTopicsRailInProviderOrder`, and
  `testUnknownProductOrTopicIsEmpty`. `EcosystemTopicProvider`/
  `EcosystemTopicEntry`/`EcosystemTopicGroup`/`EcosystemNoticeTopic`
  (`EcosystemTopic.swift`) implement the **Topic composition** group,
  pinned by `testGroupTopicListsItsChildrenAndDelegates`.

  `EcosystemCreateForm` (in `EcosystemsModule.swift`) implements the
  **Creating an ecosystem** group's form/save-action requirements, pinned
  by `testCreateFormDerivesIdentifierFromInfrastructure`,
  `testCreateFormForChildUsesParentPrefix`, `testCreateActionLowercasesSlug`,
  and `testCreateFormValidationMessages`; its slug length ceiling is the
  `EcosystemCreateForm.slugMaxLength` constant, and slug validation runs
  through `Slug.pattern`/`Slug.isValid`/`Slug.patternMessage`
  (`Support/Slug.swift`).

  `EcosystemSettingsTopic` (`EcosystemSettingsTopic.swift`) implements the
  **Ecosystem settings** group, pinned by `testSettingsFormValuesAndSave`,
  `testSettingsSaveActionLowercasesSlug`, and
  `testSettingsSaveConflictBecomesIdentifierInUse`; the same file also
  defines `ChildEcosystemsTopic`, covering the **Child ecosystems** group,
  pinned by `testChildEcosystemsLevelAndDescent`.

  Every domain error this implementation raises is a `HubError` case
  (`.notFound`, `.conflict`, `.validation`, `.offline`, ...), defined in
  `HubError.swift` and wrapped via `HubError.wrap`
  (`Support/HubError+Wrap.swift`) at every boundary that does not itself
  re-map a specific case - never a raw `Error` reaching a topic or the
  module. Rail navigation position is expressed as an `[HTDVItem]` path
  resolved through `RailPath.id(at:in:)` (`Support/RailPath.swift`);
  `HTDVItem`/`HTDVLevel`/`HTDVDetail` are this ingredient's "rail item"/"list"/
  "detail view" vocabulary. This implementation has no feature-picker data
  source in these sources - a port of the picker starts from the other
  reference implementation's contract.
- **React/Web**: This is the other reference implementation, under
  `packages/web/packages/data/src/ecosystems/`. `ecosystemsApi`
  (`ecosystems.ts`) implements the **Ecosystem record** group's row-mapping
  requirements (`toEcosystem`, `addressLeaf`) and the **Reading, listing,
  and updating an ecosystem over the wire**/**Creating an ecosystem** wire-
  shape requirements, pinned by the `ecosystems.test.ts` suite (its
  `toEcosystem`, `ecosystemsApi.workspaceDefaultEcosystemId`, and
  `ecosystemsApi.ecosystemIdForSlug` describe blocks, plus the individual
  cases cited in Conformance Test Vectors above). `identifiersApi`
  (`identifiers.ts`) implements the **Identifier rename and slug
  ownership** group's generic rename/existence-probe requirements;
  `ecosystemsApi.update`'s `slug`-carrying write, not `identifiersApi.rename`,
  is the actual ecosystem-rename route
  (**identifier-rename-is-not-ecosystems-renaming-route**).

  `useWorkspaceDefaultEcosystemId` (`use-workspace-default-ecosystem.ts`)
  is a `@tanstack/react-query` wrapper implementing the **Workspace default
  resolution** group; it passes the module-scoped `useToolkitQueryClient()`
  singleton explicitly to `useQuery` rather than reading a client from
  React context (**workspace-default-hook-shared-client**).

  `ecosystem-invitations.ts`'s hooks (`useEcoInvitationRequests`,
  `useEcoPendingUsers`, `useEcoInvites`, `useEcoRowNotes`,
  `useEcoRowHistory`, `useEcoSaveNotes`, `useEcoSendInvitations`,
  `useEcoAddPendingUsers`, `useEcoDeleteRow`) implement the **Invitations
  topic data** group; their row-shape mappers are imported from
  `@adh-sdk/adh-ui/invitations-types` rather than defined in this
  recipe (see Design Decisions).

  `ecosystemFeaturesApi` plus its hooks (`ecosystem-features.ts`, tested by
  `ecosystem-features.test.tsx`) implement both **Feature provisioning**
  groups: `catalog`, `list`, `availability`, `provision`, `remove` are the
  wire calls; `useFeatureCatalog`, `useProvisionedFeatures`,
  `useFeatureAvailability`, `useProvisionFeatures`, `useRemoveFeature`,
  `useApplyFeatureChange` are the query/mutation hooks, and `removalLevels`
  orders a batch of removals. `FeatureRequiredError` is the typed refusal and
  `toCatalogFeature`/`toProvisionedFeature` are the row mappers.
  Unlike `useWorkspaceDefaultEcosystemId`, these hooks read the query
  client from React context rather than the module singleton
  (**features-hooks-context-client**). This data has no counterpart in the
  other reference implementation.

  `feature-requirements.ts` holds the pure rules (`requiredClosure`,
  `neededBy`, `listedFeatureKey`, `listedCatalog`, `neededByMessage`) that
  implement the **Feature requirements** group, and `feature-manager.ts`
  (`featureHoldings`, `featureRowState`, `featureRowLabel`,
  `featureUnavailableReason`, `featuresAddedWith`, `useEcosystemFeatures`)
  implements the **Feature manager** group.
  `use-workspace-hub-ecosystem.ts` (`useWorkspaceHubEcosystemId`,
  `useWorkspaceHubScope`) implements the **Hub-data ecosystem resolution**
  group, resolving through `ecosystemsApi.hubDataEcosystemId` and
  `isHubDataEcosystem`. `wire.ts` holds the wire row and body types, among
  them `EcosystemType`. The update call is a POST to the ecosystem's own
  route, and every list read pages through `listAllV1`.

  Every error this implementation raises is a plain `Error` carrying a
  numeric `.status` (`AuthHttpError`-shaped, from `@adh-sdk/auth`'s
  Bearer-token client - see [adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)); `isNotFound`/`isConflict`/
  `rethrowConflict` (`http.ts`; `rethrowConflict` recognizes a conflict by an
  "already exists" message, not by status) are the conflict/
  not-found mapping helpers every requirement above that mentions
  surfacing a conflict or a not-found result relies on.
- **Compose / Android**: `OkHttp`/`Ktor` (or `Retrofit`) would replace
  `fetch`/`URLSession` for the web/Apple network calls respectively; a
  `ViewModel` exposing a `StateFlow`/`LiveData` of the resolved ecosystem
  list is the idiomatic equivalent of both `EcosystemsModule.rootLevel()`
  and the react-query list hooks. `androidx.lifecycle.SavedStateHandle` or
  a `Room`-backed repository would be where a native Android port adds a
  local cache neither reference implementation currently has. For the
  feature picker, `coroutineScope { keys.map { async { runCatching {
  remove(it) } } }.awaitAll() }` is the equivalent of `Promise.allSettled`,
  run after the provision call returns.
- **WinUI 3**: `HttpClient` with `System.Text.Json` replaces both
  `fetch` and `URLSession` for every ecosystems/identifiers request this
  recipe documents. A `NavigationView`/`TreeView` with a
  `TreeViewNode`-backed hierarchy is the idiomatic equivalent of the
  Apple rail's recursive `HTDVLevel`/`HTDVChild` model (products → topics
  → child ecosystems, recursing arbitrarily deep per
  child-ecosystems-recurse-via-rail); a `ContentDialog` hosting a form
  built from `Microsoft.UI.Xaml.Controls` (`TextBox` for `name`/`slug`,
  a read-only `TextBlock` for `id`, a multi-line `TextBox` for
  `description`) is the equivalent of `FormSheet`'s create dialog, and a
  second `ContentDialog` with a destructive-styled primary button is the
  equivalent of `FormDeleteAction`'s confirmation flow. `Task`/`async`-
  `await` replaces every `Promise`/Swift `async throws` call; a custom
  `HubError`-equivalent exception hierarchy (or a `Result<T, HubError>`)
  should carry the same `notFound`/`conflict`/`validation` distinctions
  this ingredient's error-mapping requirements rely on, since WinUI has no
  built-in typed-error convention of its own to inherit. For the feature
  picker: a `FeaturesClient` over `HttpClient` exposes `GetCatalogAsync`
  (deserialize `{ features }` with `System.Text.Json`, keep server order),
  `ListAsync`, `ProvisionAsync` (one `PostAsJsonAsync` with
  `{ keys }`, returning the full list) and `RemoveAsync` (`DeleteAsync`,
  treating `HttpStatusCode.NotFound` as success), with path segments
  escaped by `Uri.EscapeDataString`. The picker is a `ContentDialog`
  hosting a `ListView` of `CheckBox` items bound to an
  `ObservableCollection<FeatureRow>` whose rows implement
  `INotifyPropertyChanged`; a `comingSoon` row goes in a separate
  "Coming soon" group (a `CollectionViewSource` with `IsSourceGrouped`) with
  `IsEnabled="False"`, and a `provisioning` row shows as already checked.
  Applying a change awaits `ProvisionAsync` first, then walks the removal
  levels in order: for each level, `Task.WhenAll` over per-key tasks that each
  catch their own exception and return a success flag (plain `Task.WhenAll`
  throws on the first fault, unlike `Promise.allSettled`), awaited before the
  next level starts. A `FeatureRequiredError` is a small exception class
  holding the blocking keys and the other failed keys; throw it when the
  server answers `HttpStatusCode.Conflict` with the `feature_required` code,
  else throw `Couldn't remove: <keys>`, and always re-read the list in a
  `finally`. The picker also disables a row whose key is in the server's
  unavailable map (`IsEnabled="False"` with the reason in a `ToolTip`), and
  unticking a feature that others need shows the needed-by copy in an
  `InfoBar` with `Severity="Warning"` instead of changing the checkbox. The
  30-minute catalog cache has no built-in equivalent: keep the catalog and a
  fetched-at `DateTimeOffset` in a session-lifetime service. The feature
  manager is that same service exposing a holdings record and a
  row-state function, and `NavigationViewItem.Visibility` binds to the
  `hidden` row state so a rail row is drawn only while the ecosystem holds one
  of its features, with a `provisioning` row shown but not invokable.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/data/src/ecosystems/` | confirmed (2.1.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/Ecosystems/` | confirmed (2.1.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/Ecosystems/EcosystemsDataSource.swift` | confirmed (2.1.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/Ecosystems/EcosystemsModule.swift` | confirmed (2.1.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/Ecosystems/EcosystemSettingsTopic.swift` | confirmed (2.1.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/Support/HubError+Wrap.swift` | confirmed (2.1.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/Support/RailPath.swift` | confirmed (2.1.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/Support/FormDetails.swift` | confirmed (2.1.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKHubTests/EcosystemsModuleTests.swift` | confirmed (2.1.0) |
| web | `packages/web/packages/data/src/ecosystems/ecosystems.ts` | confirmed (2.1.0) |
| web | `packages/web/packages/data/src/ecosystems/identifiers.ts` | confirmed (2.1.0) |
| web | `packages/web/packages/data/src/ecosystems/use-workspace-default-ecosystem.ts` | confirmed (2.1.0) |
| web | `packages/web/packages/data/src/ecosystems/ecosystem-invitations.ts` | confirmed (2.1.0) |
| web | `packages/web/packages/data/src/ecosystems/ecosystem-features.ts` | confirmed (2.1.0) |
| web | `packages/web/packages/data/src/ecosystems/wire.ts` | confirmed (2.1.0) |
| web | `packages/web/packages/data/src/ecosystems/__tests__/ecosystems.test.ts` | confirmed (2.1.0) |
| web | `packages/web/packages/data/src/ecosystems/__tests__/use-workspace-default-ecosystem.test.tsx` | confirmed (2.1.0) |
| web | `packages/web/packages/data/src/ecosystems/__tests__/ecosystem-features.test.tsx` | confirmed (2.1.0) |

## Design Decisions

**Decision**: `EcosystemSettingsTopic.values(for:)` always reports
`region` as the literal string `"coming soon"`, and its save action never
includes `region` (or `primaryDomain`) in the `EcosystemUpdate` it sends,
regardless of what the form displays.
**Rationale**: The Apple settings form has not yet built real region
editing; showing a fixed placeholder is an honest "not yet available"
signal rather than either fabricating a value from the model's real
(currently unused) `region` field or omitting the row entirely. Never
sending it on save is a direct consequence: there is nothing real to send.
**Approved**: pending

**Decision**: `EcosystemsModule.child(for ecosystem:path:)` checks
`ecosystem.isManageable` before resolving any topic, so an unmanageable
ecosystem's `child-ecosystems`/`settings`/other topics are unreachable -
never partially reachable with per-action 403s.
**Rationale**: The alternative (resolve the topic, let the eventual
mutation 403) would let a non-admin org member browse an ecosystem's full
settings/child list read-only before hitting a wall on save/delete - worse
UX than one honest, upfront notice, and it would require every downstream
topic to independently re-check manageability.
**Approved**: pending

**Decision**: `ecosystemsApi.update` sends `slug` whenever the caller
supplies `identifier` at all, never only when it differs from the stored
`id`.
**Rationale**: `id` is the stored, mutable HANDLE; what a settings form
actually edits is the address the row DERIVES to from `(parent chain,
slug)`. The two disagree on exactly the rows this matters most for - a
row whose handle still says `…mike` while its slug column already says
`chosen` - where diffing against `id` would silently drop the one save
that heals the drift (a rename back to `…mike`, which equals `id` but is
a genuine slug change). Sending an already-correct slug costs nothing:
the route's own stored-value diff rules out a true no-op before any
cascade runs.
**Approved**: pending

**Decision**: The old two-call rename sequence (a write of ordinary fields
followed by a `registry.identifiers` PATCH of the handle) was removed in
favor of the single `ecosystemsApi.update` write carrying `slug`.
**Rationale**: The address is derived from `(parent chain, slug)`, so
moving the slug IS the rename; PATCHing the handle separately retitles it
without moving the slug column, leaving the row deriving its OLD address
- and the next ancestor cascade re-leafs the handle back, silently undoing
the rename. The two-call sequence also needed a 404-recovery branch for
the case where the first call lands and the second fails; the single-write
shape has no such window, because a failed write changes nothing.
`identifiersApi.rename` remains the correct mechanism for other,
non-address-bearing entity types (or a future purely-cosmetic handle
retitle) - it is simply not the ecosystems rename path anymore.
**Approved**: pending

**Decision**: `useWorkspaceDefaultEcosystemId` is never disabled
(`enabled`) on the absence of `workspaceSlug`.
**Rationale**: A disabled query stays `isPending` forever; a caller that
treats `isPending` as "still resolving, wait for it" then waits on an
answer that never comes. Every slug-less host (a feature-site mount whose
creates are caller-owned, not workspace-owned) needs the CALLER's own
infrastructure row, which is a real, resolvable answer, not the absence
of one - so the query must actually run for that case too.
**Approved**: pending

**Decision**: The Apple `Ecosystem` model and `EcosystemSettingsTopic`'s
form expose no `primaryDomain`/`domain` field, while the web `Ecosystem`
interface and settings-equivalent panes do (`domain`, mapped from
`primaryDomain`).
**Rationale**: This is a genuine, current cross-platform divergence, not
an inconsistency in this ingredient's sourcing: the Apple Hub UI for editing a
custom domain has not been built yet, while the web client already models
the field end-to-end (`EcosystemInput.domain`, `toEcosystem`,
`EcosystemPutBody.primaryDomain`). A future Apple settings field for it
should follow the same read-only-until-built pattern `region` uses today,
not invent new semantics.
**Approved**: pending

**Decision**: `ecosystem-invitations.ts`'s row-shape mappers
(`toRequest`, `toPendingUser`, `toInvite`, `toAdminNote`,
`toHistoryEntry`) and their backend types are imported from
`@adh-sdk/adh-ui/invitations-types` rather than defined in this
recipe.
**Rationale**: Those mappers are shared with the platform-admin
invitations hooks referenced in this file's own header comment
(`packages/web/packages/features/adh-admin/src/api/invitations.ts`) - they belong to the
Invitations feature's own contract, not to Ecosystems. This ingredient
documents what the Ecosystems-owned hooks in `ecosystem-invitations.ts`
do with their query keys, endpoints, and cache invalidation, and treats
the mappers' internal field-by-field shape as a different component's
concern, out of scope here.
**Approved**: pending

**Decision**: Features are added as one plural POST per batch, while
removals are one DELETE per key, sent dependents first in levels, each level
run concurrently and collected with `Promise.allSettled`, adds first.
**Rationale**: The picker confirms a batch of adds behind one "Add N
features?" prompt and the backend runs the batch in one transaction, so a
partial failure never leaves the owner with three of five features and no
way to tell which. The DELETE route removes one key, so removals cannot
share a request; and the backend refuses removing a key while another
active feature needs it, so sending a dependent and what it requires
together would draw a refusal. Levels remove that race inside one batch,
`allSettled` keeps one 5xx from silently aborting the rest the way a
sequential loop would, and naming the failed keys tells the caller which
features are still provisioned. Adds go first so a failed removal never costs
the features just added.
**Approved**: pending

**Decision**: Removal ordering is a courtesy, not the enforcement: if the
catalog cannot be read, removals go as one concurrent level.
**Rationale**: The backend's refusal is the real guard and surfaces as a
typed feature-required error either way; failing the whole apply because an
ordering hint was unavailable would turn a recoverable read into a lost
change.
**Approved**: pending

**Decision**: A feature-required refusal is rethrown as its own typed error
with the other failed keys attached, rather than folded into the generic
`Couldn't remove` message.
**Rationale**: The refusal is a race with another session that the caller can
explain by name, and a generic message would read as a plain failure. Folding
every other failure onto the same error means a second, unrelated failure is
never silently dropped because the first one happened to be feature-required.
**Approved**: pending

**Decision**: The feature manager is the one place that answers what an
ecosystem holds, what each feature is called, and whether a row is drawn;
rails and the Manage features dialog read it rather than keeping their own
lists.
**Rationale**: Separate hand-kept lists each agreed with the dialog until they
did not (rows with no feature behind them, a row for a feature the ecosystem
did not hold). One rule, that a row standing on catalog features is drawn only
while the ecosystem holds one of them, makes anything a rail draws ticked in
the dialog by construction.
**Approved**: pending

**Decision**: The hub-data ecosystem id prefers the workspace's live hub-data
child and falls back to the default ecosystem, and the fallback also answers a
failed child lookup.
**Rationale**: The default ecosystem held that data before the move, so it is
still correct for any user or backend the move has not reached, and the
fallback keeps hub reads working through a rollout.
**Approved**: pending

**Decision**: `ecosystemFeaturesApi.remove` treats a 404 as success.
**Rationale**: The caller's goal is that the row is gone; a double-click, a
stale list, or a second tab racing the same removal would otherwise report
failure for an outcome that already happened. Every other status still
throws.
**Approved**: pending

**Decision**: The feature catalog is cached under a key with no ecosystem id
and a 30-minute `staleTime`, and "Coming soon" entries stay in it.
**Rationale**: The catalog is a property of the server build, not of any
ecosystem, so one list serves the whole session; refetching it on every
picker open would re-download the same rows each time. Unbuilt features are
kept so the owner can see what is coming; the picker disables them and the
backend refuses to provision them, so the client needs no filter.
**Approved**: pending

**Decision**: the feature-provisioning mutations SHOULD reject an absent ecosystem id before any request is sent, or take a non-optional id; today they do neither.
**Rationale**: failing fast on the client avoids sending a request to a path holding a literal absent-marker; the gap is kept visible here as a known gap until a guard lands.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | Access Patterns |
| [adc.check.access-patterns.retry-with-backoff](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bcb17bfe-d2d6-53f3-b2af-06b7eea3da61) | failed | Access Patterns |
| [adc.check.access-patterns.offline-behavior](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/df7f401a-39be-5c60-bab4-85dd95bd1ab1) | failed | Access Patterns |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | partial | Reliability |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | partial | Reliability |

`separation-of-concerns` **passed**: `EcosystemsDataSource` is a pure I/O
boundary the module never bypasses; topics compose via the
`EcosystemTopicProvider` protocol rather than subclassing or reaching into
each other's state, and the web client keeps wire shapes (`wire.ts`)
separate from the UI-facing `Ecosystem` type. `explicit-error-handling`
**passed**: every catch on both platforms either re-maps a specific error
(`HubError.notFound`→`.empty`, `HubError.conflict`→`.validation`,
`isNotFound`→`null`, a 409→`rethrowConflict`) or wraps/rethrows
unconditionally (`HubError.wrap`) - no path silently swallows a failure.
`unit-test-coverage` **partial**: vectors `ecosystems-019` through `-066`
are covered by web tests in `ecosystems.test.ts`,
`ecosystem-features.test.tsx` and `use-workspace-default-ecosystem.test.tsx`
(vectors `-052` through `-066` name their tests; `-019` through `-051` are
one test per vector). Vectors `ecosystems-067` through `-073`, which cover the
feature requirement rules, the feature manager, the hub-data predicate and the
hub-data ecosystem hooks, are derived from source and have no test of their
own. Vectors
`ecosystems-001` through `-018` describe the Apple `EcosystemsModule` and
`Ecosystem` type, which the web client has no equivalent of; they are
exercised by `EcosystemsModuleTests.swift` (root listing, manageability gate,
topic dispatch, settings save/delete, child-ecosystem recursion, create-form
validation and prefix resolution) and are `it.skip` placeholders in the web
suite, so no web test counts them. `error-response-handling`
**passed**: `isNotFound`/`isConflict` and `HubError.notFound`/`.conflict`
consistently distinguish "missing" from "already exists" from every other
failure on both platforms, and `ecosystemIdForSlug` explicitly rethrows a
non-404 rather than treating it as license to fall back
(ecosystems-035). `retry-with-backoff` **failed**: no file in
either implementation retries a failed ecosystems/identifiers request -
the underlying `authedJson`'s 401-refresh-and-retry-once is a different,
cross-cutting auth concern (see [adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)), not a retry of this
domain's own operations. `offline-behavior` **failed**: neither
implementation defines an offline-cache-first read path or a
queued-write-when-offline behavior; every operation is a live round-trip
that fails outright when the network is unavailable.
`idempotent-operations` **partial**: the feature client is idempotent on
both mutating paths - `remove` treats an already-gone row (404) as success,
and `provision` of an already-active key is a backend no-op - and
`ecosystemsApi.update`'s write is
documented as idempotent by the backend's own locked-value diff (sending
an unchanged `slug` is a no-op, per the source's `addressPatchMoves`
comment), but `create` has no idempotency key on either platform - a
client-level retry of a create (were one ever added) could not safely be
distinguished from a genuine duplicate request without one.
`input-sanitization` **partial**: `Slug.pattern`/`FormValidator` (Apple)
validate the slug's character set client-side, and `addressLeaf` is a
pure slice with no validation of its own by design (see Edge Cases); the
server's unique-address constraint and `id`-vs-leaf assertion are the
real authority on both platforms, which this component deliberately
relies on rather than duplicating. `data-minimization` **passed**: every
field this component reads or writes is ecosystem/product metadata, apart from
the `loginAllowedEmails` email addresses, which are contact details the owner chose to
list and are needed to decide who may sign in, and the provisioner principal id, an
opaque id. `no-hardcoded-strings` **failed**: every
user-facing string this ingredient documents (labels, warnings, validation
messages) is fixed English with no lookup table or locale parameter on
either platform (see Localization) - a plain, honestly-reported gap, not
a hidden one. `fault-tolerance` **partial**: `useApplyFeatureChange`
keeps going past a failed removal and reports it by name rather than
aborting, and `FeatureSubscriptionTier` is an open string so an unknown
tier cannot break parsing; but the feature mutation hooks accept a
nullable `ecosystemId` and send it unguarded (a known gap) (see #requirements/features-mutation-null-id-unguarded).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 2.1.0 | 2026-11-22 | Mike Fullerton | Add the web feature-requirement rules, feature manager, hub-data ecosystem resolution, dependents-first removal with the typed feature-required refusal, availability, catalog dependency fields and paging; drop the Reference Implementations section |
| 2.0.0 | 2026-11-15 | Mike Fullerton | Auth settings carry the login allow-list by email (loginAllowedEmails, login_allowed_emails); privacy and compliance treat the emails as contact details |
| 1.3.0 | 2026-10-04 | Mike Fullerton | Resolve open-question markers against the code; restate unimplemented behavior as current behavior with pending Decisions. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to adh/hub/ecosystems/. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.1.0 | 2026-09-24 | Claude | Add the web feature picker data (`ecosystem-features.ts`): catalog with "Coming soon" entries, provisioned list, batch add, 404-tolerant remove, all-settled apply; correct `ecosystemIdForSlug`'s null-result fallback and the cache-settings note. |
| 1.0.0 | 2026-09-24 | Mike Fullerton | Initial recipe: Apple `EcosystemsModule`/topics/data source/models and the web `ecosystemsApi`/`identifiersApi`/`useWorkspaceDefaultEcosystemId`/Invitations-hooks contract. |
