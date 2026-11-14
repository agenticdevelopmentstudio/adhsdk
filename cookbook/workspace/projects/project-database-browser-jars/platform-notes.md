
- **SwiftUI**: Nothing here is a view; a SwiftUI app calls these operations from a
  model object off the main actor or behind one actor, and may wrap the list in
  an `ObservableObject` for a settings screen. Replace `WKWebsiteDataStore`
  identifiers with the same-named store API.
- **Compose**: Use a Room entity with a unique index on repository plus path
  filtered to `kind = 'worktree'` (a partial index via a raw migration) and a
  unique index on the pane id, a `CHECK` on kind, and `Flow` queries ordered
  by kind descending then created time. The jar identifier maps to an Android
  WebView profile or data directory name (`WebViewCompat` profiles).
- **React/Web**: A browser has no jar concept per pane; an Electron or Tauri
  port maps jars to named partitions (`session.fromPartition`) with the row
  held in SQLite (`better-sqlite3`) using the same unique-index race rule.
- **AppKit / UIKit**: Source file:
  `macOS/Features/Projects/ProjectDatabase+BrowserJars.swift`, using the
  `SQLite3` C API through the base class's helpers, a recursive common table
  expression (`liveNodesCTE`) over `project_tabs`, `layout_nodes` and `git_repo`
  to walk each tab, and `WKWebsiteDataStore` identifiers as jar ids (macOS 14
  and later). UIKit has the same store API; the layout tables are shared.
- **WinUI 3**: Use `Microsoft.Data.Sqlite` with a `SqliteConnection` and
  parameterised `SqliteCommand`s; the table needs a `CHECK (kind IN
  ('worktree','pane'))`, a partial unique index for worktree jars and a unique
  index on `pane_node_id`; translate the live-node query as the same
  `WITH RECURSIVE` statement. `BrowserJarRecord` becomes a `record` with a
  `Guid Id`; `LiveBrowserPane` a `record` (value equality gives set
  comparison); `standardizedPath` becomes `Path.GetFullPath` with
  trailing-separator trimming. A jar maps to a WebView2 user data folder or
  `CoreWebView2Profile` (`CoreWebView2ControllerOptions.ProfileName`) named by
  the id. Unique-index violations surface as `SqliteException` (error code
  19), which replaces the thrown error the source relies on; `SqliteConnection`
  is not thread-safe, so serialise access as the source requires.

