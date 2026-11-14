
### Setting declaration

- **setting-key-name**: The setting MUST be stored under the key name `file_browser.excluded_patterns`.
- **setting-value-type**: The setting's value type MUST be an ordered list of strings.
- **setting-default-empty**: The setting's default value MUST be the empty list.
- **setting-not-secure**: The setting MUST NOT be marked secure, so it is routed to the plain (non-secret) backing store; the declaration passes no secure flag and the generic setting type defaults it to false.
- **setting-shared-instance**: The setting MUST be a single shared, process-wide declaration on the `UserSettings` namespace, so every file browser and the excluded-files settings panel read and write the same list.

### Pattern entries

- **entry-gitignore-syntax**: Each entry MUST be interpreted as one `.gitignore`-style pattern, matched against a path relative to a browser root, with the syntax defined by `GitIgnoreMatcher`.
- **entry-order-significant**: The list MUST preserve entry order, because `GitIgnoreMatcher` lets the last matching pattern decide, so a later `!` pattern re-includes what an earlier pattern excluded.
- **entry-no-validation**: The setting MUST NOT validate, trim, deduplicate or reject entries; it stores whatever list it is given, and blank lines and `#` comment lines are ignored later by `GitIgnoreMatcher`, not by the setting.
- **entry-duplicates-allowed**: The setting MUST accept duplicate entries, because it stores the list as given; the excluded-files panel relies on this by giving each row its own identity instead of using the pattern text.

### Inherited behavior

- **inherits-read-default**: Reading the setting MUST return the empty list when no value has been stored, or when the stored value cannot be decoded as a list of strings, per the get-fallback contract in settings-storage.
- **inherits-write-publishes**: Writing the setting MUST publish its key name on the settings change stream after the new value is readable, per settings-storage, so a subscriber such as a file browser can re-apply its exclusions.
- **inherits-main-actor**: The setting MUST be read and written on the main actor, because `UserSetting` is declared `@MainActor`.
- **inherits-lazy-construction**: The setting MUST be created on first access of `UserSettings.fileBrowserExcludedPatterns`, and at that point it MUST read its current value from `UserSettings.shared`, because `fileBrowserExcludedPatterns` is a `static var` initialised from `UserSetting.init`.
- **inherits-live-mirror**: The setting's `currentValue` MUST follow the store: whenever the store publishes this key's name, `currentValue` MUST be re-read from `UserSettings.shared`.

### Persistence and side effects

- **persists-through-store**: The component MUST NOT touch files, the network or processes itself; the stored list survives a restart exactly as far as the plain backing store of `UserSettings.shared` does.
- **no-migration**: The component MUST NOT perform a migration or seed any patterns; the first read of an untouched store yields the empty list.

