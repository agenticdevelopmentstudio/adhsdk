
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

