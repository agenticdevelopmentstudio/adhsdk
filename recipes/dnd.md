---
id: d8f2a1c3-9e4b-4a7b-8c6d-2f9a1e5b3c7d
title: Drag-and-Drop
domain: adhsdk://recipes/dnd
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Reorderable lists and boards, plus free-form dragging for calendars and timelines.
platforms:
- typescript
- web
tags:
- drag-and-drop
- ordering
- interaction
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Drag-and-Drop

## Overview

Two distinct drag surfaces: **SortableSurface** for ordered collections (lists or multi-column boards) that report drop position as neighboring items rather than indexes — a safety measure against concurrent reordering; and **DragSurface** for unordered placement (calendar chips landing on dates, timeline bars moving along one axis). Both support pointer and keyboard interaction. The component is a thin wrapper over `@dnd-kit`, unifying its API so views speak one vocabulary for drop position and axis constraint.

## Behavioral Requirements

- **sortable-model-input**: SortableSurface MUST accept a `zones` array of `{ id: string, itemIds: readonly string[] }` objects, each describing one ordered collection and the items it contains in render order.
- **drag-surface-config-input**: DragSurface MUST accept an `onDrop` callback, plus optional `describeItem`, `describeTarget`, `renderOverlay`, `axis`, and `keyboard` props to configure its behavior.
- **drag-surface-drop-payload**: On drop, DragSurface's `onDrop` callback MUST receive `{ itemId: string, targetId: string | null, delta: { x: number, y: number } }` — the target the item landed on (or null if none) and the pixel distance it travelled.
- **drop-position-report**: SortableSurface MUST report drop position as `afterId` (item before the dropped item, or null if dropped at top) and `beforeId` (item after, or null if dropped at bottom).
- **center-crossing-drop-position**: When a drag ends over another item, SortableSurface MUST decide before/after by comparing the dragged element's translated-rect center to the target element's rect center along the active orientation axis (horizontal: `left + width/2`; vertical: `top + height/2`); the item lands after the target once the dragged center has passed the target's center.
- **no-op-reorder-ignored**: SortableSurface MUST NOT report a drop if the item lands in its original position.
- **pointer-drag-activation-distance**: Pointer drags MUST NOT start until the pointer has moved at least 5 pixels from its starting position.
- **continuous-drop-target-remeasurement**: Droppable zones MUST be re-measured continuously during a drag (not just at drag start), to accommodate zones that grow or scroll during the operation.
- **pointer-and-keyboard-interaction**: Both SortableSurface and DragSurface MUST support pointer drags and MUST provide keyboard interaction (Space or Enter to start, arrow keys to move, Enter to drop, Escape to cancel) when keyboard is enabled. SortableItem defaults to keyboard enabled; DragItem defaults to keyboard disabled. When keyboard is disabled, the host MUST provide an equivalent non-pointer path to the same change (e.g., the form fields a calendar or timeline drag would otherwise set).
- **optional-drag-overlay**: SortableSurface and DragSurface MUST render a DragOverlay component under the pointer during a drag when `renderOverlay` prop is provided; when omitted, no overlay is rendered.
- **axis-constraint**: DragSurface MAY accept an `axis` prop to constrain movement to the x or y axis only.
- **grip-handle-rendering**: DragGrip MAY render a span element with grab/grabbing cursor, icon, and optional accessible label.
- **drag-event-announcements**: SortableSurface and DragSurface MUST provide accessibility announcements (via aria-live regions) for drag start, drag over a target, drag end, and drag cancel events.
- **optional-item-and-zone-descriptions**: SortableSurface MUST accept `describeItem` and `describeZone` callbacks to customize item and zone names in announcements; DragSurface MUST accept `describeItem` and `describeTarget` callbacks.
- **nearest-corner-collision-detection**: Both surfaces MUST use nearest-corner collision detection (not center-point or bounding-box overlap) to decide which zone or target a drag is over.
- **dragged-item-de-emphasis**: During a pointer drag in SortableSurface, the dragged item's original element MUST be visibly de-emphasized (reduced opacity) to indicate it is lifted, while the overlay renders the visual representation under the pointer.
- **dragged-item-visual-elevation**: During a pointer drag in DragSurface, the dragged element MUST be visually elevated above surrounding content.
- **grip-touch-scroll-suppression**: DragGrip MUST disable the browser's touch-scroll gesture on the handle so it does not interfere with the pointer sensor.
- **horizontal-layout-support**: SortableSurface SHOULD accept an `orientation` prop set to `"horizontal"` to handle zones laid out left-to-right; the default orientation is `"vertical"`.
- **conditional-drag-disabling**: Both SortableItem and DragItem MUST accept an `enabled` prop (default true) to disable dragging for specific items (e.g., filtered rows, busy rows).
- **conditional-keyboard-attribute-spreading**: SortableItem and DragItem MAY accept a `keyboard` prop (default true for SortableItem, false for DragItem) to control whether dnd-kit's keyboard attributes are spread onto the handle; when false, only listeners are spread.
- **sortable-zone-droppable**: SortableZone MUST register its own droppable (via useDroppable) so that drops into an empty zone are reachable.

