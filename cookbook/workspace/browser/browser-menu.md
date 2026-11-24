---
id: 8a4aca5f-977b-4f4c-86f6-16f4150132ac
title: "Browser Menu"
type: ingredient
version: 0.1.3
status: draft
language: en
created: 2026-11-15
modified: 2026-11-16
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The Browser menu: Reload, Stop, Back, Forward, Show History and Show/Hide Privacy Toolbar, aimed at the key window's browser pane, with Back and Forward rebindable through the key-command registry."
platforms:
  - swift
  - macos
tags:
  - browser
  - menu
  - key-commands
  - shortcuts
  - privacy
depends-on: []
related: []
references:
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/BrowserMenuCommands.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/KeyCommands/KeyCommandMenuBridge.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/UI/AppShell/MenuContribution.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/WebBrowserWindowsFeature.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/WebBrowserPaneViewController.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/BrowserMenuCommandsTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/KeyCommands/KeyCommandMenuBridgeTests.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# Browser Menu

## Overview

This component is the application's **Browser** menu: a top-level menu,
placed after View, that gathers the commands a person uses on a web page —
reload it, stop loading it, go back, go forward — together with opening the
History window and showing or hiding the current pane's privacy toolbar.
It is contributed by the web browser windows feature, not written into the
host's menu bar, so the host only reserves the menu's place.

Every page command acts on one target: the browser pane in the key window.
When the key window holds no browser pane the page commands disable rather
than act on a pane in some other window. Back and Forward are also entries
in the Keyboard Shortcuts registry, under a "Web Browser" section, so a
person can rebind them; the menu items' displayed key equivalents follow
whatever the registry currently binds, through a small bridge between a
menu item and a registered key command. Reload and Stop keep fixed keys.

The design is written before the code (design-first, from the more privacy
features design, section 1.2, and its phase 1 plan, Task 3).

## Behavioral Requirements

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

## Appearance

- **Corner radius**: Not applicable — the menu is drawn by the platform's
  menu bar; this component sets no geometry.
- **Padding**: Not applicable — platform menu layout.
- **Font**: Not applicable — platform menu font.
- **Background**: Not applicable — platform menu background.
- **Foreground/Text**: Item titles exactly as listed: "Reload", "Stop",
  "Back", "Forward", "Show History", and "Show Privacy Toolbar" or "Hide
  Privacy Toolbar". Disabled items take the platform's disabled text
  treatment.
- **Border**: Not applicable — platform menu.
- **Shadow**: Not applicable — platform menu.
- **Min/Max size**: Not applicable — platform menu.

## States

| State | Appearance change |
|-------|------------------|
| Target pane present, idle | Reload, Show History and the privacy toolbar item enabled; Stop disabled; Back and Forward enabled as the engine can go back and forward. |
| Target pane loading | Stop enabled. |
| No target pane | Reload, Stop, Back, Forward and the privacy toolbar item disabled; Show History enabled when there is a history store. |
| No history store | Show History disabled, whatever the target pane. |
| Privacy toolbar shown on target | Toggle item titled "Hide Privacy Toolbar". |
| Privacy toolbar hidden on target | Toggle item titled "Show Privacy Toolbar". |
| Back/Forward rebound | The item's displayed key equivalent changes to the new binding. |
| Back/Forward binding cleared or disabled | The item shows no key equivalent. |
| Pressed / Focused | Not applicable — platform menu tracking. |
| Loading | Not applicable — the menu itself never waits; "loading" above is the target pane's state, which only drives Stop. |

## Accessibility

- **Role/trait**: Standard menu and menu items, exposed by the platform's
  menu bar.
- **Label requirements**: Each item's accessible label is its title; the
  privacy toolbar item's label changes with its title. Each item carries an
  accessibility identifier derived from its stable item id rather than its
  title, so a test can address the toggle under either title.
- **Announce state changes**: Not applicable — enablement and titles are
  re-evaluated when the menu opens; nothing is announced while it is closed.
