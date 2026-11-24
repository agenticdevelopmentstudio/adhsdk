---
id: 8cae34a7-d513-4851-bb97-8b8f63679b6e
title: "NSWindow Command Owner"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "NSWindow.commandOwner resolves a window to the top of its parent chain, so a command typed in a child window acts on the window it belongs to."
platforms:
  - swift
  - macos
tags:
  - ui
  - windows
  - commands
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# NSWindow Command Owner

## Overview

`commandOwner` is a read-only property added to `NSWindow` in a public
extension. It answers which window a command typed or chosen in a given window
is about: the window itself, or for a child window the window it is attached
to, followed up the chain to the top.

A child window is part of its parent rather than a window of its own. The
source gives the example of a Chrome pane's page, kept over the pane, which
takes the keys by being key itself, and so do its bubbles and menus above it.
A command that finds its target through the key window, or the window of a key
event, and stops at the child would act on a window that has no panes, no notes
and no project. This property is the one place that walks up to the real
window. It is non-visual shared logic with no state of its own.

## Behavioral Requirements

- **returns-self-without-parent**: When the window has no parent window,
  `commandOwner` MUST return that same window.
- **returns-parent-of-child**: When the window has a parent window and that
  parent has none, `commandOwner` MUST return the parent.
- **walks-to-top-of-chain**: When the window's parent itself has a parent,
  `commandOwner` MUST keep following the parent link and MUST return the
  window at the top of the chain, whatever its depth.
- **identity-not-copy**: `commandOwner` MUST return the existing window
  object, not a copy or a proxy.
- **read-only**: `commandOwner` MUST be a computed, get-only property; it
  MUST NOT store, cache or change any state on any window.
- **reads-live-parent**: `commandOwner` MUST read the parent link on every
  access, so that attaching or detaching a child window changes the answer on
  the next read.
- **non-optional**: `commandOwner` MUST always return a window; it MUST NOT
  return nil, because the window itself is the base case.

## Appearance

Not applicable — this is a computed window lookup, not a visual component.

## States

Not applicable — this is a stateless computed property, not a visual component;
its answer depends only on the window's parent chain at the moment of the read.

## Accessibility

Not applicable — this is a computed window lookup, not a visual component. It
draws nothing and takes no input.

## Conformance Test Vectors

The source has no tests beside it; every vector is derived from the property's
body and doc comment.

| ID | Requirements | Input | Expected |
|---|---|---|---|
| command-owner-001 | returns-self-without-parent | window `A` with no parent | `A.commandOwner` is `A` |
| command-owner-002 | returns-parent-of-child | child window `C` attached to window `A` | `C.commandOwner` is `A` |
| command-owner-003 | walks-to-top-of-chain | window `A` with child `B`, and `B` with child `C` | `C.commandOwner` is `A` and `B.commandOwner` is `A` |
| command-owner-004 | returns-self-without-parent, identity-not-copy | top-level window `A` | `A.commandOwner === A` (same object) |
| command-owner-005 | reads-live-parent | `C` is a child of `A`, then `A.removeChildWindow(C)` | `C.commandOwner` is `A` before the removal and `C` after it |
| command-owner-006 | reads-live-parent | standalone `C`, then `A.addChildWindow(C, ordered: .above)` | `C.commandOwner` is `C` before the attach and `A` after it |
| command-owner-007 | returns-parent-of-child | key window is a child page window over a pane; `KeyCommandRegistry.commandWindow` evaluates `(dispatchingEvent?.window ?? NSApp.keyWindow)?.commandOwner` | the result is the project window, not the page window |

## Edge Cases

- **Window with no parent**: the window itself is returned (MUST); a top-level
  window is its own command owner.
- **Deep chain**: a child of a child of a window resolves to the outermost
  window (MUST), because the source loops until the parent is nil.
- **Parent changes between reads**: the answer follows the current parent
  link (MUST); nothing is cached, so a window detached from its parent answers
  with itself on the next read.
- **Missing window (nil)**: not handled here, because the property lives on a
  window that exists. The callers handle the absent key window by optional
  chaining before reading it (`NSApp.keyWindow?.commandOwner`).
- **Cyclic parent chain**: the loop has no cycle guard, so a chain that led back
  to itself would not end. The source performs no check for it.