## Appearance

- **Grip handle cursor**: grab when at rest, grabbing when actively dragging
- **Grip handle icon**: GripVertical from lucide-react, size 14px
- **Grip foreground color**: muted foreground (apt-text-muted token) at rest, default foreground (apt-text token) on hover
- **Dragged item opacity**: 0.4 during drag in SortableSurface
- **Dragged element z-index**: 20 during drag in DragSurface
- **Grip focus ring**: 2px accent focus ring (apt-gold/25 token) on focus-visible
- **Grip dimensions**: 24px height (h-6), 16px width (w-4 in Tailwind), inline-flex layout
- **Border radius**: rounded (default Tailwind value)
- **Transition**: colors transition smoothly on state change (hover, active)

## States

| State | Appearance change |
|-------|------------------|
| Default | Grab cursor, muted text color |
| Hover | Text color brightens to apt-text |
| Focus (keyboard) | 2px ring with apt-gold/25 |
| Active (pressing down) | Cursor changes to grabbing |
| Dragging (pointer) | Grip remains visible; dragged item (SortableSurface) becomes opacity 0.4 or (DragSurface) positioned relative with z-index 20 |
| Disabled | Handle does not accept drag events |

## Accessibility

- **Role**: DragGrip renders as a span but receives `role="button"` and `tabIndex=0` from dnd-kit's attributes (when keyboard sensor is enabled), making it keyboard-focusable and operable.
- **Label**: DragGrip MUST have an accessible name via aria-label ("Reorder" or "Reorder {subject}" when subject is provided).
- **Announcements**: Live region announcements MUST announce when an item is picked up, when it is dragged over a target or over no target, when it is dropped, and when dragging is cancelled.
- **Keyboard navigation**: Space or Enter starts the drag. Arrow keys move the dragged item to adjacent items (respecting orientation and axis constraints). Enter confirms the drop. Escape cancels the drag.
- **Icon**: GripVertical icon MUST have `aria-hidden="true"` because the accessible affordance is the label and role, not the icon.
- **Minimum touch target**: DragGrip measures 24px tall × 16px wide (`h-6 w-4`), which falls short of the 44×44pt (iOS) / 48×48dp (Android) minimum touch target. Hosts that need touch compliance MUST enlarge the hit area — e.g., wrapping the grip in enough padding to reach at least 44×44 — rather than relying on the grip's own bounds.
- **No nested buttons**: DragGrip renders as span (not button) because dnd-kit may spread `role="button"` onto it, and a nested button inside a button is invalid. When the handle is inside another button (calendar chip, timeline bar), the `keyboard` prop MUST be false to prevent spreading attributes.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dnd-001 | sortable-model-input | SortableSurface with zones array containing two zones, each with two items | Surface renders without error; zones are droppable |
| dnd-002 | drop-position-report | Zone contains items `[a, b, c]` in order; drag item `a` and drop it directly below `b` | onDrop callback receives `{ itemId: "a", fromZoneId, toZoneId, afterId: "b", beforeId: "c" }` |
| dnd-003 | no-op-reorder-ignored | Drag item in same zone and drop it in its original position | onDrop callback is NOT invoked |
| dnd-004 | pointer-drag-activation-distance | Pointer moves 3px from start; then moves 6px from start | Drag does not start at 3px; drag starts and active state is set at 6px+ |
| dnd-005 | continuous-drop-target-remeasurement | Start drag; zone grows in height mid-drag; drop item | Drop calculation uses the updated zone rect, not the original |
| dnd-006 | pointer-and-keyboard-interaction | Focus on SortableItem's grip; press Space or Enter to start; press Arrow Up/Down to move; press Enter to drop | Drag starts, item moves, drag completes and onDrop is called |
| dnd-007 | optional-drag-overlay | SortableSurface with renderOverlay prop provided | DragOverlay renders the result of renderOverlay(itemId) under pointer during drag |
| dnd-008 | optional-drag-overlay | SortableSurface without renderOverlay prop | No DragOverlay appears during drag |
| dnd-009 | axis-constraint | DragSurface with axis="x" | Dragging vertically has no effect; only horizontal movement is possible |
| dnd-010 | axis-constraint | DragSurface with axis="y" | Dragging horizontally has no effect; only vertical movement is possible |
| dnd-011 | drag-event-announcements | Focus on grip and start drag via keyboard; listen to screen reader announcements | Announcement includes "Picked up {itemName}" |
| dnd-012 | optional-item-and-zone-descriptions | SortableSurface with describeItem={(id) => `Card ${id}`} and describeZone={(id) => `Column ${id}`} | Announcements use "Card X" and "Column Y" instead of bare IDs |
| dnd-013 | nearest-corner-collision-detection | Two zones side by side; dragged item's nearest corner sits 10px from Zone A's near edge and 40px from Zone B's near edge | Item lands in Zone A — the zone whose corner is closest — not by center point or bounding-box overlap |
| dnd-014 | dragged-item-de-emphasis | Start pointer drag in SortableSurface; inspect element style during drag | `opacity: 0.4` is applied to the dragged item's element |
| dnd-015 | dragged-item-visual-elevation | Start pointer drag in DragSurface; inspect element style during drag | `zIndex: 20` and `position: relative` are applied |
| dnd-016 | grip-touch-scroll-suppression | On touch device, attempt to scroll by dragging on a DragGrip | Pointer sensor receives the move events; browser does not consume scroll |
| dnd-017 | horizontal-layout-support, center-crossing-drop-position | orientation="horizontal"; dragged item's translated rect center at x=150; target item's rect spans x=100–180 (center x=140) | Dragged center (150) has passed the target's center (140) → item lands AFTER the target |
| dnd-018 | conditional-drag-disabling | SortableItem with enabled={false} | Item cannot be picked up; pointer and keyboard sensors are inactive for this item |
| dnd-019 | conditional-keyboard-attribute-spreading | SortableItem with keyboard={false} | Only listeners are spread on handleProps; no `role`, `tabIndex`, or attributes are included |
| dnd-020 | sortable-zone-droppable | SortableZone with empty itemIds array | Zone's own droppable is reachable; dropping into it lands item at the end of that (empty) zone |
| dnd-021 | drag-surface-drop-payload | Drag item in DragSurface 15px right and 3px down; release over a target | onDrop callback receives `{ itemId, targetId: <target id>, delta: { x: 15, y: 3 } }` |
| dnd-022 | drag-surface-config-input | DragSurface rendered with onDrop, describeItem, describeTarget, renderOverlay, axis, and keyboard all provided | Surface renders without error; describeItem/describeTarget values are used in announcements |

