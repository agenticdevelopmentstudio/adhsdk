
`ActivityPersistence` is the storage contract work tracking writes through, per its doc comment "Where work-tracking writes. The host implements it over its own database." It declares the operations on two kinds of record: activity spans ([adhsdk.ingredient.foundation.work-tracking.activity-span-dto](cookbook:92a9546a-eec1-47ed-8420-7db51e8d0261)), each one stretch of focus on a tracked app, and idle intervals, each one stretch with the user away. The same file declares three companions:

- `ActivitySpanClose`, the three outcomes of closing one span (`none`, `closed`, `deleted`), which conforming hosts use internally.
- `ActivityRecovery.recoveredEnd(startedAt:lastSeenAt:openIdleFrom:)`, the one pure rule for where a span left open by a crash ends.
- `WorkTrackingPersistence`, the full storage a `WorkTrackingController` runs against: `ActivityPersistence` plus `WorkTrackingSettingsStore` ([adhsdk.ingredient.foundation.work-tracking.work-tracking-prefs](cookbook:d525cc69-4d2c-4d17-a570-f71e8d5aa273)) plus `knownRepoRoots(activeSince:)`.

The file holds no storage of its own. Two hosts conform in the toolkit: `InMemoryActivityStore` (tests and previews) and `DaemonDatabase` (SQLite). The second source file, `ActivityPersistenceContract.swift`, is the executable form of this contract: `ActivityPersistenceContract.runAll` runs fourteen named checks against fresh stores and returns failure messages, "so a host can run them from its own XCTest target". This recipe specifies the contract those hosts meet and the suite that checks it.

