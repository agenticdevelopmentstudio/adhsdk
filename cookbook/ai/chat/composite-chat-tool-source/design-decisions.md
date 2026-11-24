
**Decision**: Routing re-queries every source's `toolDefinitions()` on each `callTool`, instead of caching a name-to-source map built once.
**Rationale**: The `ChatToolSource` contract describes definitions as the tools to advertise "for this turn", so a source's tool set may change between turns. A fresh lookup keeps routing in step with what each source currently advertises, at the cost of one definitions query per earlier source per call. A port that caches a map would route to stale tools.
**Approved**: pending

**Decision**: When two sources advertise the same name, the first source in the list wins every call, and the advertised list still contains both definitions.
**Rationale**: The source neither de-duplicates definitions nor rejects duplicates; the early return in the routing loop makes order the only tie-break. The model may see two tools of the same name while only one is reachable. Callers control the outcome by source order.
**Approved**: pending

**Decision**: An unknown tool is reported as a result tuple (`isError` true, content `unknown tool <name>`), not as a thrown error.
**Rationale**: `ChatToolSource.callTool` is non-throwing, and the result goes back to the model as text, so the model can read the failure and recover. The test `unknownToolIsASentence` fixes this behavior.
**Approved**: pending

**Decision**: The class is declared `@unchecked Sendable` although all stored state is an immutable array.
**Rationale**: `ChatToolSource` itself inherits `Sendable`, so the stored existentials are already `Sendable` and the unchecked declaration is not hiding a mutable field. It is recorded here because `@unchecked` disables compiler verification and a port that adds mutable state would lose the guarantee.
**Approved**: pending

