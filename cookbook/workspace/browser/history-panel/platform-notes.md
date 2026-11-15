
- **macOS (AppKit)**: The list model is
  `@MainActor public final class BrowserHistoryListModel` with
  `init(store: BrowserHistoryStore, pageSize: Int = 200)`,
  `private(set) var visits: [BrowserVisit]`, `var filter: String`,
  `func reload() async`, `func remove(_ ids: [Int64]) async`,
  `func clearAll() async` and `var onChange: (() -> Void)?`. It calls the
  store's `recent(limit:)` and `search(_:limit:)`, `remove(visit:)` and
  `removeAll()`, all inside `BrowserHistoryStore.perform(_:)`, which runs
  them off the main actor (`store-work-off-ui-thread`). The panel is
  `public final class BrowserHistoryPanelViewController: NSViewController`
  with `init(model:open: @escaping (URL) -> Void)`; it styles its filter
  field and source list after `TopicListViewController` (the Settings
  sidebar, which hosts its search field in the list's header accessory),
  shows rows in an `NSTableView`, and confirms Clear History… with an
  `NSAlert` sheet on the hosting window. Tooltips are `toolTip` on each
  `NSButton`. The window is
  `public final class BrowserHistoryWindowController: SingleWindowController`
  with `public static let windowID = "web-history"` and
  `public static func show()`; its shelf follows
  `ProjectShelfViewController` (a `ThemedBox` card with an `IconTabBar` of
  panel buttons across the top, one item "History"), and
  `SingleWindowController` saves and restores frame and visibility under
  the window id. `WebBrowserWindowsFeature` registers the window id and the
  Show History command. Opening a visit uses the key window's focused
  browser pane as a new tab, otherwise `WebBrowserWindowController.openNew`.
  The recording gate is one function,
  `recordsHistory(globalRecords:paneIsPrivate:) -> Bool` returning
  `globalRecords && !paneIsPrivate`, on `WebBrowserPaneViewController` or a
  small `BrowserHistoryRecordingPolicy`; every record call goes through it.
- **SwiftUI**: Model the list model as an `@Observable` class; bind a
  `.searchable` or `TextField` to `filter` and cancel the previous reload
  `Task` on each change to get `latest-filter-wins`. Show rows in a
  `List(selection:)` with the sidebar list style, `.help` for tooltips, a
  `.confirmationDialog` for Clear History…, and `.onSubmit` /
  `.contextMenu(primaryAction:)` for opening. The window is a
  `Window(id:)` scene, which is single by construction.
- **Compose / Windows**: The same split applies: a view model exposing the
  listed visits as observable state with a cancellable reload per filter
  change, a list view taking that model and an open callback, and a
  single-instance window hosting it. Every button carries a tooltip
  (`TooltipBox` / `ToolTipService.ToolTip`).

