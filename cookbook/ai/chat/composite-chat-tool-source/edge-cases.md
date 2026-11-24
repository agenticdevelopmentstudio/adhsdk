
- **Empty source list**: The composite MUST return no definitions and answer every call with `unknown tool <name>`. MUST.
- **Empty or unknown name**: A name matching no definition, including the empty string, MUST produce `unknown tool <name>` with `isError` true; for the empty string the content is `unknown tool ` with a trailing space. MUST.
- **Duplicate names across sources**: The earlier source wins for calls; the advertised list still shows both definitions to the model. MUST.
- **Definitions changing between listing and call**: A tool advertised in an earlier `toolDefinitions()` result but no longer advertised at call time MUST be answered with `unknown tool <name>`, because routing re-queries. MUST.
- **Boundary arguments**: `argumentsJSON` of any content, including empty `Data`, is forwarded unparsed and unvalidated; the chosen source owns validation. MUST.
- **Concurrent access**: Concurrent `toolDefinitions()` and `callTool` calls on one composite MUST NOT interfere through the composite, since it holds only an immutable array; ordering and safety among calls into a wrapped source belong to that source.
- **Error states**: The composite has no dependency of its own that can fail. A wrapped source reports failure by returning `isError` true, which passes through unchanged; the composite itself reports only the unknown-tool case. MUST.
- **Offline or disconnected state**: Not applicable — the composite performs no networking; connectivity behavior belongs to the wrapped sources.
- **Cancellation and timeout**: The composite has none; cancellation of the surrounding task reaches the awaited source calls only as far as those sources honor it.

