
This is an extension of the project database that holds the browser jar
registry: the `browser_jars` table (created by migration 5) and the queries
that read the saved layout to decide which browser panes still exist. A jar is
one browser storage container (a `WKWebsiteDataStore` identifier), and what
shares it: every browser pane in one worktree's tabs (a worktree jar) or one
pane alone (a pane jar).

It defines three value types and one set of database operations:

- `BrowserJarRecord`: one jar row, whose `id` is the WebKit store identifier
  itself, so the row and the store on disk are named by one value.
- `LiveBrowserPane`: a browser pane still present in a saved layout, with the
  worktree it works in, used by the jar reconciler to tell a jar in use from a
  leftover.
- `BrowserJarRecord.Kind`: `worktree` or `pane`.
- Operations on `ProjectDatabase`: find, insert, relabel, list and delete jar
  rows, read creation dates, list the live panes and live pane ids, and the
  upgrade step `keepExistingBrowserPanesOnTheSharedJar`.

Everything here is non-visual and synchronous. The code that creates the
stores, applies a grace period and deletes leftovers (the registry and
reconciler) lives in the browser pane feature and calls these operations; this
extension owns only the table and the layout queries. The base
`ProjectDatabase` supplies the SQLite connection and the shared `executeBound`,
`forEachRow`, `bindText`, `bindOptionalText` and `columnText` helpers.

