
- **SwiftUI**: Not applicable as a home — the settings are AppKit
  `ComposableSettings`; a SwiftUI host would show the same topics as `Form`
  sections in a `NavigationSplitView`, keys unchanged.
- **AppKit / UIKit**: The container is `BrowserSettingsPanelViewController`
  (`ComposableSettings.SettingsPanelSplitViewController`); each topic is a
  `BrowserTopicPanel(title:symbol:binding:)` subclass. New:
  `BrowserBehaviorPanel` (symbol `hand.tap`) and `BrowserAppearancePanel`
  (symbol `textformat.size`); `BrowserGeneralPanel` keeps only User Agent and
  gains the Media and Web Inspector groups; `BrowserPrivacySettingsPanel`
  (`SessionPrivacySettingsPanel.swift`) is retitled "Privacy and Security" and
  gains the five groups. Removed: `BrowserHistoryPanel`,
  `BrowserCookiesPanel`, `BrowserMediaPanel` and `SafariBrowserTopicPanel`.
  `BrowserSiteDataWindowController: NSWindowController` with
  `init(siteData: BrowserSiteData, removeAllDetail: String? = nil)` (the
  confirmation's detail, worded for the jar) and `runModal(for: NSWindow)`
  holds the
  `ComposableSettings.EditableTableCard` the Safari topic built; its window
  has `.titled`, `.closable`, `.resizable` style and is run with
  `NSApp.runModal(for:)`, not as a sheet. The recording gate is a static
  `recordsHistory(globalRecords:paneIsPrivate:) -> Bool` (or a small
  `BrowserHistoryRecordingPolicy`). The agent history setting is
  `public enum BrowserAgentHistoryAccess: String, Codable, CaseIterable,
  Sendable { case all, currentTab, none }` with `displayName`, and
  `UserSettings.browserAgentHistoryAccess` keyed
  `"browser.agent.history_access"`, listed in `BrowserSettings.allKeys` and not
  in `globalOnlyKeyNames`. Per-pane overrides go through
  `LayeredSettingsStore` and `BrowserSettingsBinding.add(...)`, which draws the
  override marker. Tooltips are `NSButton.toolTip` (a segmented control's
  per segment, `setToolTip(_:forSegment:)`). The privacy toolbar's row in
  `WebBrowserPaneViewController` also holds the Hide elements from agent
  button and the Agent view control (recipes
  `workspace/browser/hide-from-agent` and `workspace/browser/agent-views`),
  which `toolbar-buttons-have-tooltips` covers too. The pane's effective
  Hide Images is `agentHidesImages`, read from its own layered settings,
  the one value the browser tools (`BrowserPaneHandle.hidesImages`) and
  the agent views build under. `browser.hidden_items.notice_shown` (the
  element picker's one-time notice) is in `globalOnlyKeyNames` and not in
  `BrowserSettings.allKeys`, so it has no row.
- **Compose**: Desktop settings as a list-detail layout; each topic a
  composable over a shared settings repository, keys unchanged; the Site Data
  window a `DialogWindow` with `resizable = true`.
- **React/Web**: A settings route per topic; the Site Data window a
  modal dialog that can be dragged and resized; tooltips via `title`.
- **WinUI 3**: A `NavigationView` with one page per topic; the Site Data window
  a separate modal `AppWindow` with an `OverlappedPresenter` that is
  resizable; tooltips via `ToolTipService.ToolTip`.