## Edge Cases

- **Empty zone drop target**: When a zone has no items, the zone's own droppable (via useDroppable) is the only collision target. Dropping directly on a zone's own droppable (rather than on an item) always lands the item at the end of that zone's list; for an empty zone, "the end" is index 0 (afterId = null, beforeId = null).
- **Drag with no target**: Dragging outside all zones and releasing MUST NOT invoke onDrop (checked via `if (!over) return`).
- **Drag originating from invalid zone**: If the dragged item's zone cannot be determined from the zone model, the drag is ignored (checked via `if (fromZoneId === undefined) return`).
- **Cross-zone reorder**: Item is picked up from Zone A and dropped into Zone B. onDrop reports both fromZoneId and toZoneId; the view is responsible for updating its data model.
- **Concurrent drags**: Only one drag is active at a time; new drags are blocked by dnd-kit until the previous drag ends.
- **Concurrent reorders by multiple users**: The SortableDrop report uses item neighbors (afterId, beforeId) rather than indexes, so two users can reorder the same collection at once without a shared index going stale. This holds only while both reported neighbors are still present: if another user has already moved or deleted the afterId or beforeId item by the time a drop is applied, the neighbor pair is stale and the drop can no longer be placed unambiguously. A host applying drops from multiple users SHOULD detect a missing neighbor at apply time and either re-resolve the drop against the current list or reject it back to the dragging user.
- **Keyboard drag on disabled item**: When enabled={false}, keyboard sensor does not activate for that item.
- **Pointer on disabled item**: When enabled={false}, pointer sensor does not activate for that item.
- **Drag inside a button**: When the draggable is inside a button element (e.g., a calendar chip, timeline bar), setting keyboard={false} prevents spreading dnd-kit's `role="button"` onto the handle, avoiding a nested button violation.
- **Viewport scroll during drag**: If a scrollable parent scrolls during a drag (e.g., user scrolls a list while dragging), the drop position calculation accounts for the new scroll offset because droppables are re-measured continuously.
- **Overlay rendering fails**: `renderOverlay` is called directly inside DragOverlay's render, with no surrounding try/catch or error boundary. If it throws, the error propagates up React's tree exactly like any other render error — the surface does not contain it. A host that passes `renderOverlay` SHOULD wrap it (or its own subtree) in a React error boundary if it cannot guarantee the callback is error-free.
- **Missing zone in model**: If a zone ID appears in itemsOfZone but not in the zones array passed to the surface, that zone is still droppable, but the view may have inconsistent state. This case, and an item ID that cannot be resolved to a zone, are silently ignored inside onDragEnd — the callback simply returns without calling onDrop or reporting anything. The component has no logging or rejection channel of its own; a host that needs visibility into these cases must add its own checks around onDrop.

