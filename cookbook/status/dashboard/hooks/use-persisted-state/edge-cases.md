
- **Null and empty input**: a stored `null` MUST be passed to `decode`; the default `decodeBoolean` returns `undefined` for it and the value stays at its default. An empty stored string is invalid JSON and MUST keep the value, per hydrate-bad-json.
- **Boundary — missing and unrecognised data**: no entry, a value from an older build and a hand-edited value MUST all leave the value unchanged; the caller's `decode` is the only validation, so a `decode` that returns a wrongly shaped value is accepted as given.
- **Boundary — first write after a rejected hydration**: the first setter call writes over whatever unusable entry was in storage.
- **Boundary — key change**: a new key with no usable entry keeps the previous key's value in memory, and the next write goes to the new key, so the old key's value is carried across.
- **Concurrent access — same key, two uses**: two mounted uses of one key hold separate values and each write overwrites the last; the later write wins in storage and neither use sees the other until it re-reads. Another tab writing the same key is not observed.
- **Concurrent access — repeated update application**: when the environment applies an update function twice for the same input, the storage write runs twice with the same string; the result is the same.
- **Error states — storage blocked or full**: reads and writes MUST fail silently; the value still changes in memory and is lost on reload. No error is surfaced to the caller or logged.
- **Error states — caller's updater throws**: the state does not catch it, because the updater runs outside the guarded block, and no write happens for that call.
- **Error states — unserialisable value**: `JSON.stringify` of a value `encode` leaves unserialisable (a circular object, a `BigInt`) throws inside the guarded write and is ignored; the value is kept in memory only. An encoded value of `undefined` makes `JSON.stringify` return `undefined`, which local storage stores as the text `undefined`; that text is not valid JSON, so the next hydration keeps the default.
- **Offline or disconnected state**: not applicable — the state reads and writes only the browser's local storage and has no network dependency.
- **Cancellation and timeouts**: not applicable — every operation is synchronous.
- **Server rendering**: storage is read only inside an effect, so a server render never touches storage and always renders `initial`.

