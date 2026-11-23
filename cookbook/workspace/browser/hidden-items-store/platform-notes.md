
- **SwiftUI**: Not applicable as a home; the store imports only Foundation,
  GRDB and the toolkit's database module, so a SwiftUI host would use it
  unchanged.
- **AppKit / UIKit**: The store is in the toolkit's database tier, below
  the browser pane, so a daemon can serve the same lists:
  `BrowserHiddenItemsStore` in
  `Database/Daemon/Browser/BrowserHiddenItemsStore.swift`,
  with the value types `BrowserHiddenItem`, `BrowserHiddenItemList`
  (`user`, `agent`) and `BrowserHiddenItemScope` (`thisItem`, `allLikeIt`)
  in `BrowserHiddenItem.swift`. Consumers hold the protocol
  `BrowserHiddenItemsStoring` (`AnyObject, Sendable`, in
  `BrowserHiddenItemsStoring.swift`), whose operations are all
  `async throws`: `items(list:for:)`, `allItems(list:)`,
  `enabledSelectors(list:for:)`, `isSiteSwitchOn(list:site:)`, `add(_:)`,
  `setEnabled(_:_:)`, `remove(_:)` and `setSiteSwitch(list:site:on:)`, plus
  `changes: AsyncStream<Void>`. The local store conforms with async
  wrappers over its synchronous operations, each run through its `perform`
  off the main thread, and keeps `open(at:)`, `defaultURL` and
  `didChangeNotification`, which is
  `Notification.Name.browserHiddenItemsDidChange` (in
  `BrowserStoreChanges.swift`): every conforming store posts it with itself
  as the object after each committed write, and its `changes` is
  `BrowserStoreChanges.stream(of:from:)` over it. Opened
  through `BoundedDatabase` as `BrowserHistoryStore` is, with tables
  `hidden_item` (index on `(list, site)`) and `site_switch` (primary key
  `(list, site)`) in migration `v1`. Site matching and the default pattern
  are `PrivacySitePattern.matches(_:url:)` and
  `PrivacySitePattern.defaultPattern(for:)`. `WebBrowserWindowsFeature`
  opens it at launch with `BrowserHiddenItemsStore.openCurrent(at:onFailure:)`
  into `BrowserHiddenItemsStore.current`, typed
  `(any BrowserHiddenItemsStoring)?`,
  unless a host or test already set one (`hasCurrent`, which answers without
  waiting). `openCurrent` opens on a global `userInitiated` queue. Callers
  that can run during launch await
  `BrowserHiddenItemsStore.currentStore() async`, which awaits the
  `PendingOpen` in flight (`value()`, resumed in `finish`), answers nil
  when the open failed, and awaits again when a setter or a newer open
  replaced the pending one: `WebKitBrowserEngine`'s hidden-items read (its
  first runs when the engine is made), the pane's
  `openHiddenItemsStore() async` behind its three toolbar actions (each run
  in a `Task`), and the pane's `agentPageSource(engine:) async`, since a
  tab restored into an agent view reads during launch. The blocking
  `current` getter (a main-actor read waits on the `PendingOpen`'s
  `NSCondition`) is for callers after launch only; the one left is
  `BrowserToolSet`'s default `hiddenItems` closure. Setting `current`
  replaces an open in flight. A file that cannot be opened is logged through
  `onFailure` and leaves `current` nil, which every consumer takes as no
  store. A host that keeps the lists elsewhere (a daemon's adapter) sets
  its own `BrowserHiddenItemsStoring` as `current`. Main-actor callers
  await the protocol's operations, so no file access runs on the main
  thread.
- **Compose**: Room or SQLDelight over one database file, two tables of the
  same shape; post changes on a `SharedFlow`.
- **React/Web**: IndexedDB with two object stores; changes announced with
  a `BroadcastChannel` so other tabs re-render.
- **WinUI 3**: Microsoft.Data.Sqlite on a file under the app's local
  folder; changes raised as a .NET event on the store.

