---
id: b33dfe6a-991e-4262-9e79-0f29c733beb0
title: "Terminal Workspace Coordinator"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "An app feature that opens one project window of terminals over a fixed directory, with the terminal-only layout and New Terminal and Terminal Window commands."
platforms:
  - swift
  - macos
tags:
  - terminal
  - workspace
  - composable-tabs
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Terminal Workspace Coordinator

## Overview

An app feature for a host that is a terminal and nothing else: no registry, no browser, no scan. It opens one ordinary project window over a fixed directory, so the tabs carry the same cards (session, directory, branch) and the panes persist the same way as in any project window; the window manager opens it. What this feature adds is the one git repository row that window is keyed on, found by path and inserted the first time, and the terminal-only layout every tab starts from. It registers two commands, Terminal Window and New Terminal, and contributes both to the File menu with key equivalents T and 1. The layout is process-wide, so the feature installs it in its initializer before any window can load; a host that also opens other kinds of project windows wants its own layout and should not use this feature.

## Behavioral Requirements

- **installs-layout**: The initializer MUST install the terminal-only layout, built from the supplied plugin manager, chat directory and privacy vault, before any window can load, and MUST fail with the layout's error if it cannot be built.
- **layout-optional-parts**: A nil plugin manager MUST leave the persona terminal chat pane out, and a nil privacy vault MUST leave the private terminal pane out.
- **attach-database**: The initializer MUST attach the database to the window manager.
- **share-registry**: The initializer MUST give the window manager the command registry.
- **command-registry-required**: The initializer MUST require a command registry, so a dropped registry is a compile error.
- **show-window-command**: The component MUST register a command with the identifier "terminalWorkspace.action.showWindow", the title "Terminal Window" and the category "Terminal", which shows the workspace window.
- **new-terminal-command**: The component MUST register a command with the identifier "terminalWorkspace.action.newTerminal", the title "New Terminal" and the category "Terminal", which adds a terminal.
- **command-weak-self**: The commands MUST hold the coordinator weakly and do nothing once it is gone.
- **file-menu-new-terminal**: The component MUST contribute a File menu item "New Terminal" for the new-terminal command at order 0 with the key equivalent "t".
- **file-menu-show-window**: The component MUST contribute a File menu item "Terminal Window" for the show-window command at order 10 with the key equivalent "1".
- **default-directory**: WHEN no directory is supplied, the workspace directory MUST be the current user's home directory.
- **workspace-row-by-path**: The workspace row MUST be found by the directory's path in the database and MUST NOT be tracked by a stored identifier.
- **workspace-row-inserted-once**: WHEN no row exists for the directory's path, the component MUST insert one named with the supplied window name and path equal to the directory's path; WHEN a row exists, it MUST reuse it.
- **show-window**: The show-window action MUST open the workspace window through the window manager, or bring it forward when it is already open.
- **show-window-failure**: WHEN the workspace row cannot be found or inserted, the show-window action MUST log the error with the message "Cannot open the terminal workspace: " plus the error and MUST NOT open a window.
- **new-terminal-open-window**: WHEN the workspace window is open and a front window controller exists, the new-terminal action MUST add a terminal pane beside the active pane of the front project window; the source does not check that the front window is the workspace window.
- **new-terminal-closed-window**: WHEN the workspace window is closed (or no front window controller exists), the new-terminal action MUST show the window instead of adding a pane, because a window that opens on its starting terminal has already done what was asked.
- **new-terminal-refusal**: WHEN adding the pane is refused, the component MUST announce the refusal through the refusal feedback, whose default is a system beep a host may replace. The pane is refused when the front window has no active pane or its layout allows no further terminal beside it.
- **is-window-open**: The open-window query MUST be true if and only if the database has a row for the directory's path and the window manager has a window controller for that row's identifier.
- **is-window-open-error**: WHEN the database lookup throws, the open-window query MUST return false.
- **window-title**: The supplied name MUST be the name of the workspace row the window is keyed on, which is documented as the window's title.
- **main-actor**: The component MUST be used on the main actor.
- **error-surface**: NEEDS REVIEW: Not implemented in source. A failure to open the window is only logged; the user is shown nothing, and a decision whether the host should show a message would settle whether this is intended.

## Appearance

Not applicable: the component draws nothing; the window, tabs and panes it opens are drawn by the project window manager and the pane components. The only visible elements it adds are two File menu items.

- **File menu items**: "New Terminal" (key T) and "Terminal Window" (key 1), in the File slot.

## States

