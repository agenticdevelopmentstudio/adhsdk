
Only vector 002 is backed by an existing test (`testUserSettingsSnapshotIsNormalized` in `WorkTrackingXPCClientTests`); every other vector is derived from the source and has no test yet.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| work-tracking-user-settings-001 | defaults-shared, preferences-snapshot | Fresh prefix, no values set | `preferences` equals `WorkTrackingPreferences.default` (disabled, no ids, 90 days) |
| work-tracking-user-settings-002 | preferences-normalized | enabled true; added `["com.b","com.a","com.b"]`; removed `["com.z","com.z"]`; retention 1 (test `testUserSettingsSnapshotIsNormalized`) | `preferences` is enabled true, added `["com.a","com.b"]`, removed `["com.z"]`, retention 7 |
| work-tracking-user-settings-003 | preferences-normalized | retention set to 99999 | `preferences.retentionDays` is 3650 |
| work-tracking-user-settings-004 | stored-values-raw | retention set to 1 | `retentionDays.value` is 1 while `preferences.retentionDays` is 7 |
| work-tracking-user-settings-005 | key-enabled, key-added, key-removed, key-retention | prefix `p_` | the four settings' `name` are `p_activity_enabled`, `p_activity_added_bundle_ids`, `p_activity_removed_bundle_ids`, `p_activity_retention_days` |
| work-tracking-user-settings-006 | no-separator | prefix `p` | `enabled.name` is `pactivity_enabled` |
| work-tracking-user-settings-007 | prefix-isolation | Two instances with prefixes `a_` and `b_`; set `enabled` true on the first | the second `enabled.value` stays false |
| work-tracking-user-settings-008 | preferences-snapshot | Read `preferences`, change `enabled`, read again | the second read shows the new value |
| work-tracking-user-settings-009 | four-settings | Compile-time check that lists the class's public stored properties of type `UserSetting` | exactly `enabled`, `addedBundleIds`, `removedBundleIds`, `retentionDays` |

