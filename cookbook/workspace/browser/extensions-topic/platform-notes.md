
- **SwiftUI**: Not applicable as a home — the topic is AppKit; a SwiftUI host
  would use a `Table` with a toolbar-style header and `.popover` on the gear.
- **AppKit / UIKit**: `SafariExtensionsTopicPanel` (available macOS 15.4+) on a
  `ComposableSettings.EditableTableCard` with column ids `on`, `icon`, `name`,
  `version`, `description`, `gear`, `showsAddRemove = false` and
  `hidesHeaderWhenEmpty = false`; the description cell is
  `BrowserExtension.summary`. Name and Version widths are computed on every
  reload from `NSCell.cellSize` of every cell, header included, plus 12 pt;
  the table uses `uniformColumnAutoresizingStyle` and only the description
  column has `resizingMask = .autoresizingMask` (every other column `[]`, min =
  max = width), then `sizeToFit`. The header buttons are borderless
  `NSButton` subviews of the table's `NSTableHeaderView`, pinned trailing by
  Auto Layout, symbols `plus` and `arrow.triangle.2.circlepath`, with
  `toolTip`s that are also their accessibility labels. The gear shows an
  `NSPopover` (`behavior = .transient`, `preferredEdge: .maxY`) hosting
  `SafariExtensionDetailsView`, anchored to `frameOfCell(atColumn:row:)` of
  the gear; the details view has no Back control. Downloaded… uses an
  `NSOpenPanel` sheet and `SafariExtensionHost.installDownloaded(at:presentingOn:)
  async throws -> Bool`; URL… uses `ExtensionURLPromptController`, validating
  with `WebStoreExtension.id(from:)`, and a `.crx` address goes to
  `SafariExtensionHost.install(fromAddress:presentingOn:)`. A downloaded
  item's record id is `WebStoreExtension.id(ofKey:)` of its manifest `key`
  when present, else `WebStoreExtension.localID(forPath:)` of its path or
  address, both Chrome's SHA-256 a–p mapping. Chrome Web Store… calls
  `WebBrowserWindowController.showExtensions(_:store:purpose:)`; Apple App
  Store… opens `SafariAppExtension.storeURL`.
- **Compose**: A desktop `LazyColumn` table with a header row of icon buttons
  and a `Popup` from the gear; a `FileDialog` for Downloaded….
- **React/Web**: A table with a header toolbar, a popover component anchored to
  the gear, and an `<input type="file">` accepting `.crx,.zip` plus a directory
  picker.
- **WinUI 3**: A `ListView` with a grid header, a `MenuFlyout` on +, a
  `Flyout` anchored to the gear, `FileOpenPicker`/`FolderPicker`, and
  `ToolTipService.ToolTip`.

