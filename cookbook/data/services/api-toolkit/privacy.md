
- **Data collected**: None. No given source records or reports user data.
- **Storage**: Nothing is written to local storage, a database, or any durable store. Module-level caches hold only generated metadata indexes and the highlighter.
- **Transmission**: `buildRequest` forwards the caller's token only as an `Authorization` header on a same-origin request; `useCrudResource` sends row values in the request body through `authedJson`. The token is not persisted or logged.
- **Retention**: None.
- Snippets use `YOUR_TOKEN` so copying one to the clipboard cannot leak a live credential.
- The exposure gate narrows what the UI offers; it is documented as not a security boundary, and `useViewer.principal` is exposed so per-viewer caches can be keyed by user.

