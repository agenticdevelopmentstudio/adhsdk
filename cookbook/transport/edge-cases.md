
- **`transport: nil` passed to `daemon(port:transport:)`** (null/empty
  input — MUST): the default path MUST build a fresh
  `makeDaemonURLSessionTransport()` rather than reusing any transport
  instance from a prior call — each call that omits `transport` gets its own
  `URLSession`.
- **Malformed or out-of-range `port`** (boundary values): `daemonURL(port:)`
  and `healthURL(port:)` build their URL via
  `URL(string: "http://127.0.0.1:\(port)")!`, force-unwrapping the result;
  `port` is an unconstrained `Int` accepted by `TransportResolver.init`,
  `APITransport.daemon(port:)`, and `fromUserDefaults(port:)` alike, with no
  range or sign check anywhere in the given sources — see the open question
  on port-validation.
- **port-validation**: NEEDS REVIEW: Not implemented in source. No range or sign check on `port` guards the force-unwrapped `URL(string: "http://127.0.0.1:\(port)")!` in `daemonURL(port:)`/`healthURL(port:)`, so a negative or larger-than-`65535` port crashes rather than returning an error the caller can handle; `TransportResolverTests.swift` has no test for an out-of-range port, so nothing in the given sources defines the intended failure mode — resolvable by whoever decides whether an invalid port should throw, precondition, or stay an undocumented caller contract.
- **`probeTimeout <= 0`** (boundary values): `TransportResolver.init` and
  the production probe pass `probeTimeout` straight through to
  `URLSessionConfiguration.timeoutIntervalForRequest`/
  `timeoutIntervalForResource` with no validation; the given sources define
  no minimum, so the resulting behavior for a non-positive timeout is
  whatever `URLSession` itself does with that value — not defined in
  `TransportResolver.swift`.
- **Two `resolve()` calls racing before either has cached a decision**
  (concurrent access): `resolve()`'s cache check
  (`if let cached { return cached }`) happens synchronously, but the
  `await reresolve()` it falls through to is a suspension point; because
  `TransportResolver` is a (reentrant) actor, two overlapping first-time
  `resolve()` calls can each observe `cached == nil` before either has
  written a result, so each independently calls `reresolve()` and launches
  its own probe rather than sharing one in flight — see the open question
  on concurrent-resolve.
- **concurrent-resolve**: NEEDS REVIEW: Not implemented in source. No in-flight decision (e.g. a stored `Task<TransportKind, Never>` a second caller awaits instead of re-probing) coalesces concurrent first-time `resolve()` calls into a single probe and cache write; `TransportResolverTests.swift` exercises only sequential `resolve()` calls, so nothing in the given sources shows an intended de-duplication rule — resolvable by whoever adds a concurrent-resolve test and, if the duplicate probing is undesired, an in-flight cache.
- **Two `reresolve()` calls racing** (concurrent access — MUST, not a gap):
  the same reentrancy applies to `reresolve()`, but it is not a gap there —
  `reresolve()`'s own contract ("probe again and replace the cached
  decision") never claims exclusivity between overlapping calls, unlike
  `resolve()`'s cache-reuse promise. Two overlapping `reresolve()` calls
  MUST each run the override/probe decision independently, and whichever
  finishes last MUST be the value left in `cached` (last-write-wins).
- **Daemon reachable but returns a non-`200` status** (error state — MUST):
  the probe treats any non-`200` status (`404`, `500`, etc.) exactly like a
  thrown error or timeout — indistinguishably folded into `false` — so
  `.auto` MUST resolve `.direct` in every non-`200` case, per
  probe-success-is-status-200-only/probe-failure-collapses-to-false; this is
  expected behavior, not a gap, since the source draws no distinction
  between "reachable but unhealthy" and "unreachable."
- **Daemon unreachable, connection refused, DNS failure, or probe timeout**
  (offline/disconnected — MUST): all four collapse to the same `false`
  outcome via the probe's `catch`, per probe-failure-collapses-to-false;
  `.auto` MUST resolve `.direct`. Per the source's own doc comment on
  `TransportResolver`, "Direct is the guaranteed fallback, so the client
  always works." No retry or backoff is attempted by the probe itself; a
  caller that wants the daemon re-checked later MUST call `reresolve()`
  again.
- **Cancellation of the surrounding `Task` during a probe** (MUST): the
  given sources define no explicit cancellation handling in
  `TransportResolver`; Swift's standard cooperative cancellation propagates
  to the awaited `session.data(for:)` call inside the probe closure, which
  is caught by the probe's own `catch` and folded into `false` like any
  other thrown error — the resolver never distinguishes "cancelled" from
  "network failure."

