
- **Null and empty input**: A null list with no error shows "Loading…" (MUST). An empty list shows "No
  services yet." (MUST). A service with no models shows the text "No models yet — Connect or Refresh." (MUST). A
  model with no display name shows its id (MUST). Missing numbers show an em dash ("—") (MUST).
- **Boundary values**: Context or max-output of exactly 1,000 shows "1K" and exactly 1,000,000 shows
  "1.0M" (MUST). A base URL holding any `{word}` token is refused on create (MUST). A name of only
  spaces counts as blank (MUST).
- **Unknown id**: A selected id that matches no loaded service, such as one just deleted, shows the select
  hint and never a blank pane (MUST).
- **Concurrent access**: Two services panes and the persona editor share one cache entry, so a write in
  one is visible in the others once the entry is revalidated (MUST). Two people switching the same model
  at once is decided by the server's last write; the screen does no merging (not determinable from
  source).
- **Error states**: A failed list read is shown (MUST). A failed save or delete shows its message
  (MUST). A failed create keeps the modal open and shows the error message, or "Failed to create."
  (MUST). A failed template read degrades to an empty catalog (MUST). A failed connect or refresh
  request is reported and shows its message beside its button until the button is pressed again (MUST). A failed
  availability call is reported, shows an error line and leaves the checkbox at the service's last
  known state (MUST).
- **Offline or disconnected state**: The screen does no offline handling of its own. With no
  connection the list read fails and is shown as an error, and every write fails as described above;
  nothing is queued or retried (MUST NOT retry).
- **Template with both URL and header variables**: Both prompt sets render, the Base URL substitutes
  only URL values, and the header values ride in the connection spec on create (MUST).
- **Editing a service made from a template**: The editor does not re-prompt for URL or header
  variables, because they cannot be recovered from the stored URL; it edits the resolved base URL (MUST).
- **Dirty draft and object-valued fields**: The draft's URL and header value maps are compared by
  identity, so re-enabling prompts in the editor would make Save read as permanently dirty; they MUST be
  encoded as primitives first. Today the editor never renders them.
- **Provider fixed**: The provider cannot change after creation (MUST).
- **Model no longer offered**: A model switched off and then dropped by the provider stays in the list
  as "No longer offered" so it can be cleared, and ticking it back on removes its off record (MUST).

