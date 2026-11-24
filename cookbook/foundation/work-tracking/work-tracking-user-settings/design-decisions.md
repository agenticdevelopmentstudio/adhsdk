
**Decision**: The app supplies only a key prefix.
**Rationale**: The doc comment says "the app decides only the prefix, the same way `BillingUserSettings` does", so keys, defaults and normalization stay shared across apps.
**Approved**: pending

**Decision**: Defaults are read from `WorkTrackingPreferences.default`.
**Rationale**: One set of numbers serves the settings pane, the wire and the daemon's fallback, so the three cannot drift.
**Approved**: pending

**Decision**: Normalization happens in the `preferences` snapshot, not on each write.
**Rationale**: The settings stay faithful to what a control assigned (a retention field mid-edit is not clamped under the user's cursor), and the value that crosses to the daemon is always valid. The daemon and `WorkTrackingPrefs` normalize again on their side.
**Approved**: pending

**Decision**: The class is `@MainActor`.
**Rationale**: `UserSetting` is itself `@MainActor`, so a holder of them must be too.
**Approved**: pending

