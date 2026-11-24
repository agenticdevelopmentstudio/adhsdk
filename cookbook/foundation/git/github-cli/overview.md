
A client for the GitHub CLI, `gh`, that answers pull request questions for the repository a directory belongs to: whether pull requests can be shown at all, the list, the pull request of a branch, checking one out and creating one. `gh` is the user's own tool, logged in by the user; the client never stores a token, never reads `gh`'s configuration and never chooses a host. `GitHubCLI` is an actor with an injected runner and an `ExecutableLocator`, and it is the only place that spawns `gh`. Every call is recorded in the git command log with `tool` `gh`.

