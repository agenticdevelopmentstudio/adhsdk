
Derived from `PaneStateSettingsStorageProviderTests`, which sits beside the
source in the macOS test target. Vectors use an ephemeral in-memory pane state
store and the browser settings keys `browser.page_zoom` (Double, default 1.0),
`browser.home_page` (String), `browser.javascript_enabled` (Bool),
`browser.autoplay` (enum) and `browser.minimum_font_size` (Int).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pane-state-settings-001 | value-encoding, get-returns-stored, contains-by-decode, remove-deletes-value, get-falls-back-to-default (testRoundTripsBoolIntDoubleStringAndEnum) | Set false, 14, 1.25, "example.com" and the autoplay value never; read each back; then remove autoplay | Each read returns what was set; `contains` for autoplay is true, then false after `remove`, and `get` returns autoplay's default |
| pane-state-settings-002 | storage-key, default-prefix (testStoresUnderThePrefix) | Set 1.25 for `browser.page_zoom` | The store holds a non-nil value under `settings.browser.page_zoom` |
| pane-state-settings-003 | undecodable-reads-absent, contains-by-decode (testUndecodableOverrideFallsBack) | Store the text `not json` under `settings.browser.page_zoom` | `contains` is false and `get` returns 1.0 |
| pane-state-settings-004 | undecodable-reads-absent, no-change-on-fallback (testUndecodableOverrideFallsBack) | Same corrupt entry; a layered store over this provider with a fallback holding 1.5 | The layered `get` returns 1.5 and the layered store reports no override |
| pane-state-settings-005 | index-survives-relaunch, set-records-name, remove-clears-index-name (testOverridesFromAnEarlierProviderCanBeRemovedAfterARelaunch) | One provider sets zoom and home page; a second provider over the same store sits under a layered store; remove all overrides with prefix `browser.` | Before: the layered store reports a zoom override. After: neither override remains and the layered reads return the fallback values 1.5 and `global.com` |
| pane-state-settings-006 | undecodable-reads-absent, no-change-on-fallback (testACorruptOverrideStillReceivesTheGlobalChange) | Corrupt zoom entry; layered store over it; the fallback sets 1.5 | The layered `changes` publisher emits `browser.page_zoom` once and the layered `get` returns 1.5 |
| pane-state-settings-007 | keys-with-prefix, keys-sorted (testKeysWithPrefixListsOnlyWellFormedStoredNames) | Set zoom, home page and JavaScript flag; query prefixes `browser.`, `browser.p` and `editor.` | The lists are `browser.home_page`, `browser.javascript_enabled`, `browser.page_zoom`; then `browser.page_zoom`; then empty |
| pane-state-settings-008 | keys-skip-malformed, remove-clears-index-name (testKeysWithPrefixListsOnlyWellFormedStoredNames) | After vector 007, overwrite the zoom entry with `not json` and remove home page | `keys(withPrefix: "browser.")` returns only `browser.javascript_enabled` |
| pane-state-settings-009 | remove-silent-when-absent, remove-publishes-when-present, set-publishes (testRemoveOnlyPublishesWhenSomethingWasStored) | Subscribe to `changes`; remove zoom; set zoom 1.25; remove zoom | Published names after the first remove: none; after all three calls: `browser.page_zoom` twice |
| pane-state-settings-010 | set-index-unique, remove-empties-index | Set zoom twice, then remove it, on a fresh store | After the two sets the index text holds the name once; after the remove the store holds no value under `settings.__keys` |
| pane-state-settings-011 | corrupt-index-reads-empty | Store `not json` under `settings.__keys`, then `keys(withPrefix: "")` | The result is empty |
| pane-state-settings-012 | configurable-prefix, index-name | Build a provider with prefix `pane.`; set zoom | The value sits under `pane.browser.page_zoom` and the index under `pane.__keys` |
| pane-state-settings-013 | get-uses-first-element | Store `[2.0, 3.0]` under `settings.browser.page_zoom` | `get` returns 2.0; `keys(withPrefix:)` leaves the name out whether or not it is indexed, because the array has two elements |
| pane-state-settings-014 | undecodable-reads-absent | Store `["x"]` under the zoom key (a one-element array of the wrong type) | `contains` and `get` treat it as absent for the Double zoom key |

