
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| browser-menu-001 | menu-after-view, contributed-not-hosted | Build the main menu with the web browser windows feature composed | A "Browser" menu sits directly after View and before Projects, and its items are exactly the feature's contributions in the browser slot |
| browser-menu-002 | item-order, stable-item-ids | Read the Browser menu's items | Titles in order "Reload", "Stop", "Back", "Forward", separator, "Show History", "Show Privacy Toolbar", with ids `browser.reload`, `browser.stop`, `browser.back`, `browser.forward`, `browser.show-history`, `browser.toggle-privacy-toolbar` |
| browser-menu-003 | fixed-reload-stop-keys | Read Reload's and Stop's key equivalents; list the registry's descriptors | Reload is Command-R, Stop is Command-period; neither id appears in the registry |
| browser-menu-004 | page-commands-target-engine | With a stub engine as the target, choose Reload, then Stop, then Back, then Forward | The stub records reload, stop-loading, go-back, go-forward, one call each, in that order |
| browser-menu-005 | target-is-key-window-pane | The standalone browser window is key | That window's pane is the target |
| browser-menu-006 | target-is-key-window-pane | A projects window is key and its browser pane was focused last | That pane is the target |
| browser-menu-007 | target-is-key-window-pane | The last focused browser pane is in a window that is not key; the key window has no browser pane | There is no target |
| browser-menu-008 | disabled-without-target, show-history-always-enabled | No target (the Settings window is key) | Every item but Show History disabled; validating and opening the menu does not crash |
| browser-menu-009 | back-forward-follow-engine | Target engine reports cannot go back, can go forward | Back disabled, Forward enabled |
| browser-menu-010 | back-forward-follow-engine | Target engine reports can go back, cannot go forward | Back enabled, Forward disabled |
| browser-menu-011 | stop-follows-loading | Target engine reports not loading, then loading | Stop disabled, then enabled |
| browser-menu-012 | show-history-always-enabled | Choose Show History with no target | The History window opens |
| browser-menu-013 | privacy-toolbar-title-follows-pane | Target pane's effective show-privacy-toolbar is off, then on | Title "Show Privacy Toolbar", then "Hide Privacy Toolbar" |
| browser-menu-014 | privacy-toolbar-writes-pane-override | Global show-privacy-toolbar off, target pane has no override; choose the item | The pane's layered store has an override set to on; the global value is still off; the pane's popover checkbox reads on |
| browser-menu-015 | back-forward-in-registry | Read the registry's "Web Browser" section | Exactly two descriptors, `browser.back` (Command-[) and `browser.forward` (Command-]) |
| browser-menu-016 | menu-key-follows-binding | Set `browser.back`'s binding to Command-Option-Left in the registry | The Back item's key equivalent and modifiers become Command-Option-Left without rebuilding the menu |
| browser-menu-017 | cleared-binding-no-key | Disable `browser.back`'s binding; then clear `browser.forward`'s shortcut | Back's key equivalent is empty; Forward's key equivalent is empty |
| browser-menu-018 | no-duplicate-menu-key | Try to rebind `browser.forward` to Command-R (Reload's key) or to Back's current key | The rebind is refused as a conflict and no two menu items show one key |
| browser-menu-019 | fixed-keys-not-conflicts | Keep the default Back and Forward bindings and read the registry's conflicts | No conflict is reported between Back/Forward and Reload/Stop |
| browser-menu-020 | bridge-is-generic | A contribution in another slot names a key command id; another names none and a fixed key | The first follows the registry; the second keeps its fixed key |
| browser-menu-021 | show-history-always-enabled | No history store set; validate Show History with and without a target | Disabled both times |
| browser-menu-022 | back-forward-keys-need-focus | Project window whose last-focused browser pane can go back; first responder in an editor pane beside it; run the `browser.back` key command | The pane does not go back; with the first responder inside the pane it does |
| browser-menu-023 | back-forward-keys-need-focus | Target pane can go back and forward but does not have keyboard focus; validate and choose Back and Forward, then Reload | Back and Forward are disabled and record no call; Reload is enabled and records reload |

