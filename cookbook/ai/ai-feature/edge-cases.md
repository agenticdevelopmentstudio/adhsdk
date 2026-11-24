
- **Unknown raw string**: the synthesized raw-value initializer MUST return nothing for any string other than "summarize" or "oversight", including the empty string and differently-cased spellings; the source adds no fallback case.
- **A new case added later**: the provider settings lookup sends every case other than `oversight` to the general reader, so a third case would silently use the general reader and be written to the log under its own raw value; the source documents no rule beyond that.
- **Null and empty input**: Not applicable — the type has no stored data and no optional input; a value is always one of two cases.
- **Boundary values**: Not applicable — a closed two-case set has no numeric or size boundary.
- **Concurrent access**: Not applicable as a hazard — the type is `Sendable` and immutable, so concurrent reads need no synchronization.
- **Error states and offline state**: Not applicable — the type performs no network, database or file-system call; the callers that do are described by the daemon AI chat component.

