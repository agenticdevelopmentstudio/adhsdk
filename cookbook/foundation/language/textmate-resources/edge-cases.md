
- **Null / empty input**: An empty text highlights to one line with no runs; an empty line has no runs.
- **Boundary values**: A grammar embedded by a shipped grammar but itself dropped (YAML front matter in Markdown) is not found, and the engine leaves that region in the embedding grammar's colours.
- **Line endings**: A lone `\r` (classic Mac) ends a line like `\n`; `\r\n` is one break, not two.
- **Concurrent access**: The bundle is single-threaded JavaScript; the host serialises calls on one context.
- **Error states**: `highlight` before `create` resolves, or on a scope with no grammar, rejects with an `Error`. A licence disagreement or missing licence text stops the build with the file named.
- **Offline / disconnected state**: The build needs the npm registry only for `npm ci`; the bundle needs no network.
- **Cancellation**: Not applicable: The resources have no concern of this kind beyond what Behavioral Requirements state.

