
The tests named below drive the daemon code that builds this response; none sits beside the shape. Vectors without a test name follow from the source's logic.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tracking-preference-response-001 | outcome-installed, enabled-meaning | `setTracking(enabled: true)` on a fresh installer (`testTrackingInstallsAndUninstallsThroughTheHookInstaller`) | `enabled` true, `outcome` `installed`, the hook settings file exists |
| tracking-preference-response-002 | outcome-already-installed | a second `setTracking(enabled: true)` (same test) | `outcome` `already_installed` |
| tracking-preference-response-003 | outcome-uninstalled | `setTracking(enabled: false)` after an install (same test) | `outcome` `uninstalled` |
| tracking-preference-response-004 | outcome-not-installed | a second `setTracking(enabled: false)` (same test) | `outcome` `not_installed` |
| tracking-preference-response-005 | read-enabled-follows-marker, outcome-current | `currentTracking()` with no marker (`testCurrentTrackingFollowsTheDisabledMarker`) | `enabled` true |
| tracking-preference-response-006 | read-enabled-follows-marker, marker-meaning, outcome-current | `currentTracking()` after `setTrackingDisabled(true)` (same test) | `enabled` false, `disabledMarkerPresent` true, `outcome` `current` |
| tracking-preference-response-007 | write-enabled-echoes-request | `setTracking(enabled: true)` while the marker is present | `enabled` true and `disabledMarkerPresent` true in the same reply |
| tracking-preference-response-008 | response-memberwise-init, response-fields | `TrackingPreferenceResponse(enabled: true, disabledMarkerPresent: false, outcome: "current")` | the three fields hold the values passed |
| tracking-preference-response-009 | response-conformance | encode the value with `JSONEncoder` | the output holds the keys `enabled`, `disabledMarkerPresent` and `outcome` with Bool, Bool and String values, for example `{"enabled":true,"disabledMarkerPresent":false,"outcome":"current"}` (key order is not significant) |
| tracking-preference-response-010 | failed-install-no-response | `setTracking(enabled: true)` when `installHooks()` returns `.failed` | throws `PreferencesError.hookInstallFailed`; no response value |
| tracking-preference-response-011 | outcome-open-string | a reader decodes `outcome` `something_new` | the reader accepts it without failing |

