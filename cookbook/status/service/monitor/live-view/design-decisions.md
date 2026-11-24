
- **Decision**: Compute the verdicts on the server and publish them on `/live` beside the raw facts.
  **Rationale**: Stated in the source comment: the dashboard "reads a verdict instead of re-deriving one from the facts with its own copy of the rule", and the rules move off the browser's clock onto the snapshot's own `generatedAt`.
  **Approved**: pending
- **Decision**: Judge freshness as data clock versus read clock, and read fresh when a clock is missing, unparseable or negative.
  **Rationale**: Stated in the doc comment: a wedged poller keeps a fresh `generatedAt` over frozen probes; no probe yet means a brand-new monitor; "a NaN must never raise a banner".
  **Approved**: pending
- **Decision**: Scale both freshness and unconfirmed windows to 5 times the probe cadence, with floors of 5 and 10 minutes.
  **Rationale**: Stated in the doc comments: the freshness floor means "a fast cadence does not alarm on one slow cycle"; the unconfirmed window means "a slower poller must not demote a phase it confirms on its normal schedule".
  **Approved**: pending
- **Decision**: Fail closed for an in-flight deploy with an unparseable clock.
  **Rationale**: Stated in the doc comment: such a deploy "is not believed, rather than asserting live progress on a date nothing can read".
  **Approved**: pending
- **Decision**: Publish `unconfirmedAt` so a display can demote a stale in-flight phase on its own clock.
  **Rationale**: Stated in the doc comment: a client can keep showing a snapshot after the monitor or stream stalls while it still looks connected.
  **Approved**: pending
- **Decision**: Select stale monitors by down duration only, never by DNS result.
  **Rationale**: Stated in the doc comment: "DNS decides nothing: a host that still resolves can be gone"; `dnsOk` is carried through as information.
  **Approved**: pending
- **Decision**: `staleMonitorsView` always uses the default threshold and reports `thresholdDays` from the constant.
  **Rationale**: Stated in the doc comment so the banner can state the number "without owning the number". A caller wanting another threshold must call `selectStaleMonitors` directly; recorded as the code's behavior.
  **Approved**: pending

- **Decision**: `detail` is a fixed English string (`"HTTP <statusCode>"` or `"down"`), not structured data.
  **Rationale**: The doc comment on `StaleMonitor.detail` says only "what the probe last saw: its error, else the status code, else 'down'"; the source gives no reason for building text in a verdict module. A structured `{ kind, value }` that status-web formats would let it be localized, and is the alternative to weigh. Recorded as the code's behavior.
  **Approved**: pending
