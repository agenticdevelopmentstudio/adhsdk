
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
    `ref`, and `allLikeItAllowed` (`allLikeIt` names a class, its tag is
    not in `neverLikeIt` — `html`, `head`, `body`, `main` — and
    `allLikeItCount <= pageElementCount / 2`). `BrowserElementPicker.js`
    returns no looser selector for an element with no stable class or a
    tag in its own `NEVER_LIKE_IT`.
  - `BrowserSelectingMode` (`@MainActor final class`) with
    `State { idle, selecting, dialog(BrowserPickCandidate) }`,
    `init(engine:store:list:button:settings:presentDialog:presentNotice:)`
    (`button` is the address box's `BrowserHideItemsButton`, which keeps
    the symbol it shows; the presenters default to the real dialog and
    notice and are injected by tests), `begin()`, `end(_ reason:)` (the
    reason is what the log names); a local key monitor catches Esc while
    selecting, in the pane's window only. `canSelect(on:)` is false when
    `PrivacySitePattern.defaultPattern(for:)` is `everywhere`: `begin()`
    beeps and the save beeps and logs. A save the store throws on logs and
    beeps. The pane's `updateHideItemsAvailability()` disables both
    hide-items buttons by it (keeping each enabled while its own selecting
    runs) on every page change and tab switch, and
    `closeHiddenItemsPopovers()` closes both popovers on navigation commit,
    a front-page change, tab switch and pane discard. `WebBrowserPaneViewController`
    owns one, made for a WebKit engine on first use (any other engine
    beeps), and ends it on navigation commit, tab switch, tab close, engine
    replacement or rebuild, and pane discard.
  - `BrowserPickDialogController`: an `NSWindow` run app-modal by
    `present(over:)` through the shared `AppModalWindowSession`
    (`AgenticDeveloperHubSDKCoreMacOS`), held as `modalSession`. The
    preview is applied with
    `WebKitBrowserEngine.setPreviewHiddenSelectors(_:)` before the modal
    loop and from the checkbox action inside it; WebKit keeps running in
    the modal panel run-loop mode. OK, Cancel and `dismiss()` (selecting
    mode ending under the dialog, which arrives in a WebKit callback and
    saves nothing) all go through `endSession()`, which ends the session
    (posting an event so `stopModal` takes effect from no event) and
    orders the window out. The session enters `NSApp.runModal(for:)` on
    the run loop's next pass (`performOnNextRunLoopPass`, a
    `CFRunLoopPerformBlock`), out of the script-message callback the pick
    arrived in, so `present(over:)` returns at once; never from
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
    reloads on `didChangeNotification`. A row checkbox finds its row with
    `tableView.row(for:)` when clicked (no `tag`), and a failed write
    beeps.
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

