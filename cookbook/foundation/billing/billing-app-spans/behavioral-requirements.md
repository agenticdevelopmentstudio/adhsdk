
- **span-row-fields**: `BillingAppSpanRow` MUST carry exactly the fields `id`, `bundleId`, `appName`, `windowTitle`, `workingPath`, `repoRoot`, `branch`, `startedAt`, `endedAt` and `tz`, all strings.
- **span-row-immutable**: Every field of `BillingAppSpanRow` MUST be a constant set once by the memberwise initializer that takes all ten fields.
- **working-path-unresolved**: A `workingPath` of the empty string MUST mean the working path is unresolved.
- **repo-root-definition**: `repoRoot` MUST hold the main repo root, the parent of the git common directory, and the empty string MUST mean there is no repo.
- **started-at-format**: `startedAt` MUST be an ISO-8601 UTC timestamp.
- **ended-at-open**: An `endedAt` of the empty string MUST mean the span is still open.
- **span-session-id**: `BillingAppSpanRow.sessionId` MUST equal the result of `ActivitySpanSession.sessionId(spanId:)` applied to the row's `id`, which is the prefix `app:` followed by the span id.
- **session-id-marker**: The `sessionId` MUST be the one marker that tells an app segment from a Claude one, so `ActivitySpanSession.spanId(sessionId:)` applied to it MUST return the original `id`.
- **idle-interval-fields**: `BillingIdleInterval` MUST carry exactly the strings `idleFrom` and `idleUntil`, set by a two-argument initializer.
- **idle-from-meaning**: `idleFrom` MUST hold the last input before the gap.
- **idle-until-open**: An `idleUntil` of the empty string MUST mean the machine is still idle.
- **value-semantics**: Both types MUST be `Sendable` and `Equatable`, so they cross concurrency domains and compare by field value.
- **no-validation**: The initializers MUST store their arguments unchanged; neither type validates a timestamp, an identifier or the ordering of start and end. Parsing and interpretation belong to the derivation code that consumes the rows.

