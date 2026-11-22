
- **Nil tool**: `mostUsedTool == nil` MUST encode with the key omitted and decode back to `nil` (vectors 002, 003).
- **Nil node status**: `GraphNodeDTO.status == nil` MUST encode with the key omitted and decode back to `nil` (vectors 027, 028).
- **Missing required key**: Decoding MUST fail on a missing non-optional key; the types have no defaults (vectors 004, 029).
- **Unknown extra keys**: Decoding MUST ignore keys the type does not declare, which is the default behavior of synthesized decoding.
- **Empty collections**: `byType == [:]`, `causes == []`, `models == []`, `systemPromptDeltas == []`, `nodes == []` and `links == []` MUST encode as `{}` or `[]` and decode back; the empty `CacheMissesDTO` the producer returns for no store or an unparseable `since` has all three arrays empty and every number `0`, and the empty `GraphSnapshotDTO` has both arrays empty (vector 030).
- **Empty strings as sentinels**: `CacheMissesDTO.since == ""` MUST mean the whole history, `coverageStart == ""` MUST mean no tick on disk, and `CacheMissModelDTO.ttl == ""` MUST mean the TTL was unreported. They are strings, not optionals, so a port MUST keep the empty-string sentinel rather than map it to `null`.
- **Session with a null status**: A session node MUST carry `status == ""`, not `nil`, when the stored `sessions.status` is null, because the producer reads the column with a `""` default; a consumer SHOULD treat `""` as an unknown status, since the doc comment names only `"active"`, `"idle"` and `"ended"`.
- **Session with no events or no project**: A session node MUST still appear with `weight == 0` when the event store holds no Claude events for it, and with no project link when its `cwd` yields an empty or `"/"` component (vector 034).
- **Division by zero**: `missRate` MUST be `0`, never `NaN`, when `requests == 0` (vector 012).
- **Boundary values**: Counts are `Int` and costs `Double`; the initializers MUST NOT clamp or reject negative or out-of-range values (vectors 022, 037). The producers' `limit` is clamped to 1 to 100 before `models`, `causes` and `systemPromptDeltas` are filled, so each list holds at most 100 entries from `/insights/cache-misses`; `graphSnapshot` clamps its `limit` to 1 to 200 sessions, so a `?limit=` above 200 MUST yield at most 200 session nodes (vector 035).
- **Truncated list**: When `models` is cut at `limit`, the totals MUST still cover every group (`misses-totals-whole`).
- **Cause histogram short of total**: `causes` MUST be allowed to sum to less than `misses`; a cause first seen on a session's first tick is not counted.
- **Malformed `day`**: The types MUST store any `day` string unchanged; the `YYYY-MM-DD` format is a producer guarantee, not a decode check.
- **Dangling link or unknown kind**: The graph types MUST accept a link whose endpoint matches no node and a `kind` outside the three named values; referential integrity and the kind set are producer guarantees (`graph-referential`, `node-kind-values`), so a consumer rendering a decoded snapshot SHOULD skip a link whose endpoint it cannot find rather than fail, because nothing in the types prevents one.
- **Unstable order**: Tool nodes, project nodes and links MUST be allowed to arrive in a different order on each call with the same data; the producer builds them from unordered dictionaries.
- **Concurrent access**: Not applicable as a hazard: every type is an immutable `Sendable` value, so concurrent reads are safe and there is nothing to write.
- **Errors and offline**: Not applicable: the types do no I/O and throw only what the JSON decoder throws on malformed input; database failures belong to the producers (`graphSnapshot` rethrows, and `UsageRoutes` answers with `.failure`) and network failures to the client.

