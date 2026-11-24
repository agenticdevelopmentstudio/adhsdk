
- **stats-fields**: A `DBStatsDTO` MUST carry `write` and `read`, each an array of `DBStatsDTO.Pool`.
- **stats-memberwise-init**: `DBStatsDTO.init(write:read:)` MUST set both arrays as given, with no default.
- **pool-fields**: A `DBStatsDTO.Pool` MUST carry `pool` (String), `inFlight` (Int), `completed` (Int), `evicted` (Int), `p50Ms` (Double) and `p99Ms` (Double).
- **pool-name**: `pool` SHOULD be the name of the lane the counters describe (the DTO accepts any string, see **no-validation**). Producer behavior, not enforced here: the daemon's `DaemonDatabase.dbStats()` fills `write` with the lane named `write` and `read` with the lane named `read`.
- **pool-counters**: `inFlight`, `completed` and `evicted` MUST be integer counters, one per lane: `inFlight` is the operations running now, `completed` the operations that finished within their deadline and `evicted` the operations ejected for exceeding it, which the daemon does not count as completed (producer behavior, not enforced here).
- **pool-latency-unit**: `p50Ms` and `p99Ms` MUST be milliseconds. Producer behavior, not enforced here: the daemon takes them over the most recent 128 completed operations of the lane and reports 0 for a lane with none.
- **pool-memberwise-init**: `Pool.init(pool:inFlight:completed:evicted:p50Ms:p99Ms:)` MUST set every field as given, with no default.
- **conformance-protocols**: `DBStatsDTO` and `DBStatsDTO.Pool` MUST be `Codable` and `Sendable`.
- **not-equatable**: `DBStatsDTO` and `Pool` need not be `Equatable`; the Swift source declares neither, and a port MAY compare fields explicitly.
- **no-validation**: The initializers MUST NOT validate: they accept negative counts, a p99 below the p50 and an empty pool name.
- **empty-arrays-encoded**: An empty `write` or `read` list MUST be carried as an empty array, never by omitting the key.
- **wire-keys**: The synthesized `Codable` MUST use the property names as JSON keys: `write`, `read`, `pool`, `inFlight`, `completed`, `evicted`, `p50Ms`, `p99Ms`.

