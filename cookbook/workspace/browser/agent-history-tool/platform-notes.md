
- **AppKit / UIKit**: `public enum BrowserAgentHistoryAccess: String,
  Codable, CaseIterable, Sendable { case all, currentTab, none }` with
  `displayName`; `UserSettings.browserAgentHistoryAccess` keyed
  `"browser.agent.history_access"`, default `.none`, listed in
  `BrowserSettings.allKeys` and not in `globalOnlyKeyNames`; the row lives in
  `SessionPrivacySettingsPanel`'s History group. `BrowserHistoryTool.run(access:query:limit:store:backForward:privacy:)`
  returns the reply string from a `BrowserHistoryStore?` and
  `[BrowserVisitLine]` (`title`, `url`, `when: Date?`), concealing each field
  through the agent page's string path,
  `AgentPageBuilder(privacy:hideImages: false).conceal`, which applies
  `BrowserAgentPrivacy.concealing(_:)` (whose filter already adds the
  percent- and form-escaped forms, `includingURLForms`) and answers an empty
  string under a closed privacy. `BrowserPaneHandle` exposes the pane's
  effective access, its effective Hide Images (`hidesImages`, a required
  initializer argument with no default, which the page-reading tools build
  under and this tool does not read) and the driven tab's `WKBackForwardList`
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

