
**Decision**: Camelize idempotently instead of converting only snake_case input.
**Rationale**: The source header states the gateway renames only properties the legacy spec declares, so an undeclared property already arrives in camelCase (`itemKey`, `projectName`). Applying the regex to it is a no-op, so both shapes land on one key.
**Approved**: pending

**Decision**: Treat `config`, `detail`, `body`, `value` and `counts` as opaque by key name at every depth.
**Rationale**: The header comment lists these as free-form maps whose keys must keep the casing they were stored with, with `counts` keyed by category names such as `in_progress`. The cost, which a port must keep, is that any other property that happens to use one of these names is also left verbatim.
**Approved**: pending

**Decision**: Drop the `object` key on read only, and convert only numeric `created` and `updated`.
**Rationale**: `object` is the `/v1` type tag, not data (a source comment). Converting only numbers means a `null` or absent timestamp stays under its `/v1` name rather than becoming a camelCase `null`. A row that really has a field called `object` loses it on read.
**Approved**: pending

**Decision**: Silently overwrite on key collisions and skip cycle detection.
**Rationale**: The source has no guard for either; wire JSON cannot be cyclic and collisions only arise from a gateway echoing both forms. The recipe records the behavior so a port matches it.
**Approved**: pending

**Decision**: Keep `v1Write` to `POST` with no headers, and keep `v1List` on `listAllV1` defaults.
**Rationale**: The wrappers are deliberately thin. `Content-Type` is added by the request layer when a body exists, and paging, retry on 401 and error construction stay in the auth package so they are not reimplemented here.
**Approved**: pending

