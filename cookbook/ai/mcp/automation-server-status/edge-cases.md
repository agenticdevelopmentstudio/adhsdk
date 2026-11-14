
- **Nil values**: With every value nil or false the model reports `Starting.` and a nil `url`. MUST.
- **Boundary ports**: `UInt16` bounds the port to 0 through 65535. Port 0 is accepted and reported as listening on port 0, and 65535 formats as `65535`. MUST.
- **Failure with a port set**: A non-nil `failureReason` wins over a set `port` in `line` but not in `url`, so a stale port can leave `line` reporting failure while `url` still returns a URL. The host is responsible for clearing the port on failure. MUST.
- **Empty failure reason**: An empty string is still non-nil, so `line` is `Not running: ` with nothing after the colon-space. MUST.
- **Token handling**: A nil token is valid, and a token is never included in `line` or `url`. MUST.
- **Concurrent access**: The type is `@MainActor`, so the compiler keeps all access on the main actor; callers off the main actor must hop to it, and the static `line` function needs no isolation. MUST.
- **Value ordering**: `@Published` publishes the new value before the property changes, so an observer reading `self.line` inside the sink sees the old values; it must call the static `line` with the published value. MUST.
- **Error states, offline state and timeouts**: Not applicable — the component performs no I/O; failures are recorded by the host in `failureReason`.

