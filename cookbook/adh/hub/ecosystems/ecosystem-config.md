---
id: 87ca0139-6cd0-46dd-a9fb-40ad3406f175
title: "Ecosystem Config"
type: ingredient
version: 2.3.0
status: review
language: en
created: 2026-09-24
modified: 2026-11-23
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Five product-rail topics (User Auth, Sign-in apps, Feature flags, Server bags, Storage Access Tokens) that let a hub caller view and edit one ecosystem's configuration, plus their shared data models and matching client-side data layer, and the web-only sync-tables, sign-up list, product roles, sets and billing panes behind a workspace gate."
platforms:
  - swift
  - macos
  - ios
  - typescript
  - web
tags:
  - hub
  - ecosystem-config
  - feature-flags
  - oauth
  - sync-tables
depends-on: []
related:
  - 65fbb2b1-ca41-499f-ac03-7ecc0e206dcc
  - 201572ee-2e0f-4839-94f5-252f8044c4bf
references: []
approved-by: ""
approved-date: ""
---

# Ecosystem Config

## Overview

This ingredient is five topic implementations that hang off one ecosystem's product
rail - a user-auth topic, a sign-in-apps topic, a feature-flags topic, a
server-bags topic, and a storage-tokens topic (a thin wrapper around a shared token
rail) - plus the data models and five data-source interfaces they share, and a
matching client-side data layer for the same five resources. A sixth, web-only topic, sync tables, holds a client and a pane for choosing which catalog resources the ecosystem syncs to offline clients. Four more web-only panes, added in phase 5, configure a product's people and entitlements: a sign-up list (which emails may sign in, and the role and set each receives), product roles (what each role grants and who holds it), sets (named bundles of permissions and limits), and a billing placeholder. A small gate component resolves a workspace to its default ecosystem before any of these panes renders. Each topic resolves a
rail-relative navigation path into a level (a list of that ecosystem's
flags/bags/apps/tokens, with a create action) or a detail (a form specification for
viewing/editing one entity), orchestrating an injected data-source interface, domain
validation, and error normalization through a shared error type. A second,
independently maintained client layer implements the corresponding fetch operations
for the same five resources, consumed by presentation-layer panes and dialog-state
modules that are not part of this component's given sources. This is a **logic**
ingredient: none of these five topics render anything themselves - they build
declarative form/level/detail value objects that a separate presentation layer
(outside these sources) turns into UI, and the second client layer is a set of plain
fetch-based operations with no view code of its own.

## Behavioral Requirements

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

- **totals-pane-jobs**: `ProductTotalsPane` MUST show, after Storage and before the two waiting counts, a "Jobs" figure that is the sum of every status in `jobsByStatus`, followed by one figure for each status in name order, labeled "Jobs <status>" with underscores read as spaces ("Jobs timed out"). When the map is empty it MUST show "Jobs" as 0 and no status figures. The sum is the only total the pane derives; it never filters a status out.
## Appearance

Not applicable: this is a set of navigation/data-orchestration topics and data
clients, not a visual component.

## States

Not applicable: this is a set of navigation/data-orchestration topics and data
clients, not a visual component. The only stateful runtime behavior is the shared
token rail's revealed-secrets/on-screen-token reveal-once lifecycle, which is
specified under Behavioral Requirements (**tokens-reveal-once-on-create**,
**tokens-expire-revealed-secret-on-navigate**,
**tokens-revoke-clears-revealed-secret**), not here.

## Accessibility

