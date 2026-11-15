
- **SwiftUI**: Not applicable as a home; the popover and dialog are AppKit,
  matching the address bar they belong to.
- **AppKit / UIKit**: Planned as follows, all under
  `macOS/Features/BrowserPane/HiddenItems/`:
  - `BrowserElementPicker` (`@MainActor final class`, `NSObject`,
    `WKScriptMessageHandler`) with `contentWorldName = "adk-element-picker"`,
    `messageHandlerName = "adkitchenPicker"`,
    `init(webView:list:onPick:onCancel:)`, `start() async throws`,
    `pause()`, `resume()`, `stop()`. `start` adds the handler for
    `WKContentWorld.world(name:)` and evaluates `vendor/finder.js` (exposed
    as `__adkFinder`) and `BrowserElementPicker.js` in that world; both are
    bundled resources, as `BrowserSnapshot.js` is.
  - `BrowserPickCandidate` (`Decodable`, `Sendable`) with `kind`,
    `thisItem`, `allLikeIt`, `allLikeItCount`, `pageElementCount`, `label`,
    `ref`, and `allLikeItAllowed` (`allLikeIt != nil &&
    allLikeItCount <= pageElementCount / 2`).
  - `BrowserSelectingMode` (`@MainActor final class`) with
    `State { idle, selecting, dialog(BrowserPickCandidate) }`,
    `init(engine:store:list:button:)`, `begin()`, `end()`; a local key
    monitor catches Esc while selecting. `WebBrowserPaneViewController`
    owns one and ends it on navigation commit, tab switch and close.
  - `BrowserPickDialogController`: an `NSWindow` run with
    `NSApp.runModal(for:)`. The preview is applied with
    `WebKitBrowserEngine.setPreviewHiddenSelectors(_:)` before the modal
    loop and from the checkbox action inside it; WebKit keeps running in
    the modal panel run-loop mode.
  - `BrowserHiddenItemsPopover(list:store:url:onSelect:)`, an `NSPopover`
    with `.transient` behavior; the trailing button is added to
    `BrowserAddressBox` in `BrowserAddressBarControls.swift`.
  - The notice is an informational `NSAlert`.
- **Compose**: An Android `WebView` has no named content worlds; inject the
  picker with `evaluateJavascript` under a random global name and post
  through `WebMessageListener`, accepting that the page shares the world.
- **React/Web**: As a browser extension, the picker is a content script
  (its own isolated world) messaging the extension's background; the
  dialog is a draggable in-page overlay inside a closed shadow root.
- **WinUI 3**: WebView2 runs scripts in the page's world unless an
  extension is used; post picks with `chrome.webview.postMessage`.

