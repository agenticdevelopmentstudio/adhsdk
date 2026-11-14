---
id: d9e0ea89-e6f3-4c54-92c9-9d8f237f8ba1
title: "Window Titlebar Title"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A window title with a 14-point icon before it, drawn at the leading edge of the title bar after the window controls, replacing the window's own centred title."
platforms:
  - swift
  - macos
tags:
  - composable-tabs
  - titlebar
  - window
  - title
depends-on: []
related: []
references:
  - https://developer.apple.com/design/human-interface-guidelines/windows
approved-by: ""
approved-date: ""
---

# Window Titlebar Title

## Overview

A window's title with an icon before it, set at the leading edge of the title
bar just after the window controls, the way a pane's title bar shows its icon
and name. It replaces the window's own centred title, which the platform draws
without an icon. The window's `title` property still carries the name, for the
Window menu and for accessibility, but it is no longer drawn.

The component is a leading titlebar accessory. It owns an icon (14 points
square) and a single-line label in a horizontal stack, sizes itself to the
title's own width, and never takes more width than the window leaves once room
is kept for trailing accessories (such as a settings gear) and the window
controls. A long title truncates at its tail rather than running under them.

Use it in any window that wants an icon beside its title in the title bar.

## Behavioral Requirements

### Installation

- **install-hides-native-title**: Installing in a window MUST hide the title the platform draws.
- **install-adds-accessory**: Installing MUST add the component to the window as a titlebar accessory.
- **install-sets-window-title**: Installing MUST set the window's `title` to the current text, so the Window menu and accessibility still read the name.
- **install-observes-resize**: Installing MUST observe that window's resize notification, on the main queue, and re-size the component on each one.
- **install-sizes-immediately**: Installing MUST size the component once, immediately after wiring.
- **leading-edge**: The component MUST sit at the leading edge of the title bar.

### Text

- **text-reads-label**: The `text` property MUST read back the label's current string.
- **text-sets-label**: Setting `text` MUST set the label's string.
- **text-mirrors-window-title**: Setting `text` MUST also set the title of the window the component is in, when it is in one.
- **text-before-install**: Setting `text` before installation MUST NOT fail, and the first installation MUST carry that text to the window's title.
- **text-resizes**: Setting `text` MUST re-size the component.

### Icon

- **icon-reads-view**: The `icon` property MUST read back the icon view's image.
- **icon-sets-view**: Setting `icon` MUST set the icon view's image.
- **icon-nil-hides**: Setting `icon` to nil MUST hide the icon view, and setting it to an image MUST show it.
- **icon-resizes**: Setting `icon` MUST re-size the component.
- **icon-size**: The icon view MUST be fixed at 14 points wide and 14 points high, with the image scaled proportionally to fit.
- **icon-hidden-from-accessibility**: The icon view MUST NOT be an accessibility element.

### Label

- **label-single-line-tail**: The label MUST truncate at its tail.
- **label-font**: The label MUST use the system title bar font at its default size.
- **label-color**: The label MUST use the system primary label color.
- **label-low-compression-resistance**: The label MUST have its horizontal content-compression resistance set to the default-low priority, so that it is the view that gives way (the icon is held at a fixed width).
- **label-identifier**: The label MUST carry the accessibility identifier `window.title`.

### Layout

- **stack-horizontal**: The icon and label MUST be laid out in a horizontal stack, centred vertically, with 5 points between them.
- **stack-insets**: The stack MUST inset its contents by 6 points on the left and right sides and none on the top and bottom. The insets are physical left and right values, equal on both sides.
- **width-fits-title**: The component's width MUST be the stack's fitting width, so that the title is as wide as its own content.
- **width-capped-by-window**: The component's width MUST NOT exceed the window's width minus the 160 points kept for trailing accessories and the window controls.
- **width-never-negative**: The component's width MUST be clamped to 0 when the window is narrower than 160 points.
- **width-unbounded-without-window**: With no window, the component's available width MUST be unbounded, so only the fitting width applies.
- **height-minimum**: The component's height MUST be the stack's fitting height, but at least 28 points.
- **resize-on-window-resize**: The component MUST re-size whenever its window is resized.

### Lifetime and isolation

- **observer-removed-on-deinit**: The component MUST remove its resize observer when it is deallocated.
- **observer-weak**: The resize observer MUST hold the component weakly.
- **no-archive-init**: The component MUST NOT support construction from an archive.
- **ui-thread-confined**: The component MUST be used on the main thread only.

## Appearance

- **Corner radius**: Not applicable: no background or border is drawn.
- **Padding**: 6 points left and right, 0 top and bottom; 5 points between icon and label.
- **Font**: The system title bar font at its default size.
- **Background**: None; the title bar's own material shows through.
- **Foreground/Text**: The system primary label color.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: Icon 14 by 14 points. Height at least 28 points. Width from 0 up to the window's width minus 160 points.

## States