Not applicable: this is a set of navigation/data-orchestration topics and data
clients, not a visual component. Accessibility of the forms these topics build is
the concern of whatever renders the form/level/detail value objects, a different
component not among these given sources.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ecosystem-config-001 | auth-field-order, auth-signup-options | The user-auth detail resolved with sign-up mode "invite only" and sign-in enabled | Detail id "auth-settings:org.acme.shop"; fields ["signupMode", "signupHelp", "loginEnabled"]; the sign-up-help text reads "Only people you've invited can create an account." |
| ecosystem-config-002 | auth-save-sends-both-values | Sign-up mode set to "closed", sign-in disabled, then saved | The recorded update carries both fields: sign-up mode "closed" and sign-in disabled |
| ecosystem-config-003 | path-depth-dispatch | A one-segment path resolved against the user-auth topic | An empty result |
| ecosystem-config-004 | signinapps-list-sort | Two apps named "Shop web" and "Admin console" | Level items ordered ["Admin console", "Shop web"] |
| ecosystem-config-005 | signinapps-origin-validation | The origin-validation step given "https://user:pw@example.com" | "Return origin \"https://user:pw@example.com\" must not include credentials." |
| ecosystem-config-006 | signinapps-origin-canonicalization-and-dedup | The origin-canonicalization step given "HTTPS://Example.com:8443/" | "https://example.com:8443" |
| ecosystem-config-007 | signinapps-duplicate-leaf-check, signinapps-clientid-pattern | Create attempted with `clientId = "Bad.Id"`, then "shop-web" (taken, case-insensitive), then "kiosk" | First save fails with the slug-format message; second fails with "App id \"shop-web\" is already in use."; third succeeds |
| ecosystem-config-008 | signinapps-create-conflict-message | The create operation throws a conflict error for slug "kiosk" | Save fails with "A sign-in app \"kiosk\" already exists in this ecosystem." |
| ecosystem-config-009 | signinapps-detail-fields, signinapps-origin-validation | `allowedReturnOrigins` set to ["https://Shop.acme.test/", "bogus"], then saved | Save fails with "Return origin \"bogus\" is not a valid URL." |
| ecosystem-config-010 | signinapps-delete-confirmation | The delete action read for app "Shop web" | Title "Delete sign-in app"; text "Delete sign-in app \"Shop web\"? Apps using it will stop signing in." |
| ecosystem-config-011 | flags-list-sort-and-sublabel | Flags `new_checkout` (enabled, described) and `dark_mode` (disabled) | Items ordered ["dark_mode", "new_checkout"]; `dark_mode` sublabel "Off"; `new_checkout` sublabel "On · New checkout flow"; each item's icon reflects its enabled state |
| ecosystem-config-012 | flags-duplicate-key-check | Create attempted with key "dark_mode" (taken), then "beta_search" | First save fails with "A flag named \"dark_mode\" already exists."; second succeeds |
| ecosystem-config-013 | flags-delete-confirmation, flags-detail-id-format | Delete action read for flag `new_checkout` | Detail id "feature-flag:org.acme.shop:new_checkout"; confirmation "\"new_checkout\" will be removed. Anything reading it falls back to its default." |
| ecosystem-config-014 | bags-list-preview | Bag `onboarding` with value `{"maxItems": 20}` | Sublabel `{ "maxItems" : 20 }` |
| ecosystem-config-015 | bags-json-parse-before-duplicate-check, bags-invalid-json-message-generic | Create attempted with key "limits", value "{oops" | Save fails with a JSON error on the value field before any duplicate check runs |
| ecosystem-config-016 | bags-detail-full-replace-on-save, bags-json-equality-int-number | Bag `onboarding` (originally value 20) edited by typing `{"maxItems": 50}` | The recorded update's value is the object `{maxItems: 50}` with `50` written as an integer even though the original was held as a floating-point number `20`; delete confirmation reads "\"onboarding\" will be deleted. Anything reading it gets nothing <em dash> there is no default." |
| ecosystem-config-017 | tokens-reveal-once-on-create, tokens-detail-extra-fields-while-revealed, tokens-expire-revealed-secret-on-navigate | Mint token "nightly", view its detail twice, then view the level, then view its detail again | Secret shown both times before navigating away; the revealed-secrets store holds nothing for that token and the `token`/`notice` fields are absent after visiting the level |
| ecosystem-config-018 | tokens-create-three-way-catch | The create operation throws a conflict error for name "ci-sync" | Save fails with "That name is already in use. Token names stay reserved even after revoke <em dash> pick a different one." |
| ecosystem-config-019 | tokens-revoke-clears-revealed-secret, tokens-no-save-action-on-detail | Revoke token `tok-1` | No save action present; the revocation is recorded against ecosystem "org.acme.shop", token id "tok-1" |
| ecosystem-config-020 | tokens-shared-rail-parameterization, tokens-about-text-variant | The shared token rail resolved with no ecosystem id | The caller's-own-tokens listing is used; the no-ecosystem about-text reads "A storage principal scoped to your account; it gets its own empty bucket." |
| ecosystem-config-021 | flag-key-immutable-in-path | The alternate client's update operation invoked for ecosystem "eco-1", flag "dark_mode", disabling it | The request addresses the flag by embedding its key in the request path, with only the ecosystem id (`ecosystem: "eco-1"`) and `enabled: false` in the body, and never the key |
| ecosystem-config-022 | conflict-message-parity | The alternate client's create operation invoked for slug "kiosk", where the backend responds with a conflict status | Rejects with "A sign-in app \"kiosk\" already exists in this ecosystem." |
| ecosystem-config-023 | dual-scoping-channels | The alternate client's mint operation invoked with name "nightly" and ecosystem id "eco-1" via the scope-query channel | The request carries the ecosystem id only in the scope-query channel, not in the body |
| ecosystem-config-024 | sync-tables-two-families | The `"ecosystem"` client sets `content.notes` on for ecosystem "eco-1" | POST `/api/v1/ecosystems/eco-1/sync_tables/content.notes` with `{"enabled":true}` |
| ecosystem-config-025 | sync-tables-two-families | The `"admin"` client sets `content.notes` off for ecosystem "eco-1" | POST `/api/v1/sync/tables/eco-1/resources/content.notes` with `{"enabled":false}` |
| ecosystem-config-026 | sync-tables-camel-rows, sync-tables-read-drains-list | The list returns `{resource:"content.feed", push_mode:"generic", default_enabled:true, …}` | The row reads `pushMode: "generic"`, `defaultEnabled: true` |
| ecosystem-config-027 | sync-tables-clear-rereads | The `"ecosystem"` client clears `content.notes`, and the DELETE answers a tombstone | DELETE `/api/v1/ecosystems/eco-1/sync_tables/content.notes`, then a fresh read of the catalog is returned |
| ecosystem-config-028 | sync-tables-schema-of | Resource `persona_memory.links` | Schema `persona_memory` |
| ecosystem-config-029 | sync-tables-pane-skips-noops | Two rows selected, one already synced, then Sync | One POST, for the row that was not synced |
| ecosystem-config-030 | auth-login-allow-list-wire | A response omitting `login_allowed_emails`, then one carrying `[]`, then a patch setting `loginAllowedEmails` to `null` | The first reads `null`; the second reads `[]`; the patch body carries `"login_allowed_emails": null` rather than dropping the key |
| ecosystem-config-031 | auth-login-allow-list-patch | The list `[" A@x.com ", "", "b@x.com", "a@X.com"]` cleaned, then `null`, then `[""]`; then a patch turning the switch on with the sign-up emails `[" A@x.com ", "b@x.com", "a@x.com"]`, a patch turning it off, and a patch on a list that stays on | The first cleans to `["a@x.com", "b@x.com"]`; `null` stays `null`; `[""]` cleans to `[]`; turning on sends `loginAllowedEmails` as `["a@x.com", "b@x.com"]`; turning off sends `null`; the list that stays on sends nothing |
| ecosystem-config-032 | signup-email-error | The email check given an empty string, then `alice`, `alice@`, `@x.com`, `a@x`, `a b@x.com`, `a@@x.com`, `"a"@x.com`, `a@x..com`, a 255-character address, a 254-character address, and ` First.Last+tag@Sub.Example.co.uk ` | The empty string gives "Enter an email address."; each bad entry gives `"<the entry>" is not an email address.`; the 254-character address and the last one are accepted (null) |
| ecosystem-config-033 | sync-tables-set-returns-catalog | The `"ecosystem"` client sets `content.notes` on for "eco-1" and the response is `{tables: [...]}` | The result is the full refreshed catalog mapped from `tables`, not a single row |
| ecosystem-config-034 | sync-tables-pane-family | The editor mounted with no `family`, then with `family="admin"`, both for "eco-1" | The first uses the `"ecosystem"` family; the two keep separate cached catalogs, keyed by family and ecosystem id |
| ecosystem-config-035 | sync-tables-pane-sequential | Three rows selected, Sync, and the second write fails | The writes run one at a time; the run halts at the second until the user continues or stops; the first save stays in place |
| ecosystem-config-036 | sync-tables-pane-reseed | A write returns a catalog | The cached catalog is replaced with the returned catalog, then refetched once the write settles |
| ecosystem-config-038 | sync-tables-read-drains-list | A catalog row `{id:"content.feed", resource:"content.feed", …}` | The read pages from `content.feed` (the row's `id`) |
| ecosystem-config-037 | auth-login-allow-list-dropped | A sent list `["a@x.com"]`, then `[]`, then `null`, then `["a@x.com"]` against a saved `["A@x.com"]`, then a patch with no list at all, each against a saved policy without the field unless stated | The first two are a drop; `null` is not; the same list in another case is not; the patch without a list is not; a drop fails the save with "The sign-in list was not saved, so everyone can still sign in. This backend does not support the list yet." |
| ecosystem-config-039 | auth-login-allow-list-switch | Two policies whose lists are `["a@x.com"]` and `["b@x.com", "c@x.com"]`; then `[]` and `null` | The first pair compares as the same policy; the second pair compares as different |
| ecosystem-config-040 | signup-list-client | The client lists ecosystem "eco 1", then adds `a@example.com` with role "r-1" and set "s-1", then adds `b@example.com` with no role or set, then removes entry "e-1" from "eco-1" | The list reads `/api/v1/ecosystems/eco%201/signup_list_entries` and returns entries sorted by email with camel-cased fields; the first add is a `POST` with `{email, role_id: "r-1", set_id: "s-1"}`; the second sends `role_id` and `set_id` as `null`; the remove is a `DELETE` of `/api/v1/ecosystems/eco-1/signup_list_entries/e-1` |
| ecosystem-config-041 | signup-list-add | The pane given `alice`, then `a@example.com` with a chosen role and set | The first shows `"alice" is not an email address.` and sends nothing; the second sends the email, role and set, then reloads the list |
| ecosystem-config-042 | signup-list-remove, signup-list-pane | An entry removed from a list showing a granted entry and a waiting one | The entry is deleted and the list reloads; the granted entry reads with its date and the other shows its waiting state |
| ecosystem-config-043 | product-roles-grant-revoke, product-roles-holders | The holders of a role listed, then a product user chosen and granted, then a holder revoked | Only workspace-wide customer grants of that role are listed; the picker offers only product users who do not hold it; Grant puts an assignment with subject kind `customer` on the ecosystem target; Revoke deletes that assignment |
| ecosystem-config-044 | sets-pane-values-generic, sets-pane-save | A set opened whose catalog declares a storage permission, a storage-bytes count and a usage-tier text limit; the count changed to 1024 and Save; then a contained set ticked and Save | A checkbox per permission, a number field for the count and a text field for the tier; the values are sent with the permission, the count 1024 and the tier, and containment is not sent; the second Save sends containment alone |
| ecosystem-config-045 | sets-pane-save | The count field set to `1.5`, then Save | "Storage space must be a whole number." shows and nothing is sent |
| ecosystem-config-046 | sets-refusal-text | A refusal under rule 8 reading "the edit unsettles a container or puts a holder in conflict", naming limit `usage.tier` and the set "Basic" | "Refused under rule 8: the edit unsettles a container or puts a holder in conflict. Limits: usage.tier. Sets affected: Basic." |
| ecosystem-config-047 | gate-resolve-or-explain, gate-reports-busy | The gate with a scope still resolving, then resolved, then a failed re-read behind a resolved id, then a first read that failed | The busy report is true while resolving, false once resolved and true again on a cached re-read; the failed re-read keeps the pane; the failed first read replaces it with the resolution-error notice |
| ecosystem-config-048 | auth-password-enabled, client-auth-post-update | A policy whose `passwordEnabled` differs from the saved one, then saved on an ecosystem and on an application | The patch carries `passwordEnabled`; each update is a `POST` with a `client_auth` body |
| ecosystem-config-049 | product-roles-admin-seats-protected, pane-caller | The roles pane for the `product_admin` caller, then for the manager caller, each showing the `admin` role with a holder and another role with a holder | For `product_admin` the admin role's holder has no Revoke button and the note "Admins are added here and removed by the product's managers." shows, while the other role's holder keeps Revoke; for the manager both keep Revoke and no note shows |
| ecosystem-config-050 | sets-pane-caller-limits | The sets editor for the `product_admin` caller on a catalog declaring a usage tier and a storage quota; the quota set to 5368709121, then Save | The tier field is absent and the quota field's maximum is 5368709120; the Save shows "<label> can be at most 5368709120." and sends nothing |
| ecosystem-config-051 | sets-pane-tier-locked | A set whose values include `usage.tier`, opened by the `product_admin` caller; a permission toggled, then Save; then only a contained set toggled, then Save | The locked note shows; the first Save shows it as an error and sends nothing; the second sends the containment alone |
| ecosystem-config-052 | totals-pane-jobs | `ProductTotalsPane` given totals with `jobsByStatus` of `{ running: 3, done: 1200, failed: 4, timed_out: 1 }`, then with `{}` | "Jobs" 1,208, then "Jobs done", "Jobs failed", "Jobs running" and "Jobs timed out"; then "Jobs" 0 and no status figure |
## Edge Cases

- **Path deeper than one segment**: sign-in apps, feature flags, server bags, and
  storage tokens MUST return an empty result for any path longer than one segment;
  user auth MUST return an empty result for any non-empty path at all (it has no
  detail-lookup segment to descend into).
- **Unmatched id/key at depth one**: a path segment id matching no existing entity
  MUST return an empty result for all four list-based topics.
- **Malformed JSON in a server bag's value field**: the value-parsing step MUST
  discard the specific decode-error text and surface only the fixed invalid-JSON
  message, on both create and detail save.
- **Server-side duplicate after client pre-check passes**: a conflict error from
  create for flags, bags, or sign-in apps MUST be caught and re-thrown with the same
  friendly message the client-side pre-check uses, so the user sees identical
  wording regardless of which check caught the duplicate.
- **Case-insensitive sign-in-app leaf collision**: a new leaf that differs only in
  case from an existing one (e.g. "kiosk" vs. an existing "Kiosk") MUST be rejected
  by **signinapps-duplicate-leaf-check**, even though the raw strings are not equal.
- **Origin with credentials, a path, or a non-http(s) scheme**: each MUST be
  rejected by the origin-validation step with its own specific message and MUST NOT
  reach the network.
- **Re-rendering the detail currently showing a revealed secret**: MUST NOT drop the
  secret - the secret-expiry check's same-detail guard leaves it untouched; only
  navigating to a *different* destination drops it.
- **A value outside the shared error taxonomy thrown during storage-token create**:
  MUST be converted to a generic unexpected error reading "Couldn't create the
  token. Please try again.", discarding the original error's own message text - a deliberate divergence from the shared
  error-wrapping step's usual behavior of preserving as much detail as possible (see
  Design Decisions).
