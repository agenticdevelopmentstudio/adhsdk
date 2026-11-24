
- Null and empty input: a missing or empty `settings.json` reads as an empty dictionary (MUST); an empty `statusLine` slot is replaced with no adoption (MUST); an empty `hooks` map after removal is dropped from the file (MUST).
- Malformed input: a `settings.json` that is not a JSON object makes install return `failed` and uninstall return false, with no write (MUST); a non-array value under an event type is skipped by uninstall and kept by the legacy pass (MUST).
- Boundary values: `lockTimeout` defaults to 5 seconds and the lock is polled every 50 ms; the capture-script check reads at most 4096 bytes (MUST).
- Concurrent access: two processes editing the file are serialised by the two `flock` locks taken in a fixed order, so two holders cannot deadlock; a holder that is stopped in a debugger makes others fail with `lockAcquireFailed` after the timeout instead of hanging (MUST).
- Error states: any thrown error in `installHooks()` or `uninstallHooks()` is logged and converted to `failed` or false, never thrown (MUST); `setStatusLineDisplay(_:)` and `modifySettings(_:)` throw to the caller (MUST).
- Foreign content: a foreign hook sharing a matcher group with a stale hook of this owner survives the rewrite (MUST); a foreign command that merely embeds the marker or the legacy `statusline.dispatcher` name as a substring is adopted, not dropped (MUST).
- Offline or disconnected state: not applicable; the installer touches only local files and makes no network calls.
- Status-line failure on install (no bundled dispatcher, unwritable `claudehelpers` directory, full disk): hooks are still installed and `statusLine` is left as it was (MUST).
- The `statusLineNotRegistered` message capitalizes the entry name, so an entry `adkd` reads "Adkd" (MUST, from `entry.capitalized`).
- `isStatusLineDisplayed` swallows a settings read error and reads false; it never throws (MUST).

