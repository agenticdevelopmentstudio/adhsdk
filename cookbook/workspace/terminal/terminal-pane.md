---
id: b8e3f3f9-3d5e-45ef-8859-61d168f4c14d
title: "Terminal Pane Family"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Registers the terminal, private terminal, terminal chat and persona chat panes with the tabs registry, with matching allowances and a terminal-only layout."
platforms:
  - swift
  - macos
tags:
  - terminal
  - composable-tabs
  - pane-registration
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Terminal Pane Family

## Overview

The registration layer for every terminal-related pane a host can offer in a composable-tabs window. It names four pane view identifiers (terminal, terminal chat, persona terminal chat, private terminal), registers each with a display name, symbol, preferred split axis and minimum thickness, and builds the content each pane opens with. A terminal pane opens one live shell in the pane's working directory. A private terminal opens behind a privacy vault. A terminal chat types into a connected terminal. A persona terminal chat is an AI persona that works the terminal through the tab's terminal chat. A family value registers all of them together and produces the matching allowances, so no host can register a pane without allowing it. A terminal-only layout is built from the family: one terminal to start, as many more as the user splits off, and chat panes that talk to them. There is no visual surface of its own; the panes it registers carry the appearance.

## Behavioral Requirements

- **terminal-view-id**: The terminal pane's view identifier MUST have the raw value "terminal", because persisted layout rows already name it and it MUST NOT change.
- **view-id-values**: The terminal chat, persona terminal chat and private terminal view identifiers MUST have the raw values "terminal-chat", "persona-terminal-chat" and "private-terminal".
- **terminal-descriptor**: The terminal pane MUST be registered with the display name "Terminal", the symbol "terminal", the caller's preferred axis and a minimum thickness of 300.
- **private-terminal-descriptor**: The private terminal pane MUST be registered with the display name "Private Terminal", the symbol "eye.slash", the caller's preferred axis and a minimum thickness of 300.
- **terminal-chat-descriptor**: The terminal chat pane MUST be registered with the display name "Terminal Chat", the symbol "bubble.left.and.text.bubble.right", a horizontal preferred axis and a minimum thickness of 260.
- **persona-chat-descriptor**: The persona terminal chat pane MUST be registered with the display name "Persona Terminal Chat", the symbol "person.crop.circle.badge.questionmark", a horizontal preferred axis and a minimum thickness of 260.
- **terminal-no-session-list**: A terminal pane MUST hold one shell and MUST NOT show a session list, because the tab already carries the directory and branch that list would identify a shell by.
- **terminal-working-directory**: A terminal pane's shell MUST be opened in the pane's working directory.
- **terminal-opens-live**: A terminal pane MUST add its first shell session when it is created, so it never opens empty.
- **private-terminal-vault**: A private terminal pane MUST be created with the family's privacy vault and the pane's working directory.
- **environment-late-read**: The shell environment MUST be read from a closure each time a terminal or private terminal pane's content is created, not when the pane type is registered, so a value the host learns after registering reaches every pane opened after it is known. The pane hands the resulting dictionary to its session manager, which gives it to every shell that pane starts, so a pane already open keeps the values it was created with. The dictionary overloads wrap a fixed dictionary in such a closure.
- **pane-environment-variables**: Every terminal and private terminal shell MUST receive ADKITCHEN_PANE_ID set to the pane's node identifier string and ADKITCHEN_PROJECT set to the project's display name.
- **pane-environment-wins**: WHEN the host environment and the pane environment name the same variable, the pane's value MUST win.
- **terminal-chat-state-store**: A terminal chat pane MUST be created with a pane state store using the prefix "terminalChat".
- **terminal-chat-listing**: A terminal chat pane MUST be listed under an identifier derived from its node identifier, with the project display name, working directory and pane number.
- **terminal-chat-directory-optional**: WHEN no chat directory is supplied, terminal chats MUST stay private to the window.
- **persona-chat-creation**: A persona terminal chat pane MUST be created with a pane state store using the prefix "personaTerminalChat", the plugin manager, the optional browser tools and the pane's node identifier.
- **family-registers-terminal**: The family's registration MUST always register the terminal pane and the terminal chat pane.
- **family-private-needs-vault**: The family MUST register the private terminal pane only when a privacy vault is supplied.
- **family-persona-needs-plugins**: The family MUST register the persona terminal chat pane only when a plugin manager is supplied.
- **allowances-match-registrations**: The family's allowances MUST be unbounded, carry the family's preferred axis, and name exactly the panes the family registers, so the registered set and the allowed set are equal.
- **allowance-order**: The allowances MUST be ordered terminal, private terminal (if offered), terminal chat, persona terminal chat (if offered).
- **terminal-only-layout**: The terminal-only layout MUST be a horizontal split containing one terminal pane, allowing the family's allowances plus an unbounded placeholder, built over a registry the family has registered into.
- **terminal-only-axis**: The terminal-only layout MUST use a horizontal preferred axis for its family.
- **terminal-only-throws**: Building the terminal-only layout MUST propagate a failure to construct the layout rather than swallow it.
- **main-actor**: Registration and the family type MUST be used on the main actor.

