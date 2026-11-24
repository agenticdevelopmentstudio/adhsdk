
- **Empty groups list**: When `groups: []`, the list displays the empty state — see **display-empty-state**.
- **All groups empty**: When every group has zero items, the list displays the empty state and no heading is ever rendered — see **render-groups-in-order**, **display-empty-state**.
- **Single item**: When exactly one item exists, ArrowUp and ArrowDown both wrap to the same item — see **arrow-navigation** (cp-030).
- **Loading with items**: When `loading: true` and items are present, both the items and the loading indicator are visible; the items are NOT replaced — see **display-loading-state**.
- **Error with items**: When `error` is set and items are present, both are visible — see **display-error-message**.
- **Error and loading together**: When both `error` and `loading` are truthy, both the error text and the loading indicator render, following the render order of the source — see **display-error-message**, **display-loading-state** (cp-031).
- **Null error state**: When `error` is explicitly `null`, no error text renders. When `error` is `undefined`, it defaults to `null` and no error renders — see **display-error-message**.
- **Query with no matching items**: If the host does not filter its groups and provides `query: "xyz"` with items that don't match it, every item still renders — this is source behavior, not the component's responsibility — see **no-internal-filtering** (cp-026).
- **Very long labels**: Item labels and descriptions are truncated with CSS — see **truncate-long-text**.
- **Icon or badge absent**: When `icon` or `badge` are undefined, no space is reserved for them — see **no-reserved-space-for-missing-icon-badge**.
- **Reopening resets highlight, not query**: When `open` transitions from `true` to `false` to `true`, the highlight resets to the first item (see **reset-highlight-to-first-item**), but `query` remains as the host left it — it is not cleared by the component.

