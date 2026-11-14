
Derived from `testAStoredGrantIsTrustedOnlyUnderItsOwnSignature` and `testNormalizedSortsDedupsAndClamps` in `WorkTrackingModelsTests` (the latter exercises `normalized()`, which `load` and `save` rely on), `testUserSettingsSnapshotIsNormalized` in `WorkTrackingXPCClientTests`, `testLoadDefaultsWhenUnset` and `testSaveAndApplyNormalizeThePreferences` in `WorkTrackingControllerTests` (the only tests that call `load` and `save` directly, against the controller test's store), and the source.

| ID | Requirements | Input | Expected | Source |
|----|-------------|-------|----------|--------|
| work-tracking-prefs-001 | load-default | Empty store | `WorkTrackingPreferences(enabled: false, addedBundleIds: [], removedBundleIds: [], retentionDays: 90)` | `testLoadDefaultsWhenUnset` |
| work-tracking-prefs-002 | load-retention | `activity_retention_days` = `1` | `retentionDays` is 7 | source-derived |
| work-tracking-prefs-003 | load-retention | `activity_retention_days` = `99999` | `retentionDays` is 3650 | source-derived |
| work-tracking-prefs-004 | load-retention | `activity_retention_days` = `abc` | `retentionDays` is 90 | source-derived |
| work-tracking-prefs-005 | load-enabled | `activity_enabled` = ` YES ` | `enabled` is true | source-derived |
| work-tracking-prefs-006 | load-enabled | `activity_enabled` = `maybe` | `enabled` is false (the default) | source-derived |
| work-tracking-prefs-007 | load-ids, load-normalized | `activity_added_bundle_ids` = `["com.b","com.a","com.b"]` | `addedBundleIds` is `["com.a","com.b"]` | source-derived |
| work-tracking-prefs-008 | load-ids | `activity_added_bundle_ids` = `not json` | `addedBundleIds` is `[]`, no error | source-derived |
| work-tracking-prefs-009 | save-keys, save-enabled-text, save-ids-json, save-retention-text, save-normalizes | `save` of enabled true, added `["b","a","b"]`, removed `["z","z"]`, retention 1 | store holds `true`, `["a","b"]`, `["z"]`, `7` under the four keys | source-derived |
| work-tracking-prefs-010 | save-one-transaction | Store whose `setSetting` throws on the third write, transaction rolls back | `save` throws and no key changed | source-derived |
| work-tracking-prefs-011 | store-errors-propagate | Store whose `setting(for:)` throws | `load` throws the same error | source-derived |
| work-tracking-prefs-012 | trusted-granted-signature | `setLastAccessibility(.granted, signer: "A")` then `trustedAccessibility(signer: "A")` | `.granted` | `testAStoredGrantIsTrustedOnlyUnderItsOwnSignature` |
| work-tracking-prefs-013 | trusted-granted-otherwise-unknown | Same store, signer `"B"`, then signer nil | `.unknown` both times | `testAStoredGrantIsTrustedOnlyUnderItsOwnSignature` |
| work-tracking-prefs-014 | raw-answer-kept | Same store | `lastAccessibility` is `.granted` | `testAStoredGrantIsTrustedOnlyUnderItsOwnSignature` |
| work-tracking-prefs-015 | nil-signer-stored-empty, trusted-granted-otherwise-unknown | `setLastAccessibility(.granted, signer: nil)` then `trustedAccessibility(signer: "")` | `.unknown` | `testAStoredGrantIsTrustedOnlyUnderItsOwnSignature` |
| work-tracking-prefs-016 | trusted-non-granted | `setLastAccessibility(.denied, signer: "A")` then `trustedAccessibility(signer: "B")` | `.denied` | `testAStoredGrantIsTrustedOnlyUnderItsOwnSignature` |
| work-tracking-prefs-017 | last-accessibility-default | Empty store; then `activity_ax_last_status` = `bogus` | `.unknown` both times | `testLoadDefaultsWhenUnset` for the empty store; source-derived for `bogus` |
| work-tracking-prefs-018 | save-ids-json | `save` with added `["", "", "x"]` | stored ids are `["", "x"]` | source-derived |
| work-tracking-prefs-019 | save-keys, save-normalizes, load-normalized | `save` of enabled true, added `["com.b","com.a","com.b"]`, removed `["z.y","a.b","z.y","a.b"]`, retention 1, then `load` | `load` returns added `["com.a","com.b"]`, removed `["a.b","z.y"]`, retention 7; the added key holds `["com.a","com.b"]` | `testSaveAndApplyNormalizeThePreferences` |
