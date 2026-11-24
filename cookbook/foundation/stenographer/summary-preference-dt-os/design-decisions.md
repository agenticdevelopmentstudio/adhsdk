
**Decision**: The app and the daemon read one file for defaults, ranges and keys.
**Rationale**: Both sides compile against the same constants, so the settings panel and the summarizer cannot drift and "Reset to Defaults" lands where a never-configured daemon already sits.
**Approved**: pending

**Decision**: A prompt that drops `{maxWords}` is sent as written, with no sentence appended.
**Rationale**: An explicit prompt is more predictable than a hidden sentence appended behind the user's back (the doc comment on `maxWordsPlaceholder` makes this choice); the cost is that the model is not told the cap, which still trims the reply.
**Approved**: pending

**Decision**: The word cap is told to the model and enforced on the reply.
**Rationale**: A small local model routinely overruns the cap (the doc comment on `SummaryDefaults.maxWords` says so), so asking is not enough.
**Approved**: pending

**Decision**: `characterCap(maxWords:)` is `max(80, maxWords * 10)` and lives with the defaults.
**Rationale**: The startup purge must use the same number (the doc comment on `characterCap(maxWords:)` says so); two literals could drift and a purge below the cap wipes fresh titles and re-queues them forever.
**Approved**: pending

**Decision**: Out-of-range values clamp to the nearest bound instead of being rejected.
**Rationale**: An out-of-range value (the doc comment on `SummaryLimits` names both cases) from an older app or a hand-rolled HTTP POST should land on a sane number rather than wedge the summarizer.
**Approved**: pending

**Decision**: The per-run and timeout defaults are gentle: 5 sessions per pass and 60 seconds per completion.
**Rationale**: A backlog should drain gently instead of bursting model calls, and a local model on a cold load needs more time than a cloud API.
**Approved**: pending