## Configuration

Not applicable: This component accepts configuration via React props (zones, callbacks, orientation, axis, keyboard) rather than a configuration object. Each surface type (SortableSurface, DragSurface) and item type (SortableItem, DragItem) is configured inline at render time.

## Deep Linking

Not applicable: These drag-and-drop components are interaction primitives with no URL-based state representation or deep link targets.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `dnd.grip.reorder` | "Reorder" | DragGrip aria-label when no `subject` is given |
| `dnd.grip.reorder-subject` | "Reorder {subject}" | DragGrip aria-label when `subject` is given |
| `dnd.announce.picked-up` | "Picked up {item}." | Drag-start announcement (SortableSurface, DragSurface) |
| `dnd.announce.over-target` | "{item} is over {target}." | Drag-over announcement when over a zone, item, or target |
| `dnd.announce.over-none` | "{item} is over no drop target." | Drag-over announcement when over nothing |
| `dnd.announce.dropped` | "{item} was dropped." / "{item} was dropped on {target}." | Drag-end announcement |
| `dnd.announce.returned` | "{item} was returned to where it started." | SortableSurface drag-end announcement when dropped with no target |
| `dnd.announce.cancelled` | "Dragging {item} was cancelled." | Drag-cancel announcement |

These strings are hardcoded English in the reference implementation. `describeItem`, `describeZone`, and `describeTarget` let the host localize the item/zone/target *name* substituted into each sentence, but the surrounding sentence itself is not externalized or overridable — a fully localized host must currently accept the English announcement wording as-is.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Transitions and animations are still applied by dnd-kit (CSS transitions on transform and opacity). A consume-media-query hook or prefers-reduced-motion CSS class in the host app can disable these separately. |
| Increase Contrast | Grip handle's focus ring uses apt-gold/25; contrast may be insufficient for WCAG AA. Host app SHOULD apply a higher-contrast focus ring via CSS override if required. |
| Differentiate Without Color | Grip's hover state uses color change only; consider adding an outline or underline in the host app if users cannot distinguish color. |

## Feature Flags

Not applicable: No feature flags are built into the component. The host app MAY conditionally render SortableSurface or DragSurface based on its own feature flags.

