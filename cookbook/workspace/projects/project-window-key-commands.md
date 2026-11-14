---
id: 7f6eb5ef-850c-46b7-a78c-798605958ac8
title: "Project Window Key Commands"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Two bindable app-scope key commands, Command-0 and Command-1, that toggle the project shelf panel on the key project window and decline elsewhere."
platforms:
  - swift
  - macos
tags:
  - projects
  - key-commands
  - windows
depends-on: []
related:
  - 5bfadad5-c93b-432a-807e-04be57ff16b4
references:
  - https://developer.apple.com/documentation/appkit/nswindow/1419553-keywindow
  - https://developer.apple.com/documentation/swift/mainactor
approved-by: ""
approved-date: ""
---

# Project Window Key Commands

## Overview

`ProjectWindowKeyCommands` declares the keyboard commands of a project window,
one per shelf panel. Each command shows the shelf on that panel with the keyboard
in its filter field, or hides the shelf when that panel is already up. It is a
caseless namespace (an `enum`) on the main actor with two command ids, a section
title and a `section()` factory that returns a `KeyCommandSection` for the app's
key-command registry.

The window is resolved when a command runs, not when the section is built: the
command takes the registry's current command window (the window the keystroke
being performed was sent to, otherwise the key window, and for a child window
the window it is attached to) and acts only when that window's controller is a
project shelf window (a project window or the empty project window). That lets the
section be declared at launch, before any project window exists, and lets the
same chord also serve another window's command (the source says Command-0 may
also be the Conversations window's list), because each command declines unless a
project window is key.

The panels, the shelf and the toggle itself belong to other components
(`ProjectShelfPanel`, the shelf window and its view controller); this component
is the binding between a chord and a panel toggle.

## Behavioral Requirements

- **section-title**: `section()` MUST return a section titled `Project Window`.
- **section-scope-app**: The section MUST have app scope.
- **section-window-specific**: The section MUST be marked window specific
  (`isWindowSpecific` true), because each command declines unless a project
  window is key.
- **section-two-commands-ordered**: The section MUST hold exactly two commands, in
  this order: the browser toggle, then the active-projects toggle.
- **browser-command-id**: The first command's id MUST be `projects.toggleBrowser`,
  exposed as `toggleBrowserID`.
- **browser-command-title**: The first command's title MUST be `Show Project Browser`.
- **browser-command-shortcut**: The first command's default shortcut MUST be
  Command plus the 0 key.
- **active-command-id**: The second command's id MUST be
  `projects.toggleActiveProjects`, exposed as `toggleActiveProjectsID`.
- **active-command-title**: The second command's title MUST be `Show Active Projects`.
- **active-command-shortcut**: The second command's default shortcut MUST be Command
  plus the 1 key.
- **browser-command-targets-browser-panel**: Running the first command MUST toggle
  the `browser` panel.
- **active-command-targets-active-panel**: Running the second command MUST toggle the
  `activeProjects` panel.
- **window-resolved-at-run**: The target window MUST be resolved each time a command
  runs, from the registry's command window (the window the keystroke was sent
  to, otherwise the key window; a child window answers with the window it is
  attached to), and not captured when the section is built.
- **section-needs-no-window**: `section()` MUST NOT require a project window to exist.
- **perform-on-project-window**: When the command window's controller is a project
  shelf window, the command MUST call that window's panel toggle with the
  command's panel and MUST return `true`.
- **decline-elsewhere**: When there is no command window, or its controller is not a
  project shelf window, the command MUST NOT toggle anything and MUST return
  `false`, so the chord may fall to another window's command.
- **decline-is-logged**: A declined command MUST write one debug log entry that names
  the panel raw value and the key window's title, or `none` when there is no
  command window.
- **toggle-semantics-owned-elsewhere**: Whether the toggle shows the shelf on the panel,
  moves the keyboard to the filter, or hides the shelf is performed by the
  window's panel toggle, not by this component; the contract stated for it in
  the source comment is: show the shelf on that panel with the keyboard in its
  filter, or hide it when that panel is already up.
- **main-actor-isolated**: The namespace and its command closures MUST run on the main
  actor.
- **chords-rebindable**: The shortcuts are defaults of bindable commands
  (`defaultShortcut`); this component MUST NOT hard-wire the keys beyond that
  default.

