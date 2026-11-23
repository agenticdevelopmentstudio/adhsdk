
### Cross-cutting (all five topics)

- **ecosystem-scoped-navigation**: every rail path resolution MUST scope its
  data-source calls to the given ecosystem's id; every topic passes that id through
  on every call, including the storage-tokens topic passing it through to the shared
  token rail.
- **path-depth-dispatch**: for sign-in apps, feature flags, server bags, and storage
  tokens, a rail path resolution MUST return a level when the path is empty, MUST
  look up the matching entity by id/key and return a detail when found or an empty
  result when not found for a one-segment path, and MUST return an empty result for
  any longer path. User auth has no level at all: an empty path MUST return the
  single detail, and any non-empty path MUST return an empty result.
- **hub-error-wrapping**: every data-source call in each of the five topics - except
  the storage-tokens topic's create call, which uses a different pattern (see
  **tokens-create-three-way-catch**) - MUST be wrapped in the shared error-wrapping
  step, so a thrown transport/API error is normalized to a shared error kind before
  it reaches the caller.

### User Auth

- **auth-detail-only-entry**: the entry point MUST declare that it leads straight to
  a detail - there is no list level for this topic; navigating to it goes straight
  to the one settings form.
- **auth-field-order**: the detail's form specification MUST present fields in the
  order `signupMode`, `signupHelp`, `loginEnabled`, grouped into a "Sign-up" section
  (`signupMode` select plus a read-only `signupHelp` line) and a "Sign-in" section
  (the `loginEnabled` toggle).
- **auth-signup-options**: the `signupMode` select field's options MUST be every
  recognized sign-up mode in a fixed declaration order (`open`, `inviteOnly`,
  `closed`), titled "Open", "Invite only", "Closed" respectively.
- **auth-signin-help-text**: the `loginEnabled` toggle's help text MUST be the fixed
  string "When off, no one can sign in to this ecosystem." - it does not vary by
  ecosystem or current setting.
- **auth-save-sends-both-values**: the save action MUST always construct an update
  carrying both `signupMode` and `loginEnabled`, never a partial patch, even if only
  one field changed.
- **auth-save-fallback-values**: if the submitted `signupMode` value cannot be
  parsed into a recognized sign-up mode, the save action MUST silently fall back to
  `inviteOnly`; if the submitted `loginEnabled` value is missing, it MUST fall back
  to `false`. Both are documented, in-source fallbacks, not swallowed errors - the
  field's fixed option set makes an invalid `signupMode` value unreachable through
  normal use.
- **auth-detail-id-format**: the detail's id MUST be the string
  `auth-settings:<ecosystem.id>`.
- **auth-no-delete-action**: the detail's delete action MUST be absent - auth
  settings can be edited but never removed.
- **auth-allowed-providers-not-editable**: the Swift user-auth detail's form
  specification MAY leave the record's `allowedProviders` list out. Today the list
  decodes from the read operation's response, but the form never reads, displays, or
  edits it, and the update shape has no field to write it back, so the Swift topic
  offers no way to view or change the allowed providers.
- **auth-login-allow-list-wire**: the web data layer's `AuthSettings` (and so
  `ClientAuthPolicy`) MUST carry `loginAllowedEmails: string[] | null`, read
  from the wire's `login_allowed_emails`. Since phase 5 the sign-up list owns the emails, and this field is the backend's mirror of that list. `null` means every customer may
  sign in and `[]` means nobody; a response that omits the field (an older
  backend) MUST read as `null`. A patch that sets it to `null` MUST send the
  explicit `null`, never drop it, so "every customer" can be restored.
- **auth-login-allow-list-switch**: the web ecosystem client-auth pane MUST draw a
  "Who can sign in" section holding an "Only listed people" switch and a short
  paragraph pointing at the sign-up list (with a link when the host supplies one).
  The people on the list are the sign-up list's (see **signup-list-pane**),
  never edited in this form. The form's allow-list state is the switch alone, so
  two policies that differ only in their emails MUST compare as the same policy,
  and editing the sign-up list MUST NOT make this form dirty.
