
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `allowlist` | node kinds plus per-kind attribute sets | the standard allowlist (Design Decisions) | What may enter the result; passed to the walker each walk. |
| `privacy` | agent privacy state (off, enabled with words, unavailable, conflicting) | the pane's Agent Privacy | Drives concealment and the fail-closed vault rule. |
| `hideImages` | boolean | the Hide Images setting | Drops image nodes when on. |
| `excludeSelectors` | list of selectors | the site's enabled agent-list entries; no store is the unavailable page | Subtrees the walker never visits. |
| `scope` | reference or selector | none | Subtree of the walk to render. |
| `interactiveOnly`, `depth`, `includeURLs`, `delta` | as today's snapshot options | as today | Unchanged snapshot options. |
| `timeoutMs` | integer milliseconds | 1500 | Walker deadline. |

