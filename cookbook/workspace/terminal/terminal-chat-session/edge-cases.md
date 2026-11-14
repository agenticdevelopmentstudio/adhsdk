
- **Null / empty input**: Empty text sends only a Return (MUST). Connecting to nil closes without dropping typed text (MUST). An empty wait returns "(no output)" (MUST).
- **Boundary values**: Settle is held to half of timeout (MUST); `lines` below 1 returns one line (MUST); unclaimed output above 64 KiB drops the oldest replies but keeps at least one (MUST).
- **Concurrent access**: Main-actor only. One wait at a time: a second ends the first with what it had (MUST). Two quick sends keep their order (MUST). An interrupt between a message's text and its Return drops the Return; an interrupt or a new connection drops messages not yet typed (MUST).
- **Error states**: A send with no terminal fails the turn, non-retryably (MUST). A shell that exits ends any wait with the exit text (MUST).
- **Offline / disconnected state**: Not applicable: the channel is a local terminal, not a network. The chat disconnected is the not-connected path.
- **Released session**: Queued input tasks hold the session weakly; one that outlives it still types its text and Return to the terminal it was sent to (MUST).
- **Echo of a private terminal**: The echoed line is taken as the terminal presents it, not as typed, because a private terminal may have changed it (MUST).
- **Interactive programs**: Tab completion, line editors and alternate-screen programs are not supported; see `alternate-screen`.

