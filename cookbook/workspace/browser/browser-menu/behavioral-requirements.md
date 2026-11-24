
- **menu-after-view**: The Browser menu MUST be a top-level menu titled
  "Browser", placed immediately after the View menu and before the Projects
  menu.
- **contributed-not-hosted**: The Browser menu's items MUST be supplied by
  the web browser windows feature as menu contributions in a dedicated
  browser slot; the host MUST only reserve the menu's place and build the
  items it is given, holding no browser command of its own.
- **item-order**: The Browser menu MUST list, in this order: Reload, Stop,
  Back, Forward, a separator, Show History, and the privacy toolbar item.
- **stable-item-ids**: The items MUST carry the identifiers
  `browser.reload`, `browser.stop`, `browser.back`, `browser.forward`,
  `browser.show-history` and `browser.toggle-privacy-toolbar`, which do not
  change with an item's title.
- **fixed-reload-stop-keys**: Reload MUST use the fixed key equivalent
  Command-R and Stop the fixed key equivalent Command-period; neither MUST be
  an entry in the Keyboard Shortcuts registry.
- **page-commands-target-engine**: Reload, Stop, Back and Forward MUST call,
  respectively, the target pane's engine's reload, stop-loading, go-back and
  go-forward operations, and nothing else.
- **target-is-key-window-pane**: The target pane MUST be the standalone
  browser window's pane when that window is the key window; otherwise the
  most recently focused browser pane when that pane is in the key window;
  otherwise there MUST be no target. A browser pane in a window that is not
  the key window MUST never be the target.
- **disabled-without-target**: When there is no target pane, every item
  except Show History MUST be disabled, and choosing the menu or validating
  its items MUST NOT crash.
- **back-forward-follow-engine**: Back MUST be disabled when the target
  pane's engine reports it cannot go back, and Forward MUST be disabled when
  it reports it cannot go forward.
- **stop-follows-loading**: Stop MUST be disabled when the target pane's
  engine reports it is not loading.
- **show-history-always-enabled**: Show History MUST be enabled whether or
  not there is a target pane, as long as the host has given the History
  window a history store, and MUST be disabled while there is none;
  choosing it MUST open the History window.
- **privacy-toolbar-title-follows-pane**: The privacy toolbar item's title
  MUST read "Hide Privacy Toolbar" when the target pane's effective
  show-privacy-toolbar value is on, and "Show Privacy Toolbar" when it is
  off.
- **privacy-toolbar-writes-pane-override**: Choosing the privacy toolbar
  item MUST flip the target pane's show-privacy-toolbar value by writing the
  pane's own layered settings store (a per-pane override), the same write the
  checkbox in that pane's privacy popover makes; it MUST NOT change the
  global value.
- **back-forward-in-registry**: Back and Forward MUST be key command
  descriptors with the ids `browser.back` and `browser.forward`, defaulting
  to Command-[ and Command-], in a key command section titled "Web Browser"
  that holds those two descriptors only; the web browser windows feature
  MUST install that section in the shared key command registry.
- **back-forward-keys-need-focus**: The Back and Forward key commands MUST
  act only on a browser pane that has keyboard focus: the standalone
  browser window's pane, or, in another window, the target pane only while
  the window's first responder is inside it (a Chrome pane's attached page
  window counts as inside it). With an editor or terminal focused beside
  the pane they MUST do nothing to the pane, so the keys reach that view.
  The Back and Forward menu items carry those keys, so they MUST follow the
  same rule: enabled, and acting, only for the focused pane, never for a
  target pane that was merely focused last.
- **menu-key-follows-binding**: A menu item that carries a key command id
  MUST display, as its key equivalent and modifiers, the registry's current
  shortcut for that id, and MUST update it whenever the registry announces
  that bindings changed, without the menu being rebuilt.
- **cleared-binding-no-key**: When the registry's binding for a menu item's
  key command is disabled or cleared, that item MUST show no key
  equivalent.
- **no-duplicate-menu-key**: No two items in the menu bar MUST ever display
  the same key equivalent and modifiers as a result of a rebind of Back or
  Forward.
- **fixed-keys-not-conflicts**: The registry MUST NOT report Reload's or
  Stop's fixed keys as conflicts with Back's or Forward's bindings.
- **bridge-is-generic**: The bridge between a menu item and a registered key
  command MUST work for any menu contribution that names a key command id,
  not only the Browser menu's; a contribution that names none MUST keep its
  own fixed key as before.

