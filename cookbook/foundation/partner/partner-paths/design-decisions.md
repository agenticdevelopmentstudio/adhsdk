
**Decision**: The partner directory sits at a dot-prefixed folder named by the token, then `partner`.
**Rationale**: The token is the app's own storage token, so the partner's files live beside the app's other per-user data; the dot keeps the folder hidden under the home directory.
**Approved**: pending

**Decision**: The skills directory ignores the token and lives under `.claude/skills`.
**Rationale**: The skills are read by the `claude` command line tool, which looks in its own folder, not the app's; each job's directory is prefixed `adkitchen-partner-` so the app can recognise its own. The prefix is fixed to the app's name and is not a template value.
**Approved**: pending

**Decision**: `skillFile(jobID:)` takes a raw `String`, not a parsed job-ID type.
**Rationale**: The type is a pure location builder with no notion of a valid ID; the caller that takes an ID from outside the app checks it before calling, so one parsed type would have to live in a layer that owns job identity rather than here.
**Approved**: pending
