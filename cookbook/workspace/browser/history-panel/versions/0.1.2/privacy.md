
- **Data collected**: The addresses and titles of pages visited in
  non-private browser panes, with the time of each visit, recorded only
  while Record history is on. Nothing is recorded while a pane is in
  private browsing (`private-browsing-never-records`).
- **Storage**: The browser history store's own local SQLite file, separate
  from the project database so it can be cleared or deleted wholesale. The
  list model holds at most one page of visits in memory.
- **Transmission**: None — the panel and window send nothing anywhere.
  Which agents may read history is a separate setting and tool, outside
  this component.
- **Retention**: As long as the Keep visits for setting allows, until the
  user removes visits or clears all here; removal and Clear History delete
  from the store, not just from the list.

