
- **No data yet**: Before either feed has answered (`snapshot: null`, `board: null`), `pillKey` MUST be `"unknown"` and `count` MUST be `0`; without this the pill would render a false green "operational" off nothing before the first read lands.
- **Board present, snapshot not yet read**: With a non-null board and `snapshot: null`, Portfolio Indicator MUST return the board's mapped verdict, since a null snapshot is neither offline, blind nor stale.
- **Zero-endpoint monitor**: A snapshot with an empty `services` list sets `blind`, so `pillKey` MUST be `"unknown"` even if the board reports `"operational"`.
- **Zero problems**: A non-null board with an empty `problems` array MUST yield `count` `0`; the colour still comes from `board.indicator`, not from the count.
- **Unknown with a count**: When the live feed is offline, blind or stale but the board is current, Portfolio Indicator MUST return `"unknown"` together with the board's non-zero problem count; callers that print a number next to an unknown glyph see the board's count.
- **Snapshot without a freshness verdict**: A snapshot from an older backend with no `freshness` field MUST read as stale, so `pillKey` is `"unknown"`, and MUST NOT throw (portfolio-011).
- **Client clock skew or sleeping tab**: The snapshot verdict MUST be unaffected, since it is the server's verdict and the client computes nothing from time. The board staleness verdict applied inside the board state is that state's own contract, not this one's.
- **Unmapped indicator**: A `board.indicator` value outside `"operational"`, `"degraded"` or `"outage"` is excluded by the board's declared shape; Portfolio Indicator does no runtime check and would return an undefined `pillKey`. The board shape is owned by the server.
- **Network failure or unreachable server**: Portfolio Indicator MUST NOT handle transport errors itself; a failed board read surfaces as a null board from the board state and a dead live feed surfaces as `offline` true from Live Snapshot, and both MUST yield `"unknown"`.
- **Timeouts, cancellation and retries**: Portfolio Indicator has none; any timeout, retry or cancellation belongs to the board state and Live Snapshot.
- **Concurrent calls**: Multiple callers MAY use Portfolio Indicator at once; each derives independently from the same shared cache and live store, so callers sharing one cache context MUST see the same verdict at the same evaluation. Execution is single-threaded, so there is no interleaving within Portfolio Indicator.

