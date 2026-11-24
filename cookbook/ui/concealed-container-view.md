---
id: d7304911-c77d-4e33-acea-3bd1a4d47c53
title: "Concealed Container View"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A container whose contents nothing outside the app may read: hidden from accessibility and scripting, and blanked from screen capture while revealed."
platforms:
  - swift
  - macos
tags:
  - privacy
  - accessibility
  - container
  - screen-capture
depends-on: []
related: []
references:
  - https://developer.apple.com/documentation/appkit/nswindow/sharingtype
  - https://developer.apple.com/documentation/appkit/nsaccessibility
approved-by: ""
approved-date: ""
---

# Concealed Container View

## Overview

A container view whose contents nothing outside the app may read: not the
accessibility API, not a screen reader, not a script that walks views, and not
a screen capture.

- **Accessibility.** The container is not an accessibility element and has no
  children, so the subtree under it does not exist to an accessibility client,
  whether a screen reader or a programmatic walk. A hit test that lands inside
  it resolves to the nearest element above it, so nothing below is ever named.
- **Scripting.** A script command that walks views stops at one of these. A
  static check says whether any view is inside one. A framework that cannot
  import this one asks the runtime for a marker protocol by its fixed
  Objective-C name instead.
- **Screen capture.** While the container is revealed and in a window, that
  window is blanked for screenshots, screen recording and screen sharing. The
  window goes back to read-only sharing when no concealed container in it is
  revealed any longer.

Use it around anything private, such as a terminal session or an editor of
private words, which the owner reveals when its privacy screen comes down and
conceals when it goes back up.

## Behavioral Requirements

### Accessibility

- **not-an-element**: The container MUST NOT be an accessibility element.
- **no-children**: The container MUST report no accessibility children, no children in navigation order and no visible children.
- **hit-test-resolves-upward**: An accessibility hit test landing on the container MUST resolve to the nearest unignored accessibility ancestor of its superview, and never to anything inside it.
- **hit-test-no-superview**: An accessibility hit test on a container that has no superview MUST resolve to nothing.
- **inner-views-not-elements**: A view placed inside the container SHOULD NOT be an accessibility element either, because a hit test could still land on it.

### Concealment check

- **is-concealed-static**: A static `isConcealed(_:)` check MUST be offered, taking a view.
- **is-concealed-walks-up**: `isConcealed(_:)` MUST return true when the view is a concealed container or any ancestor of it is one, and false otherwise.
- **is-concealed-self**: `isConcealed(_:)` MUST return true for a concealed container itself.
- **marker-protocol**: The container MUST conform to a marker protocol with no requirements, for frameworks that cannot import this one.
- **marker-objc-name**: The marker protocol MUST be exposed to the Objective-C runtime under the fixed name `ATKConcealsContents`.
- **marker-name-fixed**: The marker protocol's Objective-C name MUST NOT be changed, because a framework that looks it up by name breaks silently if it is.

### Revealing

- **revealed-default**: A container MUST start not revealed.
- **revealed-owner-set**: The owner MUST set `isRevealed` to true when its privacy screen comes down and back to false when it goes back up.
- **revealed-updates-window**: Changing `isRevealed` MUST re-evaluate the screen-capture state of the container's window.

### Screen capture

- **capture-blank-when-revealed**: A window that has at least one revealed concealed container MUST have its sharing type set to none.
- **capture-restore-when-none**: A window with no revealed concealed container MUST have its sharing type set to read-only.
- **capture-any-container**: A window with several concealed containers MUST be blanked while any one of them is revealed, and restored only when none is.
- **capture-on-attach**: Adding the container to a window MUST re-evaluate that window's sharing type.
- **capture-on-detach**: Removing the container from a window, or moving it to another, MUST re-evaluate the old window's sharing type with the container's own claim left out, even if it is still revealed.
- **capture-search-content-view**: The re-evaluation MUST search the window's content view tree, finding a container no matter how deep it sits, and MUST NOT descend into a concealed container once found.
- **capture-no-window-no-op**: With no window, or a window without a content view, re-evaluation MUST do nothing.
- **capture-conceals-only-while-revealed**: A container that is not revealed MUST NOT blank its window.

### Lifetime and isolation

- **open-for-subclass**: The container MUST be open for subclassing, with its accessibility and window-move hooks overridable.
- **ui-thread-confined**: The container MUST be used on the main thread only; the hit-test override MUST assume the main thread because the platform asks on it.

## Appearance

- **Corner radius**: Not applicable: the container draws nothing of its own.
- **Padding**: Not applicable: the container lays out nothing.
- **Font**: Not applicable.
- **Background**: Not set here; the owner or the contents draw.
- **Foreground/Text**: Not applicable.
- **Border**: Not set here.
- **Shadow**: None.
- **Min/Max size**: Not set here.

## States

