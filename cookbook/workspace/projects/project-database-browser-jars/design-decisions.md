
**Decision**: A jar row's `id` is the WebKit store identifier.
**Rationale**: The source comment (`dry`) says the row and the store on disk are
named by one value and cannot drift apart.
**Approved**: pending

**Decision**: Duplicate jars are refused by unique indexes, and the insert throws
instead of checking first.
**Rationale**: The `insertBrowserJar` comment says this lets a caller that lost a
race read the winner's row, so no lock is needed.
**Approved**: pending

**Decision**: `layout_nodes` is the authority for live panes, not `pane_state`.
**Rationale**: The source comment says `saveTabs` rewrites it to exactly the
panes that exist and prunes `pane_state` by it, and a pane that has not yet
written state is still a pane.
**Approved**: pending

**Decision**: `livePaneNodeIDs` counts every UUID in any state key under a live
node, of any pane type.
**Rationale**: The source comment says keeping a jar a little longer than needed
is cheap and deleting one a live pane holds signs the user out.
**Approved**: pending

**Decision**: Worktree paths are keyed through one standardizing function.
**Rationale**: The source comment says a trailing slash would otherwise make one
worktree two jars.
**Approved**: pending

**Decision**: The upgrade pins existing panes to the global jar through the same
pane-state shape the settings sheet writes, and is idempotent.
**Rationale**: Before jars every pane used WebKit's default store and the
setting now defaults to a jar per pane; without the upgrade, restored panes
would sit on an empty store and sign the user out of every site. Writing the
sheet's own shape lets the user revert it, and merging the index (not replacing
it) makes a second run safe.
**Approved**: pending

**Decision**: Rows that fail to decode are skipped without a signal.
**Rationale**: This is how the source behaves (guard-and-return in every row
callback). It is recorded as an open question on `malformed-row-skipped`, not
approved behavior.
**Approved**: pending

**Decision**: A nested browser that has written no state is not listed.
**Rationale**: The source comment says the registry's in-use set covers it while
it is open; the database cannot see it.
**Approved**: pending

