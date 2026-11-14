
**Decision**: `UserDefaults` is the storage for a host with no settings system of its own.
**Rationale**: The source comment names it the platform's own answer for exactly this case (`native-controls`) and says it spares each such host from rewriting the same short adapter.
**Approved**: pending

**Decision**: The keys `theme.custom_themes` and `theme.active_theme_id` and the JSON encoding match the host's own settings system.
**Rationale**: A host that later swaps this class for its own conformer finds the user's themes where this class left them. The source comment warns that changing either key orphans saved themes silently rather than noisily.
**Approved**: pending

**Decision**: External changes are detected by comparing stored values with last-seen values, not by a writing flag.
**Rationale**: The source comment explains that `UserDefaults.didChangeNotification` arrives on a later run loop turn, after a flag set and cleared around a synchronous write is back down, so every write would report itself and `ThemeManager` would reload the theme it had just applied. Value comparison also handles coalesced notifications and a foreign write of an unchanged value.
**Approved**: pending

**Decision**: The last-seen value is recorded before the write, never after.
**Rationale**: The source comment states the notification can be delivered synchronously when the post and the observer queue are both main, so a record made afterwards would arrive too late and the object would hear its own write.
**Approved**: pending

**Decision**: An undecodable stored blob reads as no themes rather than throwing.
**Rationale**: The source comment states there is nothing useful to do with an incompatible blob and that throwing would take the app down over a preference; an empty catalog still yields every built-in theme. The cost is that the corruption is invisible and the blob stays until overwritten.
**Approved**: pending

**Decision**: An encode failure on write is dropped and logged.
**Rationale**: The setter is non-throwing because the `ThemeStorage` protocol is, so the only signal available is a log line; leaving the stored catalog untouched keeps the last good state.
**Approved**: pending

**Decision**: The `observer` field is `nonisolated(unsafe)`.
**Rationale**: The source comment says it is written once in `init` and read once in `deinit`, so the nonisolated `deinit` cannot race it; `isolated deinit` would express this safely but needs macOS 15.4 or iOS 18.4.
**Approved**: pending

