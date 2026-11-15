
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tracked-app-001 | is-allowed, defaults-list | `AppAllowlist(preferences: .default)`, ids `com.apple.dt.Xcode` and `com.apple.Safari` | `isAllowed("com.apple.dt.Xcode")` is `true`; `isAllowed("com.apple.Safari")` is `false` |
| tracked-app-002 | removed-excluded | Preferences removing `com.apple.Terminal` | `isAllowed("com.apple.Terminal")` is `false` |
| tracked-app-003 | added-appended, added-app-shape | Preferences adding `org.example.Editor` | `isAllowed("org.example.Editor")` is `true`; `app(for:)?.resolver` is `.editor` (both asserted by the test); `name` is `org.example.Editor` (from the source, not asserted by the test) |
| tracked-app-004 | defaults-resolver-assignment | `app(for: "com.sublimemerge")` on default preferences | `resolver` is `PathResolverKind.none` |
| tracked-app-005 | defaults-unique-ids | `AppAllowlist.defaults` | the set of bundle ids has the same count as the list |
| tracked-app-006 | removed-beats-added | Preferences adding and removing `org.example.Editor` | `isAllowed("org.example.Editor")` is `false` |
| tracked-app-007 | added-default-ignored | Preferences adding `com.apple.dt.Xcode` | `apps` contains one Xcode entry; `app(for:)?.resolver` is `.document` |
| tracked-app-008 | sorted-apps | Default preferences | `apps` is ordered by `name` then `bundleId`; `Android Studio` precedes `BBEdit` |
| tracked-app-009 | app-lookup | `app(for: "com.apple.Safari")` | `nil` |
| tracked-app-010 | added-duplicates-collapsed | `addedBundleIds` of `["a.b", "a.b"]` | `apps` contains exactly one entry with bundle id `a.b` |
| tracked-app-011 | lookup-first-wins | `defaults` of two apps sharing a bundle id, names "B" then "A" | `apps` has both, sorted "A" then "B"; `app(for:)` returns the "A" entry, the first in sorted order |
| tracked-app-012 | tracked-app-identity | `TrackedApp(bundleId: "x.y", name: "N", resolver: .none)` | `id` is `"x.y"` |
| tracked-app-013 | construct-from-preferences | Empty `defaults` and `.default` preferences | `apps` is empty; `isAllowed("com.apple.dt.Xcode")` and `isAllowed("")` are both `false` |

Vector 001 is covered by `AppAllowlistTests.testDefaultsAreAllowedAndOthersAreNot`, vectors 002 and 003 by `AppAllowlistTests.testRemovedDefaultIsNotAllowedAndAddedAppIs`, vector 004 by `AppAllowlistTests.testSublimeMergeIsAGitClientWithNoPath` and vector 005 by `AppAllowlistTests.testDefaultBundleIdsAreUnique`. Vectors 006 to 013 are covered by `AppAllowlistTests.testV006_removedBeatsAdded` through `testV013_emptyDefaultsAllowNothing`, one test per vector.

