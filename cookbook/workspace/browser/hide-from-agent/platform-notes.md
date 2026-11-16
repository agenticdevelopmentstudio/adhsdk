
- **SwiftUI**: Not applicable — AppKit, like the privacy toolbar it sits
  in.
- **AppKit / UIKit**: `BrowserHideFromAgentButton` in
  `macOS/Features/BrowserPane/HiddenItems/BrowserHideFromAgentButton.swift`
  is the address box's `BrowserHideItemsButton` with the agent's symbol,
  tooltip and identifier; `WebBrowserPaneViewController` puts it in the
  privacy strip's row before the Agent view control. Its menu starts the
  pane's one `BrowserSelectingMode` with `list: .agent` (and, in the Agent
  preview, `preview:` the `BrowserAgentPreviewViewController`, through the
  `BrowserAgentPickSurface` protocol), or shows
  `BrowserHiddenItemsPopover(list: .agent, …)`. A preview pick's `ref` is
  resolved against the preview's `shownPage` with `AgentPage.node(ref:)`
  and the entry takes `AgentNode.selector`
  (`BrowserSelectingMode.mapPreviewPick`); the entry's site comes from
  the engine's URL, not `AgentPage.url`, which is the concealed address
  (a commit ends selecting, so the engine's URL is the page the preview was
  built from). The dialog's preview hides
  `[data-adk-ref="…"]` with the element picker's preview style, evaluated
  in the picker world. The preview keeps
  `WKWebpagePreferences.allowsContentJavaScript = false`; the picker is
  installed with `evaluateJavaScript(_:in:in:)` in its world, and because
  `loadHTMLString` replaces the document on every rebuild, the preview's
  `onPageLoad` (its `didFinish`) installs it again. The popover toggle: a
  transient `NSPopover` closes on the mouse-down, before the button's
  action runs, so `popoverWillClose` records the event number of the
  mouse-down on its anchor that closed it (`noteClosing(by:)`), and
  `closesOnAnchorClick(_:)` treats only the mouse-up carrying that same
  event number as the toggle; any other click clears the record and opens
  the popover.
- **Compose**: An Android `WebView` cannot run one script with page
  JavaScript off; render the preview natively from the agent page instead
  and pick nodes by their ref directly.
- **React/Web**: Render the preview in a sandboxed iframe without
  `allow-scripts`, with the picker in the parent document reading
  `data-adk-ref` through the iframe's DOM.
- **WinUI 3**: WebView2 with `IsScriptEnabled = false` blocks every
  script; as with Compose, pick from a native rendering of the agent page.

