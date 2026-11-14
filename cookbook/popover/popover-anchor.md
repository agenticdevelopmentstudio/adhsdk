---
id: c130d5d5-2ac4-4a15-a13a-9127ddad6ca1
title: "Popover Anchor"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Groups a popover trigger and panel into one hover region so moving between them doesn't dismiss the popover."
platforms:
  - typescript
  - web
tags:
  - popover
  - positioning
  - layout
depends-on: []
related:
  - c61a220c-b63e-4dcd-a12b-715de20f7b5d
references:
  - packages/web/packages/popover/src/PopoverAnchor.tsx
approved-by: ""
approved-date: ""
---

# Popover Anchor

## Overview

PopoverAnchor is a positioning context wrapper that groups a popover trigger and its associated panel as a single hover target. It establishes `position: relative` as the reference frame for the popover's absolute positioning, and it suppresses `onMouseLeave` when the pointer moves from the trigger to the panel (or back), rather than treating that crossing as leaving the group.

That suppression follows DOM containment, not visual geometry: as long as every point the pointer can cross between the trigger and the panel hit-tests to a DOM descendant of the anchor, `onMouseLeave` never fires along the way — even when the panel is visually offset outside the anchor's own box, provided something hit-testable (for example a bridging element) spans the visual gap. A panel rendered with an offsetting margin or transform and no such bridge, or one rendered through a portal instead of as a normal child, can still leave a dismissal gap the anchor does not close — see **panel-in-anchor-flow** and the Edge Cases below.

## Behavioral Requirements

- **render-children**: Component MUST render its `children` prop as-is without modification or wrapping in additional elements beyond the anchor div itself.
- **relative-positioning**: Component MUST apply `position: relative` CSS to establish a positioning context for absolutely positioned children.
- **class-concatenation**: Component MUST concatenate the string `hover-popover-anchor` with any `className` prop value. If `className` is provided, the final class MUST be `hover-popover-anchor <className>`. If `className` is not provided, the class MUST be exactly `hover-popover-anchor`.
- **leave-callback**: Component MUST accept an optional `onMouseLeave` callback and invoke it when the pointer leaves the anchor element (exiting both trigger and panel boundary).
- **preserve-hover-across-elements**: Component MUST ensure that moving the pointer from the trigger to the panel (or vice versa) does NOT trigger the `onMouseLeave` callback, because both elements are contained within the same anchor div.
- **panel-in-anchor-flow**: The panel rendered as a child of the anchor MUST remain a normal DOM descendant of the anchor (not rendered through a portal). It MAY be visually offset outside the anchor's own box (for example via absolute positioning), but if so, every point the pointer can cross between the trigger and the panel MUST hit-test to a DOM descendant of the anchor — for example a bridging element spanning the gap — or **preserve-hover-across-elements** does not hold for that crossing.

## Appearance

Not applicable: PopoverAnchor is a layout utility and does not define visual appearance. Styling is applied via the `className` prop and external stylesheets targeting the `hover-popover-anchor` class.

## States

| State | Behavior |
|-------|----------|
| Default | Anchor is mounted and ready to receive children. No visual state. |

## Accessibility

Not applicable: PopoverAnchor is a positioning wrapper with no interactive element of its own. Accessibility concerns belong to the trigger and panel components it contains — see [adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d) for how keyboard operability is (and is not) handled there, and **Compliance** below for how that gap is scored against this recipe.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| anchor-001 | render-children | `children` = `<button>Trigger</button><div>Panel</div>` | Anchor renders both children in order without wrapping them in additional elements |
| anchor-002 | relative-positioning | Anchor rendered with no props | Computed style includes `position: relative` |
| anchor-003 | class-concatenation | `className` = `"custom-class"` | Final class attribute is `"hover-popover-anchor custom-class"` |
| anchor-004 | class-concatenation | No `className` prop | Final class attribute is exactly `"hover-popover-anchor"` |
| anchor-005 | leave-callback | `onMouseLeave` callback provided, pointer leaves anchor | Callback is invoked exactly once |
| anchor-006 | preserve-hover-across-elements | Pointer on trigger, moves to panel sibling | `onMouseLeave` is NOT invoked (anchor still contains pointer) |
| anchor-007 | leave-callback | `onMouseLeave` not passed, pointer leaves anchor | No error is thrown; the anchor still renders and functions as a positioning context |
| anchor-008 | preserve-hover-across-elements | Pointer enters the anchor, leaves, enters again, leaves again (two full enter/leave cycles) | `onMouseLeave` is invoked exactly twice — once per exit, never coalesced |
| anchor-009 | panel-in-anchor-flow | Panel child rendered with a margin that visually offsets it outside the anchor's box, with no other element spanning the gap; pointer moves from the trigger across that gap toward the panel | `onMouseLeave` fires when the pointer crosses the gap, because that point does not hit-test to a DOM descendant of the anchor |
| anchor-010 | panel-in-anchor-flow | Panel child rendered via `ReactDOM.createPortal` to `document.body` instead of as a direct child | The panel is not a DOM descendant of the anchor element; pointer movement into the panel is not guaranteed to stay within the anchor's boundary |
| anchor-011 | panel-in-anchor-flow | Panel child rendered with a margin that visually offsets it outside the anchor's box, plus a bridging element that is itself a DOM descendant of the anchor and spans the gap (for example a pseudo-element on the panel); pointer moves from the trigger across the gap toward the panel | `onMouseLeave` does NOT fire; every point along the crossing hit-tests to a DOM descendant of the anchor (the bridge) |

