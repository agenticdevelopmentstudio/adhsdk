---
id: 98304563-e576-4fb7-a7d2-5abeb832f279
title: "Top Anchored Flipped View"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A container view with its coordinate origin at the top-left, used as a scroll view's document so short content sits at the top, not sunk to the bottom."
platforms:
  - swift
  - macos
tags:
  - ui
  - layout
  - scroll
depends-on: []
related: []
references:
  - https://developer.apple.com/documentation/appkit/nsview/isflipped
approved-by: ""
approved-date: ""
---

# Top Anchored Flipped View

## Overview

The top anchored flipped view is an empty container whose coordinate origin is
at its top-left corner. It is for use as the document view of a scroll view.
AppKit's default origin is at the bottom-left, so a document shorter than the
scroll view's visible area sinks to the bottom and leaves an empty gap above
its content whenever the window is taller than the rows. With a flipped
document, the content stays at the top and the gap falls below it, which is
where a reader expects it.

It adds no drawing, no layout and no behavior of its own; its only job is the
flipped coordinate system.

## Behavioral Requirements

- **flipped-origin**: The view MUST report a flipped coordinate system, so its origin is the top-left corner and y grows downward.
- **content-at-top**: Inside a scroll view, a document of this view whose content is shorter than the visible area MUST sit at the top of the visible area, with the slack below.
- **no-drawing**: The view MUST NOT draw anything of its own.
- **container-only**: The view MUST NOT add layout, subviews or behavior of its own; owners add their content and constraints.
- **not-subclassable**: The type MUST be final.
- **public**: The type MUST be public so other frameworks can use it as a document view.

## Appearance

- **Corner radius**: Not applicable: the view draws nothing.
- **Padding**: None.
- **Font**: Not applicable.
- **Background**: None; transparent.
- **Foreground/Text**: Not applicable.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: None; sized by its owner's constraints.

## States

| State | Appearance change |
|-------|------------------|
| Default | Transparent container with its origin at the top-left |
| Content shorter than the scroll view | Content at the top, empty slack below |
| Content taller than the scroll view | Scrolls as any document does |
| Pressed | Not applicable: no interaction |
| Disabled | Not applicable |
| Focused | Not applicable |
| Loading | Not applicable |

## Accessibility

- Role/trait: None of its own; a plain container is not an accessibility element.
- Label requirements: None.
- Announce state changes: Not applicable.
- Minimum tap target: Not applicable: the view has no controls.

## Conformance Test Vectors

No test beside the source exercises this view. These vectors are derived from
the source and untested.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| top-anchored-001 | flipped-origin | Create the view and read `isFlipped` | True |
| top-anchored-002 | content-at-top | Subview 100 points tall pinned to the top of a document view; the scroll view's visible area 400 points tall | The subview's top edge is at the top of the visible area |
| top-anchored-003 | content-at-top | Same, using an unflipped view as the document | The subview sits at the bottom, which is the case this view prevents |
| top-anchored-004 | no-drawing | Render the view alone | Nothing is drawn |
| top-anchored-005 | container-only | Create the view and read `subviews` and `constraints` | Both are empty |
| top-anchored-006 | flipped-origin | Add a subview with frame origin (0, 10) and read its frame's minY in the view's coordinates | 10 points below the top edge |
## Edge Cases

- **Content taller than the visible area** (MUST): Behaves as any document view; the flip changes nothing but the origin.
- **Content added after creation** (MUST): Stays at the top; the view's flip is fixed.
- **Subviews with their own flip** (SHOULD): A subview's coordinates are its own; only the document's origin is changed.
- **Resizing the window** (MUST): The slack below the content grows and shrinks; the content does not move.
- **Concurrent access**: Not applicable: no state.
- **Network or offline state**: Not applicable.

## Configuration

Not applicable: the view has no options.

## Deep Linking

Not applicable: the view has no address or route.

## Localization

Not applicable: the view has no text.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: no animation. |
| Increase Contrast | Not applicable: draws nothing. |
| Differentiate Without Color | Not applicable: draws nothing. |

## Feature Flags

Not applicable: the source reads no feature flag.

## Analytics

Not applicable: the source emits no analytics event.

## Privacy

- **Data collected**: None.
- **Storage**: None.
- **Transmission**: None.
- **Retention**: Not applicable.

## Logging

Not applicable: the source writes no log entry.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/CoreUI/TopAnchoredFlippedView.swift`, a final AppKit `NSView` overriding `isFlipped`. A SwiftUI `ScrollView` already anchors short content at the top, so no counterpart is needed; when embedding in an `NSViewRepresentable` scroll view, use this view as the document.
- **Compose**: A `Column` in `verticalScroll` places content at the top by default; no counterpart is needed.
- **React/Web**: A block container with `overflow: auto` places content at the top by default; no counterpart is needed.
- **AppKit / UIKit**: In AppKit, override `isFlipped` to return true and use the view as `NSScrollView.documentView`, pinning content to its top and leading edges. UIKit's origin is already top-left, so a `UIScrollView` content view needs nothing.
- **WinUI 3**: A `ScrollViewer` with a `StackPanel` content places content at the top by default; no counterpart is needed.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/CoreUI/TopAnchoredFlippedView.swift` | confirmed (1.0.1) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Flip the coordinate system rather than pin content to the top with constraints.
**Rationale**: AppKit positions a short document from the bottom; flipping it fixes every owner's content at once without constraints that fight the clip view.
**Approved**: pending

**Decision**: The view is empty and final.
**Rationale**: It exists only for the flip; any behavior belongs in the owner.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |

The view does one thing, the flip, so separation of concerns passes. No test
covers it, so unit test coverage fails. It is a plain `NSView` using AppKit's
own flipping, so native controls preference passes.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Two more conformance test vectors |