| State | Appearance change |
|-------|------------------|
| Window closed | The open-window query is false; New Terminal and Terminal Window both open the window. |
| Window open | The open-window query is true; New Terminal adds a pane; Terminal Window brings the window forward. |
| Open failed | An error is logged and no window appears. |
| Pane refused | The refusal feedback is announced. |
| Pressed / Disabled / Focused / Loading | Not applicable: the component has no controls of its own, and the source defines no disabled or loading state for its menu items. |

## Accessibility

Not applicable: the component draws no controls; its menu items are standard menu contributions with titles and key equivalents, and a refused New Terminal is announced through the refusal feedback component. Accessibility of the window and panes belongs to the project window manager and pane components.

## Conformance Test Vectors

No test in the repository targets this coordinator; the vectors below are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-workspace-001 | installs-layout, layout-optional-parts | Create with no plugin manager and no vault | The installed layout offers the terminal and terminal chat panes (plus the placeholder); no private terminal and no persona terminal chat. |
| terminal-workspace-002 | installs-layout | Create when the layout cannot be built | The initializer throws that error. |
| terminal-workspace-003 | attach-database, share-registry | Create the coordinator | The window manager has the database attached and the command registry assigned. |
| terminal-workspace-004 | show-window-command, new-terminal-command | Read the registry after creation | Commands "terminalWorkspace.action.showWindow" ("Terminal Window") and "terminalWorkspace.action.newTerminal" ("New Terminal"), category "Terminal". |
| terminal-workspace-005 | file-menu-new-terminal, file-menu-show-window | Read the menu contributions | File items "New Terminal" (order 0, key t) and "Terminal Window" (order 10, key 1). |
| terminal-workspace-006 | default-directory | Create with no directory | The workspace path is the user's home directory. |
| terminal-workspace-007 | workspace-row-inserted-once | Show the window twice with an empty database | One row, with the supplied name and the directory path, is inserted; the second call reuses it. |
| terminal-workspace-008 | show-window | Show the window while it is open | The existing window is brought forward and no second window opens. |
| terminal-workspace-009 | show-window-failure | The database insert throws | "Cannot open the terminal workspace: " and the error are logged and no window opens. |
| terminal-workspace-010 | new-terminal-open-window | Window open; run New Terminal | A terminal pane is added beside the active pane. |
| terminal-workspace-011 | new-terminal-closed-window | Window closed; run New Terminal | The window opens on its starting terminal and no extra pane is added. |
| terminal-workspace-012 | new-terminal-refusal | Window open and adding the pane returns false | The refusal feedback is announced. |
| terminal-workspace-013 | is-window-open, is-window-open-error | Query with no row, with a row but no window, with both, and with a throwing lookup | False, false, true, false. |
| terminal-workspace-014 | command-weak-self | Release the coordinator, then run a command | Nothing happens. |
| terminal-workspace-015 | window-title | Create with name "Terminals" | The workspace row's name is "Terminals". |

## Edge Cases

- **Row missing (MUST)**: The row is inserted on first use, keyed by path.
- **Row exists from an earlier launch (MUST)**: It is reused, so the window's saved tabs and layout stay attached to it.
- **Database error on show (MUST)**: The error is logged; no window opens and nothing is shown to the user.
- **Database error on the open-window query (MUST)**: Treated as not open.
- **No front window controller while the window is open (MUST)**: New Terminal shows the window instead.
- **Pane refused (MUST)**: The refusal is announced; it happens when the front window has no active pane or its layout allows no further terminal beside it.
- **Front window is not the workspace window (MUST NOT be relied on)**: New Terminal acts on the front project window without checking that it is the workspace window.
- **Coordinator released (MUST)**: Commands do nothing.
- **Second coordinator in the same process (MUST NOT be relied on)**: The layout is process-wide and the initializer replaces it, so a host that opens other kinds of project windows must not use this feature.
- **Concurrent access**: The type is main-actor isolated, so initialization, commands and queries run on the main actor.
- **Offline or disconnected state**: Not applicable: the component touches only the local database and windows, with no network.
- **Null and empty input**: A nil plugin manager, chat directory or privacy vault omits or privatizes the matching feature; a missing directory defaults to home.
- **Boundary values**: Not applicable: no numeric input.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| database | project database | required | Where the window keeps its tabs and layout. |
| directory | URL | the user's home directory | The folder the workspace, and so every new shell, starts in. |
| name | string | required | The window's title and the workspace row's name. |
| commandRegistry | command registry | required | Where the two commands are registered. |
| pluginManager | plugin manager, optional | none | The LLM providers persona chat panes run on; nil leaves that pane type out. |
| chatDirectory | terminal chat directory, optional | none | Where terminal chat panes list themselves for outside processes to drive; nil keeps them private. |
| privacyVault | privacy words vault, optional | none | The privacy words private terminal panes run behind; nil leaves that pane type out. |
| windowManager | project window manager | the shared manager | What opens and tracks the window. |

