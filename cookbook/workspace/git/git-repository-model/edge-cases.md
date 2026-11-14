
- **Null / empty input**: An unborn repository loads empty history and refs; a repository with no stashes, submodules or linked worktrees loads empty lists (worktrees still lists the main one).
- **Boundary values**: A history shorter than one page ends paging after the first load; a refresh after paging reloads at least as many commits as were shown, so the list does not shrink under the user.
- **Concurrent access**: Main actor only. Overlapping loads are ordered by a generation counter: the newest request's result wins, and an older one is dropped.
- **Error states**: A failed git call keeps that part's last value and is logged, never thrown. A deleted repository keeps its last state.
- **Offline / disconnected state**: Not applicable: no network.
- **Cancellation**: A superseded history load still runs to completion, and its result is dropped.
- **Linked worktrees**: The git directory (`<common>/worktrees/<name>`) and the common directory lie outside the working tree, so all three are watched.
- **Event storms**: A checkout or rebase writes many files; the 300 ms debounce folds them into one refresh, and lock files and objects never trigger one.
- **Symlinked location**: A repository under `/tmp` or `/var` is reported by the event stream as `/private/...`; the roots are canonicalised with realpath to match, never with a resolver that strips `/private`.
