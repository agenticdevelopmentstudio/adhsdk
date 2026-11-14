**Decision**: Every launchd, log, keychain and path name is spelled once in these types.
**Rationale**: The source comment states the aim: one place, so the daemon, app and tool cannot drift.
**Approved**: pending

**Decision**: `supportDirectory` prefers a current directory that holds the database, then an existing legacy directory, then the current one.
**Rationale**: The source comment states that an empty new directory must not hide the user's real data while the daemon has not migrated yet.
**Approved**: pending

**Decision**: `pluginDirectories` returns both directories rather than the resolved one.
**Rationale**: The source comment states the app discovers plugins once at launch and the daemon may move the legacy directory afterwards, so a single resolved path would point at a folder that has since moved.
**Approved**: pending

**Decision**: `writeSupportFile` re-resolves the directory after each write and repeats it if it moved, up to 3 times.
**Rationale**: The source comment states that a file written into the legacy directory just before the daemon migrates it could land where the next read never looks; the bound keeps the loop finite.
**Approved**: pending

**Decision**: The legacy names are read, matched and migrated, never written.
**Rationale**: The source comment states this for the pre-1.0.173 names so old installs stay recognised without new files appearing under old names.
**Approved**: pending
