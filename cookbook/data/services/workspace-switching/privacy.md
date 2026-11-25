
- **Data collected**: None of its own. It reads the caller's workspace rows
  (slug, name, type) and their preferred workspace slug.
- **Storage**: Workspace rows live only in the in-memory query cache. The
  preferred slug is kept in the browser's cached-workspace storage
  (plaintext, Resource Data's `<prefix>:home:workspace`) and in the
  in-memory item cache; neither is a credential.
- **Transmission**: The preferred slug is sent to the caller's own account
  row through Resource Data's workspace-preferences write; rows are read
  through the shared authenticated request layer.
- **Retention**: In-memory entries follow the shared query cache's lifetime
  and are cleared when the signed-in principal changes. The browser-cache
  slug persists until overwritten or cleared by the host.

