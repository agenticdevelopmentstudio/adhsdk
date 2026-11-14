
### Encoding-skip wrapper

- **encoding-skip-shape**: The wrapper MUST be a generic value type holding
  a single mutable optional wrapped value, and MUST provide a way to
  construct it directly from that optional value.
- **encoding-skip-decode-yields-nothing**: The wrapper's decoding behavior
  MUST initialize the wrapped value to nothing unconditionally, regardless
  of whether the corresponding key is present or absent in the decoded
  input.
- **encoding-skip-encode-noop**: The wrapper's encoding behavior MUST be a
  no-op — it MUST NOT write anything to the target encoding.
- **decode-integration-skips-key**: the decoding-side integration
  specialized for the wrapper MUST return a wrapper holding nothing,
  without attempting to read the source at that key at all.
- **encode-integration-skips-key**: the encoding-side integration
  specialized for the wrapper MUST return without writing a null, a value,
  or anything else — the key MUST NOT appear in the encoded output at all.
- **encoding-skip-round-trip-loses-value**: encoding a model whose wrapped
  field holds a non-nothing value and then decoding the result back MUST
  yield a nothing wrapped value on the decoded copy — the original value
  MUST NOT survive an encode/decode round trip.

Note (non-normative): the wrapper's wrapped value is mutable and the type
makes no concurrency-safety promise, so a caller sharing one instance across
concurrency domains should supply its own synchronization.

### Secret storage

- **keychain-service-default**: the store's `service` identifier MUST
  default to the app's bundle identifier, or `"com.mikefullerton.agenticdeveloperhubsdk"` when
  none is available, and MUST be reassignable by a caller at any time.
- **keychain-per-call-service**: `set`, `get`, `read`, `delete` and `exists`
  MUST each accept an optional `service` argument that defaults to the
  process-wide `service`; when a caller passes one, the operation MUST use it
  in place of the process-wide value and MUST NOT change that value.
- **keychain-data-protection-default**: the store's
  `usesDataProtectionKeychain` flag MUST default to false.
- **keychain-entitled-access-group**: `entitledAccessGroup(_:)` MUST return
  the entry of the running process's keychain-access-groups entitlement that
  equals the given group or ends in `"." + group`, and MUST return nothing
  when the process carries no such entry. On every platform other than macOS
  it MUST return nothing.
- **keychain-access-group-default**: the store's `accessGroup` MUST default
  to nothing.
- **keychain-legacy-services-default**: the store's `legacyServices` MUST
  default to an empty list, ordered newest-retired-first.
- **keychain-query-shape**: building a query for an account MUST identify
  the item as a generic password (`kSecClass` = `kSecClassGenericPassword`),
  scoped to the store's current `service` (`kSecAttrService`) and the given
  account (`kSecAttrAccount`).
- **keychain-query-access-group-forces-data-protection**: when a query is
  built with a non-nothing access group, it MUST additionally scope to that
  group (`kSecAttrAccessGroup`) and require data-protection-keychain
  semantics (`kSecUseDataProtectionKeychain` = true). When the access group
  is nothing and `usesDataProtectionKeychain` is true, it MUST require
  data-protection-keychain semantics without an access group. When the
  access group is nothing and the flag is false, both keys MUST be absent.
- **keychain-set-overwrites**: `set` MUST first delete any existing item for
  the same query and then add the new value, so a second `set` call for the
  same key MUST overwrite the first value rather than fail.
- **keychain-set-access-group-accessibility**: when the store's access
  group is non-nothing or `usesDataProtectionKeychain` is true at the time
  `set` runs, the item's accessibility attribute (`kSecAttrAccessible`) MUST
  be set to after-first-unlock, this-device-only.
- **keychain-set-returns-status**: `set` MUST return true only when the
  underlying add/update call reports success, and MUST return false for
  any other status.
- **keychain-get-primary-lookup**: `get` MUST first query under the current
  `service`/`accessGroup` scope and MUST return the stored string directly
  when that query succeeds.
