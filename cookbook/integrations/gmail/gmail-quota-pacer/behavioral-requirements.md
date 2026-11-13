
Contract: `public actor GmailQuotaPacer` with `public init(unitsPerSecond: Double, burstUnits: Double, now: @escaping @Sendable () -> ContinuousClock.Instant = { ContinuousClock.now })`, `public func reserve(_ units: Int) -> Duration` and `public static let shared`. The only mutable state is `drainedAt: ContinuousClock.Instant?`, which starts nil.

### Reservation

- **reserve-returns-wait**: `reserve(_:)` MUST return a `Duration` that is the time the caller has to wait before sending the call whose cost is `units`.
- **no-sleep**: `reserve(_:)` MUST return without suspending or sleeping; waiting is left to the caller.
- **wait-formula**: `reserve(_:)` MUST return `max(.zero, drainedAt' - now - burstUnits / unitsPerSecond)`, where `drainedAt'` is the value set by this reservation and `now` is the single clock read. It therefore never returns a negative `Duration`, and reservations that total no more than `burstUnits` from an idle pacer each return `.zero`.
- **drain-advance**: Each reservation MUST set `drainedAt` to `max(previous drainedAt, current time)` plus `units / unitsPerSecond` seconds, where a nil `drainedAt` counts as the current time.
- **idle-credit-capped**: Time spent idle MUST NOT build up credit beyond the burst allowance, because a `drainedAt` already in the past is replaced by the current time on the next reservation.
- **zero-units**: Reserving 0 units MUST leave `drainedAt` unchanged when it is at or after the current time, and MUST return the wait that backlog still implies.
- **nanosecond-rounding**: Each conversion of units, or of the burst allowance, to a `Duration` MUST round to the nearest whole unit of the platform's `Duration` resolution (a whole nanosecond in Swift).
- **units-nonnegative**: NEEDS REVIEW: Not implemented in source. `reserve(_:)` takes an `Int` and never checks its sign, so a negative `units` moves `drainedAt` earlier and shortens the backlog; the only callers pass `GmailQuotaCost` constants, which are all positive. Settling it needs a decision whether a negative reservation is a caller error to trap, clamp or accept as a refund.
- **reservation-final**: The pacer MUST offer no cancel or release operation, so a call that fails, is retried, or is cancelled while its caller sleeps keeps the units it reserved. A negative `units` is not a designed release; see the open question on `units-nonnegative`.
- **serialised-reservations**: Concurrent `reserve(_:)` calls MUST be serialised by the actor so each one reads and updates `drainedAt` as a single step and no two calls read the same prior value.

### Configuration and clock

- **rate-precondition**: The initializer MUST trap with the message "the pacer needs a positive rate" unless `unitsPerSecond > 0` and `burstUnits >= 0`; the one message is used for both checks, so it names the rate even when the burst is the bad argument.
- **clock-injected**: The pacer MUST read the time through the `now` closure, which defaults to `ContinuousClock.now`, so a test controls time by passing its own closure.
- **clock-read-once**: `reserve(_:)` MUST read the clock exactly once per call and use that single instant for every step of the calculation.
- **sendable-clock**: The `now` closure MUST be `@Sendable` because the actor stores and calls it from its own isolation.
- **zero-burst**: A `burstUnits` of 0 MUST be accepted, and the pacer then spaces every call, including the first, by its own cost divided by `unitsPerSecond`.

### Shared instance

- **shared-defaults**: `GmailQuotaPacer.shared` MUST be created with `unitsPerSecond` 200 and `burstUnits` 200, below Google's 250 units a second ([quota page](https://developers.google.com/workspace/gmail/api/reference/quota)) to leave room for other clients.
- **shared-process-wide**: `shared` MUST be one instance for the whole process, so every account paced through it shares one `drainedAt`.
- **in-memory-only**: The pacer MUST keep `drainedAt` in memory only; nothing is persisted, so a new process starts idle and processes do not coordinate.

### Quota costs

- **cost-table**: `GmailQuotaCost` MUST define these unit costs, taken from [Google's quota table](https://developers.google.com/workspace/gmail/api/reference/quota): `profile` 1, `labelsList` 1, `historyList` 2, `messagesList` 5, `messagesGet` 5, `threadsGet` 10, `messagesBatchModify` 50.
- **cost-type**: Each `GmailQuotaCost` constant MUST be an `Int`, so it can be passed directly to `reserve(_:)`.
- **cost-visibility**: `GmailQuotaCost` MUST be module-internal; only code inside the SDK module names it.

