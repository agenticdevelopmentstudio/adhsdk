
**Decision**: The partner directory sits at a dot-prefixed folder named by the token, then `partner`.
**Rationale**: The token is the app's own storage token, so the partner's files live beside the app's other per-user data; the dot keeps the folder hidden under the home directory.
**Approved**: pending

**Decision**: The skills directory ignores the token and lives under `.claude/skills`.
**Rationale**: The skills are read by the `claude` command line tool, which looks in its own folder, not the app's; each job's directory is prefixed `adkitchen-partner-` so the app can recognise its own.
**Approved**: pending

