
- **AppKit / UIKit**: `public enum BrowserAgentHistoryAccess: String,
  Codable, CaseIterable, Sendable { case all, currentTab, none }` with
  `displayName`; `UserSettings.browserAgentHistoryAccess` keyed
  `"browser.agent.history_access"`, default `.none`, listed in
  `BrowserSettings.allKeys` and not in `globalOnlyKeyNames`; the row lives in
  `SessionPrivacySettingsPanel`'s History group. `BrowserHistoryTool.run(access:query:limit:store:backForward:privacy:)`
  returns the reply string from a `BrowserHistoryStore?` and
  `[BrowserVisitLine]` (`title`, `url`, `when: Date?`), concealing each field
  with `BrowserAgentPrivacy.concealing(_:)`, whose filter already adds the
  percent- and form-escaped forms (`includingURLForms`). `BrowserPaneHandle`
  exposes the pane's effective access and the driven tab's `WKBackForwardList`
  entries (current item first, then the back list newest first; forward
  entries are listed after them). `BrowserToolSet` adds the definition and
  dispatch, puts `browser_history` in `readToolNames`, and runs
  `requireAccess(for:on:)` first, which raises `closedRefusal()`. Refusals are
  `ToolError(sentence:)`.
- **SwiftUI**: The row is a `Picker` bound to the layered setting; the tool
  is shared non-UI code.
- **Compose**: A dropdown setting; the tool reads the WebView's
  `copyBackForwardList()` for Current tab only.
- **React/Web**: A select setting; Current tab only reads the driven tab's
  navigation history as the host browser exposes it.
- **WinUI 3**: A `ComboBox` setting; Current tab only reads WebView2's
  navigation history.

