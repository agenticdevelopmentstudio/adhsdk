
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

