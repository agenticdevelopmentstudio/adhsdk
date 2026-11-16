
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
  opens it at launch into `BrowserHiddenItemsStore.shared`, unless a host or
  test already set one; a file that cannot be opened is logged and leaves
  `shared` nil, which every consumer takes as no store. Main-actor callers go through an async `perform`
  wrapper, as with `BrowserHistoryStore`, so no file access runs on the
  main thread.
- **Compose**: Room or SQLDelight over one database file, two tables of the
  same shape; post changes on a `SharedFlow`.
- **React/Web**: IndexedDB with two object stores; changes announced with
  a `BroadcastChannel` so other tabs re-render.
- **WinUI 3**: Microsoft.Data.Sqlite on a file under the app's local
  folder; changes raised as a .NET event on the store.

