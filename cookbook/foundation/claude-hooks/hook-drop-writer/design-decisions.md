
**Decision**: Files are written to `<final>.tmp` and then renamed to `<final>`.
**Rationale**: The daemon scans the directory while hooks write into it; a scanner that filters on the `.json` extension never sees a partial file. The source states this sequence in the doc comment on `writeDropFile`.
**Approved**: pending

**Decision**: The name is a millisecond timestamp plus eight random hex characters.
**Rationale**: The timestamp orders files roughly by arrival and the random suffix keeps concurrent hook processes from colliding. The local variable is named `durationMs` in the source although it holds a point in time, not a duration; a port should name it for what it is.
**Approved**: pending

**Decision**: The override variable is derived from the configuration name.
**Rationale**: Several daemons share one machine and one `settings.json`; a per-name variable lets a test redirect one daemon's drops without affecting another's, and the source comment states production hooks never set it.
**Approved**: pending

**Decision**: `dropDirectory` leaves a leading `~` unexpanded.
**Rationale**: The configuration stores the tilde form that hooks use; expansion happens once, at the point of writing, so the choice of directory stays testable as a string.
**Approved**: pending

**Decision**: Temporary files left by a failed move are not cleaned up, and no error is reported beyond the throw.
**Rationale**: The source has no cleanup path. Because the temporary name does not end in `.json`, scanners ignore it, so the cost is leaked disk space rather than a wrong read.
**Approved**: pending