## Deep Linking

Not applicable: the component registers no URL or scheme; its entry points are two registered commands and two File menu items.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (literal) | Terminal Window | Command title and File menu item |
| none (literal) | New Terminal | Command title and File menu item |
| none (literal) | Terminal | Command category |
| none (literal) | Cannot open the terminal workspace: <error> | Log message |

- **string-localization**: NEEDS REVIEW: Not implemented in source. The command titles, menu titles and category are English literals with no localization lookup; a decision on the host's supported languages would settle it.

## Accessibility Options

Not applicable: the component draws nothing and responds to no display option.

## Feature Flags

Not applicable: which panes are offered depends on the optional plugin manager and privacy vault supplied by the host, not on a feature flag.

## Analytics

Not applicable: the source emits no analytics events.

## Privacy

- **Data collected**: None by this component; it stores a database row holding the directory path and the window name.
- **Storage**: One repository row in the project database, found by path; tabs and layout are stored by the project window manager.
- **Transmission**: None by this component. Terminal chat panes may list themselves for outside processes when a chat directory is supplied.
- **Retention**: The row persists in the database and is reused on later launches.

## Logging

Subsystem and category come from the shared logger helper for this type.

| Event | Level | Message |
|-------|-------|---------|
| Opening the workspace fails | error | `Cannot open the terminal workspace: <error>` |

## Platform Notes

- **SwiftUI**: Replace the coordinator with a scene-level model object: a WindowGroup keyed by the workspace row, commands added with the commands modifier and keyboardShortcut for T and 1 in the File menu group; the row lookup stays a database call.
- **Compose**: On desktop Compose, hold a window state object and register menu items and shortcuts in the MenuBar of the application scope; look up or insert the workspace record by path in the same way before opening the window.
- **React/Web**: Use a workspace provider that finds or creates the workspace record by path and registers two commands with keyboard shortcuts in a command palette or menu; adding a terminal appends a pane to the layout state, falling back to opening the workspace route.
- **AppKit / UIKit**: Source platform. The file is `TerminalWorkspaceCoordinator.swift`: a main-actor AppFeature subclass using the project window manager, the command registry, menu contributions, the refusal feedback and a shared logger; it installs the process-wide layout in its initializer. UIKit would use scene-based windows and UIKeyCommand instead of menu contributions.
- **WinUI 3**: Implement as a service class registering two commands as XamlUICommand objects with KeyboardAccelerator Ctrl+T and Ctrl+1 (the Windows analog of Command-T and Command-1) in a MenuBar File MenuBarItem; open the workspace in a Window per row id kept in a dictionary, bring it forward with AppWindow and Activate when it exists, look up or insert the workspace row by path with the same database call, and report a refused pane with a brief system sound or InfoBar.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/TerminalSession/TerminalWorkspaceCoordinator.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The workspace row is found by path and not by a stored identifier.
**Rationale**: The source comment says this leaves the database as the only place that knows the row (the `dry` principle).
**Approved**: pending

**Decision**: The layout is installed in the initializer.
**Rationale**: The layout is process-wide and must be in place before any window can load; a host that also opens other kinds of project windows wants its own layout and should not use this feature.
**Approved**: pending

**Decision**: New Terminal on a closed window shows the window rather than adding a second pane.
**Rationale**: A window that opens on its starting terminal has already done what was asked.
**Approved**: pending

**Decision**: The command registry is a required parameter.
**Rationale**: As for every feature, a dropped registry is then a compile error rather than a menu that lost an item.
**Approved**: pending

**Decision**: A failure to open the workspace window is logged and not shown.
**Rationale**: The source only logs the error; no user message is defined, which is why the open question on error-surface exists.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

The coordinator leaves window opening, tabs and layout persistence to the window manager and pane construction to the terminal pane family, keeping only the workspace row and the commands, so separation of concerns passes. No test in the repository targets it, so unit-test coverage fails. A failed open is caught and logged but not shown to the user, and the open-window query turns a database error into false, so error handling is partial. Command and menu titles are English literals, so the hardcoded-strings check fails.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
