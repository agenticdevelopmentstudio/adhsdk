
- **No terminal to offer (MUST)**: The property returns nothing; the start then either starts one or returns nothing.
- **Selected session stopped (MUST)**: The terminal pane content returns nothing, even though a session exists, because only running sessions are offered.
- **Start cannot succeed (MUST)**: The start returns nothing or throws; a caller treats nothing as no terminal.
- **Concurrent access**: The contract is main-actor isolated; two overlapping starts are not coordinated here, and the Terminal Chat guards against that by refusing a second start while one is in flight.
- **Offline or disconnected state**: Not applicable: the contract is in-process and uses no network.
- **Null and empty input**: Not applicable beyond the nothing results above; the contract takes no arguments.
- **Boundary values**: Not applicable: no numeric or sized input.

