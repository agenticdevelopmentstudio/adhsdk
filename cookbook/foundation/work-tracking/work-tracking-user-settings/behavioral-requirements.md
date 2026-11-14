
- **main-actor**: The class MUST be isolated to the main actor; every access, including `init`, MUST happen there.
- **four-settings**: The class MUST expose exactly four settings: `enabled` (`UserSetting<Bool>`), `addedBundleIds` (`UserSetting<[String]>`), `removedBundleIds` (`UserSetting<[String]>`) and `retentionDays` (`UserSetting<Int>`).
- **init-prefix**: `init(prefix:)` MUST take the key prefix as its only argument.
- **key-enabled**: `enabled` MUST be stored under `prefix` followed by `activity_enabled`.
- **key-added**: `addedBundleIds` MUST be stored under `prefix` followed by `activity_added_bundle_ids`.
- **key-removed**: `removedBundleIds` MUST be stored under `prefix` followed by `activity_removed_bundle_ids`.
- **key-retention**: `retentionDays` MUST be stored under `prefix` followed by `activity_retention_days`.
- **no-separator**: The class MUST concatenate prefix and key with no separator of its own; the caller supplies any separator in the prefix.
- **defaults-shared**: Each setting's default MUST be the matching field of `WorkTrackingPreferences.default`: `enabled` false, both id lists empty, `retentionDays` 90.
- **settings-public-live**: Each setting MUST be a `public let` `UserSetting`, so a caller reads and writes its `value` and the setting reflects changes the shared user-settings store publishes.
- **preferences-snapshot**: `preferences` MUST build a `WorkTrackingPreferences` from the four current `value`s on each read.
- **preferences-normalized**: `preferences` MUST return the snapshot after `normalized()`: ids sorted ascending and de-duplicated, retention clamped into 7 through 3650.
- **stored-values-raw**: The settings MUST hold exactly what a caller assigns; normalization applies only in `preferences`, not when a value is written.
- **accessibility-keys-excluded**: The class MUST NOT expose the Accessibility answer or signer keys; they are not user settings.
- **prefix-isolation**: Two instances built with different prefixes MUST NOT share values.