## Appearance

Not applicable: this component registers panes and draws nothing itself; each pane's own appearance is described by its content component. The only visual values it sets are the picker entries below.

- **Terminal entry**: The "terminal" symbol and the name "Terminal".
- **Private terminal entry**: The "eye.slash" symbol and the name "Private Terminal".
- **Terminal chat entry**: The "bubble.left.and.text.bubble.right" symbol and the name "Terminal Chat".
- **Persona terminal chat entry**: The "person.crop.circle.badge.questionmark" symbol and the name "Persona Terminal Chat".
- **Minimum size**: 300 points for terminal and private terminal panes, 260 points for the chat panes.

## States

| State | Appearance change |
|-------|------------------|
| Default (bare family) | Terminal and terminal chat panes registered and allowed. |
| With privacy vault | Private terminal pane also registered and allowed. |
| With plugin manager | Persona terminal chat pane also registered and allowed. |
| Whole family | All four panes registered and allowed. |
| Pressed / Disabled / Focused / Loading | Not applicable: the component is a registration and has no interactive or loading state of its own. |

## Accessibility

Not applicable: the component draws no controls and sets no accessibility properties; the accessibility of each pane belongs to its content component. The display names above are the labels a host's pane menu shows for each pane type.

## Conformance Test Vectors

The derived tests live in the macOS test bundle as `TerminalPaneFamilyTests`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-pane-001 | family-registers-terminal, allowance-order | Test `testTheBareFamilyIsTerminalsAndTerminalChats`: family with only a vertical axis | Allowance view identifiers are terminal, terminal chat. |
| terminal-pane-002 | family-private-needs-vault, family-persona-needs-plugins, allowance-order, allowances-match-registrations | Test `testTheWholeFamilyAddsPrivateTerminalsAndPersonaChats`: family with plugin manager and privacy vault, vertical axis | Allowance identifiers are terminal, private terminal, terminal chat, persona terminal chat, each with the vertical axis. |
| terminal-pane-003 | allowances-match-registrations, terminal-only-layout | Test `testEveryAllowanceIsRegistered`: register the whole family, then validate a horizontal split with one terminal pane, the allowances and a placeholder against the registry | Validation does not throw. |
| terminal-pane-004 | terminal-view-id, view-id-values | Read the four identifiers' raw values | "terminal", "terminal-chat", "persona-terminal-chat", "private-terminal". |
| terminal-pane-005 | pane-environment-variables, pane-environment-wins | Host environment has ADKITCHEN_PANE_ID set to X; pane node is N | The shell gets ADKITCHEN_PANE_ID equal to N's string and ADKITCHEN_PROJECT equal to the project display name. |
| terminal-pane-006 | environment-late-read | Register with a closure, then change what it returns and open a new terminal pane | The new pane's shell sees the changed value; a shell in a pane opened before the change does not. |
| terminal-pane-007 | terminal-opens-live, terminal-working-directory, terminal-no-session-list | Create a terminal pane for a context with a working directory | One live shell session is already open in that directory and no session list is shown. |
| terminal-pane-008 | terminal-descriptor, private-terminal-descriptor, terminal-chat-descriptor, persona-chat-descriptor | Read each registered descriptor | Names, symbols, axes and minimum thicknesses as listed in the requirements. |
| terminal-pane-009 | terminal-chat-listing, terminal-chat-state-store, terminal-chat-directory-optional | Create a terminal chat pane with no directory | The chat is created with prefix "terminalChat" state and a listing with the node-derived identifier, project name, directory and pane number; it is not listed anywhere. |
| terminal-pane-010 | persona-chat-creation, private-terminal-vault | Create a persona chat and a private terminal | Persona chat receives plugin manager, browser tools and node identifier; private terminal receives vault and working directory. |
| terminal-pane-011 | terminal-only-layout, terminal-only-axis, terminal-only-throws | Build the terminal-only layout | A horizontal split with one terminal pane and the family's allowances plus a placeholder; a construction failure propagates. |

## Edge Cases

