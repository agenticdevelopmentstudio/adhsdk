
- **SwiftUI**: Not applicable as a home; the popover and dialog are AppKit,
  matching the address bar they belong to.
- **AppKit / UIKit**: Built as follows, all under
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
    `init(engine:store:list:button:settings:presentDialog:presentNotice:)`
    (`button` is the address box's `BrowserHideItemsButton`, which keeps
    the symbol it shows; the presenters default to the real dialog and
    notice and are injected by tests), `begin()`, `end(_ reason:)` (the
    reason is what the log names); a local key monitor catches Esc while
    selecting, in the pane's window only. `WebBrowserPaneViewController`
    owns one, made for a WebKit engine on first use (any other engine
    beeps), and ends it on navigation commit, tab switch, tab close, engine
    replacement or rebuild, and pane discard.
  - `BrowserPickDialogController`: an `NSWindow` run with
    `NSApp.runModal(for:)`. The preview is applied with
    `WebKitBrowserEngine.setPreviewHiddenSelectors(_:)` before the modal
    loop and from the checkbox action inside it; WebKit keeps running in
    the modal panel run-loop mode. OK and Cancel end the loop with
    `stopModal`; selecting mode ending under the dialog (navigation, say)
    arrives in a WebKit callback, where only `abortModal` works, and saves
    nothing. The dialog runs on the run loop's next pass
    (`performOnNextRunLoopPass`, a `CFRunLoopPerformBlock`), out of the
    script-message callback the pick arrived in; never from
    `DispatchQueue.main.async`, whose block the modal loop would hold, and
    with it every MainActor task. Each picker start waits for the previous
    one; a mode ended before its start runs installs nothing, one ended
    during it stops the picker afterwards, and `start()` re-checks
    `isRunning` after each evaluation.
  - `BrowserHiddenItemsPopover(list:store:url:onSelect:)`, an `NSPopover`
    with `.transient` behavior. A transient popover closes on the
    mouse-down, before the button's action runs on the mouse-up, so
    `popoverWillClose` records the event number of a press on its anchor
    (`noteClosing(by:)`) and `closesOnAnchorClick(_:)` treats only a mouse
    event carrying that number as the closing toggle (any other click
    clears the record and opens the popover; a press released off the
    button leaves nothing behind); the trailing button is added to
    `BrowserAddressBox` in `BrowserAddressBarControls.swift`.
  - `BrowserHiddenItemsPopover` is the `NSViewController` that owns its
    `NSPopover`; it reads and writes the store through `perform` and
    reloads on `didChangeNotification`.
  - The notice is an informational `NSAlert`, run as a sheet on the pane's
    window; `browser.hidden_items.notice_shown` is written to the global
    layer before it shows.
- **Compose**: An Android `WebView` has no named content worlds; inject the
  picker with `evaluateJavascript` under a random global name and post
  through `WebMessageListener`, accepting that the page shares the world.
- **React/Web**: As a browser extension, the picker is a content script
  (its own isolated world) messaging the extension's background; the
  dialog is a draggable in-page overlay inside a closed shadow root.
- **WinUI 3**: WebView2 runs scripts in the page's world unless an
  extension is used; post picks with `chrome.webview.postMessage`.

