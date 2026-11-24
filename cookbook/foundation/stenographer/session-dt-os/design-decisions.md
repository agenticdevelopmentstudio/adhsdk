
**Decision**: `SessionDTO` has a hand-written decoder that makes eight fields optional on decode (defaulting to empty or false), while `SessionEventDTO` and `HealthDTO`'s required fields stay strict.
**Rationale**: The tolerant decoder protects against an old daemon serving a freshly-updated client while app, daemon and CLI update. It applies a default to `project_root` and to seven further later-added keys, which are the eight tolerant fields. `SessionEventDTO` never gained a later field, so it stays synthesized.
**Approved**: pending

**Decision**: The `SessionEventDTO.gitBranch` initializer default does not apply on decode.
**Rationale**: The type has no tolerant decoder, so a payload without `git_branch` fails. Recorded so a port does not assume the default covers the wire.
**Approved**: pending

**Decision**: `subagentWorking` is a verdict computed by the daemon, not a timestamp a client compares.
**Rationale**: The main agent's `lastEventType` cannot say whether a background subagent is working, and subagent hooks are refused so a late `SubagentStop` cannot leave a finished session spinning. The daemon owns the freshness window so no client re-derives it.
**Approved**: pending

**Decision**: `transcriptTitle` and `summary` are separate fields.
**Rationale**: They once shared a column and the Sessions window showed the name where the summary belonged for every named session; the split is the fix.
**Approved**: pending

**Decision**: The health memory properties are spelled `Mb`, not `MB`.
**Rationale**: The casing is load-bearing: the from-snake-case strategy rebuilds `memory_footprint_mb` as `memoryFootprintMb`, an all-caps property would never match, and because it is optional the synthesized decoder returns nil without throwing. The wire format is unchanged.
**Approved**: pending

**Decision**: `/health` carries no database counts; `activeSessionCount` and `totalEventCount` stay in the type but are always nil.
**Rationale**: `/health` is a pure liveness probe that never touches the database, so an in-flight retention or import cannot slow it. The fields remain for source compatibility.
**Approved**: pending

