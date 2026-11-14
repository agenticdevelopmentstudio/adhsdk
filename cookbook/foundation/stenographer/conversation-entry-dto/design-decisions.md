
**Decision**: The conversation comes from the captured transcript, not from a summarization pass.
**Rationale**: The source comment says the transcript already is the conversation, and a summary would be one sentence per ended session rather than a running feed.
**Approved**: pending

**Decision**: Attribution travels with each entry.
**Rationale**: The feed spans many sessions, so a row without it cannot be labelled, and the join that supplies it costs nothing at query time.
**Approved**: pending

**Decision**: `id` is the transcript row id times 1000 plus the block index, and it is for identity only.
**Rationale**: One captured entry can yield several lines, and the index is taken from the unfiltered entry so it does not shift when filters change. Pages are cut on `timestamp`.
**Approved**: pending

**Decision**: The role is one `kind` string, not three flags.
**Rationale**: The source comment states the combinations are mutually exclusive, and a boolean triple would admit states that cannot happen.
**Approved**: pending

**Decision**: `isFromUser` and `isWorkOutput` are the single places the `kind` vocabulary is folded, and `workOutputKinds` is the one list.
**Rationale**: The source comments say the bubble's side selection and icon share the first, and the daemon's filter and the app's mapping both read the set, so a kind added to one cannot be missed by the other.
**Approved**: pending

**Decision**: Decoding is tolerant of a missing `termProgram` only.
**Rationale**: The two binaries install separately, so an app can be newer than its daemon, and the synthesized decode would throw on a missing key and blank the whole feed over one field. The always-present fields stay required.
**Approved**: pending

**Decision**: Work output is off by default in the window.
**Rationale**: The source comment says progress and thinking lines outnumber the replies roughly three to one.
**Approved**: pending

