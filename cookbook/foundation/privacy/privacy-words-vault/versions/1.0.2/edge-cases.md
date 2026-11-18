
- **Null / empty input**: Empty pairs saved leave the loaded filter with no pairs and the store removes the keychain item (see `PrivacyWordStore`'s `save-empty-removes`). Pairs with an empty side are dropped on load and on save (MUST).
- **Boundary values**: There is no limit on the number of pairs; whatever `TextSubstitutionFilter` accepts is kept.
- **Concurrent access**: `@MainActor` isolation serialises synchronous steps; calls overlapping across an `await` can interleave. Many simultaneous `loadUpgradingIfNeeded` calls share one prompt (MUST). Two overlapping `save` calls each authenticate separately and the later write wins (see the concurrency requirement).
- **Error states**: `load` and `loadUpgradingIfNeeded` throw store errors; `authenticate` and `save` throw authentication and store errors; the failed `save` leaves the previous in-memory filter in place. The reload after another app's save drops its error silently (see the pending Design Decision on reload failure).
- **Cross-process staleness**: A vault that has not loaded does not follow other apps' saves; its first `load` then reads the current item (MUST).
- **Notification from the same process**: A second vault in this same process, with the same store, ignores the post because the object is the shared process identifier; it keeps its old words until `authenticate` re-reads .
- **Upgrade failure**: When the upgrade prompt is refused, the error propagates to every awaiting caller and the pending upgrade is cleared so a later call prompts again (MUST).
- **Offline / disconnected state**: Not applicable: the vault performs no network access; announcements travel between processes on this Mac only.
- **Cancellation**: Not applicable: the vault has no cancel call; a cancelled `Task` is not checked by the vault itself, and a refused prompt surfaces as `authenticationFailed`.