| State | Appearance change |
|-------|------------------|
| Concealed (default) | Contents drawn normally on screen; invisible to accessibility, scripting and, while not revealed, window sharing stays read-only |
| Revealed | Contents on screen; the window is blanked for screenshots, recording and sharing |
| Several revealed | The window stays blanked until the last one is concealed again |
| Detached | No window to blank; the old window's state is re-evaluated without this container's claim |
| Pressed | Not applicable: the container is not interactive. |
| Disabled | Not applicable: the source exposes no enabled flag. |
| Focused | Not applicable: the container takes no focus of its own. |
| Loading | Not applicable: nothing is fetched. |

## Accessibility

- **Role/trait**: None: the container is deliberately not an accessibility element.
- **Label requirements**: None: nothing under the container is to be named, by design.
- **Announce state changes**: Not applicable: the container posts no accessibility notification; hiding from accessibility is its purpose.
- **Keyboard navigation**: Not applicable: the container takes no focus of its own; focus inside it is the contents' business.
- **Minimum tap target**: Not applicable: the container is not interactive.
- **Minimum contrast ratio**: Not applicable: the container sets no color.
- **inner-view-guard**: The container does not stop a view placed inside it from being an accessibility element; the source leaves that to the caller, as its comment says, because a hit test could still land on such a view. Callers hosting views inside it should make those views non-elements too (see `inner-views-not-elements`).

## Conformance Test Vectors

No test beside the source drives this component. These vectors are derived from the source's behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| concealed-001 | not-an-element, no-children | Ask a container for its accessibility element flag and its three children lists | Not an element; each list empty |
| concealed-002 | hit-test-resolves-upward | Hit test the container's accessibility at a point inside it | The result is the nearest unignored ancestor of its superview, never a subview |
| concealed-003 | hit-test-no-superview | Hit test a container with no superview | The result is nothing |
| concealed-004 | is-concealed-self, is-concealed-walks-up | Call `isConcealed(_:)` on the container, on a subview, and on a view two levels deep | True for all three |
| concealed-005 | is-concealed-walks-up | Call `isConcealed(_:)` on a view outside any container | False |
| concealed-006 | marker-protocol, marker-objc-name | Ask the runtime for the protocol named `ATKConcealsContents` and check the container conforms | The protocol is found and the container conforms |
| concealed-007 | revealed-default, capture-conceals-only-while-revealed | Add a fresh container to a window | The window's sharing type is read-only |
| concealed-008 | capture-blank-when-revealed, revealed-updates-window | Set `isRevealed` to true in a window | The window's sharing type is none |
| concealed-009 | capture-restore-when-none | Set `isRevealed` back to false | The window's sharing type is read-only |
| concealed-010 | capture-any-container | Two containers in one window, both revealed, then one concealed | Sharing stays none after the first is concealed, and is read-only after the second is |
| concealed-011 | capture-on-attach | Reveal a container, then add it to a window | The window's sharing type is none |
| concealed-012 | capture-on-detach | Reveal a container in a window, then remove it | The old window's sharing type is read-only |
| concealed-013 | capture-on-detach | Move a revealed container from window A to window B | A is read-only and B is none |
| concealed-014 | capture-search-content-view | Place a revealed container five levels deep in the window | The window's sharing type is none |
| concealed-015 | capture-no-window-no-op | Set `isRevealed` on a container with no window | No error; no window changes |

## Edge Cases

- **Null/empty input** (MUST): a container with no window does nothing on reveal; a window with no content view is left alone.
- **Boundary values** (MUST): the first container revealed blanks the window and the last one concealed restores it (see `capture-any-container`).
- **Container removed while revealed** (MUST): the old window is restored when no other container there is revealed (see `capture-on-detach`).
- **Container inside container** (MAY): the window search does not descend into a concealed container once found, so a nested container's reveal state is not counted; only the outer one is.
- **Non-container ancestor** (MUST): ordinary ancestors are skipped; only a concealed container ancestor counts for `isConcealed(_:)`.
- **Sharing type changed by someone else** (MAY): the source writes the window's sharing type on every re-evaluation, overriding a value set elsewhere, and restores only to read-only, never to a previously held value.
- **Concurrent access** (MUST): confined to the main thread.
- **Error states**: Not applicable: no I/O or throwing operation.
- **Offline/disconnected state**: Not applicable: no networking.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `isRevealed` | bool | false | Whether the contents are on screen; set by the owner when its privacy screen comes down and goes back up |

## Deep Linking

Not applicable: the container is a view; the source defines no URL or route.

## Localization

Not applicable: the container has no user-visible strings.

## Accessibility Options

- **Reduce Motion**: Not applicable: nothing animates.
- **Increase Contrast**: Not applicable: the container sets no color.
- **Differentiate Without Color**: Not applicable: the container conveys no state visually.

## Feature Flags

Not applicable: the source contains no feature-flag lookup.

## Analytics

Not applicable: the source contains no analytics call, and a concealed container should never emit contents to one.

## Privacy

