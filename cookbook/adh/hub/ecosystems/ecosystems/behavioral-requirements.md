
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

