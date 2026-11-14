
- **response-fields**: A `TrackingPreferenceResponse` MUST carry `enabled` (Bool), `disabledMarkerPresent` (Bool) and `outcome` (String), all immutable.
- **response-conformance**: The type MUST be a `public struct` that is `Encodable` and `Sendable`; it is written to a reply and never decoded by this code.
- **response-memberwise-init**: `init(enabled:disabledMarkerPresent:outcome:)` MUST be public and MUST require all three values, with no defaults.
- **enabled-meaning**: `enabled` MUST say whether tracking is on after the call.
- **marker-meaning**: `disabledMarkerPresent` MUST report whether the cross-process tracking-disabled marker was present when the reply was built, read from the hook installer.
- **write-enabled-echoes-request**: After a write, `enabled` MUST echo the value that was asked for, not a re-read of the marker, because the app owns the marker and a write through the daemon may run before the app updates it.
- **read-enabled-follows-marker**: After a read, `enabled` MUST be the inverse of `disabledMarkerPresent`.
- **outcome-installed**: A write of `enabled: true` that installed the hooks MUST return outcome `installed`.
- **outcome-already-installed**: A write of `enabled: true` when the hooks were already installed MUST return outcome `already_installed`.
- **outcome-uninstalled**: A write of `enabled: false` that removed the hooks MUST return outcome `uninstalled`.
- **outcome-not-installed**: A write of `enabled: false` MUST return outcome `not_installed` whenever `uninstallHooks()` returns false, which is when there were no hooks to remove and also when the uninstall threw (the installer logs the error and returns false, so the failure is not told apart in the reply). This is a recorded limitation, not a goal: the caller is told tracking is off when the hooks may still be installed (see the Design Decisions).
- **outcome-current**: A read MUST return outcome `current`.
- **outcome-open-string**: `outcome` MUST be an open string, not a closed enum; the five values above are the ones the source writes. As a contract note for consumers (checked in their code, not here), a reader should tolerate a value it does not know.
- **wire-keys**: The encoded JSON object MUST use the exact keys `enabled`, `disabledMarkerPresent` and `outcome` (camelCase, the property names under the default `JSONEncoder` key strategy); the `outcome` values are snake_case words.
- **failed-install-no-response**: A failed hook install (including an installer whose helper is not an executable file) MUST NOT produce a `TrackingPreferenceResponse`; `setTracking` throws `PreferencesError.hookInstallFailed` and the route replies with the message `Hook install failed: <message>` and status 500.
- **no-logic-here**: The struct MUST hold no logic: no validation, no derived values and no I/O.

