
- **Null and empty input**: No key pane — every page item and the privacy
  toolbar item disabled, Show History enabled when there is a history
  store and disabled when there is none, no crash (MUST, see
  `disabled-without-target`, browser-menu-008). A cleared or disabled
  binding leaves the item with no key equivalent (MUST, see
  `cleared-binding-no-key`, browser-menu-017).
- **Boundary values**: A target pane that closes between the menu opening
  and an item being chosen: the action re-resolves the target and does
  nothing when there is none.
- **Concurrent access**: Menu validation, actions and the bridge's update all
  run on the main thread; the registry's change announcement is observed
  there.
- **Error states**: A rebind that collides with another command is refused by
  the registry's conflict check, so the menu never shows a duplicate key
  (MUST, see `no-duplicate-menu-key`, browser-menu-018).
- **Offline or disconnected state**: Not applicable — Reload, Back and
  Forward hand the request to the engine; what the engine does offline is the
  engine's concern.
- **Missing file or unreachable server**: Not applicable — the menu does no
  I/O.
- **Cancellation and timeouts**: Not applicable — every action is a
  synchronous call into the engine or the settings store.
- **Several browser windows**: Only the key window's pane is ever acted on
  (MUST, see `target-is-key-window-pane`, browser-menu-007).
- **Focus beside the pane**: In a project window with an editor or terminal
  focused, Command-[ and Command-] do not navigate the last-focused browser
  pane (MUST, see `back-forward-keys-need-focus`).

