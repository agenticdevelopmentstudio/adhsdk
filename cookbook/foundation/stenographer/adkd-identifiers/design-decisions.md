
**Decision**: Every launchd, log, keychain, hook, port and path name is spelled once, in this type, and read by the daemon, CLI and host app.
**Rationale**: The doc comment on `ADKDIdentifiers` in `ADKDIdentifiers.swift` states the aim: the three binaries never spell them twice, so a rename or a collision fix lands in one place.
**Approved**: pending

**Decision**: Every identifier and path that could collide differs from the Stenographer daemon's, and a test asserts it.
**Rationale**: The launchd output file names `stdout.log` and `stderr.log` are shared but live in separate logs directories. Both daemons run on one machine; sharing a label, port, hook marker or directory would make them overwrite each other's state.
**Approved**: pending

**Decision**: The storage token is duplicated in `ADKDPaths` instead of derived.
**Rationale**: Core cannot import the database layer that derives it; the duplicate is accepted and its agreement is checked by a test in another target.
**Approved**: pending

**Decision**: There are no legacy names and no migration.
**Rationale**: The doc comment on `ADKDIdentifiers` in `ADKDIdentifiers.swift` states the daemon has no history, so nothing needs to be read from an older location.
**Approved**: pending

