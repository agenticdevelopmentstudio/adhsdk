
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| (none) | — | — | Portfolio Indicator takes no parameters. |
| `snapshot.freshness.state` | string (server-supplied) | absent reads as stale | The server's freshness verdict; only `"fresh"` leaves the snapshot trusted. |
| Board state | injected dependency | — | Supplies the board (or null); carries its own polling, retry and board staleness configuration. |
| Live Snapshot | injected dependency | — | Supplies `snapshot`, `offline` and `blind`; carries its own transport configuration. |
| Shared cache context and status API context | required context | — | Required by the two inputs; Portfolio Indicator must be used where they are available. |

