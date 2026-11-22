
- **Empty and absent wire data (MUST)**: A list with no rows returns `[]`; a `SetWire` missing `description`, `contains`, `values` or `personal_customer_id` maps to the defaults in `set-row-defaults`; an effective body `{}` maps to empty arrays and `{}` limits; `null` or `undefined` maps to `null`.
- **Empty ecosystem id (MUST NOT validate)**: `ecoId` is not validated. An empty string is not nullish, so it is sent as `ecosystem=`; the backend decides the response.
- **Falsy inputs on create (MUST)**: An empty-string or `null` `personalCustomerId` is omitted from the create body; an empty-string `description` or an `isDefault` of `false` is sent, because only `undefined` is dropped.
- **Falsy inputs on edit (MUST)**: A patch of `{ isDefault: false }` sends `is_default: false`; only `undefined` fields are dropped.
- **Empty replacement lists (MUST)**: `setMembers` with `[]` and `setValues` with `[]` send the empty array as the replacement; the client does not treat it as a no-op.
- **Boundary rule values (MUST)**: A `rule` that is any number is accepted, with no check against 1, 2, 3, 4, 6, 8 or 9.
- **Malformed refusal body (MUST)**: A 422 with no body, a null body, a body without `error`, a different `code`, or a non-numeric `rule` is not a refusal; the original error is rethrown. A non-string `message` falls back to the thrown error's message; a non-array `limits` or `containers` and a non-number `customers` are dropped.
- **Backend errors (MUST)**: A 401 follows the transport's single refresh and retry. Any other status error (400, 403, 404, 409, 5xx) propagates unchanged. The effective route answers 200 with `{ error: "unresolved" }` whenever the backend's resolver could not compute the answer, so that body maps to the `unresolved` case; its 403 is the ecosystem-management check and propagates. The `UnresolvedSets` doc comment places a 403 for the enforcement-on case on the enforcing requests (such as `/auth/me`), not on this route.
- **204 on a JSON call (MUST)**: `authedJson` throws on a 204 with no body, so every call that goes through it (the POSTs, `effective`) needs a response body; `remove` and `revoke` use `authedRequest`, which ignores the body and so accept a 204.
- **Offline or unreachable server (MUST)**: A network failure rejects the call with the transport's error, unconverted; there is no retry, queue or cache.
- **Concurrent calls (MUST)**: Concurrent calls do not interact. The module has no shared mutable state, and the client does not order or serialize them; two writes on the same set are ordered by the backend, and the client carries no version or precondition to detect a lost update.
- **Partial failure on a multi-page read (MUST)**: A failure on any page rejects the whole `list` or `grants` call; no partial rows are returned.
- **Revoked grant on a customer (MUST)**: `grants` returns revoked rows with `revokedAt` and `revokeReason` set; the client does not filter them.
- **Customer or set id with reserved characters (MUST)**: Path ids are percent-encoded; query values are form-encoded.

