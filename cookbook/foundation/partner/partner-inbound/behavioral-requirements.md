
Shape

- **case-set**: The type MUST be a closed enumeration of exactly these cases: `owner(text:attribution:)`, `tick(jobID:jobName:previousTick:summary:)`, `sessionIdle(sessionID:title:)`, `sessionExited(sessionID:title:)` and `lifecycle(_:)`.
- **lifecycle-set**: The `Lifecycle` payload MUST be a closed enumeration of exactly these cases: `started(resumed:goneSessions:)`, `guidelinesChanged`, `willQuit(endingSessions:)` and `turnTimedOut`.
- **value-semantics**: The type and `Lifecycle` MUST be `Sendable` and `Equatable` value types, so events can cross threads and two events compare equal when their cases and payloads are equal.

Text the partner reads (`text`)

- **owner-text**: For `owner`, `text` MUST be the owner's text exactly as given, with no prefix or suffix, and MUST NOT include the attribution.
- **tick-text-first-line**: For `tick`, `text` MUST begin with the line `Timer tick for job <jobName>.`
- **tick-text-previous**: For `tick`, when `previousTick` is non-nil, `text` MUST contain a second line `Previous tick: <date>` where the date is rendered in the ISO 8601 date-time style in UTC, with whole seconds, no fractional part and a literal `Z` suffix (for example `2026-11-14T10:00:00Z`); when it is nil that line MUST be omitted.
- **tick-text-summary**: For `tick`, when `summary` is non-nil, `text` MUST end with the summary as its own line, unchanged; when it is nil no line is added. A non-nil empty summary adds an empty final line.
- **tick-text-join**: The lines of a tick's `text` MUST be joined with a single newline and MUST NOT end with a trailing newline.
- **idle-text**: For `sessionIdle`, `text` MUST be `Session <sessionID> (<title>) went idle.`
- **exited-text**: For `sessionExited`, `text` MUST be `Session <sessionID> (<title>) exited.`
- **started-text**: For `lifecycle(.started)`, `text` MUST be `You were started (resumed: <true|false>). Sessions gone since last time: <list>` where `<list>` is the gone session ids joined by a comma and a space, or `none` when the list is empty. The sentence has no trailing period after the list.
- **guidelines-changed-text**: For `lifecycle(.guidelinesChanged)`, `text` MUST be `Your guidelines changed and were applied at this restart.`
- **will-quit-text**: For `lifecycle(.willQuit)`, `text` MUST be `The app is about to quit. These sessions will end: <list>` with `<list>` built the same way as for started (ids joined by a comma and a space, or `none`).
- **turn-timed-out-text**: For `lifecycle(.turnTimedOut)`, `text` MUST be `Your previous turn was terminated after the turn timeout and the session resumed.`
- **text-verbatim-ids**: The text builders MUST insert job names, session ids and titles without escaping, truncation or validation, so any string, including an empty one, is rendered as given.

Coalescing (`coalescingKey`)

- **key-tick**: For `tick`, `coalescingKey` MUST be `tick:<jobID>`, so it is keyed by the job id, not the job name.
- **key-idle**: For `sessionIdle`, `coalescingKey` MUST be `idle:<sessionID>`.
- **key-exited**: For `sessionExited`, `coalescingKey` MUST be `exit:<sessionID>`.
- **key-distinct-kinds**: An idle event and an exited event for the same session MUST have different keys, so one never replaces the other.
- **key-none-owner-lifecycle**: For `owner` and every `lifecycle` case, `coalescingKey` MUST be nil, so those events never collapse.
- **key-ignores-payload**: A key MUST depend only on the case and its id, never on the title, name, summary or previous-tick date, so that an event with the same key as an earlier one can stand in for it in a queue.
- **queue-honors-key**: The key is the only coalescing input this type provides. What a queue does with equal keys (replace in place, append, `enqueueFirst`) is specified by Partner Turn Queue ([adhsdk.ingredient.foundation.partner.partner-turn-queue](cookbook:ae6b1991-6aed-4d8b-83e1-5d5e02470150)), not here.

Attribution

- **attribution-owner-only**: `attribution` MUST return the attribution carried by an `owner` event, which may be nil, and MUST return nil for every other case.

Concurrency and side effects

- **pure-and-stateless**: Every computed property MUST be a pure function of the value, with no I/O, no clock read and no shared state, so it is safe from any thread and may be called repeatedly with the same result.

