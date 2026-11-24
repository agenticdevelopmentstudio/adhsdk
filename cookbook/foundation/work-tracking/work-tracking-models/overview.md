
The value types the app and the daemon share for work tracking, the feature that records which allowlisted development app has focus. They are `WorkTrackingPreferences` (what the user chose), `WorkTrackingAccessibility` and `WorkTrackingStatus` (what the daemon reports), `WorkTrackingWire` (how a failed list read replies), `WorkTrackingSettingsKeys` (the daemon's `settings` table keys) and `ActivitySpanSession` (the billing session id of an app span). The file is pure data and pure functions with no I/O. Persistence, transport and recording live in sibling types in the same directory.

