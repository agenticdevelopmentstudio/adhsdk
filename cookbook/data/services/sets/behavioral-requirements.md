
### Wire rows and mapping

- **set-row-mapping**: `toSet` MUST map a `SetWire` to a `SetRow` with `id`, `slug`, `name`, `contains` and `values` copied as is, `isDefault` from `is_default`, `isPersonal` from `is_personal`, and `personalCustomerId` from `personal_customer_id`.
- **set-row-defaults**: `toSet` MUST read an absent or null `description` as `""`, an absent `personal_customer_id` as `null`, an absent `contains` as `[]` and an absent `values` as `[]`.
- **grant-row-mapping**: `toSetGrant` MUST map a `SetGrantWire` to a `SetGrantRow` with `ecosystemId` from `ecosystem_id`, `customerId` from `owner_id`, `setId` from `set_id`, `grantedBy` from `granted_by`, `grantedAt` from `granted_at`, and `id` and `source` unchanged.
- **grant-row-defaults**: `toSetGrant` MUST read an absent `billing_account_id`, `revoked_at` or `revoke_reason` as `null`.
- **grant-timestamps-verbatim**: `toSetGrant` MUST pass `granted_at` and `revoked_at` through as the strings received, with no conversion.
- **value-passthrough**: `toSet` MUST NOT validate or convert a `SetValue`; `kind`, `key` and `value` (typed `unknown`) reach the caller as received, and limit keys such as `usage.tier` are never re-cased.

### The sets answer

- **answer-absent**: `toSetsAnswer` MUST return `null` when given `null` or `undefined` (an older backend, or a realm where sets do not apply).
- **answer-unresolved**: `toSetsAnswer` MUST return exactly `{ error: "unresolved" }` when the wire value's `error` is `"unresolved"`, discarding every other field.
- **answer-effective**: `toSetsAnswer` MUST otherwise return an `EffectiveSets` with `held`, `permissions` and `readOnly` (from `read_only`) defaulting to `[]` and `limits` defaulting to `{}`.
- **answer-valid-until**: `toSetsAnswer` MUST include `validUntil` only when the wire `valid_until` is not `undefined`, and MUST keep a `null` value as `null`; when the key is absent the result has no `validUntil` key.
- **answer-guard**: `isEffectiveSets` MUST return `false` for `null` and for any value that has an `error` key, and `true` otherwise.

### Catalog set entries

- **entries-absent**: `toSetEntries` MUST return `undefined` when given `undefined`, or when the wire value has no `permission` and no non-empty `limits`.
- **entries-shape**: `toSetEntries` MUST otherwise return a `SetEntries` that has `permission: true` only when the wire `permission` is truthy and a `limits` array only when the wire `limits` is non-empty.
- **entries-limits-copied**: `toSetEntries` MUST copy each limit entry (`key`, `type`, `label`) into a new object rather than reuse the wire object.
- **entry-features**: `setEntryFeatures` MUST return one `{ key, label, setEntries }` per catalog feature whose `setEntries` is set, in catalog order, and MUST drop every other feature.

### Refusals

