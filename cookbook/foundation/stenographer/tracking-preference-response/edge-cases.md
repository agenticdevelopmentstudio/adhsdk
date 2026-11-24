
- **Empty or missing input**: not applicable to the shape; the route rejects an empty body for `POST` with status 400 and the message `Missing body: expected {"enabled": Bool}` (`testTrackingPreferenceRequiresABody`), before any response is built.
- **Malformed body**: the route replies with status 400 and an `Invalid tracking preference body` message; no response shape is built.
- **Marker and request disagree**: after a write, `enabled` may differ from the inverse of `disabledMarkerPresent`, because `enabled` echoes the request and the marker is owned by the app; the source's route comment says the app's marker self-heals at the daemon's next boot. A reader MUST NOT assume the two are always opposites.
- **Repeated writes**: writing the same value twice MUST succeed and report `already_installed` or `not_installed` the second time, so the resulting state is idempotent but the reported outcome is not: the first call reports `installed` or `uninstalled` and the second reports `already_installed` or `not_installed`.
- **Hook install failure**: no response; status 500 with the message `Hook install failed: <installer message>`. Any other thrown error replies 500 with `Tracking update failed: <description>`.
- **Uninstall failure**: `uninstallHooks()` returns false when its work throws, so a write of `enabled: false` that failed to remove the hooks reports `not_installed` with `enabled` false even though the hooks may still be installed; the installer logs the error. This differs from a failed install, which throws; see the Design Decisions.
- **Unknown outcome**: a reader MUST tolerate an `outcome` it does not know.
- **Concurrent access**: the struct is immutable and `Sendable`, so it is safe to share; two simultaneous writes are ordered by the hook installer, outside this code.
- **Error and offline states**: while the daemon is offline there is no response; the app's marker still records the preference and the daemon enforces it at its next boot.