- **A feature-flag key containing a reserved character (e.g. `:`)**: see
  **flags-key-charset-unrestricted** - it SHOULD be rejected, but no given
  implementation rejects it yet, and it is later embedded unescaped in a
  colon-delimited composite id.
- **Path segments containing special characters**: the alternate client's
  path-encoding step MUST percent-encode every ecosystem id, flag key, bag key, and
  sign-in-app id interpolated into a request path, so a key/id with `/`, `?`, or
  similar cannot corrupt the request path even though no character-set validation
  rejects such a key upstream.
- **The create body's own ecosystem-id field left unset while a scope parameter is
  also given**: neither implementation reconciles the two channels;
  **dual-scoping-channels** documents that the rail always leaves the body field
  unset and relies on the parameter/query channel exclusively.

- **Turning "Only listed people" on with an empty sign-up list**: the save sends
  the sign-up list's own emails, an empty list, which means nobody may sign in. The
  backend keeps the sign-up entries equal to the list written, so the form MUST
  never send an empty draft list of its own that would erase every entry.
- **A sign-up list entry for an email already listed**: adding it changes its role
  and set rather than adding a second row; removing an entry never takes back a
  role or set it already granted.
- **A set edit the backend refuses**: the pane shows the refusal's rule, limits and
  affected sets in its own words.
