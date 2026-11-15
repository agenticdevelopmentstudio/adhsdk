
- **SwiftUI**: Not applicable as a home — the topic is AppKit; a SwiftUI host
  would use a `Table` with a toolbar-style header and `.popover` on the gear.
- **AppKit / UIKit**: `SafariExtensionsTopicPanel` (available macOS 15.4+) on a
  `ComposableSettings.EditableTableCard` with column ids `on`, `icon`, `name`,
  `version`, `description`, `gear`; the description cell is
  `BrowserExtension.summary`. Name and Version widths are computed in
  `viewWillAppear` from `NSCell.cellSize` of every cell plus 12 pt; the
  description column has `resizingMask = .autoresizingMask` and the table a
  `columnAutoresizingStyle` that leaves only it flexible. The header buttons
  sit in the header row as an accessory, symbols `plus` and
  `arrow.triangle.2.circlepath`, with `toolTip`s. The gear shows an `NSPopover`
  (`behavior = .transient`, `preferredEdge: .maxY`) hosting
  `SafariExtensionDetailsView`, anchored to the gear cell's rect; its Back
  control is not needed there. Downloaded… uses `NSOpenPanel` and
  `SafariExtensionHost.installDownloaded(at:) async throws`; URL… uses
  `ExtensionURLPromptController`, validating with `WebStoreExtension.id(from:)`.
  Chrome Web Store… calls `WebBrowserWindowController.showExtensions(_:store:purpose:)`;
  Apple App Store… opens `SafariAppExtension.storeURL`.
- **Compose**: A desktop `LazyColumn` table with a header row of icon buttons
  and a `Popup` from the gear; a `FileDialog` for Downloaded….
- **React/Web**: A table with a header toolbar, a popover component anchored to
  the gear, and an `<input type="file">` accepting `.crx,.zip` plus a directory
  picker.
- **WinUI 3**: A `ListView` with a grid header, a `MenuFlyout` on +, a
  `Flyout` anchored to the gear, `FileOpenPicker`/`FolderPicker`, and
  `ToolTipService.ToolTip`.