## Analytics

Not applicable: The component does not emit analytics events. The host app SHOULD instrument onDrop callbacks to log drag operations (e.g., "user reordered items", "user moved card to column").

## Privacy

Not applicable: The component does not collect, store, or transmit any user data beyond the immediate drop event (itemId, zone IDs, neighbors). No tracking, logging, or analytics are built in.

## Logging

Not applicable: No logging subsystem is built into the component. Errors (e.g., missing zone, invalid item ID) are silently ignored in onDragEnd callbacks. Host apps MAY add their own logging via onDrop callbacks if needed.

## Platform Notes

- **SwiftUI**: Start from the `.draggable(_:)` and `.dropDestination(for:action:)` view modifiers (iOS 16+ / macOS 13+) for the free-drag case; a SortableSurface analogue combines `.draggable` items inside a `ForEach` with a `.dropDestination` per row or zone to detect neighbor position, or uses `List` with `.onMove` when index-based reordering is acceptable. Keyboard-equivalent interaction needs a custom accessibility action, since SwiftUI's drag gestures have no built-in keyboard path.
- **Compose**: Start from `Modifier.dragAndDropSource` and `Modifier.dragAndDropTarget` (Jetpack Compose Foundation) for the free-drag case; a SortableSurface analogue combines these with `LazyColumn`/`LazyRow` and a `LazyListState`-based reorder helper. Keyboard interaction is handled via `KeyEvent` callbacks and accessibility focus management; announcements use `AccessibilityEventCompat` live-region semantics.
- **React/Web**: Source is `packages/web/packages/ui/src/components/dnd.tsx`. SortableSurface and DragSurface wrap `@dnd-kit/core` (DndContext, DragOverlay, sensors, the `closestCorners` collision-detection strategy) and `@dnd-kit/sortable` (SortableContext, useSortable). Accessibility announcements are driven by dnd-kit's built-in Announcements API (via aria-live). The component uses CSS transforms for drag positioning (via CSS.Translate from @dnd-kit/utilities). During a pointer drag, the web implementation sets the original dragged element's opacity to 0.4 (SortableSurface) or applies `zIndex: 20` / `position: relative` (DragSurface), and applies the `touch-none` Tailwind class (`touch-action: none`) to DragGrip so the browser does not claim the touch gesture for scrolling. Grip handle renders as a span and accepts attributes from dnd-kit when keyboard={true}, or listeners only when keyboard={false}.
- **AppKit / UIKit**: Start from `UIDragInteraction` and `UIDropInteraction` (iOS 11+) for pointer drag recognition and target detection, or `NSDraggingSource`/`NSDraggingDestination` on macOS. Zones map to `UITableView`/`UICollectionView` (or `NSTableView`/`NSCollectionView`) sections, using the built-in drag-delegate methods (`UICollectionViewDragDelegate`/`UICollectionViewDropDelegate`) for reordering rather than a hand-rolled gesture recognizer. `UIAccessibility.post(notification:.announcement, argument:)` provides the live-region equivalent. A separate keyboard/VoiceOver path (custom accessibility actions, VoiceOver rotor) is required since drag gestures have no built-in keyboard equivalent.
- **WinUI 3**: Start from the native drag-and-drop support on `ListView`/`GridView` — `CanDragItems`, `AllowDrop`, `CanReorderItems`, and the `DragItemsStarting` / `DragItemsCompleted` / `Drop` events — rather than hand-rolling gesture recognition from `ManipulationStarted`/`ManipulationDelta`/`ManipulationCompleted`. Use XAML `Storyboard` animations for visual feedback. Keyboard interaction via `KeyDown` (Arrow keys, Enter, Escape). Announcements use `AutomationProperties.LiveSetting` (Polite or Assertive) or, for one-off announcements, the UI Automation `RaiseNotificationEvent` API. When a custom neighbor-based report (matching `SortableDrop`) is still needed beyond what `ListView`'s own reorder mode gives you, drop position requires hit-testing via `TransformToVisual` and computing element bounds against the destination panel.
- **Pattern (all platforms)**: The core pattern is pointer and keyboard sensor registration, nearest-target collision detection, and neighbor-based drop reporting. The web version uses dnd-kit to provide these; native platforms should start from each platform's own drag-and-drop controls (`.draggable`/`.dropDestination`, `Modifier.dragAndDropSource`/`dragAndDropTarget`, `UIDragInteraction`/`UIDropInteraction`, `ListView`'s `CanReorderItems`) and fall back to custom gesture recognition only where the native API cannot express the neighbor-based report this component needs.

