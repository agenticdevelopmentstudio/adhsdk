
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
  delegate whose `decidePolicyFor` cancels every subframe navigation and
  allows a main-frame `.other` navigation to `about:blank` (or no URL)
  only while `allowedLoads` is above zero, spending one credit per allow
  (each `loadHTMLString` adds one; the end of the latest own
  `WKNavigation`, in `didFinish`, `didFail` or
  `didFailProvisionalNavigation`, zeroes it, and the end of a superseded
  one changes nothing; a `loadHTMLString` that returns no navigation takes
  its credit back). The delegate method only unpacks the action and
  calls the internal `decidePolicy(targetFrameIsMain:url:navigationType:)`
  with `targetFrame?.isMainFrame` (nil when the action has no target frame;
  the seam cancels anything but `true`), which tests call
  directly with plain values, since WebKit does not support subclassing
  its frame and action classes; the pure rule is
  `policy(allowedLoads:url:navigationType:)`. The preview also calls
  `keepPaintingUnderQuietPresentation()` for the Debug occlusion
  workaround. `BrowserAgentSourceViewController` is a non-editable
  `NSTextView` with a small HTML highlighter building
  `NSAttributedString` attributes from the theme: `show(_:)` sets the
  text with no runs, then lexes it with
  `BrowserAgentSourceHighlighter.tokens(in:)` in a `Task.detached`
  (`highlighting`, cancelled by the next `show`) and applies
  `highlight(_:tokens:font:colors:)` only if the HTML is still the one
  shown. `BrowserAgentViews.setMode(_:)` shows `AgentPage.blank` when
  leaving Website and the last page when moving between agent modes,
  then starts the rebuild. Refresh listens for the
  engine's navigation finish, `UserSettings` changes of the privacy keys,
  privacy-word changes and `BrowserHiddenItemsStore.didChangeNotification`,
  and calls `AgentPageSource.read(options:keepingRefs: true)` (a reading
  walk, so the agent's refs stay valid), built by the same
  `AgentPageSource.reading(_:hiddenItems:privacy:hideImages:)` the tools use
  (through `WebBrowserPaneViewController.agentPageSource(engine:)`, which
  passes the pane's effective Hide Images, `agentHidesImages`, and awaits
  the hidden-items store with `BrowserHiddenItemsStore.currentStore()`,
  since a tab restored into an agent view reads during launch).
  The agent view is laid over the tab's page holder, which is hidden, not
  removed, so the live page keeps its state. Under UIKit,
  `UISegmentedControl` and a read-only `UITextView`; the web view is the
  same.
- **WinUI 3**: A `Segmented` control (Windows Community Toolkit) with
  `ToolTipService.ToolTip` per item; the preview is a WebView2 with
  `IsScriptEnabled = false`, a `WebResourceRequested` filter on `*` that
  answers every request with a blocked response, and `NavigationStarting`
  cancelling all but the `NavigateToString` load; the source view is a
  read-only `RichTextBlock`.

