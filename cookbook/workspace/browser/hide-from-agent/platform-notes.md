
- **SwiftUI**: Not applicable — AppKit, like the privacy toolbar it sits
  in.
- **AppKit / UIKit**: Planned as `BrowserHideFromAgentButton` in
  `macOS/Features/BrowserPane/HiddenItems/BrowserHideFromAgentButton.swift`,
  added to the privacy strip by `WebBrowserPaneViewController`; its menu
  starts the pane's one `BrowserSelectingMode` with `list: .agent` and a
  preview target, or shows `BrowserHiddenItemsPopover(list: .agent, …)`.
  In the Agent preview, `BrowserAgentPreviewViewController` hosts the
  picker; the pick's `ref` is resolved with `AgentPage.node(ref:) ->
  AgentNode?` and the entry takes `AgentNode.selector`. Because the
  preview keeps `WKWebpagePreferences.allowsContentJavaScript = false`,
  the picker is installed as a `WKUserScript(…, in: pickerWorld)` and
  through `evaluateJavaScript(_:in:in:)` in that world.
- **Compose**: An Android `WebView` cannot run one script with page
  JavaScript off; render the preview natively from the agent page instead
  and pick nodes by their ref directly.
- **React/Web**: Render the preview in a sandboxed iframe without
  `allow-scripts`, with the picker in the parent document reading
  `data-adk-ref` through the iframe's DOM.
- **WinUI 3**: WebView2 with `IsScriptEnabled = false` blocks every
  script; as with Compose, pick from a native rendering of the agent page.