## Appearance

Not applicable — this is a key-command declaration with no visual surface. The
menu items and any shortcut-settings rows that list these commands are drawn by
the key-command system.

## States

Not applicable — the commands have no visual states of their own; each runs
statelessly and either performs or declines (see Behavioral Requirements).

| State | Appearance change |
|-------|------------------|
| Default | Not applicable: no visual surface |

## Accessibility

Not applicable — this is a keyboard-binding declaration, not a visual component.
It adds keyboard paths to the shelf; the labels are the command titles listed in
the requirements, and the shelf's own accessibility belongs to the shelf view.

## Conformance Test Vectors

The source has no tests beside it, and the package's tests do not reference
`ProjectWindowKeyCommands`; the vectors are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| keycmd-001 | section-title, section-scope-app, section-window-specific | Call `section()` | Title `Project Window`, app scope, window specific |
| keycmd-002 | section-two-commands-ordered, browser-command-id, browser-command-title, browser-command-shortcut | Read command 0 | id `projects.toggleBrowser`, title `Show Project Browser`, shortcut Command-0 |
| keycmd-003 | active-command-id, active-command-title, active-command-shortcut | Read command 1 | id `projects.toggleActiveProjects`, title `Show Active Projects`, shortcut Command-1 |
| keycmd-004 | perform-on-project-window, browser-command-targets-browser-panel | Key window's controller is a project shelf window; run command 0 | Window receives the `browser` panel toggle once; returns `true` |
| keycmd-005 | perform-on-project-window, active-command-targets-active-panel | Same window; run command 1 | Window receives the `activeProjects` toggle; returns `true` |
| keycmd-006 | decline-elsewhere, decline-is-logged | Key window is the Conversations window; run command 0 | Returns `false`; no toggle; debug entry says `browser toggle declined: key window is <title>` |
| keycmd-007 | decline-elsewhere, decline-is-logged | No command window; run command 1 | Returns `false`; debug entry says `activeProjects toggle declined: key window is none` |
| keycmd-008 | window-resolved-at-run, section-needs-no-window | Build the section with no windows; then make a project window key; run command 0 | Section builds without a window; the command then toggles that window |
| keycmd-009 | window-resolved-at-run | Run command 0 with window A key, then with window B key | Each run toggles the window that is key at that moment |
| keycmd-010 | main-actor-isolated | Call `section()` and run a command from a main-actor test | Compiles and runs on the main actor; a call from elsewhere requires a hop |

## Edge Cases

- **Null and empty input**: No command window (`nil`) is declined and logged as
  `none` (MUST). A window with an empty title is logged with the empty title.
- **Boundary values**: The two chords are Command-0 and Command-1; another
  window's command may use the same chord, which is why a decline returns
  `false` rather than consuming the key (MUST).
- **Concurrent access**: Everything is main-actor isolated, so the window is read
  and toggled on one actor with no interleaving (MUST).
- **Error states**: Nothing throws. A wrong window is a decline, not an error;
  the only signal is the debug log, and the user sees nothing (a fact of the
  source, whose comment calls a silent chord the hardest thing to debug).
- **Window closed between resolve and toggle**: Not applicable: resolution and the
  toggle call happen in one synchronous main-actor call.
- **Offline or disconnected state**: Not applicable: no network or file access.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `toggleBrowserID` | `String` | `projects.toggleBrowser` | Id of the browser command |
| `toggleActiveProjectsID` | `String` | `projects.toggleActiveProjects` | Id of the active-projects command |
| `sectionTitle` | `String` | `Project Window` | Title of the section |
| Browser shortcut | Shortcut | Command-0 | Default, user-rebindable |
| Active projects shortcut | Shortcut | Command-1 | Default, user-rebindable |
| Command window | injected via `KeyCommandRegistry.shared.commandWindow` | the window the keystroke was sent to, otherwise the key window, resolved to its owner window | The window whose controller is tested |

## Deep Linking

Not applicable: the commands are keyboard bindings with no URL.

## Localization

The section title and command titles are hardcoded English strings.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (literal) | Project Window | Section title in menus and shortcut settings |
| none (literal) | Show Project Browser | Title of the Command-0 command |
| none (literal) | Show Active Projects | Title of the Command-1 command |

