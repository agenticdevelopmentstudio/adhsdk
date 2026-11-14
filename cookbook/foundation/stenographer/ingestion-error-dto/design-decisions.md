
**Decision**: The live file and the log row are separate shapes.
**Rationale**: The source states the log row, unlike `IngestionErrorDTO` (a live file still on disk), includes resolved history, so `status` and `resolvedAt` exist only on the log.
**Approved**: pending

**Decision**: An empty drop file is the status `lost`, recorded once and never retried.
**Rationale**: The source states its event is gone, so retrying cannot help and counting it would inflate live failures.
**Approved**: pending

**Decision**: Retry All runs asynchronously and is observed through `RetryProgressDTO`.
**Rationale**: The source states it runs off the XPC and HTTP reply thread so that a large backlog cannot time the caller out.
**Approved**: pending

**Decision**: `status` is a String and not an enum.
**Rationale**: The source types it String and lists five values in a comment; a new value decodes without a shape change, at the cost of no compile-time check; a client parses `status` at the boundary into its own enum with an `unknown` case.
**Approved**: pending

