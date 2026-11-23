
| Input | Supplied by | Default | Effect |
|---|---|---|---|
| `repoID` | caller, every public method | none (required) | Scopes every read/write to one repository id; no method here accepts an unscoped or wildcard query. |
| `tabs` | caller, writing tabs | none (required) | The whole tab-and-tree arrangement to persist; replaces whatever was previously stored for the repository id. |
| `activeTabID` | caller, writing tabs | none (required, may be absent) | Persisted only if it names one of the given tabs; otherwise dropped to `NULL` (**save-tabs-active-tab-validated**). |
| `enabledEdges` | caller, writing tabs | absent (no choice) | The user's explicit Tab Bars choice; persisted in canonical order regardless of the argument's own order. Absent keeps whatever choice is already stored (none, stored as the empty string, for a project that never made one). |
| `nodeID`, `key` | caller, pane-state operations | none (required) | Identifies one pane-scoped state slot. |
| `value` | caller, setting pane state | none (required, may be absent) | An absent value deletes the row; any other value upserts it verbatim, with no format validation. |
| `liveIDs` | caller, pruning nested pane state | none (required) | The set of node ids the caller currently considers alive; anything embedded in a stored key but absent from this set is pruned. |
| `paths` | caller, saving project directories | none (required) | The full replacement list of extra browsed directories for the repository id, in order. |

This extension reads no environment variable and no settings key of its
own; the database file's location is entirely the base project database's
concern, not this extension's.

