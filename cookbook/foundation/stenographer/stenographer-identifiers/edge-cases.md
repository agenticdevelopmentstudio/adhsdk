
- **Null / empty input**: `subsystem("")` returns the label plus a trailing dot; the suffix is not validated. `writeSupportFile(named: "")` writes to the support directory itself; the name is not validated. `attempts` of 0 or less is raised to 1.
- **Boundary values**: `attempts` has no upper bound; a directory that moves on every resolution makes `writeSupportFile` run the closure `attempts` times and return the URL resolved after the last write (a location the closure never wrote to), with no error. The ports are fixed constants and the type does not check that they are free.
- **Concurrent access**: `StenographerPaths` is `Sendable` and holds only immutable values, so it may be shared across tasks. The file system under it is not serialised: the daemon may migrate the legacy directory at any moment, which `writeSupportFile` handles by re-resolving after each write, but a write that races a migration more than `attempts` times can still land in a directory the next read does not look in.
- **Error states**: No property throws or returns an optional. `writeSupportFile` rethrows the closure's error. A directory that is missing is not an error; resolution falls through to the current directory.
- **Empty current logs directory**: Unlike `supportDirectory`, `logsDirectory` checks no sentinel file. An existing empty current logs directory hides a populated legacy one, and `logsDirectory` returns the current directory.
- **Offline / disconnected state**: Not applicable: the types perform no network access; the base URLs are strings naming the loopback address.
- **Existing empty current directory**: An empty current directory next to a populated legacy one resolves to the legacy one, so a user's real data is never hidden.

