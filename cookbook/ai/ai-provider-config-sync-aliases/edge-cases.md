
- **Null and empty input**: Not applicable — the aliases hold no data; empty configuration lists and absent selections are the Core types' behavior (see the synchronization recipe).
- **Boundary values**: Not applicable — the aliases have no constrained input.
- **A call site importing both frameworks**: it MUST see one type under two names; there is no ambiguity because an alias is not a distinct declaration.
- **A call site importing only Core**: it MUST still reach the types directly; the aliases are an addition for plugin-layer importers, not a replacement.
- **Removing the aliases later**: every `import AIPluginKit` call site naming either type would stop compiling; the source's comment says that is exactly what the aliases prevent.
- **Concurrent access**: Not applicable — the aliases are compile-time names; the aliased types are `Sendable`.
- **Error states and offline state**: Not applicable — the file performs no network, database or file-system call.