- **Concurrent access**: `NSWindow` is main-thread-only AppKit and the property
  does no locking; the callers in the source read it on the main thread: `ProjectWindowManager`,
  `NotesCoordinator` and `TerminalCoordinator` are `@MainActor`, and
  `KeyCommandRegistry.commandWindow` reads it from AppKit key handling.
- **Error states and offline state**: not applicable — the property raises
  no errors, does no I/O and has no dependency that could be unavailable.

## Configuration

Not applicable: the property takes no parameters, reads no settings or
environment, and has no defaults. Its only input is the receiver window.

## Deep Linking

Not applicable: the property resolves a window and exposes no URL or route.

## Localization

Not applicable: the property returns a window and owns no user-facing strings.

## Accessibility Options

Not applicable: the property draws nothing, so Reduce Motion, Increase Contrast
and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source reads no flag; the property behaves the same everywhere.

## Analytics

Not applicable: the source emits no events.

## Privacy

Not applicable: the property stores, transmits and logs nothing.

## Logging

Not applicable: the source contains no log calls.

## Platform Notes

- **SwiftUI**: SwiftUI has no parent-window chain to walk. A command is scoped through the focused scene with `focusedSceneValue` or `@FocusedValue`, which carries the owning scene's model to a `Commands` body wherever focus sits inside it. To reach the underlying window, use `NSApp.keyWindow` and call `commandOwner`, or an `NSViewRepresentable` that reads `view.window`.
- **Compose**: Desktop Compose has one `Window` per top-level window and no child-window attachment that takes focus apart from its owner. Key handling is routed with `onKeyEvent` or `onPreviewKeyEvent` inside the window; a dialog or popup that must act for the main window should capture the main window's state holder and use that instead of resolving a window.
- **React/Web**: There is no window parent chain. A popup opened with `window.open` exposes `window.opener`, and an iframe exposes `window.parent`; a loop of `while (w.opener) w = w.opener` is the closest analogue. Elements in an overlay portal belong to the same document, so a command handler there already runs in the owner's window.
- **AppKit / UIKit**: The source is `packages/apple/AgenticDeveloperHubSDK/CoreUI/NSWindow+CommandOwner.swift`, a public extension on `NSWindow` in the CoreUI framework. It follows `NSWindow.parent`, which is set by `addChildWindow(_:ordered:)`. Callers in the macOS framework are `KeyCommandRegistry.commandWindow`, `ProjectWindowManager`, `NotesCoordinator` and `TerminalCoordinator`, each reading it from the key window or the window of a key event. UIKit has no child windows; the nearest idea is following `UIWindowScene` to the scene a window belongs to.
- **WinUI 3**: Windows App SDK has no native owner-chain property on `Microsoft.UI.Xaml.Window`. Keep the relationship yourself, for example a `Window` wrapper with a nullable `Parent` field set when a child window is created, and expose `CommandOwner` as a get-only property that loops `while (w.Parent != null) w = w.Parent`. For a native owned window, `GetWindow(hwnd, GW_OWNER)` through P/Invoke or `Windows.Win32` gives the owner handle, which you map back to the `Window`; resolve through `AppWindow` and `AppWindow.Id`. Route shortcuts with `KeyboardAccelerator` on the root element or a `ContentDialog`, and resolve the owner when a command runs from a flyout or child window, not at construction, so the answer stays live.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/CoreUI/NSWindow+CommandOwner.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Resolve the owner by walking `parent` to the top instead of stopping at one level.
**Rationale**: The source says a child window's bubbles and menus sit above a page window that is itself a child, so a command may start any number of levels down, and only the top window has panes, notes and a project.
**Approved**: pending

**Decision**: Implement it as a computed property on `NSWindow` in a public extension, not as a helper on each caller.
**Rationale**: Several command paths (key command dispatch, project window lookup, notes, terminal) need the same answer; one definition keeps them from each stopping at the child (separation of concerns).
**Approved**: pending

**Decision**: Return the window itself, not nil, when there is no parent.
**Rationale**: The doc comment defines the owner as "this window, or ... the window it is attached to, at the top of the chain", so the base case needs no optional handling by callers.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`separation-of-concerns` passes because the extension does one thing, resolving a
window to the top of its parent chain, and leaves the decision of which command to
run to its callers. `unit-test-coverage` fails because the source has no test
beside it: no test file in the apple packages mentions `commandOwner`,
so the vectors above are derived from the body and doc comment alone.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
