
- **SwiftUI**: Nothing here is view code; the builder imports Foundation
  only, and the page source needs WebKit. A SwiftUI host uses both
  unchanged.
- **Compose**: Run the walker with `WebView.evaluateJavascript` in a
  `WebViewCompat.addDocumentStartJavaScript` isolated script; decode with
  kotlinx.serialization into the same payload shape; build the page in a
  pure Kotlin object holding the allowlist; HTML-escape with
  `TextUtils.htmlEncode`.
- **React/Web**: In an extension context, run the walker as a content
  script in an isolated world (`chrome.scripting.executeScript` with
  `world: "ISOLATED"`), passing the allowlist as `args`; build and
  escape on the extension side, never with `innerHTML` of page content.
- **AppKit / UIKit**: The reference home. `AgentPageBuilder` (a `Sendable`
  struct: `build(payload:error:) -> AgentPage`, `conceal(_:)`) is pure
  Swift; `AgentPageSource` (`@MainActor`) runs `AgentPageWalker.js` with
  `WKWebView.callAsyncJavaScript(_:arguments:in:contentWorld:)` in
  `BrowserSnapshotRuntime.world` (the `adkitchen.automation` content
  world), passing `AgentPageAllowlist.standard` JSON-encoded as an
  argument, the agent-list selectors from
  `BrowserHiddenItemsStore.enabledSelectors(list: .agent, for:)`, and the
  timeout. Concealment is `BrowserAgentPrivacy.concealing(_:)`, except that
  the string path returns `""` for `.unavailable`/`.conflicting`.
  `BrowserToolSet` routes `browser_snapshot`, `browser_text`,
  `browser_find`, `browser_wait_for` text and the action-reply titles
  through it; `rawPageRefusal(pane:)` gates `browser_screenshot`,
  `browser_click_at` and `browser_evaluate`; `BrowserAutomation` routes
  dialog messages and the focused-element description. Same code under
  UIKit's `WKWebView`.
- **WinUI 3**: Run the walker with WebView2's
  `CoreWebView2.ExecuteScriptAsync` from a script added with
  `AddScriptToExecuteOnDocumentCreatedAsync`, passing the allowlist as a
  JSON argument; decode with `System.Text.Json`; build with
  `WebUtility.HtmlEncode` for every string.

