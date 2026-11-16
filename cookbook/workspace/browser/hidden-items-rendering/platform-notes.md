
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
  `webView(_:didCommit:)`, and also reads the selectors for a main-frame
  navigation's destination in its policy decision, before the new
  document starts, so the document-start script already carries that
  address's rules (WebKit injects document-start scripts in the web
  process before the commit reaches the delegate); a navigation that fails
  provisionally puts the committed address's rules back. Reads go through
  the store's `perform` off the main thread, and a generation counter
  keeps only the last read asked for; a read answers `HiddenItemsRead`
  (`selectors`, `superseded`, `failed`), and awaits the store with
  `BrowserHiddenItemsStore.sharedStore()`, never blocking on it, since an
  engine made at launch reads before the store's open is done. The
  navigation read in the policy decision (`prepareHiddenItems`, through
  `preparedHiddenItemSelectors`) reads again when a store-change refresh
  supersedes it, since that refresh read the page being left, up to
  `hiddenItemsPrepareAttempts` (3) times. When every one of those is
  superseded and the engine is not torn down, one last read runs with
  `checkingGeneration: false`, which claims no generation and cannot be
  superseded; if it fails the document starts with no rules (`[]`), never
  the previous site's. Teardown, or a read inside the loop that fails
  outright, keeps the current rules. When a page's Content Security
  Policy refuses inline styles the element gets no sheet, so the rules go
  in an adopted constructed sheet instead (which `style-src` does not
  govern) and the element stays as the marker. Each rule goes in through its own
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

