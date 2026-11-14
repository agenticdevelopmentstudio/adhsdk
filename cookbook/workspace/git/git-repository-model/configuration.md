
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `root` | `URL` | none | The working tree the model reads. |
| `client` | `GitClient` | `.shared` | The door every git call goes through. |
| `watcher` | `GitRepositoryWatching` | none | What reports changes; `GitRepositoryWatcher` in the app, a fake in tests. |
| `query` | `GitLogQuery` | `GitLogQuery()` (all branches, tags, remotes and HEAD; 500 per page) | Which history to load; replaced with `setQuery(_:)`. |
| debounce | `TimeInterval` | 0.3 s | The watcher's quiet period before it reports. |

