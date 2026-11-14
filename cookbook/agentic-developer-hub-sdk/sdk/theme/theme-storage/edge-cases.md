
- **Nothing persisted**: a conformer MUST return an empty `customThemes` and a nil `activeThemeID`; `ThemeStore` still yields the built-in catalog.
- **`activeThemeID` naming an unknown theme**: the protocol does not validate the id. `ThemeManager.reload` resolves it through `ThemeStore` and falls back to `BuiltInThemes.solarizedDark` when no theme matches.
- **Undecodable stored themes**: `UserDefaultsThemeStorage` MUST read them as empty rather than throw, because failing a preference read would take the whole app down. The failure is logged at error level. The stored blob is left in place and is not repaired.
- **Unencodable themes on write**: `UserDefaultsThemeStorage` MUST drop the write. The failure is logged at error level but not signalled to the caller (see `no-errors-declared`), and the previous stored value remains. The last-seen record is not updated for a dropped write.
- **Writing `nil` to `activeThemeID`**: a conformer MUST accept it. `UserDefaultsThemeStorage` passes the optional straight to `UserDefaults`, which removes the key.
- **Several writes then one notification**: `UserDefaultsThemeStorage` MUST compare final values against the last seen values and fire at most once.
- **Foreign write storing the existing value**: not a change; the hook MUST NOT fire.
- **Hook unset**: a conformer MUST tolerate `onExternalChange == nil` and simply skip the call.
- **Conformer deallocation**: `UserDefaultsThemeStorage` removes its notification observer in `deinit`, and its hook closure is invoked only while the object is alive.
- **Concurrent access**: serialised by main-actor isolation of the protocol; the one nonisolated member, the observer token in `UserDefaultsThemeStorage`, is written once in `init` and read once in `deinit`, so it cannot race.
- **Offline, timeout, cancellation**: not applicable; the protocol is synchronous and does no network I/O. A sync-backed conformer's connectivity is that conformer's concern, and it reports arrivals through `onExternalChange`.
- **Storage full or unwritable**: the protocol has no error channel, so such a failure is not reported to `ThemeStore`. A conformer decides whether to log or ignore it; `UserDefaultsThemeStorage` writes through `UserDefaults` and has no failure path of its own beyond encoding.

