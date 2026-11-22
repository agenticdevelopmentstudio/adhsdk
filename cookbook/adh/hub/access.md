---
id: 39a7192e-7e1e-4e93-b615-312a5ddf69b0
title: "Hub Domain Access Client"
type: ingredient
version: 1.3.0
status: review
language: en
created: 2026-09-24
modified: 2026-11-22
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Client for the roles and permissions access API: feature areas, subjects, role CRUD, assignments, item restriction and effective access, for a workspace or ecosystem target."
platforms:
  - typescript
  - web
tags:
  - access-control
  - permissions
  - roles
  - workspace
  - ecosystem
  - api
depends-on: []
related: []
references:
  - packages/web/packages/data/src/access/access.ts (adhsdk)
  - packages/web/packages/data/src/access/wire.ts (adhsdk)
  - packages/web/packages/data/src/access/index.ts (adhsdk)
  - packages/web/packages/data/src/access/__tests__/access.test.ts (adhsdk)
  - packages/web/packages/data/src/access/__tests__/access-target.test.ts (adhsdk)
  - packages/web/packages/data/src/http.ts (adhsdk)
  - packages/web/packages/data/src/client-helpers.ts (adhsdk)
  - packages/web/packages/auth/src/client.ts (adhsdk)
  - packages/web/packages/auth/src/v1.ts (adhsdk)
approved-by: ""
approved-date: ""
---

# Hub Domain Access Client

## Overview

