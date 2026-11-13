
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `unitsPerSecond` | `Double` | none; `shared` uses 200 | Average rate the pacer allows. Must be greater than 0. Google's own limit is about 250. |
| `burstUnits` | `Double` | none; `shared` uses 200 | Units that may go out back to back before spacing starts. Must be 0 or greater. |
| `now` | `@Sendable () -> ContinuousClock.Instant` | `ContinuousClock.now` | The clock; injected so tests control time. |
| `units` (argument to `reserve`) | `Int` | none | Quota cost of the next call; callers pass a `GmailQuotaCost` constant. |

There are no environment variables or settings keys. [GmailRESTClient](cookbook:c448c9f4-195d-4625-a49d-22dd5468a914) takes the pacer as an initializer parameter that defaults to `GmailQuotaPacer.shared`, and its tests pass their own pacer with a very high rate (1,000,000 units a second and burst) to switch pacing off.

