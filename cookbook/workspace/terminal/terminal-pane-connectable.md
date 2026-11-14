---
id: f62b2712-2542-4f93-a63f-7af6596f8a7e
title: "Terminal Pane Connectable"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A contract for pane content that holds a terminal another pane, such as a Terminal Chat, can connect to, with a change notification and a start-on-connect hook."
platforms:
  - swift
  - macos
tags:
  - terminal
  - composable-tabs
  - protocol
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Terminal Pane Connectable

## Overview

A main-actor protocol for pane content that holds a terminal something else in the window can connect to and type into. A connecting pane learns only the session: whether that terminal is an ordinary one or a private one is the terminal pane's business, and what happens to the text on the way in and out happens inside the session. The contract has two members: the terminal a connection would type into right now (or nothing), and an asynchronous start that brings the terminal up first if it has not started, because a connection is a reason to start, as appearing is. A default start returns the current terminal, for terminals that run as soon as they exist. A notification, posted with the pane content as its object, tells a waiting chat that a pane's connectable terminal changed. The ordinary terminal pane's content conforms: its connectable terminal is the selected session, when that session is running. There is no visual surface.

## Behavioral Requirements

- **connectable-terminal**: A conforming pane MUST report, through its connectable terminal property, the terminal session a connection would type into, or nothing when there is none to offer right now.
- **start-connectable-terminal**: A conforming pane MUST provide an asynchronous start that returns the terminal a connection types into, starting it first if it has not started, or nothing when it cannot be.
- **start-may-throw**: The start MAY fail with an error, which the caller handles.
- **default-start**: WHEN a conforming pane does not implement the start itself, the start MUST return its current connectable terminal, without starting anything.
- **change-notification**: A pane whose connectable terminal changes, such as a terminal that starts after its pane appeared, MUST post the connectable-terminal-changed notification with the pane content as the object.
- **notification-name**: The notification MUST be named "TerminalPaneConnectableDidChange".
- **session-only**: A conforming pane MUST expose only the terminal session to a connecting pane, and MUST NOT require the connecting pane to know whether the terminal is ordinary or private.
- **main-actor**: The contract and its members MUST be used on the main actor and the conforming type MUST be a class.
- **terminal-content-selected-session**: The terminal pane content MUST report as its connectable terminal the selected session of its session manager, and MUST report nothing when there is no selected session.
- **terminal-content-running-only**: The terminal pane content MUST report its selected session only while that session is running, and MUST report nothing when the selected session is not running.
- **terminal-content-default-start**: The terminal pane content MUST use the default start, so connecting to it does not start a stopped session.
- **private-terminal-posts-change**: The private terminal pane content MUST post the connectable-terminal-changed notification, with itself as the object, the first time its session starts, which happens once its privacy words are loaded, whether the pane appeared or a connection asked it to start. It MUST NOT post it when the words are updated on a session that has already started.

## Appearance

Not applicable: the component is a protocol and a notification name; it draws nothing and has no size, color or typography.

## States

| State | Appearance change |
|-------|------------------|
| Offering a terminal | The connectable terminal property returns a session. |
| Not offering a terminal | The property returns nothing: no session, or the selected session has stopped. |
| Starting | The start has been called and has not returned; the property still returns nothing until a session runs. |
| Pressed / Disabled / Focused / Loading | Not applicable: a protocol has no appearance states; the starting state above is the only transient state. |

## Accessibility

Not applicable: the component is a protocol with no visible element, label or interaction; accessibility belongs to the panes that conform and to the pane that picks one.

## Conformance Test Vectors

No test in the repository targets this contract directly; the vectors below are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-connectable-001 | terminal-content-selected-session, connectable-terminal | Terminal pane content whose session manager has a running selected session | The property returns that session. |
| terminal-connectable-002 | terminal-content-running-only | Selected session exists but is not running | The property returns nothing. |
| terminal-connectable-003 | terminal-content-selected-session | Session manager has no selected session | The property returns nothing. |
| terminal-connectable-004 | default-start, terminal-content-default-start | Call the start on terminal pane content with a stopped selected session | It returns nothing and starts no session. |
| terminal-connectable-005 | default-start | Call the start on a conforming type that does not implement it, whose property returns a session S | The start returns S. |
| terminal-connectable-006 | start-connectable-terminal | A conforming type whose terminal is not started; call the start | It starts the terminal and returns its session. |
| terminal-connectable-007 | start-may-throw | A conforming type whose start throws | The caller receives the error. |
| terminal-connectable-008 | notification-name, change-notification | Observe notifications named "TerminalPaneConnectableDidChange" while a pane's terminal starts | The notification arrives with the pane content as its object. |
| terminal-connectable-009 | session-only | A connecting pane connects to private terminal content | It receives only a terminal session and uses no private-specific API. |
| terminal-connectable-010 | private-terminal-posts-change | Private terminal content whose session starts for the first time after its privacy words load | One notification named "TerminalPaneConnectableDidChange" is posted with that content as its object; a later privacy-words update on an already-started session posts none. The same single notification is posted when a connection's start call loads the words and starts the session. |

