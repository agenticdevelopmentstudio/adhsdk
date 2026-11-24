
`DBStatsDTO` is the payload of a daemon's database-stats endpoint: per-lane bounded-execution counters. It holds two lists of `DBStatsDTO.Pool`, one for write lanes and one for read lanes. Each `Pool` names a pool and gives its in-flight, completed and evicted counts and its p50 and p99 latency in milliseconds. The type is a plain value; the daemon fills it and a client reads it. The daemon's `DaemonDatabase.dbStats()` fills it from its bounded database executor and serves it at `GET /db/stats`; the counting and timing live in that executor, outside this file.

