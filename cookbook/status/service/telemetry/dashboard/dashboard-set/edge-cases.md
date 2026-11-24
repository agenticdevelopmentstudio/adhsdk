
- With every provider unconfigured, both dashboards answer with empty sections and never fail; this is the normal state of a fresh deployment.
- A section whose loader throws keeps its previous `data` and gains an `error`; stale data stays on screen (behavior of the underlying cache).
- A cold dashboard answers with empty sections and `refreshing` true on the first read; the data arrives on later reads.
- `analytics` stamps `generatedAt` from the clock, not from an injected time; only `errors` takes a `nowMs`.
- The runtime read can throw on a store fault; the error is carried in the section and the call still resolves.
- A `settle` on a key never read resolves true, because nothing is in flight.
- The `analytics` memo is kept per range, so a range's views are not shared with another range, and the map is created for every key of `ANALYTICS_RANGES` up front.
- Section state lives for the life of the process, so keys must come from a closed list; the set only uses the three ranges and `all` (the one key of the GlitchTip and sites caches, which hold no per-range state), and nothing caller-supplied.