- **keychain-get-access-group-migration**: when the primary lookup fails
  and the store's access group is non-nothing or `usesDataProtectionKeychain`
  is true, `get` MUST retry the query against the login keychain with no
  access group; on success it MUST re-store the recovered value under the
  current `service`/`accessGroup` scope via `set` before returning it.
- **keychain-get-legacy-service-migration**: when the access-group retry
  also fails (or does not apply), `get` MUST iterate `legacyServices` in
  order and, for the first retired service under which the key is found
  (in the current scope or, when the login-keychain fallback applies, in the
  login keychain), MUST re-store the recovered value under the current
  `service` before returning it.
- **keychain-get-exhausted-returns-nothing**: when the primary lookup, the
  access-group retry, and every entry in `legacyServices` all fail to
  locate the key, `get` MUST return nothing.
- **keychain-legacy-item-not-deleted**: when `get` recovers a value from a
  legacy access-group scope or a retired service, it MUST NOT delete the
  original item under that legacy scope — only a new copy is written under
  the current scope. `delete` is the operation that removes those copies
  (see `keychain-delete-clears-legacy`).
- **keychain-read-throws-on-failure**: `read` MUST query the current scope
  and return the stored string when that succeeds; MUST fall back to `get`'s
  migration paths when the status is item-not-found; and MUST throw an error
  carrying the status for any other failure, so a caller can tell a failed
  lookup from a missing key. `read` MUST log an error before throwing.
- **keychain-copy-value-single-match**: the lookup helper MUST limit the
  match to a single item (`kSecMatchLimit` = `kSecMatchLimitOne`) and
  request the data back (`kSecReturnData` = true), and MUST decode the
  returned data as UTF-8 text.
- **keychain-copy-value-logs-unexpected-errors-only**: the lookup helper
  MUST log an error when the underlying lookup call returns a status other
  than success and other than item-not-found; it MUST NOT log anything when
  the status is item-not-found.
- **keychain-delete-idempotent**: `delete` MUST return true when
  every underlying delete call reports success or item-not-found, and MUST
  return false when any call reports another status — deleting an
  already-absent key is therefore never an error.
- **keychain-delete-clears-legacy**: `delete` MUST remove the item under the
  current scope, the login-keychain copy when the login-keychain fallback
  applies, and the copies under every entry of `legacyServices`, so a cleared
  secret cannot be recovered by a later `get`.
- **keychain-delete-scoped-to-key**: deleting one key MUST NOT affect the
  item stored for any other key.
- **keychain-exists-checks-current-scope**: `exists` MUST return true when
  a query under the current `service`/`accessGroup` scope locates the key.
- **keychain-exists-checks-login-keychain**: when the current-scope check
  fails and the login-keychain fallback applies, `exists` MUST check the
  login keychain under the current `service` before it checks any retired
  service.
- **keychain-exists-checks-legacy-scopes**: when the earlier checks fail,
  `exists` MUST check `legacyServices` in order and MUST return true
  if any retired service holds the key.
- **keychain-exists-does-not-migrate**: unlike `get`, `exists` MUST NOT call
  `set` when it locates a key under a legacy scope — it only reports
  presence, it never re-stores.
- **keychain-get-error-ambiguity**: `get`'s optional-string return does
  not distinguish "no secret was ever stored for this key" from "a lookup
  failed for a reason other than not-found" (for example, an
  interaction-not-allowed status while the device is locked, or a missing
  entitlement). The lookup helper logs the status in that second case, but
  `get` MUST return nothing in both. A caller that needs to tell the two
  apart MUST use `read` (see `keychain-read-throws-on-failure`).

Note (non-normative): `service`, `accessGroup`, `legacyServices` and
`usesDataProtectionKeychain` are shared mutable global state that the store
does not lock. Callers should set them once at startup, before any other
thread uses the store.

### Security

- **keychain-secret-storage-mechanism**: every value `set` writes MUST go
  into the system credential store as a generic-password item — the store
  MUST NOT write a secret to a plain settings store, a file, or any other
  unencrypted store.
