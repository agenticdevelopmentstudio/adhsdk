
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
  `BrowserToolSet` reads every page through one seam, an `AgentPageReader`
  (`AgentPageSource` in the app, a spy in tests) built per call with the
  privacy that call runs under, and routes `browser_snapshot`,
  `browser_text`, `browser_find`, `browser_wait_for` text and every action
  reply through it. Only the snapshot starts a new ref generation; text,
  find, wait and the focused element read with `keepingRefs: true`
  (`beginWalk(true)` in the snapshot runtime), so the refs of the agent's
  last snapshot stay valid. `rawPageRefusal(pane:tool:)` is async, since
  the agent list is read from the store: it gates `browser_screenshot`,
  `browser_click_at` and `browser_evaluate` before the pane is revealed and
  again once the call is dequeued, and an agent list that cannot be read
  refuses as the unavailable page does. `BrowserAutomation` reports the
  focused element's ref (`BrowserActionDelta.focusedRef`), and the tool set
  renders it from the agent page or omits it, concealing the title and
  dialog message with `AgentPageBuilder.conceal`
  (`BrowserActionDelta.agentView`). The pane list and `browser_history` use
  the same string path. Same code under UIKit's `WKWebView`.
- **WinUI 3**: Run the walker with WebView2's
  `CoreWebView2.ExecuteScriptAsync` from a script added with
  `AddScriptToExecuteOnDocumentCreatedAsync`, passing the allowlist as a
  JSON argument; decode with `System.Text.Json`; build with
  `WebUtility.HtmlEncode` for every string.

