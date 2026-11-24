
`TrackedApp` is one app whose frontmost time is recorded: a bundle identifier, a display name and a `PathResolverKind` saying how the app's working path is found. `AppAllowlist` is the immutable set of tracked apps built from `WorkTrackingPreferences`: the built-in defaults, minus the bundle ids the user removed, plus the bundle ids the user added. Its own doc comment states the rule: anything not on the list is never stored. Callers ask it whether a bundle id is allowed and for the `TrackedApp` behind an id.

This is shared logic with no visual surface. It does no I/O and holds no mutable state; a new allowlist is built whenever the preferences change. The activity recorder holds an `AppAllowlist` and looks up the focused app's bundle id with `app(for:)`; an app that is not found is not recorded.

