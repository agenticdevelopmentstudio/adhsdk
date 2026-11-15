
**Shape**

- **status-cases**: `SessionStatus` MUST have exactly three cases: `active`, `stale` and `ended`.
- **status-raw-values**: Each case's `String` raw value MUST equal its case name: `"active"`, `"stale"`, `"ended"`.
- **status-sendable**: `SessionStatus` MUST conform to `Sendable`.
- **status-raw-init-optional**: Initializing from a raw string that is not one of the three values MUST yield no value (the failable `init(rawValue:)` returns `nil`).

**Meaning of each case**

- **stale-declared**: A consumer MUST accept `stale` as a valid status when it reads one, because the sessions table's status column allows it.
- **status-vs-activity**: A consumer that needs to know what a live session is doing MUST use `SessionActivity` (Session Activity ([adhsdk.ingredient.foundation.sessions.session-activity](cookbook:bc99bb92-f6b7-4767-8d29-f68ee9e5e2b4))) and not infer it from `SessionStatus`.

**Use as a stored and published value**

- **status-stored-as-raw**: Code that writes or compares the status column MUST use the `rawValue` string, as `updateSessionStatus(_:sessionId:)` and the liveness comparison `status == SessionStatus.active.rawValue` do.
- **status-update-failure**: `updateSessionStatus(_:sessionId:)` MUST NOT throw; it MUST write the raw value with a single-row UPDATE keyed by session id, and on a write failure it MUST log the error through the logger and return.
- **status-published-as-raw**: A session-status broadcast MUST carry the raw string in the payload's `status` field (see Session Event Sink ([adhsdk.ingredient.foundation.sessions.session-event-sink](cookbook:6a37e531-b5ae-4eea-b4f0-d28866776ddc))).