- **keychain-secret-value-not-logged**: every log call inside the
  secret-storage component MUST interpolate only the account key and a
  status/error value — none MUST interpolate the secret string passed to
  `set` or returned by `get`.
- **keychain-secret-no-transmission**: the store MUST perform no networking
  of any kind — it MUST NOT transmit a stored or retrieved secret
  off-device.
- **keychain-secret-lifetime-caller-controlled**: the store MUST define no
  TTL, expiry timer, or automatic-eviction policy for a stored item — a
  secret MUST persist until a caller calls `delete` or the OS/user removes
  it independently.

### Logger factory contract

- **loggable-requirement**: the contract's sole requirement MUST be a
  type-level `logger` value, obtainable without regard to any particular
  concurrency context.
- **loggable-default-subsystem**: the default `subsystem` MUST equal the
  app's bundle identifier, or the literal string `"nil"` when none is
  available.
- **loggable-default-category**: the default `category` MUST equal the
  conforming type's own name, with any trailing type-metadata suffix
  removed.
- **loggable-instance-forwarding**: the default instance-level `logger`
  MUST forward to the type-level `logger` — an instance and its type MUST
  expose the identical logger value.
- **loggable-factory**: the factory MUST return a structured logger
  constructed from `subsystem` and `category`.

Note (non-normative): only the contract's `logger` requirement carries an
explicit concurrency-context annotation; the default `subsystem`,
`category`, instance `logger`, and factory members carry none of their own.

### Float clamping

- **float-clamped-shape**: clamping a floating-point value to a closed
  range MUST return the value unchanged when it already lies within the
  range, MUST return the range's lower bound when it is below it, and MUST
  return the range's upper bound when it is above it.
- **float-clamped-degenerate-range**: when the range's lower and upper
  bounds are equal, clamping MUST return that single value for every
  possible input.
- **float-clamped-pure**: clamping MUST have no side effects and MUST
  depend only on the input value and the range — it MUST NOT read or
  mutate any external state.

### Semantic version parsing

- **semver-shape**: a semantic version MUST be a value type holding
  `major`, `minor`, and `patch` integer components, and MUST support
  equality, hashing, ordering comparison, and a human-readable description.
- **semver-parse-forms**: parsing MUST accept a string of one, two, or
  three dot-separated numeric components (`"1"`, `"1.74"`, `"1.74.0"`),
  MUST accept an optional leading `"v"`, and MUST default any component
  missing from a short form to `0`.
- **semver-parse-rejects-invalid**: parsing MUST return nothing for a
  string carrying a prerelease suffix (`"1.74.0-rc.1"`), build metadata
  (`"1.74.0+build"`), non-numeric text (`"abc"`), the empty string, or a
  non-numeric component (`"1.x.0"`).
- **semver-component-bound**: parsing MUST return nothing when any parsed
  component exceeds 2,147,483,647 (the largest 32-bit signed integer), and
  MUST accept a component exactly equal to that ceiling.
- **semver-ordering**: ordering comparison MUST order strictly by `major`,
  then `minor`, then `patch`, as numeric integer comparisons — it MUST NOT
  compare components as strings (`"9"` MUST sort before `"10"`).
- **semver-description-round-trip**: the description MUST render as
  `"major.minor.patch"`, and parsing that description MUST equal the
  original value for every value the type can represent.

### Text folding

- **text-folding-normalization**: folding a string MUST fold both case and
  diacritics, so that two strings differing only in letter case or in
  diacritical marks MUST fold to the same result (`folded("CAFÉ") ==
  folded("cafe")`).
- **text-folding-locale-independence**: folding MUST be locale-independent
  rather than using the current locale, so its result MUST NOT vary with
  the current locale (for example, it MUST fold identically whether the
  current locale is Turkish or U.S. English).
- **text-folding-empty-input**: folding `""` MUST return `""`.
- **text-folding-pure**: folding MUST have no side effects and MUST depend
  only on its input string.