- **Keyboard navigation**: Standard menu navigation; Back and Forward are
  reachable by the person's own bindings, Reload and Stop by their fixed
  keys.
- **Minimum hit target**: Not applicable — platform menu rows.
- **Contrast**: Not applicable — platform menu rendering.

## Conformance Test Vectors

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

## Edge Cases

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

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `browser.back` binding | key command binding | Command-[ | Back's shortcut, rebindable in Keyboard Shortcuts › Web Browser. |
| `browser.forward` binding | key command binding | Command-] | Forward's shortcut, rebindable in Keyboard Shortcuts › Web Browser. |
| `browser.privacy.show_toolbar` | bool, per pane over global | off | Read for the toggle's title; written as a per-pane override by the toggle. |
| key pane provider | injected closure | key window's browser pane | Supplies the target pane; injected so tests can supply a stub. |
| show history action | injected closure | opens the History window | What Show History does. |

## Deep Linking

Not applicable: the menu defines no URL scheme or route.

## Localization

Item titles ("Reload", "Stop", "Back", "Forward", "Show History", "Show
Privacy Toolbar", "Hide Privacy Toolbar") and the key section's title ("Web
Browser") are user-facing strings and localize with the app's other menu
titles. Item ids and key command ids are never localized.

## Accessibility Options

Not applicable: platform menus already honor the system's display options;
the component reads none itself.

## Feature Flags

Not applicable: the menu is always present; no flag gates it.

## Analytics

Not applicable: the menu emits no analytics event.

## Privacy

The Show/Hide Privacy Toolbar item writes only the target pane's
show-privacy-toolbar override. The menu reads no page content and stores
nothing else.

## Logging

Not applicable: the design asks for no log line of the menu's own.

## Platform Notes

- **AppKit / UIKit**: The menu slot is a new `MenuContribution.Slot.browser`
  ("Browser menu, after View"), and `MenuManager.buildMainMenu` builds the
  Browser submenu after View and before Projects. `BrowserMenuCommands`
  (`@MainActor`, `init(keyPane:canShowHistory:showHistory:)`, `contributions()`, static
  `keySection`) produces the contributions; `WebBrowserWindowsFeature`
  installs `keySection` with `KeyCommandRegistry.shared.install(_:)` and
  appends `contributions()` to its `menuContributions`. The default
  `keyPane` is `WebBrowserPaneViewController.keyPane()`: the key window's
  standalone browser pane, else `BrowserPaneFocus.shared.lastFocused` when
  its `view.window` is the key window, else `nil` — "the key window" being
  `KeyCommandRegistry.shared.commandWindow` resolved through `commandOwner`,
  so a Chrome pane's attached child window counts as its parent; the window
  form is `keyPane(in:)`. `canShowHistory` defaults to
  `BrowserHistoryWindowController.canShow` (a store is set) and is Show
  History's `isEnabled`. The `keySection` descriptors' `perform` navigate
  `WebBrowserPaneViewController.focusedKeyPane()` instead: `keyPane(in:)`
  of the command window, kept only when that window is a
  `WebBrowserWindowController`'s, when the command window is a child whose
  `commandOwner` is another window, or when the first responder is a view
  inside the pane's view. The Back and Forward items take theirs from the
  injected `focusedPane`, which defaults to that same `focusedKeyPane()`, so
  an item carrying ⌘[ or ⌘] never enables for an unfocused pane. The items'
  stable ids are
  `BrowserMenuCommands.ItemID` (`browser.reload` … `browser.toggle-privacy-toolbar`),
  which `MenuManager` prefixes into `menu.browser.*` accessibility identifiers,
  and the separator falls before `BrowserMenuCommands.showSectionOrder` (100). Engine calls are
  `BrowserEngine.reload()`, `stopLoading()`, `goBack()`, `goForward()`;
  enablement reads `canGoBack`, `canGoForward`, `isLoading`. The toggle writes
  `UserSettings.browserPrivacyShowToolbar` into the pane's
  `LayeredSettingsStore`; its title, "Show" or "Hide Privacy Toolbar", is
  re-read every time the menu opens through a second new field,
  `MenuContribution.dynamicTitle: (() -> String)?`, which `MenuManager` hands
  to `MenuUpdateDelegate.addRetitle`. `MenuContribution` gains `keyCommandID: String?`;
  `KeyCommandMenuBridge.bind(_:toCommand:registry:)` sets the `NSMenuItem`'s
  `keyEquivalent` and `keyEquivalentModifierMask` from
  `registry.shortcut(for:)` (empty when `nil` or disabled) and re-applies on
  `KeyCommandRegistry.bindingsDidChangeNotification`; `MenuManager` calls it
  for every contribution that carries an id. Default bindings: `[` and `]`
  with `.command`.
- **SwiftUI**: A `CommandMenu("Browser")` placed after the View commands,
  with `.keyboardShortcut` built from the registry's current binding and
  refreshed by observing the registry; `.disabled` from the focused pane's
  engine state through `FocusedValue` scoped to the key window.
- **Compose**: A `MenuBar` `Menu("Browser")` whose `Item`s take `shortcut`
  from an observable registry state and `enabled` from the active window's
  pane.
- **React/Web**: An application menu (Electron `Menu`) with accelerators
  rebuilt from the registry on change; enablement from the focused window's
  pane.
- **WinUI 3**: A `MenuBarItem` "Browser" with `KeyboardAccelerator`s bound
  to the registry's current binding; `IsEnabled` from the active window's
  pane.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/BrowserMenuCommands.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/KeyCommands/KeyCommandMenuBridge.swift` | unverified |

## Design Decisions

**Decision**: Every command targets the browser pane in the key window, never
the last focused pane anywhere.
**Rationale**: The design's call for the owner to check: "Menu commands
target the key window's focused browser pane." A command must not reload a
page in a window the person is not looking at
(`principle-of-least-astonishment`).
**Approved**: pending

**Decision**: Show/Hide Privacy Toolbar writes a per-pane override, not the
global setting.
**Rationale**: The design's call: it matches the existing checkbox in the
pane's privacy popover, so the menu and the popover can never disagree.
**Approved**: pending

**Decision**: Only Back and Forward are rebindable; Reload and Stop keep
fixed keys outside the registry.
**Rationale**: The design names only Back and Forward as user-definable; the
plan keeps Reload and Stop fixed and asks that the registry not report them as
conflicts.
**Approved**: pending

**Decision**: How the bridge is wired is the builder's choice. The plan's
shape — an optional key command id on a menu contribution, and a bridge the
host calls for each item that carries one, observing the registry's
bindings-changed announcement — is the starting point.
**Rationale**: The design leaves "how the menu key-equivalent bridge is
wired" to the builder; today menu keys are fixed and the registry only
conflict-checks them.
**Approved**: pending

**Decision**: The privacy toolbar item's title with no target pane is the
builder's choice; the plan's test reads "Show Privacy Toolbar" in that case.
**Rationale**: The design defines the title only in terms of the target
pane's value.
**Approved**: pending

## Compliance

Not applicable — design-first draft; no code exists yet to check. The
checks are run when the code lands and the recipe is confirmed against it.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 0.1.3 | 2026-11-16 | Mike Fullerton | Review fix: Back and Forward run only for the focused browser pane. |
| 0.1.2 | 2026-11-16 | Mike Fullerton | Show History enabled only with a history store; Back and Forward keys act only on a focused pane. |
| 0.1.1 | 2026-11-15 | Mike Fullerton | macOS implementation: dynamicTitle, ItemID, showSectionOrder, keyPane(in:) and the command-window rule recorded in platform notes |
| 0.1.0 | 2026-11-15 | Mike Fullerton | Initial creation (design-first, from the more privacy features design) |