- **A workspace that cannot be resolved**: every pane reads a missing ecosystem id
  as an empty ecosystem, so the gate MUST NOT let a failed resolution fall through
  to a pane that would then show "no server bags" for an ecosystem it never found.
- **A follower turned on while its parent is off**: the sync-tables write succeeds
  and the row comes back `overridden` but not `enabled`. The pane shows the server's
  answer rather than the requested state.
- **Switching ecosystems with rows selected**: the admin console clears the
  selection with the ecosystem, because resource ids are the same in every
  ecosystem and a kept selection would write to one the user has not looked at.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `dataSource` (user-auth topic) | data-source interface | none (required) | Injected transport for the user-auth topic: read and update operations. |
| `dataSource` (sign-in-apps topic) | data-source interface | none (required) | Injected transport for the sign-in-apps topic: list / create / update / delete, all scoped by the ecosystem id. |
| `dataSource` (feature-flags topic) | data-source interface | none (required) | Injected transport for the feature-flags topic: list / create / update(key) / delete(key). |
| `dataSource` (server-bags topic) | data-source interface | none (required) | Injected transport for the server-bags topic: list / create / update(key) / delete(key). |
| `dataSource` (storage-tokens topic) | data-source interface | none (required) | Injected transport for the storage-tokens topic and its shared rail: list / create / revoke, where an absent ecosystem id means the caller's own workspace tokens. |
| `ecosystem` | record | none (required) | Supplies the id/slug used to scope every list/create/update/delete call and to build composite detail ids. |
| `family` (sync tables, web only) | `"admin"` or `"ecosystem"` | `"ecosystem"` | Which route family the sync-tables client and editor address (the hub pane fixes it at `"ecosystem"`); see **sync-tables-two-families**. |
| `workspaceSlug` and `feature` (gate, web only) | optional string, string | none | The workspace whose default ecosystem the gate resolves, and the pane's name as the not-manageable notice says it; see **gate-resolve-or-explain**. |
| `ecosystemId` (web panes) | optional string | unset | Scopes the sign-up list, product roles, sets and billing panes; unset reads as "No product selected." where the pane reads anything. |
| `path` | list of navigation-path segments | empty | Rail-relative navigation path; see **path-depth-dispatch**. |
| `rail` | rail-provider interface | none (required, unused) | Passed to every rail path resolution per the topic-provider contract; none of these five topics call back through it themselves. |
| ecosystem id (alternate client) | string | none (required) | Ecosystem id, percent-encoded into every ecosystem-config request path. |
| scope parameters (alternate client) | optional strings | unset | Optional query-string scoping used only by the token operations. |

## Deep Linking

Not applicable: none of the given implementation files define a URL scheme, route
table, or app-continuation/universal-link handler. Navigation is expressed entirely
through the navigation-path values that a separate rail-rendering component (not
among these sources) turns into UI.

## Localization

Every user-facing string in this component is a hardcoded English literal - there
is no localization-catalog reference or i18n library call anywhere in the given
implementation files. Representative examples: the user-auth topic's "When off, no
one can sign in to this ecosystem."; the sign-up-mode help text's three case
strings; the feature-flags and server-bags removal messages; the origin-validation
step's four rejection messages; the storage-tokens rail's name-taken, create-failed,
and about-text messages. This is a fact of the current implementation, not a gap
this ingredient marks - nothing in the source suggests localization is planned or
partially wired.

## Accessibility Options

Not applicable: these files render nothing and read no accessibility display
setting (Reduce Motion, Increase Contrast, Differentiate Without Color, VoiceOver)
- that is the concern of whatever renders the form/level/detail value objects these
topics build.

## Feature Flags

