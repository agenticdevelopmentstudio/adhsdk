
Type and isolation

- **protocol-conformance**: `UserDefaultsThemeStorage` MUST conform to `ThemeStorage`, exposing `customThemes`, `activeThemeID` and `onExternalChange` as read-write properties.
- **main-actor**: The type MUST be `@MainActor` and a `final class`, so every read, write and the `onExternalChange` callback run on the main actor.
- **no-sendable**: The type MUST NOT be shared across actors; it is main-actor state, is not explicitly declared `Sendable`, and main-actor isolation is what keeps it in its domain.

Storage keys

- **key-custom-themes**: The custom themes MUST be stored under the key `theme.custom_themes`, exposed as `UserDefaultsThemeStorage.Key.customThemes`.
- **key-active-theme-id**: The active theme id MUST be stored under the key `theme.active_theme_id`, exposed as `UserDefaultsThemeStorage.Key.activeThemeID`.
- **keys-load-bearing**: The two key strings MUST NOT change. The source comment states that changing either orphans already-saved themes silently, and that they match the keys the host writes through its own settings system.

Initialization

- **init-defaults-parameter**: `init(defaults:)` MUST accept the `UserDefaults` instance to persist into and MUST default it to `UserDefaults.standard`. The doc comment says a host with an app group passes its shared suite.
- **init-snapshot**: `init` MUST record the current stored custom-themes data and active theme id as the last-seen values before observing, so values already on disk at construction do not report as a change.
- **init-observer**: `init` MUST register one observer for `UserDefaults.didChangeNotification` scoped to the given `defaults` object and delivered on the main queue.
- **deinit-removes-observer**: `deinit` MUST remove that observer from the default notification center.

customThemes

- **themes-read-empty-when-absent**: Reading `customThemes` MUST return an empty array when no data is stored under `theme.custom_themes`.
- **themes-read-decode**: Reading `customThemes` MUST decode the stored data as a JSON array of `ColorTheme` with a default `JSONDecoder` and return it in stored order.
- **themes-read-corrupt**: Reading `customThemes` MUST return an empty array, not throw or trap, when the stored data does not decode, and MUST log the decode error at error level. The source comment states that a stored blob of an incompatible shape is treated as no themes because there is nothing useful to do with it and throwing would take the app down over a preference. The corrupt blob is left in place; nothing deletes or repairs it.
- **themes-write-encode**: Writing `customThemes` MUST encode the array as JSON with a default `JSONEncoder` and store the resulting `Data` under `theme.custom_themes`.
- **themes-write-records-first**: Writing `customThemes` MUST record the encoded data as the last-seen themes before it calls the `UserDefaults` write, never after. The source comment states `UserDefaults` can deliver its change notification synchronously when the post and the observer queue are both the main queue, so a record made afterwards would arrive too late and the object would hear its own write.
- **themes-write-empty**: Writing an empty array MUST store the JSON text `[]`, so the key is present afterwards; it does not remove the key.
- **encode-failure**: When encoding `customThemes` fails, the setter MUST log the error at error level and return without writing, so the previous stored value and last-seen record stay. The caller is not told; the setter is non-throwing.

activeThemeID

- **active-read**: Reading `activeThemeID` MUST return the string stored under `theme.active_theme_id`, or nil when none is stored (the `ThemeStorage` comment: nil means none has ever been chosen).
- **active-write**: Writing `activeThemeID` MUST store the value under `theme.active_theme_id`.
- **active-write-nil-clears**: Writing nil MUST clear the stored value, so a later read, including from a new instance over the same domain, returns nil. This is the behavior of `UserDefaults.set(nil, forKey:)`.
- **active-write-records-first**: Writing `activeThemeID` MUST record the new value as the last-seen active id before the `UserDefaults` write, for the same reason as `themes-write-records-first`.
- **active-no-validation**: The setter MUST NOT check that the id names an existing theme; it stores whatever string it is given. Resolving an unknown id is the caller's job.

External-change detection

- **external-compare-values**: The observer callback MUST compare the currently stored themes data and active id with the last-seen values, and MUST invoke `onExternalChange` only when either differs. The source comment rejects a boolean "I am writing" flag because the notification arrives on a later run loop turn, after such a flag has been cleared, so every write would report itself and `ThemeManager` would reload the theme it had just applied.
- **external-update-last-seen**: When a difference is found, the object MUST update both last-seen values to the current stored values before invoking `onExternalChange`, so one foreign write fires the callback once.
- **external-coalesce**: When several writes are followed by one notification, the object MUST fire at most once. The source comment says comparing values gets the coalesced case right.
- **external-same-value**: A foreign write that stores the value this object already had MUST NOT fire the callback; the source comment calls that "genuinely not a change".
- **external-own-writes-silent**: Writes made through this object's own setters MUST NOT fire `onExternalChange`.
- **external-nil-callback**: With `onExternalChange` nil, a detected foreign change MUST update the last-seen values and do nothing else.
- **external-main-actor**: The callback MUST run on the main actor. The observer is delivered on the main queue and enters the main actor with `MainActor.assumeIsolated`; the observer holds `self` weakly, so a notification arriving after the object is released does nothing.
- **external-read-through**: After a foreign write, the getters MUST return the foreign value, because they read `UserDefaults` on every access and keep no cache of the themes or the id.
- **notification-granularity**: The observer MUST react to every `UserDefaults.didChangeNotification` for its domain, including changes to unrelated keys, and rely on the value comparison to filter them; a change to an unrelated key therefore does not fire the callback.
- **multiple-instances**: Two instances over the same `UserDefaults` domain each treat the other's writes as external, because each keeps its own last-seen values.

Persistence and side effects

- **persistence-medium**: Everything is persisted through `UserDefaults` set and get calls; the class never calls `synchronize()`, never touches the file system directly and never uses the network. Durability and flush timing are whatever `UserDefaults` provides.
- **cloud-and-suite**: Changes arriving from a shared suite or an iCloud-backed sync reach this object only through `UserDefaults.didChangeNotification`; the class has no sync code of its own.
- **failure-logging**: The class MUST log through `Loggable` (its own `logger`) on exactly two paths, a decode failure on read and an encode failure on write; it logs nothing else.

Deinit isolation

- **observer-unsafe-field**: The `observer` field is `nonisolated(unsafe)`: it is assigned once in `init`, read once in `deinit` and never touched between, so the nonisolated `deinit` cannot race it. The source comment says `isolated deinit` would state this in the type system but needs macOS 15.4 or iOS 18.4.