- **Data collected**: Not applicable: the container itself stores nothing.
- **Storage**: Not applicable.
- **Transmission**: Not applicable: nothing leaves the process; the purpose of the container is to keep its contents from clients outside the app.
- **Retention**: Not applicable.
- **capture-while-concealed**: The window is blanked for capture only while a container is revealed; while every container is concealed the window is read-only. Keeping the contents off screen in that state is the owner's job: the private terminal controller, for one, hides its terminal view and puts its privacy screen up whenever the contents are not revealed.

## Logging

Not applicable: the source contains no logging call.

## Platform Notes

- **SwiftUI**: Not directly available. Host the concealed `NSView` through `NSViewRepresentable`. For the accessibility half alone, apply `.accessibilityHidden(true)` to the subtree. Screen-capture blanking needs the underlying window; reach it with an `NSViewRepresentable` bridge and set `sharingType`.
- **Compose**: On Android set `WindowManager.LayoutParams.FLAG_SECURE` on the window while revealed and clear it when none remain, which blanks screenshots, recording and the recent-apps card. Hide the subtree from assistive technology with `Modifier.clearAndSetSemantics {}`.
- **React/Web**: The web cannot stop capture. Hide the subtree from assistive technology with `aria-hidden="true"` and `inert`, and mark scripts' walkers with a `data-concealed` attribute. Screen capture blanking is not available; the Screen Capture API exposes no hook to refuse it.
- **AppKit / UIKit** (source platform): Implemented in `packages/apple/AgenticDeveloperHubSDK/CoreUI/ConcealedContainerView.swift` as an `open` `NSView` subclass that overrides `isAccessibilityElement`, `accessibilityChildren`, `accessibilityChildrenInNavigationOrder`, `accessibilityVisibleChildren` and `accessibilityHitTest(_:)`. The hit-test override is nonisolated, so it uses `MainActor.assumeIsolated` to read the superview and ask `NSAccessibility.unignoredAncestor(of:)`. Window blanking sets `NSWindow.sharingType` to `.none` or `.readOnly`, re-evaluated from `isRevealed`, `viewWillMove(toWindow:)` and `viewDidMoveToWindow`. The marker protocol `ConcealsContents` is `@objc(ATKConcealsContents)`. Its consumers within the repo are the scripting window commands, the private words editor and the private terminal view controller. UIKit equivalent: set `isAccessibilityElement = false` with `accessibilityElements = []`, and blank capture by watching `UIScreen.isCaptured` and covering the view.
- **WinUI 3**: Hide the subtree from UI Automation with `AutomationProperties.AccessibilityView="Raw"` on the container, and a custom `AutomationPeer` for the container whose `GetChildrenCore` returns an empty list and `IsControlElementCore` and `IsContentElementCore` return false. Blank capture while revealed by calling `SetWindowDisplayAffinity(hwnd, WDA_EXCLUDEFROMCAPTURE)` from the window handle (`WinRT.Interop.WindowNative.GetWindowHandle`) when any container is revealed, and `WDA_NONE` when none is, keeping a count of revealed containers per window as the source does by walking the tree. Expose a marker interface with a stable name for other assemblies to test against.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/CoreUI/ConcealedContainerView.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Accessibility concealment works by being a non-element with no children, not by hiding each descendant.
**Rationale**: Per the source comment, the subtree under the container then simply does not exist to an accessibility client, for VoiceOver and programmatic walks alike, with no per-view bookkeeping.
**Approved**: pending

**Decision**: A hit test resolves to the nearest unignored ancestor of the superview.
**Rationale**: Per the source comment, a hit test landing inside the container must resolve to the element above it, so nothing below is ever named.
**Approved**: pending

**Decision**: Screen capture is blanked only while a container is revealed.
**Rationale**: Per the source comment, the owner reveals the contents when its privacy screen comes down; only then is anything readable on screen to protect, and the window is restored when no container in it is revealed any longer. The owner's privacy screen covers the contents whenever they are not revealed (see `capture-while-concealed`).
**Approved**: pending

**Decision**: The window's blanking is derived by searching the content view for revealed containers, not by a counter.
**Rationale**: The state is recomputed from the view tree on each change, so a container leaving or arriving cannot leave a count out of step; the cost is a tree walk per change.
**Approved**: pending

**Decision**: Scripting frameworks find a concealed view through a marker protocol under a fixed Objective-C name.
**Rationale**: Per the source comment, a framework beneath this one cannot import it, so it asks the runtime for `ATKConcealsContents` and stops at any conforming view; renaming it would break them silently, so the name is fixed.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`separation-of-concerns` passes because the container owns only concealment: when to reveal is the owner's, what to draw is the contents', and the scripting walk is another framework's, reached through the marker protocol. `unit-test-coverage` fails because no test in the repository references the container; its consumers are the scripting window commands, the private words editor and the private terminal view controller.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial recipe extracted from the Apple `ConcealedContainerView` source. |
