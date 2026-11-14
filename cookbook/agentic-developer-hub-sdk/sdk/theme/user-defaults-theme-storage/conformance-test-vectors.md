
Vectors are derived from `UserDefaultsThemeStorageTests` (Swift Testing, `.serialized`, `@MainActor`), which builds a private `UserDefaults` suite per test so one test never sees another's themes, and from the documented behavior in the source. Tests that expect a notification wait 50 milliseconds so it can arrive.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| udts-001 | themes-read-empty-when-absent, active-read | `emptyDefaultsReadAsEmpty`: new storage over an empty suite | `customThemes` is empty; `activeThemeID` is nil |
| udts-002 | themes-write-encode, themes-read-decode, key-custom-themes | `customThemesRoundTrip`: set `customThemes` to one theme (id `custom.test`, name `Test`), then read through a second storage over the same suite | the second storage returns one theme with id `custom.test` and name `Test` |
| udts-003 | active-write, active-read, key-active-theme-id | `activeThemeIDRoundTrips`: set `activeThemeID` to the GitHub Light theme id, read through a second storage | returns that id |
| udts-004 | active-write-nil-clears | `activeThemeIDRoundTrips`: after udts-003 set `activeThemeID` to nil, read through a new storage | returns nil |
| udts-005 | external-own-writes-silent, themes-write-records-first, active-write-records-first | `ownWritesAreNotExternalChanges`: set a callback that counts, set `activeThemeID` then `customThemes`, wait 50 ms | the count is 0 |
| udts-006 | external-compare-values, external-read-through, key-active-theme-id | `foreignWritesReportAsExternalChanges`: set a counting callback, write the GitHub Light id straight into the suite under `Key.activeThemeID`, wait 50 ms | the count is at least 1 and `activeThemeID` returns the GitHub Light id |
| udts-007 | themes-read-corrupt | `undecodablePayloadReadsAsEmpty`: store `Data("not json".utf8)` under `Key.customThemes`, read through a new storage | `customThemes` is empty; no trap |
| udts-008 | key-custom-themes, key-active-theme-id, keys-load-bearing | read `Key.customThemes` and `Key.activeThemeID` | `theme.custom_themes` and `theme.active_theme_id` |
| udts-009 | themes-write-empty | set `customThemes` to an empty array, read the raw `Data` under `Key.customThemes` | the data is the text `[]` and `customThemes` reads empty |
| udts-010 | init-snapshot | seed the suite with an active id, build a storage, set a counting callback, wait 50 ms | the count is 0 |
| udts-011 | external-same-value | storage with active id A; write A straight into the suite again, wait 50 ms | the count is 0 |
| udts-012 | external-coalesce, external-update-last-seen | write two different themes payloads and two ids straight into the suite in one turn, wait 50 ms | the count is 1 |
| udts-013 | notification-granularity | write an unrelated key into the suite, wait 50 ms | the count is 0 |
| udts-014 | multiple-instances | two storages over one suite, each with a counting callback; set `activeThemeID` through the first | the first count is 0 and the second count is at least 1 |
| udts-015 | external-nil-callback | storage with a nil callback; write a foreign id into the suite | no crash; a later foreign write of a different value still reports once a callback is set |
| udts-016 | init-defaults-parameter | `UserDefaultsThemeStorage()` | persists into `UserDefaults.standard` |

Vectors udts-001 to udts-007 are the source's own tests. The rest are derived from the source and have no test beside them.

