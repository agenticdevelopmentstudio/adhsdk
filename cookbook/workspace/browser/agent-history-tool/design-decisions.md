
**Decision**: Three choices — All history, Current tab only, None — with
None the default.
**Rationale**: The owner's decision in the design: an agent with privacy on
has little reason to see history, so access is opt-in
(`secure-by-default`).
**Approved**: pending

**Decision**: Current tab only reads the tab's own back/forward list, never
the store.
**Rationale**: The design: it needs no store or schema change and exposes
nothing the tab does not already hold.
**Approved**: pending

**Decision**: Concealment happens per field, before the reply is joined, on
the gatekeeper's string path.
**Rationale**: The design routes every title and address through the same
string path as page titles elsewhere; concealing each field before joining
means a privacy word can never straddle a line break or separator and escape
the match. Phase 2 moves this onto `AgentPageBuilder.conceal` without changing
the behaviour.
**Approved**: pending

**Decision**: `browser_history` is a read tool, allowed on read-only panes.
**Rationale**: The plan: it only reads, so read-only access must not refuse
it.
**Approved**: pending

**Decision**: The reply's line format, the ordering of forward entries under
Current tab only, and `limit` below 1 being treated as 1 are the builder's
choices.
**Rationale**: The design and plan fix what is returned and the 50/200
limits, not the layout of a line or the handling of a non-positive limit.
**Approved**: pending

