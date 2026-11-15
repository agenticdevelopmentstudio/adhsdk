
- **SwiftUI**: Not applicable — the renderer is WebKit user-script work
  owned by the engine, not a view.
- **AppKit / UIKit**: Planned as `enum BrowserHiddenItemsStyle` in
  `macOS/Features/BrowserPane/HiddenItems/BrowserHiddenItemsStyle.swift`,
  with `styleElementID = "__adk_hidden_items"`, `css(selectors:)`,
  `installScript(selectors:)` and `applyScript(selectors:)`, beside
  `BrowserHiddenImages`, whose pattern it follows: a `WKUserScript` at
  `.atDocumentStart` plus an `evaluateJavaScript` apply to the live page.
  The script is added in `WebKitBrowserEngine.installUserScripts()`, the
  only place user scripts are added or removed
  (`WKUserContentController` can only remove all of them). The engine
  re-runs it on `BrowserHiddenItemsStore.didChangeNotification` and in
  `webView(_:didCommit:)`. Each rule goes in through its own
  `CSSStyleSheet.insertRule` in a `try`/`catch`, after a
  `CSS.supports('selector(…)')` check. The preview rule set is
  `WebKitBrowserEngine.setPreviewHiddenSelectors(_ selectors: [String]?)`,
  `nil` removing it.
- **Compose**: An Android `WebView` has no document-start user script;
  use `WebViewCompat.addDocumentStartJavaScript` from AndroidX WebKit, and
  `evaluateJavascript` for the live apply, passing selectors through a JSON
  string.
- **React/Web**: As a browser extension, a content script at
  `document_start` builds the same style element; `CSSStyleSheet.insertRule`
  per rule gives the same isolation.
- **WinUI 3**: WebView2's `AddScriptToExecuteOnDocumentCreatedAsync` for
  the document-start script and `ExecuteScriptAsync` for the live apply,
  with selectors serialized by `System.Text.Json`.

