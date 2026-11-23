
- **SwiftUI**: Not applicable as a home; the store imports only Foundation,
  GRDB and the toolkit's database module, so a SwiftUI host would use it
  unchanged.
- **AppKit / UIKit**: `BrowserHiddenItemsStore` in
  `macOS/Features/BrowserPane/HiddenItems/BrowserHiddenItemsStore.swift`,
  with the value types `BrowserHiddenItem`, `BrowserHiddenItemList`
  (`user`, `agent`) and `BrowserHiddenItemScope` (`thisItem`, `allLikeIt`)
  in `BrowserHiddenItem.swift`. Operations: `open(at:)`, `defaultURL`,
  `items(list:for:)`, `enabledSelectors(list:for:)`, `add(_:)`,
  `setEnabled(_:_:)`, `remove(_:)`, `isSiteSwitchOn(list:site:)`,
  `setSiteSwitch(list:site:on:)`, and `didChangeNotification`. Opened
  through `BoundedDatabase` as `BrowserHistoryStore` is, with tables
  `hidden_item` (index on `(list, site)`) and `site_switch` (primary key
  `(list, site)`) in migration `v1`. Site matching and the default pattern
  are `PrivacySitePattern.matches(_:url:)` and
  `PrivacySitePattern.defaultPattern(for:)`. `WebBrowserWindowsFeature`
  opens it at launch with `BrowserHiddenItemsStore.openShared(at:onFailure:)`,
  unless a host or test already set one (`hasShared`, which answers without
  waiting). `openShared` opens on a global `userInitiated` queue. Callers
  that can run during launch await
  `BrowserHiddenItemsStore.sharedStore() async`, which awaits the
  `PendingOpen` in flight (`value()`, resumed in `finish`), answers nil
  when the open failed, and awaits again when a setter or a newer open
  replaced the pending one: `WebKitBrowserEngine`'s hidden-items read (its
  first runs when the engine is made), the pane's
  `openHiddenItemsStore() async` behind its three toolbar actions (each run
  in a `Task`), and the pane's `agentPageSource(engine:) async`, since a
  tab restored into an agent view reads during launch. The blocking
  `shared` getter (a main-actor read waits on the `PendingOpen`'s
  `NSCondition`) is for callers after launch only; the one left is
  `BrowserToolSet`'s default `hiddenItems` closure. Setting `shared`
  replaces an open in flight. A file that cannot be opened is logged through
  `onFailure` and leaves `shared` nil, which every consumer takes as no
  store. Main-actor callers go through an async `perform`
  wrapper, as with `BrowserHistoryStore`, so no file access runs on the
  main thread.
- **Compose**: Room or SQLDelight over one database file, two tables of the
  same shape; post changes on a `SharedFlow`.
- **React/Web**: IndexedDB with two object stores; changes announced with
  a `BroadcastChannel` so other tabs re-render.
- **WinUI 3**: Microsoft.Data.Sqlite on a file under the app's local
  folder; changes raised as a .NET event on the store.

