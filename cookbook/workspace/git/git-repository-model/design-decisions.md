
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

