
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `source` | `GitRefsDataSource` | none | Where the sidebar reads refs, stashes, submodules, worktrees and the repository root. |
| `delegate` | `GitRefsSidebarDelegate?` | nil | Told what the user selected. |
| `source` (history) | `GitHistoryDataSource` | none | Where the history list reads commits, graph rows, the query and the refs at a commit, and asks for pages and queries. |
| `delegate` (history) | `GitHistoryDelegate?` | nil | Told which commit is selected, or nil. |
| `identifier` (file list) | `String` | none | The list's context (`commit`, `staged`, `unstaged`); its root identifier is `git.fileList.<identifier>`. |
| `files` (file list) | `[GitFileListItem]` | `[]` | The rows. |
| `delegate` (file list) | `GitFileListDelegate?` | nil | Told which item is selected, or nil. |
| `source` (detail) | `GitContentSource` | none | Where the commit detail reads the commit's diff. |
| `pasteboard` (detail) | `NSPasteboard` | `.general` | Where the copy button puts the sha. |
| `delegate` (detail) | `GitCommitDetailDelegate?` | nil | Told which parent link and which file were chosen. |
| `source` (diff) | `GitContentSource` | none | Where the diff reads diffs and contents. |
| `coloring` (diff, blame, file history) | `GitSyntaxColoring?` | none | Syntax colour; nil shows text uncoloured. |
| `settings` (diff, file history) | `SettingsStore` | `UserSettings.shared` | Where the layout and toggles are stored. |
| `delegate` (diff) | `GitDiffDelegate?` | nil | Told when Blame or History is pressed. |
| `delegate` (blame) | `GitBlameDelegate?` | nil | Told which commit a sha click chose. |
| `source` (working copy) | `GitWorkingCopyDataSource` | none | Where the working copy reads its staged and unstaged files. |
| `delegate` (working copy) | `GitWorkingCopyDelegate?` | nil | Told the selected file's diff target, or nil. |