Not applicable, in the build-time/runtime-toggle sense this section means: none of
the given implementations gate their own behavior behind a feature flag. (The
feature-flags topic itself *manages* feature flags as domain data for other apps to
read - that is the component's subject matter, documented under Behavioral
Requirements, not a toggle over this component's own code paths.)

## Analytics

Not applicable: no given source calls an analytics or event-emission API of any
kind.

## Privacy

- **Data collected**: this component collects no analytics of its own. It
  transports user-auth, sign-in-app, feature-flag, and server-bag records -
  configuration entities holding no end-user personal data, except the sign-up
  list (and the user-auth login allow-list the backend mirrors from it), which holds
  the email addresses an owner types to name who may sign in - and storage-token
  records, which do carry a security-sensitive secret: the raw `adh_`-prefixed
  token minted by the create/mint operation.
- **Storage**: on the primary implementation, the revealed-secrets store holds the
  raw secret in an in-memory map on the topic instance only; it is never written to
  persistent storage or any file by this component. It is dropped by the revoke
  action and by the secret-expiry check on navigating away from the detail that
  revealed it. On the alternate client, the mint operation returns the
  created-token result to the caller with no persistence of any kind in that
  layer - the create-response body is the only response that carries the raw
  secret, and it is shown once.
- **Transmission**: the mint/create request travels over whichever transport the
  injected data source (primary implementation) or the equivalent
  authenticated-fetch helper (alternate client) implementation uses - neither is
  part of this component's given sources, and this component configures no TLS or
  transport-level behavior itself.
- **Retention**: the plaintext secret is retained only until the reveal-once
  contract expires it (primary implementation) or for as long as the caller holds
  the create response (alternate client; no retention logic is given). User-auth,
  sign-in-app, feature-flag, and server-bag records have no retention policy
  defined in these sources beyond whatever the backend itself enforces.

## Logging

Not applicable: none of the given implementation files call a logging API of any
kind.

## Platform Notes

- **SwiftUI**: not applicable to these sources directly - none of the Swift files
  imports SwiftUI; they build form/level/detail value objects that a SwiftUI (or
  AppKit) rendering layer elsewhere consumes unchanged.
- **AppKit / UIKit**: this is one of the two source platforms. The files live under
  `packages/apple/AgenticDeveloperHubSDK/Hub/Features/EcosystemConfig/`
  (`AuthSettingsTopic.swift`, `EcosystemConfigModels.swift`,
  `FeatureFlagsTopic.swift`, `ServerBagsTopic.swift`, `SigninAppsTopic.swift`,
  `StorageTokensRail.swift`, `StorageTokensTopic.swift`), part of the
  `AgenticDeveloperHubSDKHub` sources directory that `project.yml` builds into both
  `AgenticDeveloperHubSDKHub-macOS` and `AgenticDeveloperHubSDKHub-iOS` targets from the same
  source tree - there is no platform-specific branch anywhere in these files. Each
  topic conforms to `EcosystemTopicProvider` and implements
  `child(for:path:rail:)`; every data-source call not covered by the exception
  below is wrapped in `HubError.wrap { ... }`, with specific mappings to
  `HubError.conflict`/`.validation`/`.unexpected` where the requirements above call
  for a distinct message.

  Three requirements exist only because of Swift's concurrency and protocol model
  and apply to this platform alone: `AuthSettingsTopic`, `SigninAppsTopic`,
  `FeatureFlagsTopic`, `ServerBagsTopic`, and `StorageTokensRail`/
  `StorageTokensTopic` are declared `@MainActor final class`, with every method
  that touches their own stored state running only on the main actor. Static
  helpers a `FormAction.perform` closure calls directly -
  `ServerBagsTopic.parsedValue`, `SigninAppsTopic.validateOrigin`/
  `canonicalOrigin`/`canonicalOrigins`, `StorageTokensRail.nameTakenMessage`/
  `createFailedMessage` - are declared `nonisolated`, because `FormAction.perform`
  closures are not `@MainActor`-isolated (per the source's own comments citing
  `FormSpec.swift`). `AuthSettings`, `AuthSettingsUpdate`, `SigninApp`,
  `SigninAppCreate`, `SigninAppUpdate`, `FeatureFlag`, `FeatureFlagCreate`,
  `FeatureFlagUpdate`, `ServerBag`, `ServerBagCreate`, `ServerBagUpdate`,
  `StorageToken`, `StorageTokenCreated`, and `StorageTokenCreate` are all declared
  `Codable, Hashable, Sendable` value types, so they can cross actor boundaries
  (e.g. into a `FormAction.perform` closure) without a data race.

  `AuthSettingsTopic.entry` declares `leadsTo: .detail`; the sign-up options come
  from `SignupMode.allCases`, parsed with `SignupMode(rawValue:)`, with help text
  from `SignupMode.help` (declared in `EcosystemConfigModels.swift`).
  `AuthSettings.allowedProviders: [String]?` decodes from
  `AuthSettingsDataSource.get`'s response but `AuthSettingsTopic.detail`'s form
  specification never surfaces it, and `AuthSettingsUpdate` has no field for it. The
  login allow-list (`login_allowed_emails`) is not decoded on Apple at all
  yet; that editor is planned.

  `SigninApp.leaf(in:)` implements leaf computation; the duplicate check compares
  against it case-insensitively; the `clientId` field validates against
  `Slug.pattern` with message `SigninAppsTopic.leafMessage`.

  The flags level's icon is `systemImage: "flag.fill"` when enabled or `"flag"`
  when disabled. `FeatureFlagsTopic.removalMessage` and
  `ServerBagsTopic.removalMessage` are the two distinct removal-message constants
  (**bags-removal-message-distinct-from-flags**). The wrapped JSON value type is
  `JSONValue` (`Support/JSONValue.swift`); its `.int`/`.number` cases are the two
  representations **bags-json-equality-int-number** reconciles;
  `ServerBagsTopic.parsedValue(_:)` discards `JSONValue.parse`'s specific
  `DecodingError`-derived message in favor of the fixed
  `ServerBagsTopic.invalidJSONMessage`; the detail save writes through
  `ServerBagUpdate.value`.

  `StorageTokensRail.child(path:ecosystemID:levelID:title:)` is the shared
  parameterized resolution operation; `StorageTokensRail.createSpec` implements the
  three-way catch and the reveal-once write via `MainActor.run`;
  `StorageTokensRail.aboutText(ecosystemID:)` returns `aboutWithoutEcosystem`/
  `aboutWithEcosystem`; the `name` field validates against `Slug.pattern` with
  `Slug.patternMessage`; `revealedSecrets`/`revealedOnScreen` are the rail's own
  `@MainActor`-isolated stored state, read and cleared by
  `expireRevealedSecret(unless:)`; the post-reveal notice text is
  `ApplicationsTopic.revealMessage`, declared in the sibling Applications module
  (see Design Decisions); date fields format through `HubDates.display`.

  The test suite (`EcosystemConfigTopicsTests.swift`) exercises every Apple topic
  against fakes with concrete assertions for each requirement above.
- **React / Web**: this is the other source platform. `feature-flags.ts`,
  `server-bags.ts`, `client-auth.ts`, `storage-tokens.ts`, and `wire.ts` under
  `packages/web/packages/data/src/ecosystem-config/` (plus shared helpers in
  `http.ts` and `client-helpers.ts`) are plain `fetch`-based clients with no JSX.
  `clientAuthApi` reads and `POST`s the ecosystem's and each application's
  client-auth settings, sending a `compact`ed body that drops undefined keys but
  keeps an explicit `registration: null`; `ecosystemFeatureFlagsApi.update`/`delete`
  embed `key` in the URL path via `enc()` (`encodeURIComponent`), as do the
  equivalent path segments in `server-bags.ts` and `client-auth.ts`. `tokenPrincipalsApi.list`/`mint`/`revoke`
  accept a `TokenScope` (`ecosystemId`/`workspace`, serialized by `scopeQuery`)
  independently of `MintTokenPrincipalBody.ecosystemId`, a separate body field;
  `TokenPrincipalCreated` (the 201-only body carrying `token`) is a distinct type
  from `TokenPrincipal` (the list-row shape, carrying only `prefix`).
  `EcosystemServerBag.value`/`EcosystemServerBagCreate.value`/
  `EcosystemServerBagUpdate.value` are typed `unknown` in `server-bags.ts`. The UI
  panes and dialog-state modules that call these clients live in
  `packages/web/packages/features/ecosystem-config/src/` (`FeatureFlagsPane.tsx`,
  `ServerBagsPane.tsx`, `StorageTokensPanel.tsx`, `ApplicationClientAuthSection.tsx`,
  `bag-dialog-state.ts`, `flag-dialog-state.ts`); see Design Decisions for the
  validation-layering split observed there.
  `signup-list.ts` in the data folder is the sign-up list client (`signupListApi`,
  with `list`, `put` and `remove`). The sets client lives in the sibling
  `@adh-sdk/data/sets` module, and the roles client and the ecosystem subject
  directory in `@adh-sdk/data/access` and `@adh-sdk/teams`; this ingredient only
  consumes them. The login allow-list is now two parts. `ClientAuthFields.tsx` draws
  the "Who can sign in" section, a switch with a pointer to the Sign-up list pane;
  `client-auth-model.ts` holds `cleanEmailList`, `policyPatch`, `samePolicy`,
  `allowListTurnedOn`, `allowListDropped`, `signupEmailError`, `registrationError`
  and the not-saved message; and `ClientAuthSettingsPane.tsx` seeds the form from the
  saved policy. The emails are typed in `SignupListPane.tsx`, because the hub has no
  owner-scoped customer listing to pick from. The email shape check is a local
  regular expression in `client-auth-model.ts`, because no shared web package
  exports an email validator; the backend's zod check stays authoritative.
  `pane-caller.ts` declares `PaneCaller` (`manager` or `product_admin`); the
  sign-up list, roles and sets panes take it as `caller`, and `SetsPane.tsx` exports
  `setEntryFeaturesFor` (the catalog entries a caller may edit),
  `USAGE_TIER_LIMIT_KEY` and `STORAGE_QUOTA_LIMIT_KEY`, importing the quota ceiling
  `DEFAULT_QUOTA_BYTES` from `@adh-sdk/data/product-admin`. `ProductRolesPane.tsx`
  exports `isAdminRole`. The phase-6 `AdminSitePane` and `ProductTotalsPane` are in
  the product admin site recipe.
  The phase-5 panes are `SignupListPane.tsx`, `ProductRolesPane.tsx` (with
  `RoleHolders`), `SetsPane.tsx` (with `refusalText` and `valuesOfDraft`) and
  `BillingPane.tsx`, each taking `{ ecosystemId, title, help }` so a host renders
  them through one signature; `EcosystemConfigGate.tsx` sits above them when the
  host holds a workspace rather than an ecosystem id. `SignupListPane`,
  `ProductRolesPane` and `SetsPane` read with `useResourceList` and guard writes
  with a single-flight flag; the sync-tables editor uses react-query hooks instead.
  The sync-tables topic is web-only. `sync-tables.ts` in the same data folder is
  the client (`syncTablesApi(family)`, `schemaOf`). `SyncTablesPane.tsx` in the
  features package holds `SyncTablesEditor` (the list and its progress modal, no
  chrome, `family` defaulting to `"ecosystem"`) and `SyncTablesPane` (the hub's
  `DetailsPane` around it); the hooks are in `sync-tables-hooks.ts`, keyed by
  family and ecosystem. Bulk actions run through `useBatchRun` from
  `@adh-sdk/data/query`. The admin console's `SyncPane` adds a picker over every
  ecosystem and mounts `SyncTablesEditor` with `family="admin"`, keyed on the
  ecosystem id; the hub's `[workspace]/sync` page mounts `SyncTablesPane`. Apple,
  Android and Windows have no sync-tables editor; it is planned.
- **Compose**: model each Apple protocol as a Kotlin `interface` with `suspend
  fun`s (e.g. `interface FeatureFlagsDataSource { suspend fun list(ecosystemId:
  String): List<FeatureFlag> }`); represent the shared token rail's revealed-secrets
  store as a `MutableStateFlow<Map<String, String>>` so Compose recomposition
  observes the reveal-once transition; model the wrapped JSON value type with
  `kotlinx.serialization.json.JsonElement`, noting the same integral-`Double`-vs-`Long`
  equality pitfall **bags-json-equality-int-number** documents applies to
  `JsonPrimitive` unless normalized the same way. Model the sync-tables client as a
  Kotlin `interface` with `suspend fun`s that return the refreshed catalog, the
  sign-up list as a `List<SignupListEntry>` of a lowercase email with an optional
  role id and set id, and the policy's allow-list as a switch, `null` meaning every
  customer and a non-null list meaning only the listed people.
- **WinUI 3**: model each data-source interface as a C# interface returning
  `Task<T>` (e.g. `Task<IReadOnlyList<FeatureFlag>> ListAsync(string
  ecosystemId)`) backed by `HttpClient` and `System.Text.Json` for
  (de)serialization, mirroring the `async`/`await` shape of Swift's `async throws`
  and TypeScript's `Promise`; back a level's item list with an
  `ObservableCollection<T>` (or a view-model implementing `INotifyPropertyChanged`)
  for a WinUI 3 `ListView`/`ItemsView`. For the shared token rail's reveal-once
  secret, keep the equivalent of `revealedSecrets` as a plain in-memory field on the
  view-model - deliberately never written to `Windows.Storage.ApplicationData` or
  any DPAPI-backed store - so the "shown once" contract this component enforces is
  preserved rather than accidentally persisted. Model the sync-tables client as a
  C# interface with one `Task`-returning method per operation, the sign-up list as
  a view-model over an `ObservableCollection<SignupListEntry>` (lowercase email,
  nullable role id and set id) with add and remove commands, and the sets editor as
  a view-model that builds one `CheckBox` per permission and one `NumberBox` or
  `TextBox` per limit from the catalog's entries, so no feature is named in the
  view.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/EcosystemConfig/` | confirmed (2.2.0) |
| web | `packages/web/packages/data/src/ecosystem-config/` | confirmed (2.3.0) |
| web | `packages/web/packages/features/ecosystem-config/src/` | confirmed (2.3.0) |
| web | `packages/web/packages/data/src/ecosystem-config/sync-tables.ts` | confirmed (2.3.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/EcosystemConfig/AuthSettingsTopic.swift` | confirmed (2.2.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/EcosystemConfig/EcosystemConfigModels.swift` | confirmed (2.2.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/EcosystemConfig/FeatureFlagsTopic.swift` | confirmed (2.2.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/EcosystemConfig/ServerBagsTopic.swift` | confirmed (2.2.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/EcosystemConfig/SigninAppsTopic.swift` | confirmed (2.2.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/EcosystemConfig/StorageTokensRail.swift` | confirmed (2.2.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/EcosystemConfig/StorageTokensTopic.swift` | confirmed (2.2.0) |
| web | `packages/web/packages/data/src/ecosystem-config/feature-flags.ts` | confirmed (2.3.0) |
| web | `packages/web/packages/data/src/ecosystem-config/server-bags.ts` | confirmed (2.3.0) |
| web | `packages/web/packages/data/src/ecosystem-config/client-auth.ts` | confirmed (2.3.0) |
| web | `packages/web/packages/data/src/ecosystem-config/storage-tokens.ts` | confirmed (2.3.0) |
| web | `packages/web/packages/data/src/ecosystem-config/wire.ts` | confirmed (2.3.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKHubTests/EcosystemConfigTopicsTests.swift` | confirmed (2.2.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/Ecosystems/EcosystemTopic.swift` | confirmed (2.2.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/Ecosystems/EcosystemsModels.swift` | confirmed (2.2.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/Support/Slug.swift` | confirmed (2.2.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/Support/HubDates.swift` | confirmed (2.2.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/Support/HubText.swift` | confirmed (2.2.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/Support/JSONValue.swift` | confirmed (2.2.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Hub/Features/Applications/ApplicationsTopic.swift` | confirmed (2.2.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/project.yml` | confirmed (2.2.0) |
| web | `packages/web/packages/features/ecosystem-config/src/dialog-state/bag-dialog-state.ts` | confirmed (2.3.0) |
| web | `packages/web/packages/features/ecosystem-config/src/dialog-state/flag-dialog-state.ts` | confirmed (2.3.0) |
| web | `packages/web/packages/features/ecosystem-config/src/ApplicationClientAuthSection.tsx` | confirmed (2.3.0) |
| web | `packages/web/packages/features/ecosystem-config/src/SyncTablesPane.tsx` | confirmed (2.3.0) |
| web | `packages/web/packages/features/ecosystem-config/src/sync-tables-hooks.ts` | confirmed (2.3.0) |
| web | `packages/web/packages/features/ecosystem-config/src/ClientAuthFields.tsx` | confirmed (2.3.0) |
| web | `packages/web/packages/features/ecosystem-config/src/client-auth-model.ts` | confirmed (2.3.0) |
| web | `packages/web/packages/features/ecosystem-config/src/ClientAuthSettingsPane.tsx` | confirmed (2.3.0) |

## Design Decisions

**Decision**: the server-bags delete confirmation's removal message ("will be deleted. Anything reading it gets nothing <em dash> there is no default.") is declared independently rather than reusing the feature-flags delete confirmation's message ("will be removed. Anything reading it falls back to its default."), even though both are one-line "what deleting this costs" strings for a very similar delete-confirmation UI.
**Rationale**: the source's own comment states the reason directly: server bags have no defaults to fall back to, unlike feature flags - deleting one leaves readers with nothing at all. Borrowing the flags' message promised a fallback that does not exist, in the one dialog whose job is to say what deleting costs. Sharing the string would have made the confirmation dialog lie about what actually happens.
**Approved**: pending

**Decision**: the storage-tokens create form's save action uses a three-way catch (a conflict error → friendly message; any other shared error kind → rethrown as-is; anything else → a generic unexpected error) instead of the shared error-wrapping convention every other create/update/delete call in this component uses.
**Rationale**: the conflict case needs its own friendly text rather than whatever detail the backend's conflict response carries, and the source chooses to discard a non-shared-error-kind failure's own message in favor of a generic one rather than risk surfacing raw transport detail from a mint request specifically. This is documented here as an observed, intentional divergence rather than corrected to match the shared error-wrapping convention. It applies to the Swift implementation only; the alternate client has no equivalent create-error taxonomy to diverge from.
**Approved**: pending

**Decision**: the storage-tokens detail sources its post-reveal notice text from a constant declared in a sibling Applications module (Applications' own token-reveal notice), rather than declaring its own copy.
**Rationale**: the source's own comment states this directly - the reveal-once behavior exists specifically because that sibling constant's promise ("you won't be able to see it again") must actually hold; the same lifecycle and constant are documented as canonical in the sibling recipe [adhsdk.ingredient.adh.hub.security.authentication-client](cookbook:65fbb2b1-ca41-499f-ac03-7ecc0e206dcc), which this ingredient treats as the complete reference for that shared behavior rather than re-deriving it here. The coupling means a future rename of that constant would need to be tracked across both modules with no compiler-enforced link beyond the direct reference. This is a cross-module source-file coupling specific to the Swift codebase's module layout.
**Approved**: pending

**Decision**: JSON-shape validation for a server bag's value lives inside the value-parsing step on the Swift implementation, combining transport-adjacent orchestration with domain validation in one type; on the web implementation, the equivalent validation is not in the given data client at all - it lives in a sibling `features/ecosystem-config` package's dialog-state module.
**Rationale**: the two platforms split responsibilities differently: the Swift topic types are the single place that both talk to the data source and build the declarative form, so validation naturally lives there too; the web implementation keeps its data-client layer free of any dependency on UI-adjacent validation state, pushing that concern into the package that owns the dialog. Both are internally consistent with their own layering; this ingredient documents the divergence rather than treating either as a gap. It applies differently to each of the two reference implementations, by design.
**Approved**: pending

**Decision**: on the web implementation, origin-format validation for a sign-in app's `allowedReturnOrigins` (mirroring the Swift implementation's origin-validation/canonicalization steps) is not present in the given data client - it lives in a UI-pane file's own validation helpers, outside this component's given sources.
**Rationale**: this follows the same data-client/features-package split as the server-bag JSON validation above, and was confirmed by reading the actual caller rather than assumed, per this ingredient's requirement to resolve an apparent gap against the real codebase before marking it unresolved. It applies to the web implementation.
**Approved**: pending

**Decision**: feature-flag keys SHOULD be restricted so they cannot contain the composite id's `:` delimiter, either by the slug-pattern restriction already applied to the sign-in-app `clientId` field and the storage-token `name` field or by escaping the key inside the composite id. Neither is implemented yet.
**Rationale**: the key is embedded unescaped in a colon-delimited composite id, so a colon in a key could collide with another item's id; a validating pattern on the key field, or confirmation from the composite-id format's other consumers that a reserved character cannot collide, would close the gap.
**Approved**: pending

**Decision**: one sync-tables pane, in this package, serves both the admin
console and the hub's `[workspace]/sync` page; the route family is a prop.
**Rationale**: the two surfaces differ only in who may call the backend, and the
backend already shares one handler set between its two route families. A second
pane would be two copies of the same list that nothing keeps in step. This package
is the lowest tier that holds an ecosystem's configuration panes, and the admin
console already sits above it. The owner approved this in the Temporal plan on 2026-11-13.
**Approved**: yes

**Decision**: the login allow-list's emails are owned by the sign-up list, and the client-auth form carries only the "Only listed people" switch, sending the list's emails only when the switch turns on and `null` when it turns off.
**Rationale**: each sign-up entry carries a role and a set as well as an address, and the backend keeps the entries equal to whatever list is written. A second editor for the same emails inside the form could erase entries or disagree with the list, so one list is edited in one place and the form's dirty check compares the switch alone.
**Approved**: pending

**Decision**: the product roles pane mounts the Teams roles editor on the ecosystem target and adds only the per-role holder list through the editor's footer seam, rather than a roles editor of its own.
**Rationale**: a product's roles and a workspace's are the same kind of thing, and one editor means they cannot drift. What a workspace has and a product does not is the holder list, so that is the only piece written here, and it offers only the realm's product users.
**Approved**: pending

**Decision**: the gate resolves the workspace's default ecosystem once, above the panes, and each pane reads a missing `ecosystemId` as "No product selected." rather than doing its own resolution.
**Rationale**: a pane that rendered after a failed resolution would show an empty ecosystem as if it were a real answer, and a plain org member would discover the same refusal separately in every pane. Resolving once, and explaining once, keeps the wording and the failure handling in one place.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | partial | Security |

`separation-of-concerns` is partial: transport is cleanly isolated behind five single-purpose protocols (`AuthSettingsDataSource`, `SigninAppsDataSource`, `FeatureFlagsDataSource`, `ServerBagsDataSource`, `StorageTokensDataSource`), and none of the Swift topic files import a UI-rendering framework - but each Topic still combines data-source orchestration, domain validation (origin/JSON/duplicate-key checks), and declarative `FormSpec`/`HTDVLevel` construction with hardcoded user-facing strings in one type; this follows from the HTDV framework's declarative-model design rather than a UI-rendering leak, but it is still multiple responsibilities sharing one file. `unit-test-coverage` is partial: `EcosystemConfigTopicsTests.swift` exercises every Apple sub-component with fakes and concrete assertions, and the web side is covered unevenly. The data clients are covered by `sync-tables.test.ts`, `signup-list.test.ts`, `client-auth.test.ts`, `feature-flags.test.ts` and `storage-tokens.test.ts`, and the sync-tables hooks by `sync-tables-hooks.test.tsx`. The panes, models and dialog state are covered by `client-auth-model.test.ts`, `ClientAuthSettingsPane.test.tsx`, `ApplicationClientAuthSection.test.tsx`, `BagDialog.test.tsx`, `FlagDialog.test.tsx`, `flag-dialog-state.test.ts`, `bag-dialog-state.test.ts`, `StorageTokensPanel.test.tsx`, `SyncTablesPane.test.tsx`, `SignupListPane.test.tsx`, `ProductRolesPane.test.tsx`, `SetsPane.test.tsx` and `EcosystemConfigGate.test.tsx`; vectors 031, 032 and 037 are named by id in `client-auth-model.test.ts` (037 also in `ClientAuthSettingsPane.test.tsx`), and 021, 023-030, 033-036 and 038 in the data-client, hook and pane tests. Still unproven by unit tests, hence partial: vectors 001-020 are Apple-only and are skipped as placeholders on the web side (the Swift suite covers them), vectors 039-048 are named in no test, 022 names a web sign-in-app create client that does not exist, and `server-bags.ts`, `wire.ts`, `FeatureFlagsPane.tsx`, `ServerBagsPane.tsx` and `BillingPane.tsx` have no adjacent test. `explicit-error-handling` passes: every Apple call site wraps its data-source call in `HubError.wrap` or an explicit `catch` (including `StorageTokensRail`'s three-way catch, which is still explicit, never silent), and every web call either lets `authedJson`'s thrown rejection propagate or maps it through `rethrowConflict`; no given source catches and discards an error. `input-sanitization` is partial: `SigninAppsTopic.validateOrigin`/`canonicalOrigin`, `ServerBagsTopic.parsedValue`, and the `Slug.pattern`-constrained `clientId`/token-`name` fields validate before any network call on Apple, but the parallel web data clients (`client-auth.ts`, `server-bags.ts`) forward `allowedReturnOrigins`/`value` with no validation of their own (that validation lives in the features package: `registrationError` and `signupEmailError` in `client-auth-model.ts`, and `bag-dialog-state.ts` - see Design Decisions), and neither platform restricts a feature-flag key's character set at all (see the `flags-key-charset-unrestricted` requirement). `secure-storage` is partial: the one genuinely sensitive value, the storage-token secret, is deliberately never written to the Keychain, `UserDefaults`, or any persistent store by this component - it lives only in `StorageTokensRail.revealedSecrets`'s in-memory dictionary and is dropped on navigation-away or revoke - which avoids insecure persistence entirely rather than routing through a platform secure-storage API, so the check's literal Keychain/DPAPI expectation does not apply the way it would to a persisted credential.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 2.3.0 | 2026-11-23 | Mike Fullerton | Phase 7: consented support access |
| 2.2.0 | 2026-11-23 | Mike Fullerton | Phase 6: a pane caller for the sign-up list, roles and sets panes; admin seats protected, usage tier hidden, storage quota capped for a product admin |
| 2.1.0 | 2026-11-22 | Mike Fullerton | Phase 5: sign-up list, product roles, sets, billing placeholder and workspace gate panes; the login allow-list is now a switch whose emails live in the sign-up list; client-auth updates are POSTs; passwordEnabled |
| 2.0.0 | 2026-11-15 | Mike Fullerton | Login allow-list by email (loginAllowedEmails, login_allowed_emails): the client-auth pane's Who can sign in editor, lowercased on save, with email-shape, 254-character and 500-entry bounds |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Design Decisions keep the Decision / Rationale / Approved triple; each decision's platform line is folded into its rationale. |
| 1.2.0 | 2026-10-04 | Mike Fullerton | Resolve open-question markers against the code; restate unimplemented behavior as current behavior with pending Decisions. |
| 1.1.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to adh/hub/ecosystems/. |
| 1.0.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.0.0 | 2026-09-24 | Mike Fullerton | Initial creation |
