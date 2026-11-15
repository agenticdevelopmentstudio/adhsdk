
- **Null commit fields**: A null `commitHash`, `commitRepo` or `commitMessage` MUST yield `sha`, `commitUrl` and `message` of null, and `commitBody` of null (row-model-003).
- **Empty strings**: The commit-URL function called with an empty repository or an empty hash MUST return null. An empty `environment` MUST produce an empty env column in the row-text function's output, and an empty `sha` or `message` MUST be dropped from the commit column.
- **Unknown problem state**: A state absent from the state-label table MUST render verbatim (row-model-005). The server's documented state vocabulary contains only the seven names in state-label-table.
- **Unknown source**: A row's `source` that is not a known issue-source identifier (an activity row's `kind` fallback) MUST appear verbatim in the clipboard source column (row-model-025).
- **Malformed `at`**: A row's `at` is documented as an ISO timestamp. An unparseable value makes the relative-time calculation produce a non-numeric duration and render `"NaNd"`; this MUST be treated as a caller precondition violation, not handled here.
- **Future `at`**: A timestamp later than the current time gives a negative elapsed time and MUST render `"just now"`.
- **Unconfirmed activity phase**: A row with verb `"unknown"` and tone `"stale"` MUST keep that word and tone however old `at` is, and render in the muted stale color, not bold (row-model-027, row-model-028).
- **Tabs and newlines in clipboard fields**: Not escaped; see the open question on text-field-escaping (row-model-033).
- **Commit subject over 200 characters**: `message` MUST be the first 200 characters with no ellipsis, while `commitBody` and the search-text function keep the full text.
- **Concurrent access**: Not applicable — every export is pure and synchronous, so calls cannot interleave.
- **Error states**: Not applicable — no function touches a network, file or other dependency, and none throws for well-formed input.
- **Offline or disconnected state**: Not applicable — no network is involved; freshness of the server data is judged elsewhere, by other logic outside this module.