## Design Decisions

**Decision**: SortableDrop reports `afterId` and `beforeId` rather than an index.
**Rationale**: This solves the concurrent reorder problem where two users simultaneously reorder the same collection — each reports a position relative to two neighbors, which remains valid even if items are inserted elsewhere. An index-based report would be ambiguous when the list changes mid-operation.
**Approved**: pending

**Decision**: Pointer drags require 5 pixels of movement before activating.
**Rationale**: This allows clicks and taps on draggable items to reach their own event handlers (e.g., a card's select or edit button) without immediately starting a drag.
**Approved**: pending

**Decision**: Droppables are re-measured on every drag move (MeasuringStrategy.Always), not just at drag start.
**Rationale**: This accommodates zones that grow, shrink, or scroll during the operation.
**Approved**: pending

**Decision**: If a drag ends with the item landing in its original position (same zone and neighbors), onDrop is not invoked.
**Rationale**: This avoids spurious writes to the backend for a user who simply jiggles an item.
**Approved**: pending

**Decision**: SortableItem and DragItem conditionally spread dnd-kit's `role="button"` and `tabIndex` onto the handle; when keyboard={false}, only listeners are spread.
**Rationale**: This prevents nested `role="button"` violations when the handle is inside another button (e.g., calendar chip, timeline bar).
**Approved**: pending

**Decision**: If renderOverlay is omitted, no DragOverlay is rendered.
**Rationale**: This allows lightweight drag feedback (e.g., just an opacity change on the original item) for simple scenarios.
**Approved**: pending

**Decision**: DragSurface MAY be constrained to the x or y axis; SortableSurface does not support axis constraint.
**Rationale**: An axis constraint reflects the semantic meaning of a free drag (e.g., a timeline bar moves horizontally to change date; vertical movement is noise). Reordering already moves along the layout axis, so SortableSurface has no separate axis to constrain.
**Approved**: pending

**Decision**: The Tailwind class `touch-none` is applied to DragGrip.
**Rationale**: Without it, a touch drag on the grip would be consumed by the browser's scroll handler, and the pointer sensor would never see a move event.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | partial | Accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | failed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | failed | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | partial | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Statuses rest on the source directly: the keyboard sensor, `aria-live` Announcements, and dnd-kit's `role`/`tabIndex`/`aria-label` attributes back the passed and partial accessibility checks (partial on keyboard-navigable because DragItem's `keyboard` prop defaults to false and needs a host-provided alternative path); the grip's `h-6 w-4` dimensions and its reliance on dnd-kit's own CSS transitions with no `prefers-reduced-motion` handling back the two failed checks, and the `apt-gold/25` focus ring's self-admitted possible AA shortfall backs the partial contrast-ratio check; and the hardcoded English announcement sentences (`Picked up …`, `… is over …`, etc.) alongside the fully overridable item/zone/target names back the partial internationalization check. `separation-of-concerns` passes because sorting/dragging logic (`landsAfter`, `asHandleProps`, `useDragSensors`) is extracted into standalone helpers and hooks, leaving the exported components as thin, mostly stateless wrappers; `unit-test-coverage` passes because `dnd.test.tsx` imports `DragGrip`, `DragItem`, `DragSurface`, `DropTarget`, `SortableItem`, `SortableSurface`, and `SortableZone` directly and exercises them with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only names; split drag-surface config into input and drop-payload requirements with typed shapes; moved dnd-kit implementation values (closestCorners, opacity 0.4, zIndex 20, touch-none) out of requirements into the React/Web platform note; corrected grip dimensions, appearance token roles, and touch-target status; rewrote Platform Notes to the five required bullets with accurate native APIs; converted Design Decisions to Decision/Rationale/Approved format; added Compliance and Localization tables; sharpened ambiguous test vectors and edge-case wording |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
