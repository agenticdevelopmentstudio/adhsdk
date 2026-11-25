
**Decision**: The host keeps two kinds of stream: a per-turn stream returned by `send`, and a per-session tail from `events(_:)` that spans turns, and both receive the same numbered envelope.
**Rationale**: Ending the per-turn stream does not stop the turn and the tail lasts until the session is deleted or the caller stops listening, so the requesting client can follow one turn while a second client watches the session; the shared `seq` lets a client detect a gap or a repeat.
**Approved**: pending

**Decision**: `seq` lives in memory and restarts at 0 for a session after the host is recreated, separate from the stored message `seq`.
**Rationale**: Events are a live feed, not a log, and the host persists only the messages.
**Approved**: pending

**Decision**: A tool that throws, or a tool that does not exist, is returned to the model as an error result and the turn continues; only cancellation and host-level failures end the turn.
**Rationale**: This lets the model correct a bad call itself instead of failing the whole turn.
**Approved**: pending

**Decision**: A `role` selector that no enabled entry holds falls back to the first enabled entry, but a `config` selector never falls back.
**Rationale**: The fallback makes an agent work as soon as any model is set up; a `config` selector names one entry on purpose, and the registry treats a disabled entry as out of service everywhere.
**Approved**: pending

**Decision**: The plugin is chosen on the first round and reused, and a provider that is not an HTTP provider with native tool support gets `PromptedToolCallingPlugin`.
**Rationale**: A subprocess provider never receives native tool definitions, and choosing once keeps a turn's rounds on one request shape.
**Approved**: pending

**Decision**: `toolPermissions`, `arrival` and `deadlineSeconds` are stored and returned but never enforced by the host.
**Rationale**: The definition's doc comments say they are enforced in a later phase, so phase 1 runs every tool the model asks for (the requirement is `policy-fields-not-enforced`).
**Approved**: pending

**Decision**: `runTool` reports activity only for mutating tools run in a session, and records nothing else.
**Rationale**: It serves a client of the host's handlers or its MCP bridge; the model's own view of a conversation is made only by turns, so a direct run must not add `tool_use` messages to it.
**Approved**: pending

**Decision**: A turn emits its terminal event before finishing the per-turn stream and clearing its running marker.
**Rationale**: Every consumer then sees the terminal event as the last one before the stream ends, and a `send` made after the stream ends does not meet a stale `turnInProgress`.
**Approved**: pending

**Decision**: The envelope carries no host-instance epoch; a client resets its `seq` tracking when it reconnects.
**Rationale**: Adding an epoch changes the wire format that clients already read; until that change is approved, the reset rule in `envelope-seq-memory-only` is how a client tells a restart from a repeat.
**Approved**: pending

**Decision**: This ingredient specifies the `AgentDefinition`, `AgentEvent`/`AgentEnvelope` and `AgentStore` contracts together with the host and does not split them into ingredients of their own.
**Rationale**: The host is the only producer of events and the only user of the store and definition in the SDK, the four types change together, and a split would put one behaviour across several ingredients with no second consumer to justify it; a split stays possible if another host appears.
**Approved**: pending
