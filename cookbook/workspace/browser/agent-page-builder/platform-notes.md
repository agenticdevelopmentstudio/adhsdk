
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
  timeout, the scope ref and `hideImages`, then builds the page in a
  `Task.detached(priority: .userInitiated)`, so the decode, the tree build
  and the concealment run off the main actor. Concealment is
  `BrowserAgentPrivacy.concealing(_:)`, except that
  the string path returns `""` for `.unavailable`/`.conflicting`. The
  privacy words come from `PrivacyWordsVault` (Core/Privacy), whose
  `filter(for:)` holds the enabled words whose sites match a page and whose
  `everySiteFilter` holds every enabled word whatever its sites
  (`[PrivacyWord].everySiteFilter`), the one `browser_history` conceals
  with. A walker answer of `{"error":"agent-list"}` (an agent-list
  selector `querySelectorAll` throws on) builds the unavailable page with
  `AgentPageBuilder.agentListReason`.
  `BrowserToolSet` reads every page through one seam, an `AgentPageReader`
  (`AgentPageSource` in the app, a spy in tests) built per call with the
  privacy that call runs under by `BrowserToolSet.agentPageSource(for:privacy:hiddenItems:)`,
  which calls `AgentPageSource.reading(_:hiddenItems:privacy:hideImages:)`
  with the pane's own effective Hide Images (`BrowserPaneHandle.hidesImages`,
  a required handle argument), never a value from the tool set's settings
  store. The Agent preview and Agent source build through the same
  factory (`WebBrowserPaneViewController.agentPageSource(engine:)`, with
  `agentHidesImages`), so the views and the tools build under one value.
  It routes `browser_snapshot`,
  `browser_text`, `browser_find`, `browser_wait_for` text and every action
  reply through it. `AgentPageWalker.js` (runtime version 6, `AgentPageWalkerRuntime.version`;
  the snapshot runtime `BrowserSnapshot.js` is version 4, `BrowserSnapshotRuntime.version`)
  gives element nodes refs from the snapshot runtime's `assignRef`, except
  the `GENERIC_KINDS` (`paragraph`, `label`), which take walk-local `gN`
  refs as text pieces take `tN`, so printed `eN` refs have no gaps (fixture
  `BrowserAutomation/Fixtures/landmarks.txt`). `AgentNodeKind` holds
  `rowGroup`, `columnHeader` and `rowHeader`; the walker maps
  `thead`/`tbody`/`tfoot` and `role="rowgroup"` to `rowGroup`, `th` and
  `role="columnheader"` to `columnHeader`, `role="rowheader"` to
  `rowHeader`, and names both header kinds from content; `AgentPage`
  prints them as `rowgroup`, `columnheader` and `rowheader`, renders
  `rowGroup` as a text block, and emits `tbody`, `th scope="col"` and
  `th scope="row"` in the HTML. `AgentNodeKind` also holds `grid`,
  `treeGrid` and `gridCell` (roles `grid`, `treegrid`, `gridcell`), printed
  as written and emitted as `table` and `td`. With `hideImages` the walker
  skips an `img` element or `role="img"` before it assigns a ref. The
  snapshot runtime's `resolveScope` takes a ref only (no
  `document.querySelector` fallback) and answers nil for a missing,
  disconnected or withheld element; the walker then walks the whole page.
  Each walk hands its excluded elements to the runtime's `setWithheld`, and
  `resolve` and `resolveScope` refuse an element under any of them.
  `BrowserAutomation` observes `BrowserHiddenItemsStore.didChangeNotification`
  and calls `invalidateRefs()`, which runs the runtime's `invalidate()`
  (generation advanced, ref table cleared). Only the snapshot starts a new ref generation; text,
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
  (`BrowserActionDelta.agentView`). Replies and errors are concealed with
  `BrowserAgentPrivacy.combined(with:)` of the privacy the call started
  under and the pane's privacy when it returns. The pane list and `browser_history` use
  the same string path. Same code under UIKit's `WKWebView`.
- **WinUI 3**: Run the walker with WebView2's
  `CoreWebView2.ExecuteScriptAsync` from a script added with
  `AddScriptToExecuteOnDocumentCreatedAsync`, passing the allowlist as a
  JSON argument; decode with `System.Text.Json`; build with
  `WebUtility.HtmlEncode` for every string.

