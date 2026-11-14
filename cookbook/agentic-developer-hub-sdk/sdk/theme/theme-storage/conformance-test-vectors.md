
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| theme-storage-001 | custom-themes-empty-default, active-id-none | Test `a fresh domain reads as no themes and no selection`: `UserDefaultsThemeStorage` over an empty private suite | `customThemes` is empty; `activeThemeID` is nil |
| theme-storage-002 | custom-themes-round-trip, user-defaults-conformer | Test `customThemes round-trips through the defaults domain`: write one theme with id `custom.test`, then read through a second storage over the same suite | The second storage returns one theme with id `custom.test` and name `Test` |
| theme-storage-003 | active-id-round-trip | Test `activeThemeID round-trips, and nil clears it`: write the GitHub Light id, read from a second storage, write `nil`, read again | First read returns the GitHub Light id; second read returns nil |
| theme-storage-004 | external-hook-silent-on-own-write, user-defaults-self-write-detection | Test `the storage's own writes do not report as external changes`: set a hook counter, write both properties, wait 50 ms | Counter is 0 |
| theme-storage-005 | external-hook-fires, user-defaults-self-write-detection | Test `a write from outside the seam reports as an external change`: write `theme.active_theme_id` straight to the defaults domain, wait 50 ms | Counter is at least 1 and `activeThemeID` reads the written id |
| theme-storage-006 | user-defaults-undecodable | Test `a corrupt custom-themes payload reads as no themes rather than trapping`: store the bytes of `not json` under `theme.custom_themes` | `customThemes` is empty |
| theme-storage-007 | external-hook-consumer, external-hook-fires | Test `writing UserSettings.activeThemeID.value directly posts didChangeNotification and updates currentPalette` in `ExternalThemeChangeObservationTests`: a `ThemeManager` over `UserSettingsThemeStorage`, then a direct write of the Dracula id | `ThemeManager.didChangeNotification` fires and `currentTheme.id` is the Dracula id |
| theme-storage-008 | external-hook-fires, external-hook-consumer | Test `writing UserSettings.customThemes directly posts didChangeNotification when it redefines the active theme`: rewrite the active custom theme with a new name through the setting | The notification fires and `currentTheme.name` is `Nord Custom (edited)` |
| theme-storage-009 | external-hook-reentrancy-tolerated | Test `selectTheme(id:) posts didChangeNotification exactly once, not twice`: select the Dracula id, drain the main queue | Exactly one notification is counted |
| theme-storage-010 | active-id-cleared-on-delete | `InMemoryThemeStorage` with a custom theme as `activeThemeID`; `ThemeStore.delete(id:)` of that theme (derived from the `delete` source; no named test) | `customThemes` no longer contains it and `activeThemeID` is nil |
| theme-storage-011 | external-hook-optional-observation | `InMemoryThemeStorage` with a hook set, then both properties written | The hook is never invoked |

