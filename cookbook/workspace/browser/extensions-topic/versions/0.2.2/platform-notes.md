
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
  `NSOpenPanel` sheet and
  `SafariExtensionHost.installDownloaded(at:presentingOn:appModalWithoutWindow:)
  async throws -> Bool`, passing `appModalWithoutWindow` true when the topic
  has no window, so the confirmation `NSAlert` runs with `runModal()`
  instead of a sheet; the topic reports an error with
  `NSAlert(error:).runModal()` when it has no window. URL… uses
  `ExtensionURLPromptController` (message text only, no `informativeText`),
  validating with `WebStoreExtension.id(from:)`, and a `.crx` address goes to
  `SafariExtensionHost.install(fromAddress:presentingOn:)`, which reads it
  with `SafariExtensionLibrary.download(from:limit:session:)`: a
  `URLSession.bytes` stream refused past `maximumDownloadSize` (128 MB),
  checked against `expectedContentLength` first and every byte after; the
  store's `download(id:session:)` goes through it too. Every install path
  (downloaded, address, store `install(crx:)`, app extension) stages in
  `Task.detached(priority: .userInitiated)` and calls `refuseLinks`, which
  throws `Failure.symbolicLink` when `SafariExtensionLibrary.symbolicLink(in:)`
  finds one; that answers `"."` for a root that is not a directory (an
  lstat) or cannot be enumerated, the item itself when its
  `isSymbolicLinkKey` cannot be read, and the failing path when the
  enumerator's error handler fires. The confirmation is asked by
  `InstallKind` (`new`, `update`, `replacement(String)`); `installLocal`
  sets `replacement` with the installed one's display name when a keyed id
  is already installed, and `installStaged` then grants nothing from the
  old record and, after commit, sets `isFromWebStore` false, `appSource`
  nil, `sourceMissing` false and clears `grantedPermissions` and
  `grantedOrigins`. A downloaded
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