| State | Appearance change |
|-------|------------------|
| Default | Icon then title, left to right, after the window controls |
| No icon | The icon view is hidden; the stack closes up and the title leads |
| Long title | The title truncates at its tail where the window leaves no more room |
| Narrow window | Width clamps to 0 when the window is narrower than the reserved width |
| Pressed | Not applicable: the component is not interactive. |
| Disabled | Not applicable: the source exposes no enabled flag. |
| Focused | Not applicable: the label is static text and takes no focus. |
| Loading | Not applicable: nothing is fetched. |

## Accessibility

- **Role/trait**: Static text for the label; the icon is not an accessibility element.
- **Label requirements**: The label carries the identifier `window.title`. The window's own `title` carries the same name for the Window menu and assistive technology.
- **Announce state changes**: Not applicable: the component posts no accessibility notification; it keeps the window title in step with the text.
- **Keyboard navigation**: Not applicable: nothing here takes focus.
- **Minimum tap target**: Not applicable: nothing here is interactive.
- **Minimum contrast ratio**: The system primary label color against the title bar; the contrast is the platform's, not set here.
- **icon-accessibility-description**: The icon is hidden from accessibility and has no description; the label beside it, and the window's `title`, carry the name.

## Conformance Test Vectors

No test beside the source drives this component. These vectors are derived from the source's behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| titlebar-title-001 | install-hides-native-title, install-adds-accessory | Install in a window | The window's title visibility is hidden and the window lists the component among its titlebar accessories |
| titlebar-title-002 | install-sets-window-title, text-before-install | Set `text` to "Notes" before installing, then install | The window's `title` is "Notes" |
| titlebar-title-003 | text-sets-label, text-mirrors-window-title | After install, set `text` to "Plan" | The label reads "Plan" and the window's `title` is "Plan" |
| titlebar-title-004 | text-reads-label | Set `text` to "Plan", read `text` | "Plan" |
| titlebar-title-005 | icon-nil-hides, icon-sets-view | Set `icon` to an image, then to nil | The icon view is shown with the image, then hidden with no image |
| titlebar-title-006 | icon-size, icon-hidden-from-accessibility | Read the icon view's constraints and accessibility flag | Width 14 and height 14; not an accessibility element |
| titlebar-title-007 | label-identifier, label-single-line-tail | Read the label | Identifier `window.title`; line break mode truncates the tail |
| titlebar-title-008 | stack-horizontal, stack-insets | Read the stack | Horizontal, centred vertically, spacing 5, insets 6 left and 6 right, 0 top and bottom |
| titlebar-title-009 | width-fits-title, width-capped-by-window | Install in a 1000-point window with a short title | Width equals the stack's fitting width |
| titlebar-title-010 | width-capped-by-window, resize-on-window-resize | Set a very long title in a 400-point window | Width is 240 points; widening the window to 600 points raises it, narrowing lowers it |
| titlebar-title-011 | width-never-negative | Resize the window to 100 points | Width is 0 |
| titlebar-title-012 | height-minimum | Install with a stack whose fitting height is under 28 points | Height is 28 |
| titlebar-title-013 | width-unbounded-without-window | Set `text` on a component not installed in any window | Width equals the stack's fitting width |
| titlebar-title-014 | observer-removed-on-deinit, observer-weak | Install, release the component, resize the window | The window resizes with no callback to the released component and no crash |
| titlebar-title-015 | no-archive-init | Attempt to construct from an archive | The attempt is rejected with a fatal error |

## Edge Cases

- **Null/empty input** (MUST): an empty `text` leaves an empty label and sets the window's `title` to empty; a nil `icon` hides the icon.
- **Boundary values** (MUST): a window narrower than 160 points clamps the width to 0, so the title is not visible (see `width-never-negative`).
- **Very long title** (MUST): the title truncates at its tail, since its width is capped by the window (see `width-capped-by-window`).
- **Text set before installation** (MUST): there is no window to mirror to, and the first install carries the text across (see `text-before-install`).
- **Installed twice** (MAY): the source does not guard; each install adds the controller as an accessory again and registers another observer, and only the last observer is released on deallocation. Callers should install once.
- **Concurrent access** (MUST): confined to the main thread.
- **Window narrower than reserved width** (MUST): no handling beyond the clamp to 0; the source does not hide the accessory or re-flow it.
- **Error states**: Not applicable: no I/O or throwing operation.
- **Offline/disconnected state**: Not applicable: no networking.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `icon` | image or none | none | Icon before the title; none hides the view |
| `text` | string | empty | Name shown, also the window's title |
| Icon size | points | 14 | Fixed side of the icon, exposed as a static constant |
| Reserved width | points | 160 | Room kept for trailing accessories and window controls; fixed, not exposed |

## Deep Linking

Not applicable: the component is part of a window's title bar; the source defines no URL or route.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| Window title | Supplied by the caller | The only text; no string of its own |

- **title-direction**: The component sets no layout-direction handling of its own. It pins itself with the leading layout attribute and arranges its icon and label in a horizontal stack; its 6-point insets are physical left and right values, equal on both sides, so they look the same in either direction.

## Accessibility Options