## Edge Cases

- **Multiple children**: Component accepts ReactNode, which can be a single element, multiple elements, or a fragment. Children are rendered without iteration or mapping, so the developer is responsible for uniqueness and key management.
- **Null or undefined children**: If `children` is null or undefined, the anchor renders an empty div. This is valid and matches React's children handling.
- **Callback not provided**: If `onMouseLeave` is not passed, no callback is invoked. The anchor still functions as a positioning context. This is the expected behavior for a pure layout component.
- **Rapid pointer entry/exit**: If the pointer enters and exits the anchor repeatedly within a single event cycle (enter → leave → enter → leave), `onMouseLeave` MUST be invoked once per exit — twice for two full enter/leave cycles — not coalesced into a single call.
- **Nested interactive elements**: Child elements can be interactive. The `onMouseLeave` handler on the anchor fires only when the pointer leaves the entire anchor boundary, not when interacting with children.
- **Panel offset outside the anchor's box**: If the panel child is positioned with a margin or transform that visually separates it from the anchor (rather than sitting flush against it) and nothing hit-testable spans that gap, the pointer crossing the gap resolves to a non-descendant of the anchor and fires `onMouseLeave`, even though trigger and panel still look contiguous to the user. A bridging element that is itself a DOM descendant of the anchor (rendered so it covers the gap, for example a pseudo-element on the panel) avoids this, because every point along the crossing still hit-tests to a descendant. See **panel-in-anchor-flow**.
- **Panel rendered in a portal**: If the panel is rendered outside the anchor's DOM subtree (for example via `ReactDOM.createPortal`), it is no longer a descendant of the anchor element, so the anchor's containment guarantee for `onMouseLeave` does not extend to it. See **panel-in-anchor-flow**.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `children` | `ReactNode` | — | The trigger and the `<Popover>` panel it opens; rendered as-is inside the anchor div (see **render-children**). |
| `className` | `string` | — | Concatenated after `hover-popover-anchor` to allow custom styling (see **class-concatenation**). |
| `onMouseLeave` | `() => void` | — | Invoked when the pointer leaves the anchor element, exiting both the trigger and panel boundary (see **leave-callback**). |

## Deep Linking

Not applicable: PopoverAnchor is a layout utility, not a user-facing destination.

## Localization

Not applicable: PopoverAnchor contains no user-visible text.

## Accessibility Options

Not applicable: PopoverAnchor is a positioning wrapper without interactive state or text to respond to accessibility display options (e.g., Reduce Motion, Increase Contrast).

## Feature Flags

Not applicable: PopoverAnchor is a utility component that requires no feature toggle.

## Analytics

Not applicable: PopoverAnchor is a layout wrapper and not a user interaction point.

## Privacy

Not applicable: PopoverAnchor does not collect or transmit data.

## Logging

Not applicable: PopoverAnchor is an internal layout component with no user-visible events to log.

## Platform Notes

- **SwiftUI**: Use a container view (a `ZStack`, or a view with a `.background`) to hold the trigger and panel together, giving the group the same "shared positioning context" role that `position: relative` gives on web. Track hover with `.onHover { isHovering in ... }` (or `.onContinuousHover` for phase-level detail) attached to that container so it covers both children as one hit region; only treat the group as "left" when the container's own hover state goes false, since SwiftUI delivers `.onHover` per view rather than per DOM-style subtree.

