
- **Empty bucket list**: `alignToBuckets([], points)` MUST return `[]`, because nothing can match. Not a source-defined case in the tests; it follows from the length rule.
- **Empty points**: An empty iterable MUST give an all-zero array of the bucket length.
- **Timestamp on a bucket boundary but a different spelling**: Parsing then re-serialising MUST normalise it, so `"...T00:00:00Z"` and `"...T00:00:00.000Z"` agree.
- **Timestamp inside a bucket but off its start**: MUST be dropped. The module matches bucket starts exactly and has no rounding. A provider that returns finer-grained timestamps needs to truncate them first.
- **Unparseable or non-scalar timestamp**: `"nope"`, `null` and any value that is not a string or number MUST be skipped without an error.
- **Timestamp outside the window**: Points older than `since` or newer than the last bucket MUST be dropped.
- **Time of day exactly on an hour or day boundary**: For `"24h"`, a `nowMs` on the hour still yields 25 buckets, with the current hour as the last and zero elapsed time in it. For day ranges, a `nowMs` of 00:00:00.000 UTC makes that new day the last bucket.
- **Range outside the union**: Undefined behaviour: the module does not handle it, and a port MUST NOT copy what any one runtime happens to do. Callers MUST validate against `ANALYTICS_RANGES` first.
- **Invalid `nowMs`**: Undefined behaviour: a non-finite clock reading is outside the contract and is not validated. Callers pass `Date.now()` or a fixed test value.
- **Concurrent access**: Not applicable: both functions are synchronous and pure, JavaScript runs them without interleaving, and no state is shared.
- **Error states and offline**: Not applicable: the module does no I/O and has no dependency that can be unavailable. It has no defined error path.

