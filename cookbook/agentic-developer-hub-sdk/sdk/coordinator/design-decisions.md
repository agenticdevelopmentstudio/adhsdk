
**Decision**: `describe(_:fallback:)` names the concrete
`PersonaChatError` type in its `as?` cast instead of casting to
`CustomStringConvertible`.
**Rationale**: `any Error` bridges to `NSError` on Apple platforms, and
`NSError` itself conforms to `CustomStringConvertible` — so `error as?
CustomStringConvertible` succeeds for every error, not just
`PersonaChatError`, which silently skipped the `NSError.localizedDescription`
fallback for every non-`PersonaChatError` case and surfaced a raw Swift
`String(describing:)` dump (e.g. a verbose `DecodingError` case) instead
of the friendlier message the function exists to prefer. This is a fixed
workaround, documented inline in the source, not a hypothetical risk.
**Approved**: pending
**Decision**: `send`'s turn `Task` captures `self` weakly and is
deliberately detached from the caller's own task rather than being a
child task.
**Rationale**: The turn outlives the `send` call that started it — the
reply arrives later, on `inboundEvents` — so tying it to the caller's
task would cancel the reply the moment the caller's own work finished.
The capture is `weak` because `TurnControl` holds the task and the actor
holds `TurnControl`; a strong capture would keep the coordinator alive
for as long as a turn it is no longer wanted for.
**Approved**: pending
**Decision**: Cancellation state (`TurnControl`) lives outside the actor,
guarded by an `NSLock` instead of actor isolation.
**Rationale**: `destroy()` has to cancel a turn immediately, from any
context, including one holding no async capability at all — a `deinit`,
a SwiftUI `onDisappear`. Actor isolation would turn `destroy()` into a
request to cancel (queued behind whatever the actor is doing) rather
than an immediate cancellation.
**Approved**: pending
**Decision**: Tool call correlation is by `commandName` and FIFO arrival
order, not by a server-supplied invocation id.
**Rationale**: adh's `tool_call_completed` payload carries a `name` and
no id, so the coordinator has nothing else to correlate on; it assumes
adh completes calls to the same command in the order it started them.
**Approved**: pending
**Decision**: A turn-phase transition is reported through both the
`onStatus` callback and the `statusChanged` event, with neither derived
from the other at the call site.
**Rationale**: `onStatus` is kept for its existing callers (in the apple package today only `TestSupport.swift` passes it) and can be deleted once no host passes it, a removal the SDK maintainer owns, while
`statusChanged` is the newer, out-of-band channel
(`status-not-a-transcript-event`); both are driven from the same single
`report(_:via:)` call so they can never disagree, but the source
maintains them as two explicit sinks rather than one deriving from the
other.
**Approved**: pending

**Decision**: `message-encode-failure-swallowed` stays open: a `send`-time encoding failure either throws synchronously (matching `ensureConversation()`) or fails the turn via `messageFailed`.
**Rationale**: The source uses `try?` and sends a bodyless POST if `JSONEncoder` ever fails, unlike `ensureConversation()`, which propagates the equivalent failure. `SendMessageBody` holds only a `String`, so failure is unlikely, but no test exercises it.
**Approved**: pending

**Decision**: `concurrent-turns` stays open: serialize `send()` behind an actor-held queue, track one task per turn in `TurnControl`, or reject a second concurrent `send()` as a caller error.
**Rationale**: `TurnControl` stores a single task, so a second `send()` before the first turn ends overwrites it and `destroy()` cancels only the latest turn. `ensureConversation()` re-checks `conversationID` before `await options.authorize(request)`, so two back-to-back sends can each create a conversation. `test_pcc002_conversationReuse_twoSendsShareOneConversation` serializes its sends, so no test covers this.
**Approved**: pending
