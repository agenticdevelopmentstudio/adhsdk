
- **Null / empty input**: A reply with neither field set is accepted and is not an error; a consumer that gets one has no summary and no reason, and SHOULD treat it like a transport failure and show its generic text. An empty `summary` or `error` string is a value, not nil.
- **Boundary values**: Not applicable: the fields are free text with no length limit in this type.
- **Concurrent access**: Not applicable: the type is an immutable `Sendable` value, safe to pass between tasks.
- **Error states**: A reply with an `error` is a daemon refusal or failure carried as data. A reply that cannot be encoded or decoded is the "transport or encoding failed" case and surfaces as a nil XPC reply, not as this type.
- **Offline / disconnected state**: Not applicable: the type performs no network access. A daemon that is down yields a nil reply, which is the transport case.
- **Producer scope**: Where the XPC service builds and returns this type is outside the sources given; no code in the repository references `SummarizeReplyDTO` apart from its own declaration and doc comment, which names `summarizeSession`. The in-repo path that carries the same information is HTTP: `StenographerHTTPClient.summarize` throws `SummarizeDaemonFailure` with the daemon's reason, and `StenographerSummarizing` shows it.

