
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `workspaceListLabel.individualFallback` | My Workspace | The list-label helper's answer for an individual workspace with a blank name |
| `workspaceListLabel.fallback` | Workspace | The list-label helper's answer for an organization or team with a blank name |

Both are hardcoded English literals in `workspace-rows.ts`, with no message
catalog or locale parameter. A non-blank name is the backend's own text,
shown as is.

