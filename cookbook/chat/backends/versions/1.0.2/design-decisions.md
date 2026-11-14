
**Decision**: `ChatBackendAdapter` translates any `ChatBackend` into a
`Backend` at one seam, rather than teaching `useChatSession` (or every
consumer) to speak both vocabularies.
**Rationale**: `ChatBackend` streams `ChatStreamEvent`s that mutate a
placeholder bubble in place; the contract streams `InboundEvent`s into an
immutable transcript plus a separate `ActiveDraft`. Translating once here is
what lets `useChatSession` own no transport type-switch of its own — every
backend it is handed, legacy or contract, reaches it as `InboundEvent`s.
**Approved**: pending

**Decision**: Both `ChatBackendAdapter` and `PersonaChatBackend` serialize
their turns on a private promise `tail` chain rather than allowing
overlapping turns.
**Rationale**: Each holds exactly one draft per participant and (for
`PersonaChatBackend`) one cancellation handle and one open-invocation map per
instance; two turns racing would either interleave one draft's text from two
different replies, or let the second turn's per-turn state silently clobber
the first's. Nothing upstream (no chat surface disables its composer while a
turn is in flight) prevents the caller from trying anyway, so the
serialization has to live here.
**Approved**: pending

**Decision**: Both implementations correlate a tool-call completion to its
invocation by command name plus arrival order (oldest-open-first), never by
an id carried on the wire.
**Rationale**: Neither `ChatStreamEvent`'s `tool_call_completed` nor adh's
SSE `tool_call_completed` event carries an invocation id — only a name. Given
that constraint, oldest-open-first is the one answer both `Turn.close`
(`ChatBackendAdapter`) and `closeInvocation` (`PersonaChatBackend`) settle on,
so the package has one rule for this rather than two.
**Approved**: pending

**Decision**: `ChatBackendAdapter.Turn.close` synthesizes an invocation for a
tool completion it never saw start, rather than dropping it.
**Rationale**: The live command channel (`commandInvoked`/`commandCompleted`)
and the frozen `toolCalls` record on the committed message are meant to
agree about which invocations happened; dropping an unmatched completion
would show its result in the committed record and nowhere on the live
channel. See **divergence-unmatched-tool-completion** for the contrasting
choice `PersonaChatBackend` makes for the same situation.
**Approved**: pending

**Decision**: `PersonaChatBackend.closeInvocation` drops a tool completion it
never saw start, rather than synthesizing an invocation for it.
**Rationale**: adh is the single source of truth for what tool calls exist in
a live conversation; an unmatched completion arriving from adh is treated as
a protocol anomaly to ignore rather than a gap for the client to paper over
with a fabricated invocation record. See **divergence-unmatched-tool-completion**.
**Approved**: pending

**Decision**: `ChatBackendAdapter` commits a message on a stream `error`
event (using whatever text had accumulated, or the error's own message when
none had); `PersonaChatBackend` never commits on an equivalent failure and
reports `messageFailed`/`transportError` instead.
**Rationale**: `ChatBackendAdapter` preserves behavior from the placeholder
era it replaced — sites are rendering the commit-on-error case today, so
changing it would be an unannounced behavior change to every existing
`ChatBackend` consumer. `PersonaChatBackend` is new code with no such
installed base, and treats a truncated/errored reply as never having
happened rather than displaying a partial answer as if it were complete. See
**divergence-error-commit-vs-fail**.
**Approved**: pending

**Decision**: `ChatBackendAdapter` collapses every turn-level failure into
one generic committed apology; `PersonaChatBackend` distinguishes
`messageFailed` (nothing reached adh) from `transportError` (the stream
itself failed) and commits neither.
**Rationale**: `ChatBackendAdapter` wraps an arbitrary caller-supplied
`ChatBackend` whose failure modes it cannot enumerate in advance, so one
generic fallback is the only response it can give without guessing.
`PersonaChatBackend` talks to one known API (adh) whose two failure classes
it can and does tell apart, and callers (`ci-transport-vs-message` in the
`persona-chat-coordinator` ingredient spec) rely on the distinction to decide
whether the outgoing message itself failed. See
**divergence-failure-granularity**.
**Approved**: pending

**Decision**: `EventQueue<T>` is single-consumer, backed by a plain array
buffer and an array of waiting resolvers, rather than a general
multi-subscriber pub/sub primitive.
**Rationale**: Every `Backend.inboundEvents` in this package has exactly one
consumer, the orchestrator; a fan-out primitive would add complexity (and a
"who gets which events on reconnect" question) that nothing here needs.
**Approved**: pending

**Decision**: `FetchBackend`'s default `mapResponse` assumes the response
body is `{ reply: string }`, rather than the raw JSON body or a required
mapper.
**Rationale**: Keeps the zero-configuration path usable against the simplest
possible echo-style backend, which is `FetchBackend`'s primary use case
(demos, quick integrations); a caller with a different response shape
supplies `mapResponse` rather than the common case paying for it.
**Approved**: pending

**Decision**: `MockBackend` matches on the exact lowercased, trimmed input
text rather than any fuzzy or substring matching.
**Rationale**: `MockBackend` exists to give a deterministic, scriptable
canned-response backend for demos and tests; exact-match keeps its behavior
fully predictable from its `ResponseMap`, at the cost of not recognizing
"tell me about the big panel" as `'big panel'`.
**Approved**: pending

**Decision**: `ShuffleBag` reshuffles lazily, on the draw that empties the
pile, rather than precomputing a long shuffled sequence up front.
**Rationale**: The bag's caller (`MockBackend`-style canned replies driven by
`streamTokens`) draws indefinitely over an unbounded session; reshuffling
on demand keeps memory bounded to one copy of the item set regardless of how
many draws have happened.
**Approved**: pending

**Decision**: `streamTokens` preserves whitespace runs as their own tokens
and delays on every loop iteration, including one that yields nothing.
**Rationale**: Splitting on `/(\s+)/` and delaying unconditionally keeps
whitespace appearing with realistic timing, rather than every space
appearing instantly attached to the word before or after it, which is what
made a persona's canned reply look like it was actually being typed rather
than pasted in two chunks.
**Approved**: pending

**Decision**: `PersonaChatBackend` holds a `lifetime` `AbortController`
separate from the per-turn `controller`, rather than one `AbortController`
covering both the conversation-creation request and the message stream.
**Rationale**: `ensureConversation` can be in flight before any turn has a
`controller` of its own; a single shared controller left a `destroy()` during
that window with nothing to abort, and the creation request ran to
completion (and could then post the user's message) after the caller
believed the backend was gone.
**Approved**: pending

**Decision**: `PersonaChatBackend.onStatus` transitions are delivered on a
dedicated callback, never as an `InboundEvent`.
**Rationale**: A retry, or the thinking/responding phase, is progress
information about the turn, not something that happened in the conversation;
folding it into the transcript stream would give a consumer no way to tell a
transient status blip from an actual event without hardcoding knowledge of
which `InboundEvent` kinds are "really" status.
**Approved**: pending

