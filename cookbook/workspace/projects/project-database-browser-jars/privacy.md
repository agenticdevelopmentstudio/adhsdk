
- **Data collected**: Jar rows hold a project id, a worktree path, an optional
  pane id, a label and a creation time. The labels and paths can reveal what the
  user works on. The jar itself identifies where cookies and site data live, and
  the upgrade exists to stop signing the user out of every site.
- **Storage**: The project database (SQLite) on the local disk; the site data
  lives in WebKit's store named by the jar `id`, outside this file.
- **Transmission**: None through this code.
- **Retention**: A row lives until `deleteBrowserJar` is called by the
  reconciler or a user action; this extension applies no expiry of its own.

