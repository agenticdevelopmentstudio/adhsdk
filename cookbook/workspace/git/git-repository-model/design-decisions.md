
**Decision**: The model is reached through four protocols, one per view family, rather than as one concrete type.
**Rationale**: Each view needs a narrow slice, and a fake of that slice is a few lines, so view tests need no repository.
**Approved**: pending

**Decision**: The watcher reports kinds of change, and the model reloads by kind rather than by path.
**Rationale**: git's own files say which part changed (a ref, the index, an operation's state file); reloading a whole part is cheap and avoids patching state from paths.
**Approved**: pending

**Decision**: A failed load keeps the last value instead of clearing it or surfacing an error.
**Rationale**: A repository deleted or moved under an open window should leave the window readable, and a transient failure (a lock held by another git) heals on the next event.
**Approved**: pending

**Decision**: Staged and unstaged come from the existing status parser, which keeps each column too, not from a second parser.
**Rationale**: One porcelain parser; the merged map the file browser uses and the per-column maps come from the same pass.
**Approved**: pending


**Decision**: `perform(_:)` refreshes every kind after any action, and after a failure too.
**Rationale**: Which parts an action touches is git's knowledge, not the caller's (a checkout moves refs, history and the working copy; a failed merge leaves conflicts); one full refresh is cheap and the watcher's later event finds nothing new.
**Approved**: pending

**Decision**: `isPerforming` goes false before the post-action refresh, not after it.
**Rationale**: The refresh is what observers react to; if they saw it still true, controls they disable while performing would stay disabled until some unrelated later change.
**Approved**: pending