This is the client for the gated roles and permissions surface at `/api/v1/access`. It covers
feature areas, the people an ecosystem's roles can be granted to, role CRUD, role assignments,
item restriction and an effective-permission explainer. Every call names its **target**: a
workspace by slug (a personal workspace's customer slug or an org slug), or an owner-made
ecosystem by id, whose roles are its product users' roles. A bare string is a workspace slug,
which is what every caller passed before ecosystems had roles. The module's own comment states
the server-side rules: reads answer 404 to non-members, role definition is admin-only, and
assignments and restriction need the manage verb (`M`) at the target scope, with the server
enforcing no-escalation. The client holds none of those rules. It exports a target type and two
target helpers, a set of camelCase row shapes mapped from snake_case wire shapes, a fallback
feature list, two write input shapes, and the `accessApi` object with twelve operations, each a
thin request builder over the shared authenticated-request helpers. It is a headless **logic**
module with no visual surface, so Appearance, States and Accessibility are not applicable and
the runtime contract is carried by Behavioral Requirements.

## Behavioral Requirements

**Targets**

- **target-one-query-parameter**: Every operation MUST name its target with exactly one query
  parameter, `workspace` carrying a workspace slug or `ecosystem` carrying an ecosystem id,
  and MUST NOT send both.
- **target-bare-string-is-workspace**: A target passed as a bare string MUST be treated as a
  workspace slug and sent as `workspace`.
- **target-ecosystem-checked-first**: When an object target carries an `ecosystem` key,
  `accessTargetQuery` MUST return only `{ ecosystem }`; otherwise it MUST return only
  `{ workspace }`. The `AccessTarget` type admits exactly one of the two keys, so the
  precedence is observable only for an object that bypasses the type.
- **target-key-prefix**: `accessTargetKey` MUST return `workspace:<slug>` for a workspace
  target or bare string, `ecosystem:<id>` for an ecosystem target, and the bare prefix
  `workspace:` when the target is `undefined`. The workspace form is kept so panes that share
  an entry (the roles list) keep sharing it.
- **target-values-encoded**: The target value MUST be placed in the query string through the
  shared query builder, so a slug such as `a b/c` decodes back to itself on the server.

**Feature areas**

- **feature-list-request**: `listFeatures` MUST send a GET to `/api/v1/access/features` with
  the target parameter and `limit=100`.
- **feature-list-unwraps-envelope**: `listFeatures` MUST return the bare array taken from the
  `data` member of the list envelope, not the envelope.
- **feature-row-shape-validated**: `listFeatures` MUST throw a plain `Error` with the message
  `GET /v1/access/features returned a malformed feature list` when `data` is not an array, when
  any element is not an object with a non-empty string `key` and a non-empty string `label`, or
  when the envelope's `has_more` is exactly `true`.
- **feature-has-more-rejected**: `listFeatures` MUST fetch one page only; a response whose
  `has_more` is `true` MUST be rejected with the same malformed-list error rather than paged
  or truncated.
- **feature-rows-projected**: `listFeatures` MUST return each row as `{ key, label }` and MUST
  drop any other member the backend sent.
- **feature-order-preserved**: `listFeatures` MUST return rows in the order the backend sent
  them, with no client-side sort.
- **feature-validation-error-has-no-status**: The malformed-list error MUST carry no numeric
  `status`, so `httpStatus` returns `undefined` for it, distinguishing a malformed body from an
  HTTP failure.
- **fallback-features-fixed-set**: `ACCESS_FEATURES` MUST be exactly the ordered two-entry list
  `[{ key: "projects", label: "Projects" }, { key: "personas", label: "Personas" }]`. The
  source's comment says it MUST NOT be widened, because it is the intersection every product on
  this toolkit is known to enforce.
- **fallback-features-not-invoked-automatically**: `listFeatures` MUST NOT substitute
  `ACCESS_FEATURES` on any failure. The list is exported for a caller's own catch block; the
  source's comment says a backend with no such route (404) is the expected case for that
  fallback.

**Subjects**

- **subject-list-request**: `listSubjects` MUST send a GET to `/api/v1/access/subjects` with
  the target parameter, adding `q` only when it is a non-empty string and `limit` only when it
  is given.
- **subject-list-single-page**: `listSubjects` MUST issue one request and return that page's
  rows; it MUST NOT follow `has_more` or send a cursor.
- **subject-row-projected**: `listSubjects` MUST return each row as `{ kind: "customer", id,
  label, email, slug }`, forcing `kind` to `"customer"` whatever the backend sent and
  replacing a missing `email` with `null`.
- **subject-list-missing-data-is-empty**: `listSubjects` MUST resolve to an empty array when
  the response has no `data` member.
- **subject-list-ecosystem-only-by-backend**: The source's comment says a workspace target has
  no subject list here and the backend answers 400. The client MUST NOT reject a workspace
  target itself; the backend's refusal surfaces as a thrown HTTP error.

**Roles**

- **role-list-pages-to-end**: `listRoles` MUST GET `/api/v1/access/roles` with the target
  parameter and walk the collection with the shared pager, `limit=100` per page and
  `starting_after` set to the last row's `id` while `has_more` is true, and return every row.
- **role-list-unvalidated**: `listRoles` MUST map each row without any shape check; a row that
  lacks `grants` fails with a `TypeError` from the mapping.
- **role-list-cursor-required**: When a page reports `has_more` but its last row has no `id`,
  the shared pager MUST throw a plain `Error` rather than return a truncated list.
- **role-row-mapping**: Every role returned by an operation MUST be mapped from `is_system`,
  `default_for` and `grants[].item_verbs` / `subitem_verbs` to `isSystem`, `defaultFor` and
  `grants[].itemVerbs` / `subitemVerbs`; `id`, `slug`, `name` and `description` pass through.
- **role-create-request**: `createRole` MUST POST to `/api/v1/access/roles` with the target
  parameter and a body of `slug`, `name` and `grants` (each grant as `feature`, `item_verbs`,
  `subitem_verbs`), and MUST return the created role mapped per `role-row-mapping`.
- **role-create-optional-fields-omitted**: `createRole` MUST include `description` and
  `default_for` in the body only when the input defines them.
- **role-update-request**: `updateRole` MUST POST (not PATCH) to `/api/v1/access/roles/<id>`
  with the target parameter, the id percent-encoded, and MUST return the updated role.
- **role-update-sends-defined-fields-only**: `updateRole` MUST include `name`, `description`,
  `default_for` and `grants` in the body only when the patch defines them, so an empty patch
  sends `{}`.
- **role-update-excludes-slug**: `updateRole` MUST NOT send `slug`, even when one is smuggled
  into the patch; the patch type is `Partial<Omit<AccessRoleInput, "slug">>`.
- **role-delete-request**: `deleteRole` MUST send a DELETE to `/api/v1/access/roles/<id>` with
  the target parameter and the id percent-encoded, and MUST resolve with no value, discarding
  any response body (an empty 204 is accepted).
- **role-empty-grants-passed**: `createRole` and `updateRole` MUST send `grants: []` unchanged
  when the caller supplies it.

**Assignments**

- **assignment-list-request**: `listAssignments` MUST GET `/api/v1/access/role_assignments`
  with the target parameter; when a scope is given it MUST add `feature` and `item_id`, and
  when it is not it MUST send neither.
- **assignment-list-scope-pair**: The scope argument of `listAssignments` MUST carry `feature`
  and `itemId` together; the type offers no way to pass one alone.
- **assignment-list-result**: `listAssignments` MUST return `{ assignments, restricted? }`,
  with each assignment mapped per `assignment-row-mapping` and `restricted` present only when
  the response carries it. The source's comment says `restricted` is present on item-scoped
  listings.
- **assignment-row-mapping**: Every assignment returned by an operation MUST be mapped to
  `id`, `subjectKind`, `subjectId`, `scopeFeature`, `scopeItemId` and `roleId`, and MUST add
  `roleSlug`, `roleName`, `grantedBy` and `grantedAt` only when the wire row defines them. A
  `granted_by` of `null` counts as defined and is kept.
- **assignment-put-request**: `putAssignment` MUST POST to `/api/v1/access/role_assignments`
  with the target parameter and a body of `subject_kind`, `subject_id` and `role_id`, adding
  `feature` and `item_id` only when the input defines them, and MUST return the assignment
  mapped per `assignment-row-mapping`. The source's comment says this grants or replaces, one
  role per subject per scope.
- **assignment-put-scope-passthrough**: `putAssignment` MUST send whatever combination of
  `feature` and `itemId` the caller passes. The field's comment says to provide them together
  to scope a grant to one item and to omit both for a workspace-wide grant; the client does not
  check the pairing.
- **assignment-delete-request**: `deleteAssignment` MUST send a DELETE to
  `/api/v1/access/role_assignments/<id>` with the target parameter and the id percent-encoded,
  and MUST resolve with no value.

**Item restriction**

- **item-restrict-request**: `restrictItem` MUST POST to `/api/v1/access/items/restrict` with
  the target parameter and a body of `{ feature, item_id }`.
- **item-restore-request**: `restoreItem` MUST POST to `/api/v1/access/items/restore` with the
  target parameter and a body of `{ feature, item_id }`.
- **item-restrict-restore-parse-body**: `restrictItem` and `restoreItem` MUST parse the
  response body and discard it, so each MUST throw the shared helper's error `Unexpected empty
  response (204 No Content); use authedRequest for endpoints with no body` when the backend
  answers 204, despite their `Promise<void>` return type.

**Effective access**

- **effective-request**: `effective` MUST GET `/api/v1/access/effective_permissions` with the
  target parameter and `feature`, `subject_kind` and `subject_id`, adding `item_id` only when
  `itemId` is a non-empty string.
- **effective-subject-kinds**: The `subjectKind` of an effective-access query MUST be
  `"customer"` or `"persona"`; unlike an assignment input, `"team"` is not accepted.
- **effective-response-mapping**: `effective` MUST return `{ itemVerbs, subitemVerbs,
  restricted, decidedBy }` mapped from `item_verbs`, `subitem_verbs`, `restricted` and
  `decided_by`, with `decidedBy` passed through unchanged. The wire shape documents its keys as
  a verb mapped to a provenance, with sub-item verbs keyed `sub:<verb>`.
- **restricted-flag-shared-meaning**: The `restricted` flag on an effective-access row and the
  optional `restricted` flag on an item-scoped assignment listing both describe whether the
  item was restricted; the listing's is present only for an item-scoped query, the effective
  row's is always present.

**Cross-cutting**

- **path-identifiers-encoded**: Every id placed in a URL path (role id, assignment id) MUST be
  percent-encoded.
- **one-request-per-call**: Every operation except `listRoles` MUST issue exactly one request;
  `listRoles` MUST issue one request per page.
- **no-client-side-cache**: The client MUST NOT cache or memoize any response. `accessTargetKey`
  only names a key for the caller's own cache.
- **stateless-module**: The client MUST hold no mutable state across calls; the only
  module-level value is the read-only `ACCESS_FEATURES`.
- **access-wire-camelcase-boundary**: Callers MUST see only camelCase row shapes; the
  snake_case wire shapes are an internal mapping and MUST NOT be returned by an operation,
  except `decidedBy`, which passes through as the backend sent it.

### Security

This is a security-relevant recipe: it is the client for a role and permission (authorization)
surface. It carries no secret of its own, because the bearer credential lives in the shared
authentication client that this module composes, and it performs no client-side authorization
check, deferring entirely to the backend.

- **auth-delegated-to-shared-client**: Every call MUST go through the shared authenticated
  request helpers, which attach a bearer credential read from the shared token store; this
  module MUST NOT read, store or attach a token itself.
- **session-refresh-waterfall**: A `401` response to any call MUST trigger one token refresh
  and, when the refresh yields a token, one retried request carrying it; a second `401` MUST
  propagate as a thrown HTTP error with `status: 401`. When the refresh yields no token the
  original `401` propagates with no retry. This is inherited from the shared authenticated
  fetch; the module defines no refresh or retry of its own.
- **errors-carry-status-and-code**: Any non-2xx response not recovered by the refresh retry
  MUST cause the call to throw an HTTP error carrying the response's status and, when the body
  supplies one, a machine-readable `code`, with the body's message as the error message (when
  the body has none, `HTTP <status>`, or `Server error (<status>)` for a 5xx).
- **authorization-enforced-server-side**: The client MUST NOT perform any client-side
  permission check before sending a request. Per the module's top comment, membership, the
  admin-only gate on role definition and the manage-verb requirement on assignment and
  restriction writes are enforced by the backend, which answers a non-member's read with `404`
  rather than `403`.
- **no-escalation-is-a-server-guarantee**: The module's comment says the server enforces
  no-escalation on assignment and restriction writes; this module contains no code that checks
  or blocks a self-escalating grant. The guarantee belongs to the backend.
- **token-lifetime-and-storage-external**: Token lifetime, storage and revocation are owned by
  the shared authentication client (`readAccessToken`, `refreshAccessToken`); this module
  specifies none of them and holds no credential beyond the duration of a call.

## Appearance

Not applicable: this is the roles and permissions data-access client, not a visual component.

## States

Not applicable: this is the roles and permissions data-access client, not a visual component;
any loading, error or empty visual state is owned by the presentation layer that consumes it.

## Accessibility

Not applicable: this is the roles and permissions data-access client, not a visual component.

## Conformance Test Vectors

Test names are in `access.test.ts` unless the file is given as `access-target.test.ts`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hub-domain-access-001 | feature-list-request, target-one-query-parameter | List feature areas for workspace `acme` | URL contains `/api/v1/access/features` and `workspace=acme`; test "hub-domain-access-001 GETs the workspace-scoped features route" |
| hub-domain-access-002 | target-values-encoded | List feature areas for workspace `a b/c` | The `workspace` parameter decodes back to `a b/c`; test "hub-domain-access-002 encodes a workspace slug that needs escaping" |
| hub-domain-access-003 | feature-list-unwraps-envelope | Body `{ object: "list", data: [{ key: "projects", label: "Projects" }], has_more: false }` | Resolves to `[{ key: "projects", label: "Projects" }]`; test "hub-domain-access-003 unwraps the list envelope to the bare array" |
| hub-domain-access-004 | feature-order-preserved | `data` rows in order `projects`, `personas`, `audiences` | Resolves in that order; test "hub-domain-access-004 preserves registration order across multiple rows" |
| hub-domain-access-005 | feature-row-shape-validated | Body `{ data: "abc" }` | Rejects; test "hub-domain-access-005 rejects when `data` is a string, not an array" |
| hub-domain-access-006 | feature-row-shape-validated | `data` of `[{ key: "", label: "Projects" }]` | Rejects; test "hub-domain-access-006 rejects a row whose `key` is the empty string" |
| hub-domain-access-007 | feature-row-shape-validated | Body `{}` | Rejects; test "hub-domain-access-007 rejects when the `data` key is absent entirely" |
| hub-domain-access-008 | fallback-features-fixed-set | Read `ACCESS_FEATURES` | Deep-equals the two-entry `projects`, `personas` list; test "hub-domain-access-008 the fallback feature list is the fixed two-entry set" |
| hub-domain-access-009 | fallback-features-not-invoked-automatically, feature-validation-error-has-no-status | Malformed features response | Rejects with `GET /v1/access/features returned a malformed feature list`, not the fallback; test "hub-domain-access-009 a malformed features response rejects; the fallback list is not substituted" |
| hub-domain-access-010 | role-list-pages-to-end, role-row-mapping | List roles for `acme`, one page holding a snake_case role | `GET /api/v1/access/roles?workspace=acme&limit=100`; resolves to the camelCase role; test "hub-domain-access-010 listRoles pages through /v1 and maps rows to camelCase" |
| hub-domain-access-011 | role-create-request, role-create-optional-fields-omitted | Create `{ slug: "editor", name: "Editor", grants: [] }` for `acme` | `POST /api/v1/access/roles?workspace=acme`, body without `description` or `default_for`; test "hub-domain-access-011 createRole POSTs the snake_case role body and maps the created role" |
| hub-domain-access-012 | role-update-excludes-slug, role-update-sends-defined-fields-only | Update with a patch that smuggles `slug` | Patch `{ name: "Renamed", slug: "hacked" }` sends body `{ name: "Renamed" }` with no `slug`; test "hub-domain-access-012 updateRole never sends a slug, even if one is smuggled into the patch" |
| hub-domain-access-013 | role-delete-request | Delete role `role-1` in `acme` | `DELETE /api/v1/access/roles/role-1?workspace=acme`, resolves to no value; test "hub-domain-access-013 deleteRole DELETEs the role and resolves with no value" |
| hub-domain-access-014 | assignment-list-request | List assignments for `acme`, no scope | `GET /api/v1/access/role_assignments?workspace=acme`, no `feature` or `item_id`; test "hub-domain-access-014 listAssignments with no scope sends only the workspace" |
| hub-domain-access-015 | assignment-list-request, assignment-list-result | List for `acme` scoped to `projects` and `p1`, body `restricted: true` | Request carries `feature=projects` and `item_id=p1`; resolves to `{ assignments: [], restricted: true }`; test "hub-domain-access-015 listAssignments with a scope adds feature and item_id, and passes `restricted` through" |
| hub-domain-access-016 | assignment-put-request, assignment-row-mapping | Put `{ subjectKind: "customer", subjectId: "c1", roleId: "r1" }` for `acme` | `POST /api/v1/access/role_assignments?workspace=acme`, body `{ subject_kind, subject_id, role_id }`; resolves to the camelCase assignment; test "hub-domain-access-016 putAssignment POSTs the snake_case assignment body and maps the result" |
| hub-domain-access-017 | assignment-delete-request | Delete assignment `a1` in `acme` | `DELETE /api/v1/access/role_assignments/a1?workspace=acme`, resolves to no value; test "hub-domain-access-017 deleteAssignment DELETEs the assignment and resolves with no value" |
| hub-domain-access-018 | item-restrict-request | Restrict `p1` in `projects` for `acme` | `POST /api/v1/access/items/restrict?workspace=acme`, body `{ feature: "projects", item_id: "p1" }`, resolves to no value; test "hub-domain-access-018 restrictItem POSTs feature and item_id to the restrict route" |
| hub-domain-access-019 | item-restrict-restore-parse-body, item-restore-request | Restrict or restore with a 204 response | Rejects with `Unexpected empty response (204 No Content); use authedRequest for endpoints with no body`; test "hub-domain-access-019 restrictItem and restoreItem throw on a 204 because they parse a JSON body" |
| hub-domain-access-020 | effective-request, effective-response-mapping | Effective query for `acme` with `projects`, `customer`, `c1`, no item | `GET /api/v1/access/effective_permissions` with no `item_id`; resolves to the camelCase row; test "hub-domain-access-020 effective omits item_id when no item is given" |
| hub-domain-access-021 | effective-request | Same query with item `p1` | Request carries `item_id=p1`; test "hub-domain-access-021 effective adds item_id when an item is given" |
| hub-domain-access-022 | session-refresh-waterfall, auth-delegated-to-shared-client | First response `401`, refresh returns a token | One retry with `Bearer fresh-token`; a second `401` rejects with `status: 401`, three fetches in all; test "hub-domain-access-022 a 401 refreshes once and retries with the new token; a second 401 throws status 401" |
| hub-domain-access-023 | errors-carry-status-and-code | `403` with `{ error: { message: "forbidden", code: "no_manage_verb" } }` | Rejects with `status: 403`, `code: "no_manage_verb"`, message `forbidden`; test "hub-domain-access-023 a 403 error carries its status and machine code" |
| hub-domain-access-024 | authorization-enforced-server-side, one-request-per-call | `404` to list roles, list assignments and effective access by a non-member | Each rejects with `status: 404`; three fetches in all; test "hub-domain-access-024 a 404 for a non-member rejects with status 404; the client sends one request per call" |
| hub-domain-access-025 | target-one-query-parameter, target-ecosystem-checked-first | Each of `listFeatures`, `listRoles`, `createRole`, `updateRole`, `deleteRole`, `listAssignments`, `putAssignment`, `deleteAssignment`, `listSubjects` with `{ ecosystem: "eco-1" }` | `ecosystem=eco-1` present, `workspace` absent; `access-target.test.ts` "sends ?ecosystem= for an ecosystem target, never ?workspace=" |
| hub-domain-access-026 | target-one-query-parameter | The same nine calls with `{ workspace: "acme" }` | `workspace=acme` present, `ecosystem` absent; `access-target.test.ts` "sends ?workspace= for a workspace target, never ?ecosystem=" |
| hub-domain-access-027 | target-bare-string-is-workspace | `listRoles("acme")` and `accessTargetQuery("acme")` | `workspace=acme` sent, query is `{ workspace: "acme" }`; `access-target.test.ts` "a bare string is a workspace slug" |
| hub-domain-access-028 | target-key-prefix | `accessTargetKey("acme")`, `accessTargetKey({ workspace: "acme" })`, `accessTargetKey({ ecosystem: "eco-1" })` | `workspace:acme`, `workspace:acme`, `ecosystem:eco-1`; `access-target.test.ts` "keys a workspace target as before and an ecosystem target apart" |
| hub-domain-access-029 | subject-list-request, subject-row-projected | `listSubjects({ ecosystem: "eco-1" }, { q: "ad" })`, one row `{ kind: "customer", id: "c1", label: "Ada", email: "ada@example.test", slug: "ada" }` | URL contains `/api/v1/access/subjects`, `q=ad`; resolves to that row; `access-target.test.ts` "listSubjects reads the realm's product users and passes the search" |
| hub-domain-access-030 | subject-list-request, subject-list-missing-data-is-empty | `listSubjects` against the empty stub list | Resolves to `[]` with no `q` or `limit` parameter; `access-target.test.ts` calls `listSubjects` under both targets |
| hub-domain-access-031 | feature-has-more-rejected | Features body `{ data: [valid row], has_more: true }` | Rejects with the malformed-list error; derived from `listFeatures` (no test beside it covers `has_more`) |
| hub-domain-access-032 | feature-rows-projected | Features row `{ key: "projects", label: "Projects", extra: 1 }` | Resolves to `[{ key: "projects", label: "Projects" }]`; derived from `listFeatures` (untested) |
| hub-domain-access-033 | subject-row-projected | Subject row with `email` absent and `kind: "persona"` | Resolves with `kind: "customer"` and `email: null`; derived from `listSubjects` (untested) |
| hub-domain-access-034 | role-list-cursor-required | Roles page with `has_more: true` whose last row has no `id` | Rejects with a plain `Error` naming the url; derived from `listAllV1` (untested here) |
| hub-domain-access-035 | effective-request | Effective query with `itemId: ""` | `item_id` absent from the query; derived from `effective` (untested) |

## Edge Cases

- **Empty target value**: The client does not check a target. An empty workspace slug is sent
  as `workspace=` and an empty ecosystem id as `ecosystem=`; a non-empty value is a caller
  precondition, and the backend answers any 400 (MUST NOT be checked client-side).
- **Both target keys on one object**: `accessTargetQuery` returns only `ecosystem`. The type
  forbids this input; the behavior is fixed by `target-ecosystem-checked-first` (MUST).
- **Undefined target in `accessTargetKey`**: Returns `workspace:` (MUST), so a cache key can be
  built before a target is known.
- **Empty feature list**: `listFeatures` resolves to `[]` for `data: []` (MUST); the test
  "resolves an EMPTY list to an empty array" asserts it.
- **Malformed feature rows**: A string, an array of bare strings, an object, a missing `key` or
  `label`, a wrong-typed `key`, an empty `key` or `label`, one empty row among good ones, and a
  `null` row each MUST reject the whole list; `access.test.ts` has a test for each except a row
  missing `key`, which `isAccessFeatureRow` rejects but no test covers.
- **More than one page of features**: A registry of more than 100 areas, reported by
  `has_more: true`, MUST be rejected rather than truncated.
- **Empty search term**: `listSubjects` with `q: ""` MUST omit `q`, because the builder gets
  `undefined`.
- **Empty `grants` array**: `createRole` and `updateRole` MUST send `grants: []` unchanged. The
  client never requires a grant.
- **Grant verb strings**: `itemVerbs` and `subitemVerbs` document a comma-letter subset of
  `C,R,U,D,M` and `C,R,U,D`. The client sends whatever string the caller gives with no charset
  or length check; the module's comment says the server refines every submitted grant. This is
  the contract, not a gap.
- **Empty patch**: `updateRole` with `{}` MUST send an empty JSON object.
- **Partial assignment scope**: `putAssignment` with `feature` but no `itemId`, or the reverse,
  MUST be sent as given; the doc comment states the pairing and the backend decides.
- **Boundary page size**: `listRoles` pages at 100 rows (`V1_PAGE_MAX`) and `listFeatures` asks
  for 100 in one page (MUST).
- **Concurrent access, module state**: The module holds no mutable state, so concurrent calls
  cannot race inside it.
- **Concurrent access, competing writes**: Two concurrent `putAssignment` calls for one subject
  and scope follow upsert semantics, the last response received winning, with no client-side
  sequencing or optimistic lock; the backend's ordering is outside this module.
- **Missing assignments member**: `listAssignments` maps `body.assignments` unchecked, so a
  body without it fails with a `TypeError` rather than a typed error.
- **204 on a declared-void write**: `restrictItem` and `restoreItem` MUST throw on a 204, see
  `item-restrict-restore-parse-body`.
- **Non-member read**: A `404` MUST reject with `status: 404`; the client sends one request and
  does no membership pre-check.
- **Offline or disconnected state**: No operation catches a network failure; it propagates to
  the caller with no retry, queue or offline handling (the one retry is the inherited `401`
  waterfall).
- **No timeout**: No call sets a deadline, so an unresponsive backend leaves the call pending
  until the transport's own limit.
- **No cancellation**: No operation accepts a cancellation signal.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `target` | string or `AccessTarget` | none, required on every call | A bare workspace slug, `{ workspace }` or `{ ecosystem }`; sent as the single `workspace` or `ecosystem` query parameter. |
| `opts` (listSubjects) | `{ q?, limit? }` | `{}` | `q` searches email, name or slug and is omitted when empty; `limit` is sent only when given. |
| `scope` (listAssignments) | `{ feature, itemId }` | omitted, workspace-wide listing | When given, narrows the listing to one item and adds `feature` and `item_id`. |
| `input` (createRole) | `AccessRoleInput` | none, required | `slug`, `name`, optional `description`, optional `defaultFor` (`""`, `"customer"` or `"persona"`), and `grants`. |
| `patch` (updateRole) | `Partial<Omit<AccessRoleInput, "slug">>` | none, required | Any subset of `name`, `description`, `defaultFor` and `grants`. |
| `input` (putAssignment) | `AccessAssignmentInput` | none, required | `subjectKind` (`customer`, `persona` or `team`), `subjectId`, optional `feature` and `itemId`, and `roleId`. |
| `q` (effective) | `{ feature, subjectKind, subjectId, itemId? }` | none, required | `subjectKind` is `customer` or `persona`; `itemId` is sent only when non-empty. |
| base route | constant `/api/v1/access` | fixed | Not injectable; every path is built from it. |
| page size | constant `100` | fixed | `listFeatures` sends `limit=100`; `listRoles` pages at `V1_PAGE_MAX`. |
| `ACCESS_FEATURES` | read-only list of `AccessFeatureRow` | the two-entry fallback | For a caller's catch block; never applied by this client. |

## Deep Linking

Not applicable: the module registers no URL scheme, route or navigation target; it is a data
client consumed by a presentation layer.

## Localization

The module authors two English strings of its own; every other message a caller sees comes
from the backend's response body.

| String Key | Default (en) | Context |
|-----------|---------------|---------|
| none | `GET /v1/access/features returned a malformed feature list` | Thrown by `listFeatures` when the response fails its shape or page check |
| none | `<url>: has_more is set but the last row carries no id to page from` | Thrown by the shared pager used by `listRoles` |

There is no catalog, key or i18n call in the module; both strings are hardcoded literals,
stated as fact rather than a gap.

## Accessibility Options

Not applicable: the module renders no UI and responds to none of Reduce Motion, Increase
Contrast or Differentiate Without Color.

## Feature Flags

Not applicable: the feature areas `listFeatures` and `ACCESS_FEATURES` name (`projects`,
`personas`) are a data-domain concept, not a feature-flag key, and the source contains no flag
or gating check.

## Analytics

Not applicable: the source contains no analytics or event-emission call.

## Privacy

- **Data collected**: None originated by the module. It reads and writes role, grant and
  assignment records saying which subjects (`customer`, `persona`, `team`) hold which roles at
  which scopes, and `listSubjects` returns each subject's `label`, `email` and `slug`.
- **Storage**: None. The client is a stateless per-call request builder, per
  `no-client-side-cache` and `stateless-module`.
- **Transmission**: Yes. Every call carries a bearer credential attached by the shared
  authentication client, and subject search text travels as the `q` query parameter.
- **Retention**: None. Nothing is held after a response is returned to the caller.

## Logging

Not applicable: the module contains no logging call of any kind.

## Platform Notes

- **SwiftUI**: Model the row shapes as `Codable, Hashable, Sendable` structs with
  `CodingKeys` mapping snake_case to camelCase, and the target as an enum with `workspace` and
  `ecosystem` cases. Expose `accessApi` as an `actor` or `@MainActor` class of `async throws`
  methods on `URLSession`, build query items with `URLComponents` so values are percent-encoded,
  and throw an error type carrying the HTTP status and optional code. Swift has no
  `JSON.stringify` omission of undefined, so omit optional fields with `encodeIfPresent`.
- **Compose**: Model the rows as `@Serializable` data classes with `@SerialName` for the
  snake_case members, the target as a sealed interface, and `accessApi` as a class of
  `suspend fun` methods on Ktor or OkHttp. Use `HttpUrl.Builder` or Ktor `parameters` for the
  query, and set `explicitNulls = false` so unset optional fields are omitted from bodies.
- **React/Web**: Source platform. `packages/web/packages/data/src/access/access.ts` holds
  `accessApi`, `accessTargetQuery`, `accessTargetKey`, `ACCESS_FEATURES` and the two input
  types; `wire.ts` holds the camelCase rows, the `*Wire` shapes and `AccessTarget`; `index.ts`
  re-exports both. The calls are built on `authedJson`, `authedRequest`, `listAllV1` and
  `withV1Query` (re-exported through `http.ts` from `@adh-sdk/auth/client`) and `enc`
  (`encodeURIComponent`) from `client-helpers.ts`. Optional body fields are omitted with
  conditional spreads, so an unset field never reaches the body. The refresh-on-401
  waterfall and `AuthHttpError` live in `auth/src/client.ts`.
- **AppKit / UIKit**: No UI dependency exists. A macOS or iOS feature consumes the ported
  client through an injected data-source protocol, so views never call `URLSession`, and keys
  its caches with the string `accessTargetKey` produces. Present the role matrix with
  `NSTableView` or `UITableView` and fall back to the fixed list on a failed features load.
- **WinUI 3**: Model rows as C# `record`s read with `System.Text.Json` and
  `JsonPropertyName("is_system")`-style attributes, set `JsonIgnoreCondition.WhenWritingNull` to
  mirror the omitted optional fields, and model the target as a discriminated record pair.
  Implement `AccessApi` as a class of `Task<T>` methods on one shared `HttpClient`, with a
  `DelegatingHandler` attaching `Authorization: Bearer <token>` and doing the one refresh and
  one retry on a `401`. Build query strings with `Uri.EscapeDataString` or
  `HttpUtility.ParseQueryString`, throw an `AccessApiException` (`HttpStatusCode`, `Code`)
  parallel to `AuthHttpError`, page roles with a loop on `has_more` and `starting_after`, and
  read a 204 as `HttpStatusCode.NoContent` to keep the restrict and restore behavior. Bind
  the matrix to an `ObservableCollection<AccessRoleRow>` in an `ItemsRepeater` or `ListView`,
  with `INotifyPropertyChanged` on the view model, not on this client.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/data/src/access/` | confirmed (1.3.0) |

## Design Decisions

**Decision**: `ACCESS_FEATURES` is exported but `listFeatures` never consults it.
**Rationale**: The source's comment frames it as a degraded path for a backend that predates
the features route and warns that the authoritative registry is per-deployment. Keeping
`listFeatures` strict leaves the fallback decision to the caller and stops a real
response mismatch from looking like an old backend.
**Approved**: pending

**Decision**: `restrictItem` and `restoreItem` use `authedJson` although they are declared
`Promise<void>`, so a 204 throws.
**Rationale**: Recorded as observed behavior, not smoothed into the declared type. A port
preserves it rather than switching to `authedRequest`, because the backend's actual response
for these routes is outside this checkout.
**Approved**: pending

**Decision**: Only `listFeatures` validates its response at runtime; `listRoles`,
`listAssignments`, `listSubjects` and `effective` rely on the typed cast or a plain mapping.
**Rationale**: The `isAccessFeatureRow` comment explains the guard was added after a bare
cast let a malformed features response look like real data. No equivalent fix exists for the
other reads, so the asymmetry is recorded as fact.
**Approved**: pending

**Decision**: `listFeatures` rejects `has_more: true` instead of paging.
**Rationale**: It asks for the widest page (100) and treats a longer registry as malformed, so
the roles matrix never renders a silently truncated set of columns.
**Approved**: pending

**Decision**: `putAssignment` does not check that `feature` and `itemId` are given together.
**Rationale**: The field's comment states the pairing and the client leaves enforcement to the
backend, whose handling of a half-scoped write is outside this checkout. A client guard or a
discriminated input type would close the gap.
**Approved**: pending

**Decision**: `accessTargetKey` keeps the `workspace:<slug>` prefix for workspace targets.
**Rationale**: The source's comment says panes that share an entry, such as the roles list,
must keep sharing it after ecosystem targets were added.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.security.server-side-authorization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90e085e3-5112-5c02-9c10-4a2e324eeca1) | passed | Security |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | partial | Access Patterns |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | partial | Reliability |

