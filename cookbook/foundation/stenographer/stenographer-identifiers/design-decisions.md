
**Decision**: Every launchd, log, keychain and path name is spelled once in these types.
**Rationale**: The aim is stated in the doc comment on `StenographerIdentifiers` in `StenographerIdentifiers.swift`: one place, so the daemon, app and tool cannot drift. The alternative is for each target to spell its own names, which is the drift the type exists to prevent.
**Approved**: pending

**Decision**: `supportDirectory` prefers a current directory that holds the database, then an existing legacy directory, then the current one.
**Rationale**: The comment on `StenographerPaths.supportDirectory` in `StenographerIdentifiers.swift` states that an empty new directory must not hide the user's real data while the daemon has not migrated yet. A plain existence check on the current directory, as `logsDirectory` uses, would let an empty current directory win.
**Approved**: pending

**Decision**: `pluginDirectories` returns both directories rather than the resolved one.
**Rationale**: The comment on `StenographerPaths.pluginDirectories` in `StenographerIdentifiers.swift` states the app discovers plugins once at launch and the daemon may move the legacy directory afterwards, so a single resolved path would point at a folder that has since moved.
**Approved**: pending

**Decision**: `writeSupportFile` re-resolves the directory after each write and repeats it if it moved, up to 3 times, and when the attempts run out it returns the newly resolved URL without raising an error.
**Rationale**: The comment on `StenographerPaths.writeSupportFile` in `StenographerIdentifiers.swift` states that a file written into the legacy directory just before the daemon migrates it could land where the next read never looks; the bound keeps the loop finite. Returning a result that says whether the directory settled would let a caller tell "settled" from "gave up", but the source returns a plain `URL`, so the silent case is accepted for now.
**Approved**: pending

**Decision**: `logsDirectory` checks only that a directory exists, with no sentinel file, while `supportDirectory` checks for `stenographer.db`.
**Rationale**: The source gives `logsDirectory` the simple existence rule in `StenographerIdentifiers.swift`, and it has no sentinel file to test because log files are not a fixed name. The asymmetry means an empty current logs directory hides a populated legacy one; checking for a log file would align the two, and the source does not do that.
**Approved**: pending

**Decision**: The legacy names are read, matched and migrated, never written.
**Rationale**: The comment on the `legacy*` values in `StenographerIdentifiers.swift` states this for the pre-1.0.173 Stenographer names so old installs stay recognised without new files appearing under old names.
**Approved**: pending

