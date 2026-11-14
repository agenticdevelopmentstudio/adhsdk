
### Protocol shape

- **main-actor-isolated**: `ThemeStorage` MUST be isolated to the main actor, so every read, write and hook invocation of a conformer happens on the main thread.
- **class-bound**: `ThemeStorage` MUST be class-bound, so a `ThemeStore` that holds its storage as an immutable reference can still write through it.
- **minimal-surface**: `ThemeStorage` MUST declare exactly three members: `customThemes`, `activeThemeID` and `onExternalChange`. The source states the surface is exactly what `ThemeStore` touches.

### customThemes

- **custom-themes-type**: `customThemes` MUST be a readable and writable array of `ColorTheme`.
- **custom-themes-order**: `customThemes` MUST hold the user's imported and custom themes in insertion order.
- **custom-themes-round-trip**: A value written to `customThemes` MUST be what a later read returns, including a read after a later launch.
- **custom-themes-excludes-built-ins**: `customThemes` MUST NOT be used to store built-in themes; `ThemeStore` appends `BuiltInThemes.all` at read time.
- **custom-themes-empty-default**: A conformer with nothing persisted MUST read `customThemes` as an empty array, so the catalog is the built-in themes alone.

### activeThemeID

- **active-id-type**: `activeThemeID` MUST be a readable and writable optional string holding a `ColorTheme.id`.
- **active-id-none**: `activeThemeID` MUST read `nil` when no theme has ever been chosen (a fresh install).
- **active-id-round-trip**: A value written to `activeThemeID`, including `nil`, MUST be what a later read returns, including a read after a later launch.
- **active-id-cleared-on-delete**: When `ThemeStore.delete(id:)` removes the theme whose id equals `activeThemeID`, the store MUST write `nil` to `activeThemeID`, so storage never keeps pointing at a theme that no longer exists.

### onExternalChange

- **external-hook-type**: `onExternalChange` MUST be a readable and writable optional closure taking no arguments and returning nothing.
- **external-hook-fires**: A conformer with a way to observe its backing setting MUST invoke `onExternalChange` when `customThemes` or `activeThemeID` changes through any route other than writing through this protocol (a settings panel bound to the underlying setting, a sync from another device).
- **external-hook-silent-on-own-write**: A conformer SHOULD NOT invoke `onExternalChange` for a write made through its own `customThemes` or `activeThemeID` setters, because the writer has already applied the change and a reload would repeat it.
- **external-hook-optional-observation**: A conformer with nothing to observe (an in-memory test double) MAY leave `onExternalChange` as a plain stored property that is never invoked.
- **external-hook-consumer**: `ThemeManager` MUST assign `onExternalChange` in its initializer to a closure that holds `self` weakly and calls `reload()`. Without it a theme chosen elsewhere persists but nothing repaints until relaunch.
- **external-hook-reentrancy-tolerated**: `ThemeManager.selectTheme(id:)` writes `activeThemeID` and also calls `reload()` itself, so `reload()` can run twice for one selection. `reload()` MUST return without posting when the resolved theme equals the current theme, which is how a conformer's occasional echo of its own write stays harmless.

### Ordering, concurrency and side effects

- **ordering-main-actor**: Reads, writes and hook calls are serialised by main-actor isolation; no ordering rule beyond that is declared, and none is needed for the protocol.
- **no-side-effects-declared**: The protocol declares no file, network, notification or logging side effect; those belong to a conformer.
- **no-errors-declared**: Neither property can throw and neither setter returns a status, so a conformer that cannot persist has no way to report it through this protocol.

### Shipped and test conformers

- **user-defaults-conformer**: `UserDefaultsThemeStorage` is the SDK's conformer. It MUST persist `customThemes` as JSON under the key `theme.custom_themes` and `activeThemeID` as a string under `theme.active_theme_id`, the same keys and encoding a host settings system uses, so a host that later swaps conformers finds the user's themes where it left them.
- **user-defaults-undecodable**: `UserDefaultsThemeStorage` MUST read an undecodable `customThemes` blob as an empty array, MUST log the decode failure at error level, and MUST NOT trap.
- **user-defaults-unencodable**: `UserDefaultsThemeStorage` MUST ignore a `customThemes` write whose value fails to encode, leaving the stored value unchanged, and MUST log the encode failure at error level.
- **user-defaults-self-write-detection**: `UserDefaultsThemeStorage` MUST decide whether a change is external by comparing the stored values with the values it last wrote or last saw, and MUST record the new value before writing it. A boolean "writing" flag is wrong because the change notification arrives on a later run-loop turn.
- **user-defaults-coalescing**: `UserDefaultsThemeStorage` MUST NOT invoke `onExternalChange` when a foreign write stores the value it already had, and MUST invoke it at most once per notification.
- **user-defaults-injectable-domain**: `UserDefaultsThemeStorage` MUST accept the `UserDefaults` instance to use, defaulting to `.standard`, so a host with an app group can pass its shared suite.
- **in-memory-double**: Tests use `InMemoryThemeStorage`, a conformer whose two properties are stored values and whose hook is never invoked.

