
### Shape

- **fields**: MailSyncSettings MUST expose the mutable fields `includeArchived`, `includeSpam` and `includeTrash` (Bool) and `windowDays` and `pollIntervalMinutes` (Int).
- **value-semantics**: MailSyncSettings MUST be an `Equatable`, `Codable` and `Sendable` value type, so two instances with equal fields compare equal.
- **default-values**: The static `default` MUST have all three include flags false, `windowDays` 30 and `pollIntervalMinutes` 15.
- **memberwise-init-defaults**: The memberwise initializer MUST default each parameter to the same value as `default`, so omitting every argument yields `default`.
- **range-constants**: MailSyncSettings MUST publish `windowDaysRange` as 1 through 3650 and `pollIntervalRange` as 1 through 1440, both inclusive.

### Decoding

- **decode-keys**: Decoding MUST read the five keys `includeArchived`, `includeSpam`, `includeTrash`, `windowDays` and `pollIntervalMinutes`, spelled exactly so, and the encoded form MUST use the same five keys.
- **decode-lenient**: Decoding MUST take the value from `default` for each key that is absent, so an empty JSON object decodes to `default`.
- **decode-null-key**: Decoding MUST treat a key present with a JSON null the same as an absent key, because the source reads each key with `decodeIfPresent`.
- **decode-partial**: Decoding MUST keep the keys that are present and default only the missing ones.
- **decode-wrong-type**: Decoding MUST propagate the decoder's error when a present key has the wrong type (for example a string for `windowDays`); the source does not catch it.
- **decode-no-range-check**: Decoding MUST NOT validate ranges, so an out-of-range number decodes unchanged and is rejected only when `validated()` is called.
- **init-no-range-check**: The memberwise initializer MUST NOT validate ranges.

### Classification gate

- **allows-filed**: `allows(_:)` MUST return true for `.filed` regardless of the three flags.
- **allows-flagged**: `allows(_:)` MUST return `includeArchived` for `.archived`, `includeSpam` for `.spam` and `includeTrash` for `.trash`.

### Validation

- **validated-window**: `validated()` MUST throw `IntegrationError.invalidSettings` with the message `windowDays must be 1–3650, got <value>` when `windowDays` is outside 1 through 3650.
- **validated-poll**: `validated()` MUST throw `IntegrationError.invalidSettings` with the message `pollIntervalMinutes must be 1–1440, got <value>` when `pollIntervalMinutes` is outside 1 through 1440.
- **validated-order**: `validated()` MUST check `windowDays` before `pollIntervalMinutes`, so when both are invalid the error names `windowDays`.
- **validated-returns-self**: `validated()` MUST return the unchanged instance when both numbers are in range, accepting the boundary values 1 and 3650 for `windowDays` and 1 and 1440 for `pollIntervalMinutes`.
- **validated-no-clamp**: `validated()` MUST NOT clamp or repair a bad value; it only accepts or throws.

### Use by the integration service

- **service-validates-first**: The mail integration service calls `validated()` as the first step of its settings update, so an invalid value is rejected before any stored data changes. This is the caller's contract and is not enforced by this type.
- **service-reads-settings**: The service reads `allows(_:)` to decide which message classes to keep or tombstone, `windowDays` to compute the look-back start and tombstone older rows, and `pollIntervalMinutes` as the minimum time between sync attempts per connection (`pollIntervalMinutes` times 60 seconds).

### Ordering and concurrency

- **no-shared-state**: MailSyncSettings has no shared mutable state; it is a `Sendable` value, so copies move freely between threads and the type adds no ordering rule.

### Persistence and side effects

- **no-side-effects**: Every operation MUST be a pure function of the instance fields; none touches files, the network, processes or notifications.
- **persisted-as-json**: The type is persisted by its `Codable` conformance as a JSON text column inside the connection record, as the sibling records recipe describes.

