
`GmailQuotaPacer` is a public Swift `actor` that keeps Gmail API calls under Google's per-user quota of 15,000 units a minute, which Google enforces as a moving average of about 250 units a second. A caller asks it to `reserve` the quota cost of a call before sending the call, and the pacer returns how long the caller must wait first. The pacer never sleeps and never sends anything itself; the caller performs the wait.

The arithmetic is the generic cell rate algorithm. The pacer keeps one value, `drainedAt`, the instant when every unit reserved so far would have drained at `unitsPerSecond`. A call waits only for the part of that backlog which lies beyond the burst allowance, so the first `burstUnits` units go out back to back and later calls are spaced to the configured average rate.

The same file holds `GmailQuotaCost`, an internal `enum` of `static let` constants giving each Gmail call's cost in units, taken from Google's published quota table. `GmailRESTClient` is the consumer: every request attempt, retries included, reserves its cost, sleeps for any returned wait, and then sends. The REST client, its retry and backoff policy and the Gmail response types are separate components.

