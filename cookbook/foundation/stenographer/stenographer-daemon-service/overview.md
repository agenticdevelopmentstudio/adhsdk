
`StenographerDaemonService` is the one injectable seam through which the moved Stenographer windows (sessions, conversations, oversight findings and scripts, the AI log, preference panes) ask the stenographer daemon for data. The production implementation is `StenographerHTTPClient` over the daemon's loopback HTTP API; tests hand the windows a stub. The file holds the protocol, the default-argument convenience overloads in a protocol extension, `SummarizeDaemonFailure` (the daemon declined to summarize and said why) and `DaemonProviderConfig` (one row of the daemon's saved provider list).

The protocol is the contract that matters: what each operation asks, what it answers, and what "the daemon could not be reached" looks like to a caller. The routes, query spelling, timeouts and reconnect polling belong to the implementation and are described under Platform Notes and Edge Cases only where a conforming port must match them.

