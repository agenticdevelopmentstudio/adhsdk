
- **Empty lists**: a daemon with no write or no read lanes returns an empty array; the shape carries it as an empty array, not an omitted key (see **empty-arrays-encoded**).
- **Missing key**: a payload without `write` or `read` fails to decode, because neither is optional.
- **Boundary values**: counters and latencies are unbounded here; zero, negative and very large values all construct, and the source states no range.
- **Unit mixups**: the field names carry `Ms`; a client MUST read the latencies as milliseconds and not scale them.
- **Lane with no completed work**: the daemon reports `p50Ms` and `p99Ms` of 0 for a lane that has completed nothing, so 0 is not a measured latency.
- **Concurrent access**: both types are immutable `Sendable` values, so a snapshot is safe to share across threads; the counters are a point-in-time snapshot taken by the daemon.
- **Error and offline states**: the type performs no I/O; an unreachable daemon is the client's failure, not this shape's.

