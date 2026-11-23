
- **SwiftUI**: The source is
  `packages/apple/AgenticDeveloperHubSDK/Database/Daemon/Projects/ProjectDatabase.swift`,
  in the Database tier (`AgenticDeveloperHubSDKDatabase`), importing only
  `Foundation`, `SQLite3` (the C SQLite library linked directly, not
  `Core Data` or `SwiftData`) and `AgenticDeveloperHubSDKCore`; it depends
  on no UI framework, so a daemon links it as readily as an app. The
  registry conformance is the sibling `ProjectDatabase+Registry.swift`, and
  the layout and browser-jar extensions stay in the macOS tier, reaching the
  connection through `@_spi(ProjectDatabaseStorage)`. `ProjectDatabase` is a
  `final class` declared `@unchecked Sendable`, holding an `NSRecursiveLock`
  (`lock`) around every transaction and registry call — the mechanism behind
  **transactions-and-registry-calls-serialized** — and a separate `NSLock`
  guarding the live change streams, so a change is announced after the
  write's lock is released. Its one connection is stored as
  `database: OpaquePointer?`, opened in `init(path:upgrades:)` and closed in
  `deinit` only when non-`nil` — the mechanism behind
  **connection-closed-on-teardown**. `init(path:upgrades:)` takes a
  `ProjectDatabase.Upgrades` defaulting to `.none`; the macOS tier supplies
  `ProjectDatabase.Upgrades.windowState`, whose `browserJars` step is the
  one an app's own `Projects.db` must pass. The raw insert is
  `insertRow(_:)`; the registry's `insert(_:)` refuses any kind but
  `project` with `ProjectDatabaseError.notAProject`. The registry's
  `async` requirements are witnessed by synchronous methods, so a caller
  holding the concrete type calls them synchronously and one holding
  `any ProjectRegistry` awaits them.
- **Compose**: Port the SQLite access with `androidx.sqlite` or a light
  wrapper over `android.database.sqlite.SQLiteOpenHelper`/`SQLiteDatabase`,
  keeping the same one-connection-per-store shape; run the seven migrations
  inside `SQLiteDatabase.beginTransactionNonExclusive()`/`endTransaction()`,
  re-issue the `foreign_keys=ON` pragma per connection the same way opening
  the connection does here, and represent `GitRepo` as the Kotlin `data
  class` the sibling `GitRepo` recipe already specifies.
- **React/Web**: A browser has no filesystem or SQLite; if this pattern is
  ported into a Node-hosted process (e.g. an Electron main process or a
  local dev server), use `better-sqlite3` or `node:sqlite`, apply the same
  `PRAGMA journal_mode=WAL`, `PRAGMA foreign_keys=ON`, and a busy-timeout
  equivalent (`better-sqlite3`'s `pragma('busy_timeout = 5000')`), and run
  the migration chain inside one transaction — checking `PRAGMA table_info`
  for column existence the same way this file's column-existence check
  does before any `ALTER TABLE`.
- **AppKit / UIKit**: Identical to the SwiftUI note — nothing in this file
  is tied to a UI framework; it ports unchanged to either, or to a headless
  command-line tool, since this component's own design rationale for the
  default path explicitly notes "this is the same registry the command
  line tools read".
- **WinUI 3**: Port with `Microsoft.Data.Sqlite` (or the raw `sqlite3`
  P/Invoke layer for closer fidelity) rather than `Windows.Storage`'s
  roaming or local settings APIs, since this component's contract is
  relational rows with foreign-key cascades, not key-value settings
  storage. Open the connection, then issue `PRAGMA journal_mode=WAL;` and
  `PRAGMA foreign_keys=ON;` immediately after, exactly as opening the
  connection does here, and issue `PRAGMA busy_timeout=5000;` to match the
  5-second wait (`Microsoft.Data.Sqlite` has no dedicated
  `SQLITE_OPEN_FULLMUTEX` flag, but serializes access per connection by
  default, preserving the same one-connection, thread-safe-by-default
  shape). Run the seven migrations inside a transaction opened with `BEGIN
  IMMEDIATE;`/`COMMIT;`/`ROLLBACK;` issued as raw command text the way this
  file's own execute operation does, guarding each `ALTER TABLE` with a
  `PRAGMA table_info('table')` read the way this file's column-existence
  check does. Model `GitRepo` as the C# `record` the sibling `GitRepo`
  recipe specifies, and keep this component's own operations
  synchronous — this file performs every SQL call synchronously on the
  caller's thread — letting a `Task.Run` at the call site, not inside this
  component, move a call off a UI dispatcher thread.
- **transactions-and-registry-calls-serialized**: On Apple platforms the class carries no actor isolation; it is `@unchecked Sendable` because its own recursive lock serializes every transaction and registry call.