- **auth-login-allow-list-patch**: a policy patch MUST send `loginAllowedEmails`
  only when the switch flips. Turning it off MUST send the explicit `null`. Turning
  it on MUST send the sign-up list's emails, each trimmed and lowercased, with
  blanks and duplicates dropped and the first occurrence kept. The draft's own
  emails MUST NOT travel: a list that stays on is never sent, whatever it holds.
  The turn-on case sends the sign-up list because the backend keeps the sign-up
  entries equal to whatever list is written, so an empty list would delete every
  entry.
- **auth-password-enabled**: the web policy MUST carry `passwordEnabled`, MUST
  count a change to it as an edit, and MUST send it in the patch when it differs
  from the saved value.
- **signup-email-error**: the email check shared by the form and the sign-up list
  MUST trim and lowercase its input first. It MUST return "Enter an email
  address." for an empty result, and `"<email>" is not an email address.` (the
  trimmed, lowercased form) for one longer than 254 characters or not shaped as an
  email: exactly one `@`, a non-empty local part with no whitespace and no quote,
  and a domain of at least two non-empty dot-separated labels. The backend's own
  check stays authoritative; this one only refuses sooner.
- **auth-login-allow-list-dropped**: when a save sent `loginAllowedEmails` and
  the saved policy comes back without that list (a backend that predates the
  allow-list strips the unknown field and still answers 200), the save MUST fail
  with "The sign-in list was not saved, so everyone can still sign in. This
  backend does not support the list yet." The draft MUST keep the owner's switch,
  rather than re-seeding it off. The cache still takes the answer, because the
  other fields did save. An absent list reads as `null`, so sending `null` to such
  a backend is not a failure, and two lists compare as the same when they would
  save the same, as sets.
- **client-auth-post-update**: the web client-auth client MUST update the
  ecosystem's policy with a `POST` to `/api/v1/ecosystems/{id}` and an
  application's registration with a `POST` to `/api/v1/applications/{id}`, each
  carrying a `client_auth` body. The ecosystem update MUST drop undefined keys from
  its body and keep an explicit `null`, so a field can be cleared. The application
  update sends a `client_auth` body holding only `registration`, with no such
  dropping.

### Sign-in Apps

- **signinapps-list-sort**: the level's items MUST be sorted by `name` using a
  case-insensitive, locale-aware comparison ("Admin console" before "Shop web");
  each item's sublabel MUST be the app's full `slug` (e.g. "shop.shop-web").
- **signinapps-leaf-computation**: the leaf-computation step MUST strip the
  `"<ecosystem.slug>."` prefix from `slug` when present, returning `slug` unchanged
  when it is not - a defensive fallback, since the server prefixes the client slug
  with the ecosystem slug and forces the ecosystem, so every listed `slug` is
  expected to carry that prefix in practice.
- **signinapps-create-fields**: the create form specification MUST expose only
  `name` and `clientId`; `allowedReturnOrigins` and `githubEnabled` are editable
  only after creation, in the detail.
- **signinapps-duplicate-leaf-check**: before calling create, the save action MUST
  reject a `clientId` whose lowercased value matches any existing app's lowercased
  leaf, with the message `App id "<leaf>" is already in use.`.
- **signinapps-clientid-pattern**: the `clientId` field MUST validate against the
  shared slug-format rule with message `App id must be a lowercase token, e.g.
  my-app.` before the duplicate check runs.
- **signinapps-create-conflict-message**: a conflict error thrown by create MUST be
  caught and re-thrown as a validation error reading `A sign-in app "<leaf>" already
  exists in this ecosystem.`; any other error MUST be re-wrapped through the shared
  error-wrapping step.
- **signinapps-origin-validation**: the origin-validation step MUST return no error
  for an acceptable origin and, for a rejected one, the first-violated-rule message:
  not-a-URL ("... is not a valid URL."), non-http(s) scheme ("... must be http(s)."),
  embedded credentials ("... must not include credentials."), or a
  non-empty/non-"/" path, query, or fragment ("... must be just a scheme + host (no
  path).").
- **signinapps-origin-canonicalization-and-dedup**: the origin-canonicalization step
  MUST lowercase the scheme and host and drop a trailing slash while preserving the
  port (e.g. `"HTTPS://Example.com:8443/"` → `"https://example.com:8443"`); the
  origin-list canonicalization step MUST validate every raw origin (throwing a
  validation error on the first failure), then canonicalize and de-duplicate in
  first-seen order.
