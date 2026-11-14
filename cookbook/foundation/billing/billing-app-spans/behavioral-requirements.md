
- **span-row-fields**: `BillingAppSpanRow` MUST carry exactly the fields `id`, `bundleId`, `appName`, `windowTitle`, `workingPath`, `repoRoot`, `branch`, `startedAt`, `endedAt` and `tz`, all strings.
- **span-row-immutable**: Every field of `BillingAppSpanRow` MUST be a constant set once by the memberwise initializer that takes all ten fields.
- **working-path-unresolved**: The host MUST write an empty `workingPath` only when the working path is unresolved, and consumers MUST read an empty `workingPath` as unresolved.
- **repo-root-definition**: The host MUST fill `repoRoot` with the main repo root, the parent of the git common directory, and MUST write the empty string when there is no repo; consumers MUST read the empty string as no repo.
- **started-at-format**: The host MUST supply `startedAt` as an ISO-8601 UTC timestamp. The type does not check it (see **no-validation**).
- **ended-at-open**: The host MUST write an empty `endedAt` only for a span that is still open, and consumers MUST read an empty `endedAt` as open.
- **span-session-id**: `BillingAppSpanRow.sessionId` MUST equal the result of `ActivitySpanSession.sessionId(spanId:)` applied to the row's `id`, which is the prefix `app:` followed by the span id.
- **session-id-marker**: The `sessionId` MUST be the one marker that tells an app segment from a Claude one, so `ActivitySpanSession.spanId(sessionId:)` applied to it MUST return `Optional(id)`, the original `id`. The round trip holds even when `id` already starts with `app:`, because `spanId(sessionId:)` strips only one prefix.
- **idle-interval-fields**: `BillingIdleInterval` MUST carry exactly the strings `idleFrom` and `idleUntil`, set by a two-argument initializer.
- **idle-from-meaning**: The host MUST supply `idleFrom` as the last input before the gap, and consumers MUST read it that way.
- **idle-until-open**: The host MUST write an empty `idleUntil` only while the machine is still idle, and consumers MUST read an empty `idleUntil` as still idle.
- **unspecified-fields**: The source gives `bundleId`, `appName`, `windowTitle`, `branch` and `tz` no stated format or meaning: it does not say whether `tz` is an IANA name or an offset, or whether an empty `branch` is a sentinel. A port MUST store them as opaque strings and MUST NOT assign them a format the source does not state.
- **value-semantics**: Both types MUST be `Sendable` and `Equatable`, so they cross concurrency domains and compare by field value.
- **no-validation**: The initializers MUST store their arguments unchanged; neither type validates a timestamp, an identifier or the ordering of start and end. Parsing and interpretation belong to the derivation code that consumes the rows.

