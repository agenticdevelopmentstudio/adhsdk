
**Decision**: Failures read as `nil` or `false` rather than throwing, with `summarize` as the exception.
**Rationale**: The source comment states the aim: a failed connection, a non-2xx reply or an undecodable body all mean "unreachable", so callers handle one case. `summarize` throws so the daemon's reason (a memory guard, a provider error) reaches the user instead of a generic failure.
**Approved**: pending

**Decision**: A 404 on a single session is `.some(nil)`, a real answer, not unreachable.
**Rationale**: The source comment names it as the one exception; callers need to tell "no such session" from "daemon down".
**Approved**: pending

**Decision**: `setAIPreferences` uses a default `JSONEncoder` instead of the wire encoder.
**Rationale**: The source comment states that `POST /preferences/ai` decodes the registry with a default `JSONDecoder`, so its keys stay camelCase.
**Approved**: pending

**Decision**: Timeouts are 605, 15 and 10 seconds by route.
**Rationale**: The source comment gives the reasons: a summary runs inline on the daemon for up to 600 seconds plus 5, the heavy reads can be slow on a cold cache, and everything else is a quick read.
**Approved**: pending

**Decision**: Reconnect is detected by an `uptime` that went down, polled every 30 seconds.
**Rationale**: The source comment states the daemon has no push channel to a client that is not an XPC subscriber, so polling `/health` is the only signal.
**Approved**: pending

**Decision**: The client does not retry or back off.
**Rationale**: The source has no retry; a failed call returns at once and the caller decides. The poll interval is the only repetition.
**Approved**: pending