- **No vault (MUST)**: The private terminal is neither registered nor allowed; the layout offers no entry for it.
- **No plugin manager (MUST)**: The persona terminal chat is neither registered nor allowed.
- **No chat directory (MUST)**: Terminal chats are private to the window.
- **Null browser tools (MUST)**: Persona chats receive no browser tools.
- **Environment clash (MUST)**: The pane's identity variables replace host values of the same name.
- **Environment read late (MUST)**: A bound port or similar value that becomes known after registration reaches panes created afterwards, not panes already open or their running shells.
- **Concurrent access**: The registrations and the family are main-actor isolated and the environment closure is main-actor isolated, so no concurrent use is defined.
- **Offline or disconnected state**: Not applicable: registration does no network access.
- **Boundary values**: Minimum thickness is fixed at 300 and 260 points; no variable range is accepted.
- **Error states**: The only error path is the layout construction in the terminal-only layout, which throws to the caller.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| preferredAxis | split axis | required | Which way the Split menu proposes adding another terminal; a host stacking terminals beside other panes wants vertical, a terminal-only window wants side by side. |
| pluginManager | plugin manager, optional | none | The LLM providers a persona chat runs on; without it the persona terminal chat pane is not offered. |
| chatDirectory | terminal chat directory, optional | none | Where terminal chats list themselves for outside processes to drive. |
| privacyVault | privacy words vault, optional | none | Without it the private terminal pane is not offered. |
| environment | dictionary or closure | empty | Extra shell variables for every terminal pane's shell, under the pane's own identity variables, read each time a pane is created. |
| browserTools | chat tool source, optional | none | Tools for driving the Browser pane, offered to persona chats beside the terminal tools. |

## Deep Linking

Not applicable: the component registers no URL or scheme; the only external addressing is the ADKITCHEN_PANE_ID environment variable, which a process in the shell sends as the MCP caller header so "this pane" resolves to the Browser pane beside it.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (literal) | Terminal | Pane display name |
| none (literal) | Private Terminal | Pane display name |
| none (literal) | Terminal Chat | Pane display name |
| none (literal) | Persona Terminal Chat | Pane display name |

- **display-name-localization**: The four display names shown in the pane menu MUST be English literals written in the source; registration does no localization lookup.
## Accessibility Options

Not applicable: the component renders nothing and responds to no display option.

## Feature Flags

Not applicable: whether a pane is offered depends on whether the host supplied a vault or plugin manager, not on a feature flag.

## Analytics

Not applicable: the source emits no analytics events.

## Privacy

- **Data collected**: None by this component. It passes the project display name and the pane's node identifier to each shell as environment variables.
- **Storage**: None; the raw value of the terminal view identifier is what persisted layout rows already name.
- **Transmission**: The two environment variables are visible to every process the shell starts, and a process in the shell sends the pane identifier as the MCP caller header.
- **Retention**: Not applicable: nothing is retained by this component.

## Logging

Not applicable: the source declares no logger and writes no log entries.

## Platform Notes

- **SwiftUI**: Model the registry as a dictionary from pane identifier to a descriptor and a content factory closure; offer entries in a Menu or a Picker driven by the family's allowances, and host the AppKit terminal through a representable.
- **Compose**: Use a registry object mapping an identifier to a descriptor (label, icon, preferred orientation, minimum size) and a composable factory; derive the allowed list from the same object so registration and allowance cannot drift.
- **React/Web**: Use a typed registry map from pane id to metadata and a component factory, with a function that returns the allowances from the registered entries, and a hook-free layout builder that throws on invalid specs.
- **AppKit / UIKit**: Source platform. The file is `TerminalPane.swift`, extensions on the composable-tabs view identifier and registry plus `TerminalPaneFamily` and a layout factory; everything is main-actor isolated and the environment is a main-actor closure.
- **WinUI 3**: Register pane types in a static registry class holding a descriptor record (DisplayName, Glyph from Segoe Fluent Icons such as the terminal and hide glyphs, PreferredOrientation as Microsoft.UI.Xaml.Controls.Orientation, MinimumWidth set to 300 or 260) and a factory delegate returning the pane UserControl; a PaneFamily class registers and exposes allowances from one list; set the shell environment with ProcessStartInfo.Environment, merging so the pane's values replace the host's.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/TerminalSession/TerminalPane.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The terminal pane opens on a live shell.
**Rationale**: The source comment says an empty pane is a dead end the user would have to click out of every time.
**Approved**: pending

**Decision**: The terminal pane shows no session list.
**Rationale**: In a project window the tab already carries the directory and branch that list would identify a shell by.
**Approved**: pending

**Decision**: The shell environment is a closure read when a pane's content is created.
**Rationale**: A value the host learns later, such as the port a server has bound, must reach every pane opened after it is known; the source comment says each shell, but the closure is evaluated in the pane factory and the resulting dictionary is fixed for that pane's shells.
**Approved**: pending

**Decision**: The pane's own variables replace host variables of the same name.
**Rationale**: ADKITCHEN_PANE_ID is how "this pane" resolves to the Browser pane beside it, so a host value must not override it.
**Approved**: pending

**Decision**: Registration and allowance come from one family value.
**Rationale**: A pane added to the family reaches every host that offers it with no edit there, and no host can register a pane without allowing it.
**Approved**: pending

**Decision**: The raw value of the terminal view identifier is fixed.
**Rationale**: Persisted layout rows already name it.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |

Registration is separated from the content each pane builds, and the family keeps registration and allowances together, so separation of concerns passes. The family test file covers allowances and validation against the registry but not environment merging, descriptors or content creation, so unit-test coverage is partial. Pane names are English literals, so the hardcoded-strings check fails. The layout factory propagates its failure to the caller rather than swallowing it, so error handling passes.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
