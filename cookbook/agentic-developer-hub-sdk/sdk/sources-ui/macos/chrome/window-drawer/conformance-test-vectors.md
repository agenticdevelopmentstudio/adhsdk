
| ID | Requirements | Input | Expected |
|----|----|-------|---------|
| drawer-001 | open-and-close | Call `open()` on closed drawer. | `isOpen` becomes true; drawer frame is visible. |
| drawer-002 | open-and-close | Call `close()` on open drawer. | `isOpen` becomes false; drawer frame is hidden. |
| drawer-003 | open-with-tab-selection | Call `open(selecting: "help")` with tab ID "help" present. | Drawer opens and body shows "help" tab content. |
| drawer-004 | open-with-tab-selection | Call `open(selecting: "nonexistent")` on a freshly initialized drawer (currently selected tab is the first tab). | Drawer opens; the invalid ID is ignored and the currently selected tab (the first tab) keeps showing. |
| drawer-005 | toggle-state | Call `toggle()` on closed drawer. | Drawer opens on currently selected tab. |
| drawer-006 | toggle-state | Call `toggle()` on open drawer. | Drawer closes. |
| drawer-007 | toggle-state | Call `toggle(selecting: "other")` while open on "help". | Drawer remains open and switches to "other" tab. |
| drawer-008 | toggle-state | Call `toggle(selecting: "help")` while open on "help". | Drawer closes. |
| drawer-009 | lazy-load-tabs | Call `view(forTab: "tab1")` once; call again. | Both calls return the same NSView instance (not newly created). |
| drawer-010 | lazy-load-tabs | Call `view(forTab: "missing")`, where "missing" names no tab. | Returns `nil`; no view is cached. |
| drawer-011 | track-open-state | Observe `isOpen` before and after `open()`. | Returns false initially, true after `open()` completes. |
| drawer-012 | track-selected-tab | Initialize with tabs `[tab1, tab2]`. | `selectedTabID` is "tab1" (first tab). |
| drawer-013 | track-selected-tab | Call `open(selecting: "tab2")`. | `selectedTabID` becomes "tab2". |
| drawer-014 | announce-visibility-changes | Set `onVisibilityChange` callback; call `open()`. | Callback is invoked at least once; it may be invoked twice (once from `open()`, once from the platform's own open notification). |
| drawer-015 | honor-dragged-close | Open drawer; user drags outer edge closed by hand. | Callback is invoked; `closeIsAttributableToTheReader` is true. |
| drawer-016 | honor-dragged-close | Open drawer; call `close()` programmatically. | `closeIsAttributableToTheReader` is false. |
| drawer-017 | honor-dragged-close | Minimize parent window (drawer auto-closes). | `closeIsAttributableToTheReader` is false. |
| drawer-018 | honor-dragged-close | Parent window deallocates. | `closeIsAttributableToTheReader` is false (weak `parentWindow` becomes nil). |
| drawer-019 | clamp-content-width | Set `contentWidth = 150` (below min 220). | `contentWidth` is clamped to 220. |
| drawer-020 | clamp-content-width | Set `contentWidth = 600` (above max 520). | `contentWidth` is clamped to 520. |
| drawer-021 | clamp-content-width | Set `contentWidth = .nan`. | `contentWidth` falls back to default 300. |
| drawer-022 | clamp-content-width | Set `contentWidth = .infinity`. | `contentWidth` falls back to default 300. |
| drawer-023 | expose-content-width | Read `contentWidth` after initialization with default. | Returns 300.0. |
| drawer-024 | expose-content-width | Set `contentWidth = 400`; read it back. | Returns 400.0. |
| drawer-025 | hide-single-tab-strip | Initialize with 1 tab. | `tabStripIsHidden` is true. |
| drawer-026 | hide-single-tab-strip | Initialize with 2+ tabs. | `tabStripIsHidden` is false. |
| drawer-027 | use-tab-symbols | Initialize with tabs specifying SF symbol names. | Each segment displays the symbol image; image is non-nil. |
| drawer-028 | use-theme-colors | Observe `contentView`'s theme role after initialization. | Role is `windowBackground` (not `.surface`); the container and the platform-drawn border chrome match, with no contrast seam at the drawer's edge. |
| drawer-029 | sync-height-at-open | Initialize drawer while parent window frame height is 0; later set frame height to 800. Call `open()`. | `contentHeight` reflects 800 (not 0). |
| drawer-030 | reapply-remembered-state-on-window-key | Set `reapplyVisibility` callback to call `open()`. Initialize drawer; window not yet on-screen. Window becomes key. | Callback is invoked; drawer opens. |
| drawer-031 | accessibility-prefixed-ids | Initialize with `accessibilityPrefix = "help"`; select tab "settings". | Container ID is "help"; strip ID is "help.tabs"; body ID is "help.tab.settings". |
| drawer-032 | release-delegate-on-deinit | Initialize a drawer, release the only strong reference to it, then trigger an event the platform would otherwise deliver to its delegate (e.g., post the parent window's key/main notification). | No crash and no delegate callback fires against the deallocated instance. |

