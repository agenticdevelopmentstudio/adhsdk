
- **Empty or odd name** (SHOULD): `name` is not validated (**no-input-validation**), so an empty or space-containing `name` yields file and lock names built from it verbatim; callers SHOULD pass a short identifier of letters, digits and hyphens as the shipped owners do.
- **Executable with no parent bundle** (MUST, **bundled-helper-no-parent-bundle**): `bundledHelperPath(named:executable:)` for an executable such as `/usr/local/bin/tool` returns `/usr/local/Helpers/<helperName>`, because it only compares the directory name to `Helpers`; it does not check that the result exists.
- **Executable that is a missing path**: symlink resolution leaves a path that does not exist unchanged, so the result is computed from the path as written.
- **No main executable** (MUST, **bundled-helper-default-executable**): the default `executable` argument force-unwraps `Bundle.main.executableURL`; a process without one traps rather than returning an error.
- **Helper path with fewer than two parent directories** (MUST, **resolved-dispatcher-derived**): `resolvedBundledDispatcher` strips two path components, so `/steno` yields `/Resources/dispatch.py`; no error is raised.
- **Changed `name`** (SHOULD, **derived-fields-not-recomputed**): assigning a new `name` leaves `ownLockName` and `statusLineEntryName` at their initial values; a caller that renames SHOULD set them again.
- **Excluded type in `hookedEvents`** (MUST, **explicit-hooked-events-kept**): kept as given; the installer drops it at registration.
- **Empty `hookedEvents`**: accepted as given; nothing is registered for passive observation.
- **Concurrent access** (MUST, **value-semantics**): each copy is an independent value and no code here mutates shared state; sharing one copy across threads is safe, and two threads editing one `var` copy is the caller's race.
- **Error states, offline or disconnected** (not applicable): this type does no I/O that can fail except the symlink read, which does not throw, and uses no network.