- **refusal-detect**: `asSetRefusedError` MUST return a `SetRefusedError` when the thrown value's HTTP status is 422, `body.error.code` is `"set_refused"` and `body.error.rule` is a number, and MUST return `null` in every other case.
- **refusal-duck-typed**: `asSetRefusedError` MUST read the status through `httpStatus` and the body through a `.body` property, never through `instanceof` on one error class, so a host's own auth error class is read the same; a non-`Error` value with a `status` property yields `null`.
- **refusal-fields**: The `SetRefusal` built by `asSetRefusedError` MUST carry `rule` (the number as received, cast to the rule union without range checking), `message` (the body's `error.message` when it is a string, else the thrown error's own message), and MUST add `limits` only when `error.limits` is an array, `containers` only when `error.containers` is an array and `customers` only when `error.customers` is a number.
- **refusal-error-class**: `SetRefusedError` MUST extend `Error`, MUST set its `name` to `"SetRefusedError"`, MUST use `refusal.message` as its `message`, and MUST expose the `SetRefusal` as the read-only property `refusal`.
- **refusal-rule-meaning**: The `SetRefusal.rule` field MUST be read by the rule it would break: 3 (a container whose contained sets disagree on a limit must define it), 4 (the customer holds a conflicting set), 6 (a containment loop), 8 (the edit unsettles a container or puts a holder in conflict) and 9 (the set conflicts with another live offer's set). The type also admits 1 and 2, which the doc comment does not describe.

### The setsApi calls

- **ecosystem-query**: Every `setsApi` call MUST name the ecosystem as `ecosystem=<ecoId>` in the query string, built by `withV1Query`, so the id is form-encoded (a space is written `+`).
- **id-encoding**: Every set id, grant id, customer id and offer id placed in a path MUST be encoded with `encodeURIComponent`.
- **list-sorted**: `setsApi.list` MUST fetch every page of `/api/v1/sets` with `listAllV1`, map each row with `toSet`, and return the rows sorted by `name` with `localeCompare`.
- **list-personal**: `setsApi.list` MUST add `personal=true` only when `opts.personal` is truthy, and MUST send no `personal` param otherwise (including for `false`).
- **create-body**: `setsApi.create` MUST POST to `/api/v1/sets` a body that always carries `slug` and `name`, adds `description` and `is_default` only when the input value is not `undefined`, and adds `personal_customer_id` only when `personalCustomerId` is truthy.
- **create-returns**: `setsApi.create` MUST return the created set mapped with `toSet`.
- **edit-body**: `setsApi.edit` MUST POST (not PUT or PATCH) to `/api/v1/sets/{id}` a body carrying only the patch fields (`slug`, `name`, `description`, `isDefault` as `is_default`) that are not `undefined`, and MUST return the edited set mapped with `toSet`.
- **edit-default-clears**: Making a set the default (`isDefault: true`) MUST be a plain edit; clearing the flag on the previous default is the backend's doing, and the client sends nothing extra.
- **remove-delete**: `setsApi.remove` MUST send a DELETE with no body to `/api/v1/sets/{id}` through `authedRequest` and MUST resolve with no value.
- **members-replace**: `setsApi.setMembers` MUST POST `{ contains }` to `/api/v1/sets/{id}/members`, replacing the whole containment list, and MUST return the set mapped with `toSet`.
- **values-replace**: `setsApi.setValues` MUST POST `{ values }` to `/api/v1/sets/{id}/values`, replacing the whole value list, and MUST return the set mapped with `toSet`. That every key is one the catalog's `setEntries` declares, with a value of its type, is a caller precondition the backend enforces; the client does not check it.
- **grants-list**: `setsApi.grants` MUST fetch every page of `/api/v1/set_grants` with `customer=<customerId>` added to the ecosystem query and MUST map each row with `toSetGrant`; revoked grants are included, and the order is the backend's (the doc comment says newest first), as the client does not sort.
- **grant-call**: `setsApi.grant` MUST POST `{ customer_id, set_id }` to `/api/v1/set_grants` and MUST return `{ grantId, revoked }` from the response's `grant_id` and `revoked`, reading an absent `revoked` as `[]`. Granting a set already held returns that grant (backend behavior, per the doc comment).
- **revoke-call**: `setsApi.revoke` MUST send a DELETE with no body to `/api/v1/set_grants/{id}` through `authedRequest` and MUST resolve with no value; the row stays on the backend with the reason `direct`.
- **effective-call**: `setsApi.effective` MUST GET `/api/v1/set_grants/effective/{customerId}` and MUST return the body mapped with `toSetsAnswer`, so the result is `null`, `{ error: "unresolved" }` or an `EffectiveSets`. The answer is the customer's before the ecosystem's ceiling.
- **offer-set-call**: `setsApi.setOfferSet` MUST POST `{ set_id: setId }` to `/api/v1/offers/{offerId}/set`, sending `null` unchanged to stop the offer granting a set, and MUST resolve with no value, discarding the response body.
- **write-refusal-conversion**: `create`, `edit`, `remove`, `setMembers`, `setValues`, `grant` and `setOfferSet` MUST rethrow a backend 422 `set_refused` as a `SetRefusedError` (through the module's `write` wrapper, which `post` also uses).
- **revoke-refusal-conversion**: `setsApi.revoke` calls `authedRequest` directly rather than the `write` wrapper, and MUST NOT convert any error: the backend's revoke route (`DELETE /api/v1/set_grants/{id}`) answers 204, or an error from the ecosystem check (404 for an unknown ecosystem, 403 when the caller does not manage it) or 404 for an unknown or malformed grant id, and never a 422 `set_refused`, so there is nothing to convert. The file header's "every write here" covers the writes that can be refused.
- **other-errors-unchanged**: A thrown value that is not a 422 `set_refused` MUST propagate from every `setsApi` call as the same object, unwrapped.
- **no-transport-policy**: The client MUST NOT add a timeout, retry, cancellation, caching or logging of its own; each call sends one request (or one `listAllV1` walk) with no idempotency key, and the transport owns the 401 refresh.
- **client-directive**: `sets.ts` MUST carry the `"use client"` directive.
- **entry-point**: `index.ts` MUST re-export everything from `./sets` and `./wire`.