## Accessibility Options

Not applicable: no drawing or animation here; the shelf's slide is owned by the
shelf window.

## Feature Flags

Not applicable: the source reads no feature flag.

## Analytics

Not applicable: the source records no analytics event.

## Privacy

- **Data collected**: None stored. A declined command logs the key window's title
  with public privacy, and a window title can name a project or document.
- **Storage**: None here.
- **Transmission**: None through this code.
- **Retention**: Not applicable; the log entry follows the system log's retention.

## Logging

Subsystem: the projects coordinator's logger | Category: the projects coordinator's
category (`ProjectsCoordinator.logger`)

| Event | Level | Message |
|-------|-------|---------|
| A command declined | debug | `<panel raw value> toggle declined: key window is <window title or none>` |

## Platform Notes

- **SwiftUI**: Use `.commands { CommandGroup(...) }` with `Button` items and
  `.keyboardShortcut("0", modifiers: .command)`; the key window check becomes
  `@FocusedValue` or `@FocusedObject`, which disables the item (rather than
  declining) when no project window is focused.
- **Compose**: Desktop Compose has `Modifier.onPreviewKeyEvent` or window menu
  `Item(shortcut = KeyShortcut(Key.Zero, meta = true))`; return `false` from the
  handler to let the event fall through, as the source returns `false`.
- **React/Web**: Register a `keydown` listener (or `react-hotkeys-hook`) for
  Meta+0 and Meta+1 (Ctrl on non-Mac) that acts only when the project window root
  has focus and otherwise does not call `preventDefault`, so the chord falls
  through. Browsers reserve Command-0 and Command-1 for zoom and tab selection.
- **AppKit / UIKit**: Source file:
  `macOS/Features/Projects/ProjectWindowKeyCommands.swift`, built on the
  `KeyboardShortcuts` package (`KeyboardShortcuts.Shortcut`),
  `KeyCommandSection`, `KeyCommandDescriptor`, `KeyCommandRegistry.shared` and
  the `ProjectShelfWindow` protocol that the composable-tabs window controller and
  the empty project window controller conform to. The target is
  `KeyCommandRegistry.shared.commandWindow`'s `windowController`. UIKit uses
  `UIKeyCommand` with `UIKeyCommand.inputZero`-style inputs and the responder
  chain, which replaces the explicit key-window lookup.
- **WinUI 3**: Use `KeyboardAccelerator` on a `MenuFlyoutItem` or a
  `XamlUICommand` with `KeyboardAccelerators` (`Key = VirtualKey.Number0`,
  `Modifiers = VirtualKeyModifiers.Control`; Windows uses Control where macOS
  uses Command). Set `KeyboardAccelerator.Invoked` args `Handled = false` to
  decline. Scope it with `KeyboardAcceleratorPlacementMode` or by attaching the
  accelerators to the project window's content so they act only when that
  window is active; write the log entry with `ILogger.LogDebug`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Projects/ProjectWindowKeyCommands.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The window is resolved when a command runs, not when the section is
built.
**Rationale**: The source comment (like `ConversationsKeyCommands`) says this lets
the section be declared at launch, before any project window exists.
**Approved**: pending

**Decision**: A command declines (returns `false`) unless a project window is key.
**Rationale**: The source comment says this lets Command-0 also be the
Conversations window's list; `isWindowSpecific` records it in the section.
**Approved**: pending

**Decision**: A declined command is logged at debug level with the key window's
title.
**Rationale**: The source comment says declining is normal, but a chord that
silently does nothing is the hardest thing to debug, so the log says which window
had the keyboard.
**Approved**: pending

**Decision**: Shortcuts are defaults only, not fixed bindings.
**Rationale**: The commands are described as bindable, so the user can rebind
them in the key-command settings.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

The namespace only binds a chord to a toggle on the key window; the panels, the
shelf and the toggle live in other types, so it meets separation-of-concerns. A
search of the package's tests finds none that reference it, so unit-test
coverage fails and the vectors above are unasserted. It gives the shelf a
keyboard path and does not capture keys it cannot serve, which meets
keyboard-navigable. The section and command titles are English literals, so
no-hardcoded-strings fails.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