- **Compose**: Use a `Box` to hold the trigger and panel and to serve as the positioning context (children within it can be placed with `Modifier.offset`/`align`). Attach `Modifier.pointerInput { awaitPointerEventScope { ... } }` to the `Box`, watching for `PointerEventType.Exit`, to detect the pointer leaving the combined bounds. Ensure the `Box`'s layout bounds include both the trigger and panel so the exit event fires only when leaving the entire group.

- **React/Web** (source: `packages/web/packages/popover/src/PopoverAnchor.tsx`): Render a `<div>` with `className="hover-popover-anchor"` (plus optional additional classes, see **class-concatenation**). Set `position: relative` in CSS. Attach the `onMouseLeave` handler directly to the div. The trigger and panel are placed inside the same div as `children`, so pointer movement between them does not fire the leave event — provided the panel is a normal child rather than portaled elsewhere (see **panel-in-anchor-flow**).

- **AppKit / UIKit**: Create a container view (`NSView` on macOS, `UIView` on iOS) that lays out the trigger and panel as its own subviews (Auto Layout or manual frames), giving the container the same positioning-context role `position: relative` gives on web. On macOS, attach an `NSTrackingArea` spanning the container's bounds and use `mouseExited` to detect the pointer leaving. On iOS, attach a `UIHoverGestureRecognizer` (iOS 13.4+) to the container and watch for its ended/exit state — hover *detection* on iOS is gesture-recognizer-based; `UIPointerInteraction` instead drives pointer *appearance* (e.g. cursor shape) and is not the mechanism for detecting hover exit. Ensure the tracked region spans both the trigger and panel so the leave callback fires only when exiting the entire container.

- **WinUI 3**: Use a `Grid` or `Canvas` with a transparent background to establish the positioning context. Apply `Grid.RowDefinitions` or absolute Canvas positioning to lay out the trigger and panel as children. Attach a `PointerExited` event handler to the container element. Set the container's `Background` to `Transparent` so pointer events are captured across its entire bounds, not just its opaque regions.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/popover/src/PopoverAnchor.tsx` | unverified |

## Design Decisions

**Decision**: PopoverAnchor wraps both the trigger and the panel inside the same container, rather than wrapping only the trigger.
**Rationale**: Keeping both inside one DOM subtree means the pointer never leaves the anchor's boundary while moving from the trigger to the panel, so `onMouseLeave` does not fire along the way. Wrapping only the trigger would put the panel outside that boundary and reintroduce the close-delay gap the anchor exists to remove.
**Approved**: pending

**Decision**: The component defines no padding, background, or border of its own.
**Rationale**: It is purely a positioning and hover-boundary context; visual styling is left entirely to the `className` prop and external CSS, so it composes with whatever panel appearance is applied on top of it.
**Approved**: pending

**Decision**: The anchor's optional callback prop wires the native `mouseleave` event (`onMouseLeave`) rather than `pointerleave` (`onPointerLeave`).
**Rationale**: `useHoverPopoverGroup`'s `anchorProps` contract is typed and implemented as `{ onMouseLeave: () => void }` (`packages/web/packages/popover/src/useHoverPopoverGroup.ts`) and is spread directly onto `<PopoverAnchor>`. Matching that event keeps `PopoverAnchor` a drop-in target for the hook's props without an adapter layer.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | failed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

The anchor closes only via `onMouseLeave`; nothing in `PopoverAnchor.tsx` offers a keyboard-equivalent way to dismiss the group, so keyboard operability depends entirely on whatever the composed trigger and panel add on top of it (see [adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)). `PopoverAnchor.tsx` is nothing but a positioning `<div>` with no business logic (separation-of-concerns passed), but no test file exercises it at all (unit-test-coverage failed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | panel-in-anchor-flow now keys on DOM-descendant hit-testing (bridging elements allowed) instead of banning any visual gap; added anchor-011 bridge test vector. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename `must-*` requirements to subject-only kebab-case everywhere they're cited; add `panel-in-anchor-flow` requirement plus offset/portal edge cases and test vectors documenting the close-delay technique's limits; add a missing-callback and a repeated-cycle test vector; populate Configuration as a props table; cite `PopoverAnchor.tsx` in the React/Web note and in frontmatter `references`; fix wrong SwiftUI/Compose/UIKit platform APIs; reformat Design Decisions to Decision/Rationale/Approved and ground the `onMouseLeave`-over-`onPointerLeave` choice in `useHoverPopoverGroup`'s contract; populate Compliance as a table (`keyboard-navigable`); add the Popover recipe to `related`; align `created`/`modified` date format; reword `summary` and Overview |
| 1.0.0 | 2026-09-22 | Claude | Initial creation |
