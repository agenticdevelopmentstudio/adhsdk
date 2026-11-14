
**Decision**: The sidebar hosts a topic list as a child rather than subclassing it.
**Rationale**: The sidebar's public surface is its data source, delegate and `reload()`; a subclass would also publish the list's own setters, letting a caller replace the sections behind the sidebar's back.
**Approved**: pending

**Decision**: Remote branches are grouped as one flat section per remote (`Remotes · origin`) rather than nested under one `Remotes` header.
**Rationale**: The topic list is deliberately flat (no disclosure, no indentation); a section per remote groups them without a second list type.
**Approved**: pending

**Decision**: The ahead/behind badge and the bold head row are topic-list features (`badge`, `isEmphasized`), not sidebar drawing.
**Rationale**: Built from the shared component upward: any sectioned sidebar can show a count or mark the current row, and the topic list keeps owning its cells.
**Approved**: pending

**Decision**: The data source vends the repository root, so a submodule row can name its directory.
**Rationale**: `git submodule status` reports paths relative to the working tree; the model already knows its root.
**Approved**: pending

**Decision**: `GitHistorySearch` lives in `AgenticDeveloperHubSDKCore`, beside `GitLogQuery`, not with the view.
**Rationale**: It is pure Foundation; the lowest tier that can hold it is Core, where a CLI or another view can parse the same search text.
**Approved**: pending

**Decision**: `sha:` selects among loaded commits rather than filtering the log.
**Rationale**: The search is for finding a commit in context; filtering to one commit would hide the graph around it. A prefix not yet loaded selects nothing.
**Approved**: pending

**Decision**: Paging is asked for when the table requests a row near the end, and not again until the count or the query changes.
**Rationale**: The table only requests rows it is about to show, so the request is the visibility signal; the count guard keeps a finished history from reloading in a loop.
**Approved**: pending

**Decision**: After a page arrives the list reloads itself; the owner's reload on the model's history notification is a second, harmless one.
**Rationale**: The list must not depend on its owner to show the pages it asked for; the owner's reload is still needed for changes the list did not ask for (refresh, refs).
**Approved**: pending

**Decision**: `setQuery` tracks the query it sent and the task sending it, never the data source's query after the first search.
**Rationale**: The model takes the new query before it awaits the log, so its query says nothing about whether results have arrived.
**Approved**: pending

**Decision**: One changed-files list (`GitFileListViewController`) serves the commit detail and both working-copy lists, and its row model `GitFileListItem` lives in `AgenticDeveloperHubSDKCore`.
**Rationale**: The same row in three places is one component (DRY); the item's mapping from a status entry or a diff is pure Foundation, so Core is the lowest tier that can hold it.
**Approved**: pending

**Decision**: The file list, commit detail and working copy delegates take an optional (`GitFileListItem?`, `GitDiffTarget?`) and report nil when the selection clears.
**Rationale**: The owner shows a diff for the selection; without the nil a removed file's diff would stay on screen after a refresh (Review Focus: stale selection clears). The history list's delegate does the same.
**Approved**: pending

**Decision**: The commit detail reports a file as the `GitFileListItem` and the commit, not as a diff target.
**Rationale**: The owner builds the target (`.commit(id, paths:)`) for the diff view; the item carries the old path a rename's diff needs.
**Approved**: pending

**Decision**: The commit detail's latest-call-wins check is its own counter, bumped before it awaits, and the list empties when a different commit is shown.
**Rationale**: A check on state the content source changes before it awaits would let an older diff through; emptying at once means the header and the files never disagree.
**Approved**: pending

**Decision**: The commit detail lists the diff's files rather than a separate `--name-status` call.
**Rationale**: The diff is the one source the content source offers and its parser already reads renames, copies and binaries; a second call per commit is a second process for the same facts.
**Approved**: pending

