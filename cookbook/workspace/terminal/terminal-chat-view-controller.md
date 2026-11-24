---
id: 707561b1-a978-4c36-9e9c-30d6b71133db
title: "Terminal Chat View Controller"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A chat pane whose messages are typed into a connected terminal pane and whose replies are what the terminal prints, with a link to choose or drop it."
platforms:
  - swift
  - macos
tags:
  - terminal
  - chat
  - composable-tabs
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Terminal Chat View Controller

## Overview

A pane content view controller that stands in for a terminal's command line. It shows a chat view whose composer types into one terminal pane in the same tab, and whose replies are whatever that terminal prints. The user chooses the terminal: a link control beside the pane's gear (or a Connect to Terminal row in the pane's Settings) puts up the terminal pane picker, and the user clicks the pane they mean. The chat knows nothing about what kind of terminal it is: any pane whose content offers the terminal-pane-connectable contract will do. The choice is remembered per pane, as the node identifier of the chosen pane, and re-made whenever the chat next appears or a connectable terminal announces that it changed. The link control shows whether the chat is connected; pressing it while connected asks before disconnecting. The chat session it owns is public so a persona chat in the same tab can drive it, and it can list itself in a directory so processes outside the app can drive it too.

## Behavioral Requirements

- **chat-surface**: The component MUST present a chat view bound to its own terminal chat session, pinned to all four edges of a window-background container.
- **initial-size**: The container MUST have an initial frame of 360 by 500 points.
- **interrupt-enabled**: The chat view MUST have its interrupt control enabled, because Control-C is how a terminal is stopped.
- **session-exposed**: The component MUST expose its terminal chat session publicly so another chat in the same tab can drive it.
- **composer-gated**: The chat composer MUST be enabled if and only if the session has a connected terminal.
- **composer-prompt**: The composer prompt MUST read "$" while connected and MUST be absent while not connected.
- **status-cleared-when-connected**: WHEN the session has a terminal, the component MUST clear the chat status line and any remembered start error.
- **status-starting**: WHILE a terminal start is in flight and the session has no terminal, the status line MUST read "Starting the terminal…".
- **status-start-failed**: WHEN a start has failed and no start is in flight, the status line MUST read "The terminal could not start: " followed by the error's localized description, and MUST keep reading so until the next connection attempt.
- **status-remembered-unavailable**: WHEN a pane is remembered but the session has no terminal, no start is in flight and no start error is held, the status line MUST read "Its terminal isn't available yet — or click the link to choose another".
- **status-not-connected**: WHEN no pane is remembered and the session has no terminal, no start is in flight and no start error is held, the status line MUST read "Not connected — click the link to choose a terminal".
- **accessory-refresh**: After every connection-state update, the component MUST ask its parent pane to refresh its accessory views.
- **connection-remembered**: The component MUST store the connected pane's node identifier, as a UUID string, in the pane state store under the key "connectedPane" whenever a connection is requested.
- **connection-forgotten**: WHEN the user confirms a disconnect, the component MUST remove the remembered pane identifier from the pane state store.
- **reconnect-on-appear**: WHEN the view has appeared and the session has no terminal, the component MUST try to re-make the remembered connection.
- **reconnect-on-change**: WHEN a connectable-terminal-changed notification arrives, the session has no terminal, the view is loaded and the view is in a window, the component MUST try to re-make the remembered connection. The notification's object is not filtered.
- **reconnect-needs-pane**: WHEN re-making a connection and no pane in the tab has the remembered node identifier, or that pane's content is not connectable, the component MUST only refresh the connection state and MUST NOT start anything.
- **connect-running-terminal**: WHEN connecting to a pane whose connectable terminal exists, the component MUST connect the session to it immediately.
- **connect-starts-terminal**: WHEN connecting to a pane that has no connectable terminal yet, the component MUST ask that pane to start one and connect the session to the result.
- **single-start**: WHILE a start is in flight, the component MUST NOT begin a second start.
- **start-superseded**: WHEN a start finishes (by success or failure) and the remembered pane is no longer the pane it was started for, the component MUST NOT connect to its result or show its error, and MUST re-make the connection to the now-remembered pane.
- **start-nil-result**: WHEN a start succeeds but returns no terminal, the component MUST leave the session unconnected and show the remembered-unavailable status.
- **terminal-exit-refresh**: WHEN the session reports that its terminal exited, the component MUST update its connection state.
- **link-accessory**: The component MUST offer exactly one pane accessory view: a borderless button showing a link symbol at 13 points, regular weight, while connected and the same symbol with a slash through it while not connected.
- **link-title-connected**: WHEN connected to a pane that is still in the tab, the link's title MUST read "Connected to <pane title> — click to disconnect"; when that pane is not in the tab, it MUST read "Connected — click to disconnect".
- **link-title-disconnected**: WHEN not connected, the link's title MUST read "Not connected — click to choose a terminal".
- **link-title-reuse**: The link's title MUST be used as its tooltip, its accessibility label and the image's accessibility description.
- **link-accessibility-value**: The link's accessibility value MUST be "connected" while connected and "not connected" otherwise, and its accessibility identifier MUST be "terminalChat.link".
- **link-action**: WHEN the link is pressed while not connected, the component MUST start choosing a terminal; WHEN pressed while connected, it MUST ask for confirmation before disconnecting.
- **disconnect-confirmation**: The confirmation MUST be a sheet on the window titled "Disconnect from <pane title>?" (or "Disconnect from the terminal?" when the pane is not in the tab), with the text "This chat stops typing into the terminal and reading what it prints." and buttons Disconnect and Cancel.
- **disconnect-no-window**: WHEN the view is not in a window, the component MUST NOT present the confirmation.
- **disconnect-effect**: WHEN the user confirms, the component MUST disconnect the session from its terminal and update its connection state, and the chat history MUST remain.
- **options-row**: The component MUST offer one pane options row: a rounded button titled "Connect to Terminal…" with the accessibility identifier "terminalChat.options.connect".
- **picker-dismisses-options**: WHEN choosing a terminal starts, the component MUST first close the pane's Settings sheet.
- **picker-single**: WHILE a picker is already running, or the view has no window, the component MUST NOT put up another.
- **picker-panes-live**: The picker MUST be given the tab's panes through a closure evaluated on each use, so the answer follows the current layout.
- **picker-deferred-start**: The component MUST begin the picker on the next main-queue turn, so the panel is not put up behind the closing sheet.
- **picker-pick-connects**: WHEN the picker reports a pick, the component MUST connect to that pane.
- **picker-released**: WHEN the picker reports it finished, the component MUST release it.
- **directory-listing**: WHEN both a directory and a listing are supplied, the component MUST add its session to the directory under that listing at creation, and MUST remove it at teardown.
- **teardown**: WHEN the pane's content is about to be discarded, the component MUST cancel a running picker, stop observing connectable-terminal changes and close the session.
- **no-coder-init**: The component MUST NOT be creatable from an archive; that initializer traps.
- **link-target-size**: NEEDS REVIEW: Not implemented in source. The link button is a borderless button sized by its 13-point symbol with no explicit minimum size, so whether its click target is acceptable cannot be settled from the source; a measured target size against the platform's minimum would settle it.

## Appearance

- **Container**: A themed background view in the window-background role, 360 by 500 points initially.
- **Chat view**: Pinned to the container's top, leading, trailing and bottom edges with no inset.
- **Composer prompt**: The literal "$" while connected.
- **Link glyph**: The "link" system symbol at 13 points, regular weight; while not connected, the same glyph with a round-capped 1.5-point slash from the top-left to the bottom-right, with a 4-point gap cleared beside the slash so the stroke reads apart from the link. The image is a template, recolored as a whole by the system.
- **Link border**: None.
- **Connect row**: A rounded-bezel push button in the pane's Settings sheet.
- **Disconnect sheet**: A standard alert sheet with the Disconnect and Cancel buttons.

## States

| State | Appearance change |
|-------|------------------|
| Default (never connected) | Composer disabled with no prompt; status "Not connected — click the link to choose a terminal"; slashed link. |
| Remembered, terminal unavailable | Composer disabled; status "Its terminal isn't available yet — or click the link to choose another"; slashed link. |
| Loading (starting) | Composer disabled; status "Starting the terminal…". |
| Start failed | Composer disabled; status "The terminal could not start: <description>". |
| Connected | Composer enabled with the "$" prompt; status cleared; whole link. |
| Picking | The picker panel is up; the chat's own appearance is unchanged. |
| Confirming disconnect | A sheet is up on the window; the chat's own appearance is unchanged. |
| Pressed / Focused | Not applicable: the link and the connect row are standard system buttons and the source sets no custom pressed or focused appearance. |
| Disabled | Not applicable: the link and the connect row are always enabled; only the composer is disabled, as above. |

## Accessibility

- **link-role-label**: The link is a button whose accessibility label is its current title, which names the connected pane when there is one.
- **link-value**: The link exposes "connected" or "not connected" as its accessibility value.
- **link-identifiers**: The link and the connect row carry the stable identifiers "terminalChat.link" and "terminalChat.options.connect".
- **link-keyboard-path**: The link and the connect row are standard buttons; the source adds no key equivalents or custom focus handling, and Connect to Terminal is also reachable from the pane's Settings sheet.
- **status-announcement**: NEEDS REVIEW: Not implemented in source. The controller changes the status line text through the chat view's status line, which sets only its label text and tooltip, and never posts an accessibility announcement for connection changes, including a failed start; evidence that settles it is whether VoiceOver users are told of a changed status line some other way, such as a live-region role on the label.

## Conformance Test Vectors

No test in the repository exercises this controller directly; the vectors below are derived from the source's code paths.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-chat-001 | chat-surface, initial-size, interrupt-enabled | Create the controller and load its view | A 360 by 500 container holds one chat view pinned to all four edges, with the interrupt control enabled. |
| terminal-chat-002 | composer-gated, composer-prompt, status-not-connected | Load the view with no remembered pane | Composer disabled, no prompt, status "Not connected — click the link to choose a terminal". |
| terminal-chat-003 | connect-running-terminal, composer-gated, composer-prompt, status-cleared-when-connected, connection-remembered | Connect to a pane whose connectable terminal is running | Session connected at once; composer enabled with "$"; status cleared; "connectedPane" holds that pane's UUID string. |
| terminal-chat-004 | connect-starts-terminal, status-starting | Connect to a pane with no terminal yet | Status "Starting the terminal…" until the start finishes, then the session connects to the started terminal. |
| terminal-chat-005 | status-start-failed | The pane's start throws an error | Status "The terminal could not start: " plus the error's description; composer stays disabled. |
| terminal-chat-006 | single-start | Connect to the same unstarted pane twice while its start is in flight | Only one start is requested. |
| terminal-chat-007 | start-superseded | Start pane A, choose pane B before A finishes, then A finishes | The session does not connect to A's result; the connection is re-made to B. |
| terminal-chat-008 | start-nil-result, status-remembered-unavailable | A start returns no terminal | Session unconnected; status "Its terminal isn't available yet — or click the link to choose another". |
| terminal-chat-009 | reconnect-on-appear, reconnect-needs-pane | View appears with a remembered node identifier that matches no pane in the tab | Connection state refreshed; nothing started; remembered-unavailable status. |
| terminal-chat-010 | reconnect-on-change | Unconnected, in a window, and a connectable-terminal-changed notification arrives | The remembered connection is re-made. |
| terminal-chat-011 | reconnect-on-change | Already connected, or no window, and the notification arrives | Nothing happens. |
| terminal-chat-012 | link-title-connected, link-title-reuse, link-accessibility-value | Connected to a pane titled "Server" | Link title and label "Connected to Server — click to disconnect", value "connected", identifier "terminalChat.link". |
| terminal-chat-013 | link-title-disconnected, link-action, picker-dismisses-options, picker-single | Press the link while unconnected, twice quickly | Settings sheet closed and one picker started; the second press puts up no second picker. |
| terminal-chat-014 | link-action, disconnect-confirmation, disconnect-effect, connection-forgotten | Press the link while connected and click Disconnect | Sheet "Disconnect from <pane title>?" appears; afterwards the session is unconnected, the remembered identifier is removed, and the chat history remains. |
| terminal-chat-015 | disconnect-confirmation | Press the link while connected and click Cancel | Nothing changes. |
| terminal-chat-016 | disconnect-no-window | Press the link while connected with the view outside any window | No sheet is presented. |
| terminal-chat-017 | picker-pick-connects, picker-released, picker-deferred-start | The picker reports a pick, then finishes | The controller connects to the picked pane and then drops the picker. |
| terminal-chat-018 | terminal-exit-refresh | The terminal's process exits | The controller updates to the unconnected state with the remembered-unavailable status. |
| terminal-chat-019 | options-row | Ask for the pane options rows | One rounded button "Connect to Terminal…" with identifier "terminalChat.options.connect". |
| terminal-chat-020 | directory-listing, teardown | Create with a directory and listing, then discard the pane content | The session is added at creation, then removed, the picker cancelled, the observer removed and the session closed. |

## Edge Cases

- **Start returns no terminal (MUST)**: The start call can return nothing; the controller connects the session to nothing, ends the starting state and shows the remembered-unavailable status.
- **Choice changes during a start (MUST)**: The newer choice is put off while a start is in flight (a second start is refused) and acted on the moment the first finishes, whether it succeeded or failed.
- **Start error for a superseded pane (MUST)**: The error is dropped, not shown.
- **Remembered pane closed (MUST)**: Re-making the connection finds no pane and only refreshes the state; the remembered identifier stays until the user connects elsewhere or disconnects.
- **Minimized or never-appeared pane (MUST)**: Connecting starts that pane's terminal, since a minimized pane never appears to start itself.
- **No window (MUST)**: The disconnect confirmation and the picker are not started when the view has no window.
- **Picker already running (MUST)**: A second request is ignored.
- **Concurrent access**: The controller is main-actor isolated and the notification handler asserts main-actor isolation; no other concurrency is defined.
- **Offline or disconnected state**: Not applicable: the component talks only to an in-process terminal session, not to a network; the exit of the shell is covered by the terminal-exit-refresh requirement.
- **Null and empty input**: A nil directory or listing keeps the chat private to the window; an unparseable remembered string is treated as no remembered pane.
- **Boundary values**: Not applicable: the component takes no numeric input beyond its fixed container size.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| stateStore | pane state store | required | Where the remembered pane identifier is kept, under the key "connectedPane". |
| directory | terminal chat directory, optional | none | Where the chat lists its session for processes outside the app to drive; none keeps it private. |
| listing | directory listing, optional | none | The identity the session is listed under; both directory and listing are needed for the session to be listed. |
| session | terminal chat session | created per instance | Read-only; what a persona chat uses to drive this chat's terminal. |

## Deep Linking

Not applicable: the controller is pane content inside a window and registers no URL or scheme in the source.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (literal) | Not connected — click the link to choose a terminal | Status while no pane is remembered |
| none (literal) | Its terminal isn't available yet — or click the link to choose another | Status while a pane is remembered but has no terminal |
| none (literal) | Starting the terminal… | Status while a start is in flight |
| none (literal) | The terminal could not start: <description> | Status after a failed start |
| none (literal) | Connected to <pane title> — click to disconnect | Link title, tooltip and accessibility label |
| none (literal) | Not connected — click to choose a terminal | Link title while unconnected |
| none (literal) | Disconnect from <pane title>? | Confirmation message |
| none (literal) | This chat stops typing into the terminal and reading what it prints. | Confirmation detail |
| none (literal) | Connect to Terminal… | Settings row |

- **string-localization**: Every user-visible string MUST be an English literal written in the source; the controller does no localization lookup, and the macOS package has no string catalog or localized-string call.
## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the controller runs no animation of its own. |
| Increase Contrast | Not applicable: the controller sets no colors itself; the link image is a template recolored by the system and the container uses a themed window background. |
| Differentiate Without Color | Met by shape: connection is shown by a whole link versus a slashed link and by the status text, never by color alone. |

## Feature Flags

Not applicable: the source reads no feature flag.

## Analytics

Not applicable: the source emits no analytics events.

## Privacy

- **Data collected**: What the user types into the composer and what the connected terminal prints, both held in the chat's history.
- **Storage**: Only the remembered pane's node identifier is persisted, in the pane state store; chat history storage belongs to the chat session and view model.
- **Transmission**: Messages go to the connected in-process terminal session. When a directory and listing are supplied the session is listed so processes outside the app can drive it.
- **Retention**: The remembered identifier lasts until a confirmed disconnect or another connection replaces it; a disconnect keeps the chat history.

## Logging

Not applicable: the controller declares no logger and writes no log entries.

## Platform Notes

- **SwiftUI**: Host the chat view and a toolbar link button in a view with an observable connection model carrying the states in the States table; present the disconnect confirmation with a confirmation dialog and the terminal choice with an overlay or sheet; there is no SwiftUI equivalent of the clicking-through picker, so it needs an AppKit bridge.
- **Compose**: Use a stateful composable driven by a sealed connection state (idle, remembered, starting, failed, connected), an icon button with a link and a link-off icon, and an alert dialog for the disconnect confirmation; the pick-by-clicking flow needs a full-window pointer-input overlay.
- **React/Web**: Use a controlled chat component with a toggle button (aria-pressed or an aria-label that carries the connected title), a modal alertdialog for the disconnect confirmation and a full-page capturing overlay for choosing a pane; persist the remembered pane id in local storage keyed by pane.
- **AppKit / UIKit**: Source platform. The file is `TerminalChatViewController.swift` in the macOS TerminalSession feature: an NSViewController with a themed background container, pane accessory and options-row provider protocols, a main-queue deferral to put the picker above a closing sheet, and a Task bridging an async terminal start. UIKit has no equivalent of a local mouse-event monitor, so the picker would be a tap-capturing overlay.
- **WinUI 3**: Use a UserControl hosting the chat control in a Grid with a CommandBar AppBarButton as the link (Symbol.Link when connected, a Segoe Fluent Icons link glyph with a slash overlay or the Unlink glyph when not), set AutomationProperties.Name to the title and AutomationProperties.AutomationId to "terminalChat.link". Show the disconnect confirmation as a ContentDialog with PrimaryButtonText "Disconnect" and CloseButtonText "Cancel", and drive the composer's IsEnabled from the connection state; run the start with an awaited Task on the DispatcherQueue, and pick a pane with a full-window overlay that handles PointerPressed and marks it handled.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/TerminalSession/TerminalChatViewController.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The connection is remembered by the chosen pane's node identifier and re-made when the chat appears and when a connectable-terminal-changed notification arrives.
**Rationale**: The remembered pane can only be found once the chat is in the tab tree, and a private terminal may start after the chat appears; the source comments say both cases connect "the moment it is there".
**Approved**: pending

**Decision**: Connecting to a pane with no running terminal starts that terminal.
**Rationale**: A minimized pane never appears to start itself, so the connection is the reason to start it.
**Approved**: pending

**Decision**: A choice made while a start is in flight is put off, then acted on when the start ends.
**Rationale**: Only one start runs at a time; the source comment says the choice "was put off only because a start was in flight".
**Approved**: pending

**Decision**: The chat enables its interrupt control.
**Rationale**: Control-C is how a terminal is stopped, so the chat standing in for its command line must be able to send it.
**Approved**: pending

**Decision**: The unlinked glyph is drawn by slashing the link symbol.
**Rationale**: The system symbol set has no broken link, so the slash is drawn the way the system's own slash variants are, with a cleared gap so the stroke reads apart from the link.
**Approved**: pending

**Decision**: Disconnecting keeps the chat history.
**Rationale**: The confirmation text states the chat only stops typing into and reading from the terminal.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |

The controller keeps connection logic, remembered choice and presentation in one class but delegates sending, reading, picking and starting to the chat session, the picker and the connectable contract, so separation of concerns passes. No test in the repository targets it, so unit-test coverage fails. A failed start is shown on the status line and a superseded one is dropped deliberately, so error handling passes. The link has a label, a value and an identifier but the controller posts no announcement, so screen-reader support is partial. All strings are English literals, so the hardcoded-strings check fails. The controls are standard buttons, an alert sheet and symbols, so native controls pass.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
