
**Decision**: Unreachable reads answer nil and writes answer false or nil, instead of throwing.
**Rationale**: The type comment gives the reason: callers keep what is on screen when the daemon is down. The cost is that a caller cannot tell an unreachable daemon from a refusal or an undecodable body; only `summarize` and `actOnOversightFinding` surface a reason.
**Approved**: pending

**Decision**: `session(id:includeCounts:)` returns `SessionDTO??`.
**Rationale**: One type carries two distinct answers, unreachable (outer nil) and not found (inner nil). A port without nested optionals should use a three-case result.
**Approved**: pending

**Decision**: `summarize` throws while every other operation answers nil or false.
**Rationale**: A refusal has a reason the list can show (a memory guard, a provider error), so `SummarizeDaemonFailure` is distinct from a transport error. The act operation instead answers a result value carrying the reason. Examples of a reason from the source documentation are a memory guard or a provider error.
**Approved**: pending

**Decision**: `setAIPreferences` is sent with camelCase keys while all other bodies are snake_case.
**Rationale**: The daemon's `POST /preferences/ai` decodes the registry with a default `JSONDecoder`. The wire definition is otherwise one dialect, so this is the documented exception; the implementation's comment and a test assert it.
**Approved**: pending

**Decision**: Reconnect is detected by polling `/health` and watching uptime fall, not by a push.
**Rationale**: The daemon has no push channel to a client that is not an XPC subscriber. A restart that reaches a higher uptime than the previous poll between polls is not detected; that is the cost of the approach.
**Approved**: pending

**Decision**: The default-argument overloads live in a protocol extension rather than in the requirement list.
**Rationale**: Conforming types implement only the full operations; the convenience forms (200-row limits, `includeCounts` true, nil status) stay identical everywhere and a stub cannot drift from the defaults.
**Approved**: pending

**Decision**: The implementation discards decode errors and non-2xx statuses and writes no log or signpost when it maps them to nil or false.
**Rationale**: The source has no logging in the protocol or the HTTP implementation, and the type comment documents the collapse to "unreachable" as deliberate. The cost is that schema drift between client and daemon looks exactly like a daemon that is down, with no trace anywhere; only `summarize` and `actOnOversightFinding` surface a reason. A port that wants diagnosability can log at debug level without changing any contract here.
**Approved**: pending