## Edge Cases

- **No terminal to offer (MUST)**: The property returns nothing; the start then either starts one or returns nothing.
- **Selected session stopped (MUST)**: The terminal pane content returns nothing, even though a session exists, because only running sessions are offered.
- **Start cannot succeed (MUST)**: The start returns nothing or throws; a caller treats nothing as no terminal.
- **Concurrent access**: The contract is main-actor isolated; two overlapping starts are not coordinated here, and the Terminal Chat guards against that by refusing a second start while one is in flight.
- **Offline or disconnected state**: Not applicable: the contract is in-process and uses no network.
- **Null and empty input**: Not applicable beyond the nothing results above; the contract takes no arguments.
- **Boundary values**: Not applicable: no numeric or sized input.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| connectableTerminal | terminal session, optional | none | Read-only; the terminal a connection would type into now. |
| startConnectableTerminal | async throwing call | returns connectableTerminal | Starts the terminal if needed and returns it. |

## Deep Linking

Not applicable: the contract names no URL or scheme.

## Localization

Not applicable: the component declares no user-visible string; the only string is the notification name, which is an identifier and not user-facing.

## Accessibility Options

Not applicable: the component draws nothing and responds to no display option.

## Feature Flags

Not applicable: the source reads no feature flag.

## Analytics

Not applicable: the source emits no analytics events.

## Privacy

- **Data collected**: None; the contract passes a terminal session handle.
- **Storage**: None.
- **Transmission**: A connecting pane can type into and read from the session it is given; the session decides what happens to text on the way in and out, including for a private terminal.
- **Retention**: Not applicable: nothing is retained by the contract.

## Logging

Not applicable: the source declares no logger and writes no log entries.

## Platform Notes

- **SwiftUI**: Express the contract as a protocol with an observable terminal property and an async start; use a Combine publisher or an observation stream in place of the notification.
- **Compose**: Use an interface exposing a StateFlow of the terminal session and a suspend start function; the StateFlow replaces the change notification.
- **React/Web**: Use a TypeScript interface with a getter, an async start method and an event emitter or subscribe function; a React context can hold the connectable pane registry.
- **AppKit / UIKit**: Source platform. The file is `TerminalPaneConnectable.swift`: a main-actor class-bound protocol with a default async start, a notification name extension and a conformance extension for the terminal pane's content view controller. UIKit would use the same protocol and a notification.
- **WinUI 3**: Define a C# interface ITerminalPaneConnectable with a ConnectableTerminal property and Task StartConnectableTerminalAsync() with a default interface method returning the property; raise ConnectableTerminalChanged as a typed event or publish it through a WeakReferenceMessenger from the CommunityToolkit.Mvvm; marshal calls through the DispatcherQueue because the conforming UserControl is UI-thread-bound.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/TerminalSession/TerminalPaneConnectable.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The contract exposes only the terminal session.
**Rationale**: Whether the terminal is ordinary or private is the terminal pane's business, and what it does to text on the way in and out happens inside the session.
**Approved**: pending

**Decision**: A connection is a reason to start the terminal.
**Rationale**: The source comment says a connection starts a terminal as appearing does, so a pane that never appeared can still be started by a connection.
**Approved**: pending

**Decision**: The default start returns the current terminal.
**Rationale**: A terminal that is running as soon as it exists has nothing to start.
**Approved**: pending

**Decision**: The terminal pane content offers its selected session only while running.
**Rationale**: A stopped session cannot be typed into.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |

The contract exposes one handle and leaves what is typed, hidden or started to the pane and the session, so separation of concerns passes. No test in the repository targets the contract or the terminal content's conformance, so unit-test coverage fails.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
