
- **Empty or odd name** (MUST): `name` is not validated, so an empty or space-containing `name` yields file and lock names built from it verbatim; callers MUST pass a short identifier of letters, digits and hyphens as the shipped owners do.
- **Executable with no parent bundle** (MUST): `bundledHelperPath(named:executable:)` for an executable such as `/usr/local/bin/tool` returns `/usr/local/Helpers/<helperName>`, because it only compares the directory name to `Helpers`; it does not check that the result exists.
- **Executable that is a missing path** (SHOULD): symlink resolution leaves a path that does not exist unchanged, so the result is computed from the path as written.
- **No main executable** (MUST): the default `executable` argument force-unwraps `Bundle.main.executableURL`; a process without one traps rather than returning an error.
- **Helper path with fewer than two parent directories** (SHOULD): `resolvedBundledDispatcher` strips two path components, so `/steno` yields `/Resources/dispatch.sh`; no error is raised.
- **Excluded type in `hookedEvents`** (MUST): kept as given; the installer drops it at registration.
- **Empty `hookedEvents`** (MUST): accepted as given; nothing is registered for passive observation.
- **Concurrent access** (MUST): each copy is an independent value and no code here mutates shared state; sharing one copy across threads is safe, and two threads editing one `var` copy is the caller's race.
- **Error states, offline or disconnected** (not applicable): this type does no I/O that can fail except the symlink read, which does not throw, and uses no network.

