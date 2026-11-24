
- **Null / empty input**: An empty branch is refused before anything runs. An empty `base` is treated as no base. An empty body is passed as `--body ""`, so `gh` does not open an editor.
- **Boundary values**: A `limit` below 1 is sent as 1. A pull request number below 1 is refused.
- **Malformed input**: A dash-led branch is refused so it cannot be read as a flag. A branch named like a number or URL is still looked up as a head branch. A pull request from a fork whose branch has the same name is not this branch's, and is skipped; so, knowingly, is the user's own pull request opened from their fork (a triangular workflow), which `headRepositoryOwner` is fetched to support later. Output that does not decode is `failed`, never a partial list.
- **Concurrent access**: `GitHubCLI` is an actor, and each call suspends while `gh` runs, so calls do not serialise behind one another.
- **Error states**: See **error-mapping**. A missing `gh` and a `gh` that is not logged in are not errors to show: the caller hides what depends on them.
- **Offline / disconnected state**: `gh` reports the network failure on standard error, which maps to `failed`; a hung network ends at the budget as `timedOut`.
- **Cancellation and timeouts**: A cancelled task's cancellation propagates unchanged and the call is recorded with no exit status; a budget overrun terminates the child and is `timedOut`.