- **Reduce Motion**: Not applicable: nothing animates.
- **Increase Contrast**: Not applicable: only a system color is used, so the platform's own contrast adaptation applies.
- **Differentiate Without Color**: Not applicable: the component conveys no state by color.

## Feature Flags

Not applicable: the source contains no feature-flag lookup.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data collected**: Not applicable: the component stores nothing; it shows a caller-supplied icon and text.
- **Storage**: Not applicable.
- **Transmission**: Not applicable.
- **Retention**: Not applicable.

## Logging

Not applicable: the source contains no logging call.

## Platform Notes

- **SwiftUI**: Use the window toolbar: `.toolbar { ToolbarItem(placement: .navigation) { Label(text, image: icon) } }` with `.navigationTitle(text)` kept for the Window menu and accessibility, and `.toolbarTitleDisplayMode(.inline)` or an empty visible title so the system title is not drawn twice. Use `.lineLimit(1)` with `.truncationMode(.tail)`, a 14-point frame for the icon with `.accessibilityHidden(true)`, and `.accessibilityIdentifier("window.title")`.
- **Compose**: Not a window concept; on desktop Compose, draw the title in the window's custom decorated title bar, a `Row` with 5.dp spacing, an `Icon` at 14.dp, and a `Text` with `maxLines = 1` and `overflow = TextOverflow.Ellipsis` and `Modifier.weight(1f, fill = false)`. Set the window `title` for the task switcher, and `Modifier.testTag("window.title")`.
- **React/Web**: A title bar is the page's header: a flex row with `gap: 5px`, `padding-inline: 6px`, an `<img width="14" height="14" alt="" aria-hidden="true">`, and a `<span id="window.title">` with `white-space: nowrap; overflow: hidden; text-overflow: ellipsis; min-width: 0`. Set `document.title` to the same text, the web equivalent of the window `title`.
- **AppKit / UIKit** (source platform): Implemented in `packages/apple/AgenticDeveloperHubSDK/macOS/UI/ViewControllers/ComposableTabs/WindowTitlebarTitle.swift` as a `@MainActor` public final `NSTitlebarAccessoryViewController` with `layoutAttribute = .leading`. The accessory's width is its view's frame width, so the component sets the stack's frame size directly rather than constraining it. Installation sets `titleVisibility` to `.hidden`, adds the accessory, and observes `NSWindow.didResizeNotification`. The observer is `nonisolated(unsafe)` so `deinit` can remove it, and the handler uses `MainActor.assumeIsolated`. UIKit has no titlebar accessory; on iPadOS use `UINavigationItem.titleView` or `UIWindowScene.titlebar`.
- **WinUI 3**: Extend content into the title bar with `Window.ExtendsContentIntoTitleBar = true` and `SetTitleBar(element)`. Put a `StackPanel Orientation="Horizontal" Spacing="5" Padding="6,0"` holding an `Image` (`Width="14" Height="14"`, `AutomationProperties.AccessibilityView="Raw"`) and a `TextBlock` (`TextTrimming="CharacterEllipsis"`, `MaxLines="1"`, `AutomationProperties.AutomationId="window.title"`) in the title bar region. Leave room for the caption buttons by reading `AppWindow.TitleBar.RightInset` and `LeftInset` rather than a fixed 160 points, and subtract trailing accessories, setting the `MaxWidth` of the panel on `SizeChanged`. Set `Window.Title` too, since it feeds Alt-Tab and the taskbar.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/UI/ViewControllers/ComposableTabs/WindowTitlebarTitle.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The title is a leading titlebar accessory that replaces the platform's centred title instead of decorating it.
**Rationale**: Per the source comment, the platform draws the centred title without an icon, so the only way to show an icon before the name, as a pane's title bar does, is to hide the platform's title and draw our own at the leading edge.
**Approved**: pending

**Decision**: The window's `title` is still set to the name even though it is not drawn.
**Rationale**: Per the source comment, the Window menu and accessibility read that property, so it must keep carrying the name.
**Approved**: pending

**Decision**: The width is set from the stack's fitting size, capped by the window's width minus a fixed 160 points.
**Rationale**: Per the source comment, a leading accessory is as wide as its view's frame, so the title must be sized by hand: its own width, but never more than the window leaves after the trailing accessories and window controls, so a long title truncates instead of running under them.
**Approved**: pending

**Decision**: The reserved width is a fixed constant, not measured from the actual trailing accessories.
**Rationale**: The source keeps 160 points for the trailing accessories (a settings gear) and window controls with no measurement; this is recorded as the design as built, not an invention of intent.
**Approved**: pending

**Decision**: The icon is hidden from accessibility.
**Rationale**: The icon sits beside a label that already names the window, so the icon is treated as decoration and carries no accessibility description of its own.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`separation-of-concerns` passes because the component owns only the title's drawing and sizing: the caller supplies the icon and text, and the window owns its other accessories. `unit-test-coverage` fails because no test beside the source builds or drives this component.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial recipe extracted from the macOS `WindowTitlebarTitle` source. |
