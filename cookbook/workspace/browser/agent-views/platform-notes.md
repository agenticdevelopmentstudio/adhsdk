
- **SwiftUI**: Host the AppKit controllers through
  `NSViewControllerRepresentable`; a `Picker` with `.segmented` style and
  `.help(_:)` per item stands in for the control.
- **Compose**: A `SingleChoiceSegmentedButtonRow` with
  `TooltipBox` per segment; the preview is a `WebView` with
  `javaScriptEnabled = false`, `blockNetworkLoads = true`, and a
  `WebViewClient` whose `shouldOverrideUrlLoading` returns true.
- **React/Web**: The preview is an `iframe` with `srcdoc` set to the HTML,
  `sandbox=""` (no scripts, no navigation) and a CSP meta of
  `default-src 'none'` in the document; the source view is a `pre` with
  escaped, highlighted spans.
- **AppKit / UIKit**: The reference home. `BrowserAgentViewMode`
  (`website`, `agentPreview`, `agentSource`); an `NSSegmentedControl`
  (`.selectOne`, images only, `setToolTip(_:forSegment:)`) in
  `WebBrowserPaneViewController`'s privacy strip.
  `BrowserAgentPreviewViewController` owns a `WKWebView` with
  `defaultWebpagePreferences.allowsContentJavaScript = false`, the
  `WKContentRuleList` from `BrowserContentRules.blockEverything()`
  (`[{"trigger":{"url-filter":".*"},"action":{"type":"block"}}]`,
  compiled once), `loadHTMLString(page.html(), baseURL: nil)`, a navigation
  delegate whose `decidePolicyFor` cancels everything after the initial
  load, and `keepPaintingUnderQuietPresentation()` for the Debug occlusion
  workaround. `BrowserAgentSourceViewController` is a non-editable
  `NSTextView` with a small HTML highlighter building
  `NSAttributedString` attributes from the theme. Refresh listens for the
  engine's navigation finish, `UserSettings` changes of the privacy keys,
  privacy-word changes and `BrowserHiddenItemsStore.didChangeNotification`,
  and calls `AgentPageSource.agentPage(options:)`. Under UIKit,
  `UISegmentedControl` and a read-only `UITextView`; the web view is the
  same.
- **WinUI 3**: A `Segmented` control (Windows Community Toolkit) with
  `ToolTipService.ToolTip` per item; the preview is a WebView2 with
  `IsScriptEnabled = false`, a `WebResourceRequested` filter on `*` that
  answers every request with a blocked response, and `NavigationStarting`
  cancelling all but the `NavigateToString` load; the source view is a
  read-only `RichTextBlock`.

