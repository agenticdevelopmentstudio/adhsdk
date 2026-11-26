
- **Empty and missing input**: an entry with a blank name, empty plugin
  identifier or empty template id MUST be rejected before anything is written
  (`upsert-validation`). A selector with an empty override MUST fall back to the
  entry's default model, not ask for an empty model name (`resolve-selector-config`).
  A minimal entry payload with only `configuration` MUST decode with defaults
  (`entry-minimal-decode`).
- **Unknown and absent ids**: `get` of an absent id MUST return none; `remove` of
  an absent id MUST succeed; `resolve` of an absent id MUST return none;
  `listModels` of an absent id MUST throw `notFound`; `test` of an absent id MUST
  return a failed result rather than throw.
- **Boundary values**: an empty secret value is the same as no secret
  (`upsert-secrets-empty-dropped`). A name made only of a newline is not trimmed
  to empty, because only spaces and tabs are trimmed. The `updated_at` column holds
  fractional seconds but the JSON dates are ISO-8601 at whole-second precision, so
  `updatedAt` read back from the JSON MAY be rounded down to the second.
- **Error states**: a secret write failure MUST abort `upsert` or `create`
  before the row is written, and the secrets the call already wrote or removed
  are put back as they were (`secret-write-rollback`); a database failure MUST
  propagate from the call that hit it, after the same rollback. An undecodable
  row is skipped and logged by `list()` (`list-decode-failure`), so pickers and
  `resolve(role:)` work from the remaining entries; `get` of that id still
  throws, because it decodes the one row it was asked for. A failed `test` MUST be a result, not a
  thrown error. A live model list that fails or answers nothing MUST fall back to
  the template's static list, with no error surfaced to the caller.
- **Concurrent access**: the registry is `Sendable` and may be called from any
  thread, and several processes share the file; the database serialises writes.
  An upsert of one id from two processes at once is last-writer-wins for the
  row and keeps the stored `createdAt` (`concurrent-upsert`). Two `create` calls of
  one new id store one row; the other throws `duplicate` without touching the
  secrets (`create-atomic`, `create-duplicate-first`). Two `changes` streams each hold their own
  signal so neither replaces the other's handler.
- **Concurrent writers and secrets**: two `upsert` calls of one id may interleave
  their field-by-field secret writes, leaving a mix of both calls' values, and a
  stale-field removal decided from the pre-transaction read may miss a field a
  concurrent writer just added (`concurrent-upsert`, `upsert-stale-read`). A
  rollback after a failed call restores the values that call read first, which
  MAY overwrite a value a concurrent call wrote meanwhile.
- **Offline or disconnected**: the store and the Keychain are local and need no
  network. `listModels` and `test` contact the provider over its own transport; an
  unreachable provider makes `listModels` fall back to the static list and `test`
  return a failed result with the error's description. The registry sets no
  timeout, retry or cancellation of its own on either call.
- **Missing environment**: a process without the shared-Keychain entitlement MUST
  read and write the same service in its own Keychain, so entries it creates are
  not visible to other processes' secret reads (`secret-store-keychain-choice`). A
  plugin removed after an entry was created MUST make `listModels` throw
  `pluginNotInstalled` and `test` return a failed result.

