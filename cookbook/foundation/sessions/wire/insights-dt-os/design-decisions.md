
**Decision**: Wire names come from the encoder's snake_case key strategy, not from per-type coding keys.
**Rationale**: Both file comments say "Snake-case JSON on the wire; camelCase Swift on this side", none of the thirteen types declares `CodingKeys`, and `RouteResponse.makeJSONEncoder` sets `convertToSnakeCase` for every route. One strategy keeps every field's name derivable; the cost is that a client decoding without the matching strategy fails on every multi-word key.
**Approved**: pending

**Decision**: `CacheMissCauseDTO.cause` is an open string rather than an enum.
**Rationale**: The doc comment: the set of causes "grows without notice, which is why it is stored opaquely ... and reported here as whatever was observed rather than as a fixed enum".
**Approved**: pending

**Decision**: Unattributed misses are counted in the totals but never priced.
**Rationale**: The `unattributedMisses` doc comment: a counter advance across a model or TTL change happened at an unknown rate; dropping it "would understate the miss rate", and pricing it at the arriving model's rate "overstated cost by ~8× on the capture DB". The cost is therefore a floor, and the three `unattributed*` fields tell a reader how large the unpriced slice is.
**Approved**: pending

**Decision**: `ttlKnown` is reported beside `ttl` instead of refusing to price an unknown TTL.
**Rationale**: The doc comment: an unknown spelling is priced at the API-default 1.25× premium "as a fallback, not as a measured rate", and "only this flag distinguishes that from a genuine 5-minute write", since a 1-hour entry under an unknown spelling is understated by 37.5%.
**Approved**: pending

**Decision**: `CacheMissesDTO` echoes `since` and reports `coverageStart` as strings with `""` sentinels.
**Rationale**: The report differences raw status-line events with no frozen rollup behind it, so retention can silently narrow any window; reporting where coverage begins "lets a caller tell 'no misses in that window' from 'no data left for it'" (the comment in `cacheMisses`). Empty strings, not optionals, keep both keys always present on the wire.
**Approved**: pending

**Decision**: Cache-miss counts are sums of observed increases, and a session's first tick counts nothing.
**Rationale**: The `CacheMissesDTO` doc comment: the status line re-renders cumulative counters on every tick, "so a row count is not a miss count", and a first tick's counters "describe misses that happened before this daemon was watching".
**Approved**: pending

**Decision**: Graph node ids are namespaced by kind (`session:`, `tool:`, `project:`), and `kind` and `status` are plain strings.
**Rationale**: The `GraphNodeDTO.id` doc comment: namespacing means "a session and a tool cannot collide" in one flat id space the JS renderer keys links by. Keeping `kind` and `status` as strings, with their values named only in doc comments, matches the rest of the file's open-string style; the cost is that the types cannot reject an unknown kind or status, which is why `node-kind-values` and `node-status-session` are producer guarantees.
**Approved**: pending

**Decision**: The graph snapshot is capped at 200 sessions even though the route accepts a `?limit=` up to 1000.
**Rationale**: The `graphSnapshot` doc comment: sessions are "Capped at 200 to keep the client-side force simulation interactive". The route's shared `boundedLimit(default: 100, max: 1000)` is applied first and the tighter clamp second, so a `limit` between 201 and 1000 is silently reduced; the snapshot reports no echo of the limit applied.
**Approved**: pending

