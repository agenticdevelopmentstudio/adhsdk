
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

