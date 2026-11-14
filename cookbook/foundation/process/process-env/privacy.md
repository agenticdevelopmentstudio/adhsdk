
- **Data collected**: An OAuth credential (`CLAUDE_CODE_OAUTH_TOKEN`) read from a parent `claude` process's launch environment; the same call can read any variable of any same-user process.
- **Storage**: In memory only, in the pid-to-token cache, bounded to 128 entries and 30 seconds of use. Nothing is written to disk. The token is not revoked or refreshed here; it is whatever the `claude` process was started with.
- **Transmission**: This component does not transmit it; it returns it to the calling daemon or tool, which decides what to do with it.
- **Retention**: A negative result is also kept. An entry that is never read again is dropped when the cache goes over its ceiling, so a quiet daemon can hold the last few tokens past 30 seconds (see the `token-cache-ceiling` requirement).