`separation-of-concerns` passes: `access.ts` and `wire.ts` hold no UI code, and `index.ts` is
the public surface of a data domain consumed by a separate presentation layer.
`unit-test-coverage` is partial: `access.test.ts` and `access-target.test.ts` exercise every
operation, the fallback list, the refresh retry and the status and code carry-through, but
nothing asserts the `has_more` rejection in `listFeatures`, the row projection of
`listFeatures` and `listSubjects`, the multi-page walk of `listRoles`, or the empty-string
`itemId` omission in `effective`; vectors 031 to 035 are derived from the source for those.
`explicit-error-handling` passes: nothing in the module swallows an error, and every failure
throws either the shared HTTP error or a plain `Error` the module or its pager raises.
`server-side-authorization` passes: the module performs no client-side permission check and
defers membership, the admin-only role edit and the manage-verb rule to the backend.
`error-response-handling` is partial: every call exposes a status and optional code, but only
the `listFeatures` comment documents a per-status contract (a 404 meaning the backend predates
the route), the fallback is the caller's, and no other operation offers per-code handling.
`graceful-degradation` is partial: `ACCESS_FEATURES` is a documented escape hatch, but
degradation is opt-in by the caller and no other operation offers a fallback.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.3.0 | 2026-11-22 | Mike Fullerton | Ecosystem targets, listSubjects, paged listRoles, /v1 features page check; vectors 025 to 035 added |
| 1.2.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (access.test.ts, 24 of 24 vectors); unit-test-coverage now passed. Vector text rewritten to match the real /api/v1 routes and snake_case wire shapes. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Design Decisions keep the Decision / Rationale / Approved triple; each decision's platform line is folded into its rationale. |
| 1.2.0 | 2026-10-04 | Mike Fullerton | Resolve open-question markers against the code; restate unimplemented behavior as current behavior with pending Decisions. |
| 1.1.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to adh/hub/. |
| 1.0.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.0.0 | 2026-09-24 | Mike Fullerton | Initial creation |