- **signinapps-start-url-placeholder**: the start-URL text MUST be a
  non-resolvable, placeholder-templated string of the form
  `<your-adh-auth-host>/oauth/signin/start?clientId=<clientID>&providerId=github&return=<your-app-origin>/auth/callback`
  where `<clientID>` is the app's full slug (the detail passes `app.slug`) and only
  the host and the return origin are literal placeholders
  - it is documentation text for the detail's read-only "Start URL" field, not a URL
  the app itself ever fetches.
- **signinapps-detail-fields**: the detail form specification MUST present fields in
  the order `name`, `slug`, `githubEnabled`, `allowedReturnOrigins`, `startURL`;
  `slug` is read-only.
- **signinapps-delete-confirmation**: the delete action's title MUST be "Delete
  sign-in app" and its confirmation text MUST be `Delete sign-in app "<app.name>"?
  Apps using it will stop signing in.`.
- **signinapps-unknown-app-empty**: a path segment id matching no existing app's id
  MUST return an empty result.
- **client-slug-normalization**: the alternate client's create operation MUST trim
  and lowercase the submitted `slug` and trim the submitted `name` client-side
  before sending the create request - a defensive normalization not strictly
  required at create time, since the `clientId` field's slug-format rule already
  constrains it to lowercase in the primary implementation.
- **conflict-message-parity**: the alternate client's create operation's conflict
  handling MUST use the message `A sign-in app "<slug>" already exists in this
  ecosystem.` - identical wording to **signinapps-create-conflict-message**,
  keeping the two implementations' user-visible error text in parity.
- **origin-validation-delegated**: the alternate client's create/update operations
  MUST forward `allowedReturnOrigins` with no client-side format check of their own;
  the equivalent scheme/credentials/path checks (mirroring
  **signinapps-origin-validation**) live in a separate presentation-layer file
  outside this component's given sources, not in the data-client layer itself (see
  Design Decisions).
- **leaf-helper-absent**: the alternate client's own data shape MAY omit an
  equivalent of the leaf-computation step. A caller on that side that needs the
  ecosystem-stripped leaf MUST recompute it from `slug` and the ecosystem's own slug
  itself.

### Feature Flags

- **flags-no-cache-per-call**: the rail path resolver MUST fetch the flag list
  fresh on every invocation - there is no in-memory cache of the flag list between
  calls.
- **flags-list-sort-and-sublabel**: the level's items MUST be sorted by `key`
  ascending (e.g. `["dark_mode", "new_checkout"]`); each item's sublabel MUST be
  "On" or "Off", with " · <description>" appended when `description` is non-empty,
  and its icon MUST visually distinguish the enabled state from the disabled state.
- **flags-create-fields**: the create form specification MUST expose `key`,
  `description`, `enabled` in that order; `key` is required.
- **flags-duplicate-key-check**: before calling create, the save action MUST reject
  a `key` already present in the passed-in `existing` list with `A flag named
  "<key>" already exists.`; a conflict error from the network call itself MUST be
  caught and re-thrown with the identical message.
- **flags-detail-fields**: the detail form specification MUST present `key`
  (read-only), `enabled`, `description` in that order; the update sent on save MUST
  fall back to the current `flag.enabled`/`flag.description` for any field the
  values dictionary omits.
- **flags-delete-confirmation**: the delete action's title MUST be "Delete flag" and
  its confirmation text MUST be `"<flag.key>" will be removed. Anything reading it
  falls back to its default.`.
- **flags-detail-id-format**: the detail id MUST be
  `feature-flag:<ecosystem.id>:<flag.key>`.
- **flags-key-charset-unrestricted**: a feature-flag key SHOULD NOT contain a colon,
  because the key is embedded unescaped in the colon-delimited composite id
  `feature-flag:<ecosystem.id>:<flag.key>` and used directly as a navigation-item id,
  so a key containing a colon could collide with another item's composite id. A port
  SHOULD reject such a key on the create form's `key` field. Today neither the primary
  implementation's create form nor the alternate client's create operation and dialog
  state enforces any character-set restriction: only non-blank and non-duplicate are
  checked.
- **flag-key-immutable-in-path**: the alternate client's update/delete operations
  MUST address a flag by embedding its `key` in the request path, never in the
  body - the key is immutable once created, matching the primary implementation's
  use of `key` as the flag's own identifier.
- **flags-no-precheck-in-alternate-client**: the alternate client's create operation
  MUST send the request unconditionally and let a duplicate key surface as whatever
  status the backend returns; unlike the primary implementation's create form, it
  performs no pre-flight duplicate check against an existing list and does not
  intercept a conflict into a friendlier message.

### Server Bags

- **bags-list-preview**: the level's items MUST be sorted by `key` ascending, with
  sublabel set to the bag's value collapsed to one line by splitting its pretty
  text on newlines, trimming each line's surrounding spaces, and rejoining with a
  single space (e.g. `{ "maxItems" : 20 }`).
- **bags-create-fields**: the create form specification MUST expose `key`, `value`
  (a required JSON-value field), `description`, in that order.
- **bags-json-parse-before-duplicate-check**: in the create save action, `value`
  MUST be parsed via the value-parsing step before the duplicate-`key` check runs -
  invalid JSON with a taken key still surfaces the JSON error first.
- **bags-invalid-json-message-generic**: the value-parsing step MUST discard the
  underlying decode error's specific message and throw a validation error reading
  `Value must be valid JSON <em dash> e.g. true, 42, "text", or {"a": 1}.` instead.
- **bags-duplicate-key-check**: the same dual client-pre-check-plus-conflict-catch
  pattern as feature flags applies, with the message `A bag named "<key>" already
  exists.`.
- **bags-detail-full-replace-on-save**: the detail save action MUST re-parse
  `value` from the form's current text on every save and send it as a full
  replacement in the update's `value` field, never a merge of the previous and new
  JSON.
- **bags-removal-message-distinct-from-flags**: the server-bags delete
  confirmation's removal message ("will be deleted. Anything reading it gets
  nothing <em dash> there is no default.") MUST NOT reuse the feature-flags delete
  confirmation's message ("will be removed. Anything reading it falls back to its
  default.") - server bags have no default fallback, unlike feature flags, so
  borrowing the flags' message would promise a fallback that does not exist (see
  Design Decisions).
- **bags-json-equality-int-number**: the wrapped JSON value type's equality and
  hashing MUST treat an integral floating-point number and a plain integer as the
  same value whenever they represent the same integral quantity - e.g. a stored
  value held as the floating-point number `20` (a decoded `20` reads as an integer
  first, so this arises for a value constructed as a number), updated by typing
  `{"maxItems": 50}`, produces an update whose value is written as the integer `50`
  even though the original was held as a floating-point `20` - this exists
  because naive derived equality otherwise misfires a form's dirty-check.
- **bag-value-validation-delegated**: the alternate client's bag data shapes MUST
  leave `value` untyped, and that layer performs no JSON-shape validation of its
  own - the equivalent of the value-parsing step's parse-or-reject behavior lives
  in a sibling presentation-layer package outside this component's given sources,
  not in the data-client layer itself (see Design Decisions).

### Storage Access Tokens

- **tokens-shared-rail-parameterization**: the shared token rail's resolution
  operation MUST serve both the ecosystem-scoped case and the caller's-own-tokens
  case through the same operation, parameterized only by the ecosystem id (or its
  absence), the level id, and the title.
- **tokens-ecosystem-scoping-via-parameter**: the create form's save action MUST
  always construct its create body with no ecosystem id of its own - ecosystem
  scoping happens exclusively through the operation's own ecosystem-id parameter,
  never through the body's own ecosystem-id field.
- **tokens-about-text-variant**: the rail's about-text MUST return the no-ecosystem
  variant when no ecosystem id is given and the ecosystem-scoped variant otherwise.
- **tokens-name-pattern**: the create form's `name` field MUST validate against the
  shared slug-format rule ("Use lowercase letters, numbers and hyphens.").
- **tokens-create-three-way-catch**: the create form's save action MUST catch
  errors in three tiers: a conflict error becomes a validation error reading `That name is already in use.
  Token names stay reserved even after revoke <em dash> pick a different one.`; any other
  shared error kind MUST be re-thrown unchanged; any error outside that shared
  taxonomy MUST become a generic unexpected error reading `Couldn't create the
  token. Please try again.`, discarding the original error's own message. This is an
  explicitly different pattern from the shared error-wrapping convention used
  everywhere else in this component (see Design Decisions).
- **tokens-reveal-once-on-create**: on a successful create, the raw secret MUST be
  stored in the revealed-secrets store keyed by the created token's id.
- **tokens-detail-extra-fields-while-revealed**: the token detail MUST append
  `token` and `notice` read-only fields - with `notice` set to the fixed reveal
  notice ("Copy this token now <em dash> you won't be able to see it again.") - only while
  the revealed-secrets store holds a value for that token, and MUST set the
  on-screen-token marker to that token's id as a side effect of building that
  detail.
- **tokens-expire-revealed-secret-on-navigate**: the secret-expiry check MUST run
  at the top of every rail path resolution; it MUST drop the revealed secret and
  clear the on-screen-token marker when navigating to any destination other than
  the detail currently showing the secret, and MUST leave it untouched when
  re-rendering that same detail.
- **tokens-revoke-clears-revealed-secret**: the revoke action MUST wrap the revoke
  operation in the shared error-wrapping step and then clear that token's entry in
  the revealed-secrets store, regardless of whether a value was present.
- **tokens-no-save-action-on-detail**: the token detail's save action MUST be
  absent - a storage token has no editable fields once created, only revoke.
- **tokens-delete-confirmation**: the revoke action's title MUST be "Revoke token"
  and its confirmation text MUST be `Revoke storage token "<token.slug>"? Anything
  using it will lose access to its bucket.`.
- **tokens-detail-date-formatting**: the `lastUsed`/`created`/`expires` fields MUST
  format through the shared date-display helper. `lastUsed` and `expires` fall back
  to "never used" and "never" respectively when the underlying value is absent;
  `created` always formats.
- **dual-scoping-channels**: the alternate client's list/mint/revoke operations
  MUST accept scoping through a query-parameter scope channel independently of the
  mint-request body's own ecosystem-id field, a separate channel; that layer
  performs no reconciliation between the two channels - a caller sets whichever one
  the operation needs (mirroring the primary implementation's rail, whose create
  form always leaves the body's ecosystem-id field unset and relies solely on the
  parameter channel).
- **token-created-once**: the created-token result (the response that carries the
  plaintext secret) MUST be a distinct shape from the token list-row shape (which
  carries only a `prefix`); the alternate client gives no other route through which
  the raw secret can be retrieved again.

### Sync tables (web)

Which catalog resources one ecosystem syncs to offline clients. The backend
contract is adhbackend's sync-table-enrollment recipe; this topic is its client
and pane. It is web-only for now.

- **sync-tables-two-families**: the sync-tables client MUST be built for one of two
  route families. `"admin"` addresses `/api/v1/sync/tables/{id}`, with one resource
  at `/api/v1/sync/tables/{id}/resources/{resource}`, for platform staff.
  `"ecosystem"` addresses `/api/v1/ecosystems/{id}/sync_tables`, with one resource
  at `/api/v1/ecosystems/{id}/sync_tables/{resource}`, for the ecosystem's
  managers. The ecosystem id and the resource MUST be URL-encoded in both.
- **sync-tables-camel-rows**: each catalog row MUST be mapped from the wire's
  snake_case (`push_mode`, `default_enabled`) to `pushMode` and `defaultEnabled`,
  keeping `resource`, `scope`, `enabled` and `overridden` as they are.
- **sync-tables-read-drains-list**: reading the catalog MUST drain the /v1 list
  envelope, so every resource is returned however the server pages it. It pages
  by each row's `id`, which the backend sets to the row's resource, because the
  /v1 gateway pages only by `id`.
- **sync-tables-set-returns-catalog**: setting a resource MUST POST
  `{ enabled }` to its resource path and return the full refreshed catalog from the
  response's `tables`.
- **sync-tables-clear-rereads**: clearing a resource's override MUST DELETE its
  resource path and then re-read the catalog, because /v1 answers a DELETE with a
  tombstone, not the catalog.
- **sync-tables-schema-of**: a row's schema MUST be the part of its resource before
  the first dot.
- **sync-tables-pane-family**: the editor (`SyncTablesEditor`) MUST take the family
  as a prop, defaulting to `"ecosystem"`, and MUST key its cached catalog by family
  and ecosystem id, so the admin console and the hub never share a cache entry. The
  hub's `SyncTablesPane` takes no `family` and always uses the `"ecosystem"` family.
- **sync-tables-pane-skips-noops**: Sync and Don't sync MUST act only on selected
  rows not already in that state, and Reset to default only on selected rows that
  are overridden. A no-op set would store an override that pins the resource
  against a later change to its default.
- **sync-tables-pane-sequential**: the pane's bulk actions MUST run one resource at
  a time through the shared batch runner, halting on the first failure until the
  user continues or stops, and leaving earlier saves in place.
- **sync-tables-pane-reseed**: after each write the pane MUST replace its cached
  catalog with the catalog the write returned, then refetch once the write settles.

### Sign-up list (web)

An ecosystem's sign-up list: the emails that may sign in, each with the product
role and the set it receives the first time that person proves the address. It
replaces the allow-list field the client-auth form used to carry.

- **signup-list-client**: the sign-up list client MUST address
  `/api/v1/ecosystems/{id}/signup_list_entries`, with the ecosystem id and the
  entry id URL-encoded. Listing MUST drain the /v1 envelope, map each row from
  snake_case (`role_id`, `set_id`, `created`, `granted_at`, `granted_customer_id`)
  to `roleId`, `setId`, `createdAt`, `grantedAt` and `grantedCustomerId`, convert
  the epoch-seconds `created` to an ISO timestamp, and return the entries sorted by
  email. Adding MUST `POST` `{ email, role_id, set_id }` with `null` for a role or
  set that was not chosen. Removing MUST `DELETE` the entry's own path.
- **signup-list-pane**: the pane MUST read nothing and say "No product selected."
  when it has no ecosystem id. Otherwise it MUST list each entry with its email,
  its role name ("No role" when none, "Unknown role" when the id is not in the
  product's roles), its set name (likewise), and a status that reads "Granted"
  with the date once granted and a waiting state before the person's first proven
  sign-in. An empty list MUST read "No one is on the sign-up list."
- **signup-list-add**: Add MUST refuse an address that fails **signup-email-error**
  with that message and send nothing. Otherwise it MUST send the trimmed email and
  the chosen role and set (or `null`), then clear the form and reload. Add is
  disabled while the email is blank or a request is in flight. Adding an email
  already listed changes its role and set. A failure MUST show the error's own
  message (or "Something went wrong." when it has none) and keep the form as typed.
- **signup-list-remove**: removing an entry MUST delete it and reload, and MUST NOT
  take back what the entry already granted; a role is revoked in Product roles and
  a set in Sets.
- **signup-list-choices-tolerant**: an unreadable role list or set list MUST offer
  no choices and MUST NOT block adding an entry without them.

### Product roles (web)

- **product-roles-editor-shared**: the pane MUST be the Teams roles editor mounted
  on the ecosystem target, so a product's roles and a workspace's are edited by the
  same code. It MUST say "No product selected." and read nothing without an
  ecosystem id.
- **product-roles-holders**: below the selected role, the pane MUST list the
  holders of that role whose grant is workspace-wide (no feature scope) and whose
  subject is a customer, read on the ecosystem target. It MUST say "No product user
  has been granted this role." when there are none, and MUST show a note that every
  product user holds the role when it is the customers' default role.
- **product-roles-grant-revoke**: the grant picker MUST offer only the realm's
  product users (customers from the ecosystem's subject directory) who do not
  already hold the role; an unreadable directory MUST offer none. Grant MUST put an
  assignment with subject kind `customer`, the chosen subject and the role, on the
  ecosystem target. Revoke MUST delete that holder's assignment. Both MUST reload
  the holders afterward, run one at a time, and show a failure in the pane.
- **pane-caller**: the sign-up list, product roles and sets panes MUST accept an
  optional caller, either `manager` (the default: a workspace manager in the hub)
  or `product_admin` (a product's own admin on its admin site, phase 6), so the
  admin site mounts the same panes the hub does. A caller narrows only what the
  backend would refuse that caller anyway. The sign-up list pane behaves the same
  for both.
- **product-roles-admin-seats-protected**: for the `product_admin` caller, the
  holders of the product's `admin` role (the system role whose slug is `admin`)
  MUST be listed without a Revoke button and the pane MUST say "Admins are added here
  and removed by the product's managers."; every other role keeps Revoke, and the
  manager caller keeps Revoke on every role. The backend refuses a product admin any
  change to an admin seat (422 `admin_seat_protected`).

### Sets (web)

- **sets-client**: the sets client MUST address `/api/v1/sets` (list by `GET`,
  create by `POST`), `/api/v1/sets/{id}` (edit by `POST`, delete by `DELETE`),
  `/api/v1/sets/{id}/members` (replace what a set contains, by `POST`) and
  `/api/v1/sets/{id}/values` (replace its permissions and limits, by `POST`), each
  scoped to the ecosystem through the /v1 query. A refusal from the backend MUST
  surface as a set-refused error carrying its rule, message, and optionally limits,
  containing sets and a customer count.
- **sets-pane-list-create**: the pane MUST say "No product selected." and read
  nothing without an ecosystem id, list the sets with a "Default" badge on the
  default one, and say "This product has no sets." when there are none. Create MUST
  send the trimmed name and slug, be disabled while either is blank, and select the
  new set.
- **sets-pane-values-generic**: the editor MUST render the feature catalog's
  `setEntries` generically, with a checkbox per permission and a typed field per
  limit (a number field for a count, a text field for a tier), and MUST NOT name a
  feature itself. A stored value the catalog no longer declares MUST be kept, and an
  empty limit MUST be left undefined.
- **sets-pane-save**: Save MUST send the values only when they differ from the
  stored ones, and MUST send the containment (which sets this one contains) only
  when that changed; when neither changed nothing is sent. A count that is
  not a whole number MUST be refused with "<label> must be a whole number." and
  nothing sent.
- **sets-pane-default-delete**: Make default MUST edit the set with `isDefault`
  true. Delete MUST remove the set.
- **sets-refusal-text**: a refusal MUST read `Refused under rule <rule>: <message>.`,
  then ` Limits: <a>, <b>.` when limits are named, then ` Sets affected: <names>.`
  with each set's name (its id when unknown), then `<N> customer would conflict.` or
  `<N> customers would conflict.` when a count is given. Any other error MUST show
  its own message, or "Something went wrong." when it has none.
- **sets-pane-caller-limits**: for the `product_admin` caller, the editor MUST NOT
  show the usage-tier limit (`usage.tier`), and MUST cap the storage-quota limit
  (`storage.quota_bytes`) at the default quota (5 GiB): the field's maximum is that
  many bytes and a larger whole number is refused with "<label> can be at most <N>."
  with nothing sent. The manager caller sees every limit and no cap.
- **sets-pane-tier-locked**: for the `product_admin` caller, a set whose stored values
  include `usage.tier` MUST show "This set has a usage tier, which only the product's
  managers can change, so its permissions and limits are theirs to change too. What it
  contains is yours." and a Save that would change its values MUST show that text and
  send nothing, because a set's values are written whole and the backend refuses a
  product admin any write naming the tier; a change to what the set contains is still
  sent.


### Billing and the workspace gate (web)

- **billing-placeholder**: the billing pane MUST state plainly that billing is
  coming soon and MUST NOT show an empty table, which would read as "no charges".
  It MUST accept the same props as its sibling panes and read none of them.
- **gate-resolve-or-explain**: the gate MUST resolve a workspace to its default
  ecosystem before rendering any pane, and MUST hand the resolved id to its child
  function. When the resolution failed with no answer, it MUST render the
  resolution-error notice instead of the pane. When an id resolved but the caller
  cannot manage the ecosystem, it MUST render the not-manageable notice naming the
  pane's feature. A failed re-read behind a resolved id MUST keep the working pane.
- **gate-reports-busy**: the gate MUST report whether the scope is being fetched
  (not whether the pane's content is) to the topic list above it, including on a
  cached re-read, and MUST stop reporting once the scope has landed.

### Product totals job counts (web)

- **totals-pane-jobs**: `ProductTotalsPane` MUST, when the totals it is given carry a non-empty `jobsByStatus`, show one count for each job status beside the eight figures, and MUST show no jobs section when the map is empty or absent. The pane MUST NOT sum the statuses itself into a new total.
