---
id: 240f8d48-45af-49ea-aebf-95d756d74707
title: SplitDivider
domain: adhsdk://recipes/split-divider
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A draggable and keyboard-operable separator that splits a container into
  two panes, reporting a ratio of space given to the leading pane.
platforms:
- typescript
- web
tags:
- layout
- divider
- resizable
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# SplitDivider

## Overview

SplitDivider is a bare separator primitive that allows users to resize the space between two panes by dragging a divider or using keyboard controls. It reports a ratio (0–1) representing the fraction of the split given to the leading pane (above for horizontal, left for vertical). The component owns neither the panes nor any collapse state; the caller renders the regions and applies the ratio to layout. It is designed for layouts like search results / preview panes or repository tree / activity log pairs.

## Behavioral Requirements

- **separator-role**: Component MUST render an element with `role="separator"`.
- **ratio-change-callback**: Component MUST call `onRatioChange` with a new ratio when the user drags or operates keyboard/step controls.
- **ratio-clamp**: Component MUST clamp the reported ratio to the range `[minRatio, maxRatio]` before calling `onRatioChange`.
- **horizontal-orientation**: Component MUST support `orientation="horizontal"` (default), splitting vertical space with a horizontal line and responding to vertical drags and up/down arrow keys.
- **vertical-orientation**: Component MUST support `orientation="vertical"`, splitting horizontal space with a vertical line and responding to horizontal drags and left/right arrow keys.
- **ratio-prop**: Component MUST accept a `ratio` prop (0–1) and use it to set `aria-valuenow` as a percentage (rounded to nearest integer).
- **minmax-ratio-props**: Component MUST accept `minRatio` (default 0.2) and `maxRatio` (default 0.8) props and expose them as `aria-valuemin` and `aria-valuemax` (as percentages).
- **container-ref**: Component MUST accept a `containerRef` prop (React.RefObject) pointing to the layout container and use it to measure pointer drag offsets.
- **drag-resize**: Component MUST support pointer drag to resize; on `pointerdown`, capture the pointer; on `pointermove`, calculate the new ratio as the pointer coordinate minus the container's leading edge (via `getBoundingClientRect`), divided by the container's extent; on `pointerup` or `pointercancel`, release capture and end the drag.
- **drag-end-on-release**: Component MUST end the drag if the primary pointer button is released mid-drag (checked via `(event.buttons & 1) === 0`).
- **step-button-pointerdown-guard**: A `pointerdown` on a step button MUST NOT start a drag on the separator; the buttons are siblings of the `role="separator"` element, outside its pointer-capture area.
- **zero-extent-guard**: Component MUST not apply a drag resize if the container extent (height for horizontal, width for vertical) is zero.
- **keyboard-shrink**: Component MUST decrement the ratio by `step` (default 0.03) on the shrink arrow (up for horizontal, left for vertical) and call `onRatioChange`.
- **keyboard-grow**: Component MUST increment the ratio by `step` on the grow arrow (down for horizontal, right for vertical) and call `onRatioChange`.
- **home-key**: Component MUST set the ratio to `minRatio` on Home key press.
- **end-key**: Component MUST set the ratio to `maxRatio` on End key press.
- **keyboard-default-prevention**: Component MUST call `preventDefault()` for every handled key (shrink/grow arrows, Home, End) so the page does not scroll while the separator is operated via keyboard.
- **visual-line**: Component MUST render a thin visual divider line (3px) centered in the 24px grab row/column, colored with `apt-border` and changing to `apt-border-strong` on hover and focus.
- **step-buttons**: Component MUST render two step buttons (24px × 24px, fully contained within the 24px grab row/column) for incrementing and decrementing the ratio, with aria-labels describing the resize direction.
- **step-button-mapping**: Component MUST render the two step buttons in a fixed order — a shrink button (decrements the ratio by `step` on click) followed by a grow button (increments the ratio by `step` on click) — each showing a directional glyph (▲/▼ for horizontal, shrink/grow respectively; ◀/▶ for vertical, shrink/grow respectively), positioned together near the trailing end of the grab strip (right edge for horizontal, bottom edge for vertical).
- **grab-cursor**: Component MUST apply `cursor-row-resize` for horizontal orientation and `cursor-col-resize` for vertical orientation.
- **grab-area-size**: Component MUST size the root row/column to 24px width (vertical) or height (horizontal) and full length on the opposite axis.
- **grab-area-focusable**: Component MUST set `tabIndex={0}` on the separator to make it keyboard-operable.
- **default-label**: Component MUST set `aria-label` to "Resize split" by default (overridable via the `label` prop).
- **step-button-labels**: Component MUST accept `growBottomLabel` and `growTopLabel` props for accessible step button labels; if not provided, MUST default to labels like "Grow bottom pane" (horizontal) or "Grow left pane" (vertical).
- **focus-ring**: Component MUST show a focus-visible ring (2px, `apt-gold/40`) when the separator receives keyboard focus, not on pointer focus.
- **classname-prop**: Component MUST accept a `className` prop for additional CSS classes on the root element.
- **touch-none**: Component MUST apply `touch-none` CSS class to prevent the default touch-drag behavior and allow the pointer handler to control resize.
- **select-none**: Component MUST apply `select-none` CSS class to prevent text selection during drag.

## Appearance

- **Width/Height**: 24px (6 units with `h-6` / `w-6` in Tailwind), full length on the opposite axis (full width for horizontal, full height for vertical).
- **Visual line**: 3px wide (horizontal) or 3px tall (vertical), `apt-border` color, centered in the 24px grab area.
- **Line hover state**: `apt-border-strong` color on hover.
- **Line focus state**: `apt-border-strong` color on focus.
- **Focus ring**: 2px solid ring, color `apt-gold/40`, visible only on keyboard focus (`:focus-visible`).
- **Step button size**: 24px × 24px, positioned absolutely within the grab area.
- **Step button colors**: `text-apt-text-muted` (default), `text-apt-text` on hover.
- **Step button icons**: Unicode arrow glyphs (▲/▼ for horizontal, ◀/▶ for vertical).
- **Corner radius**: 4px (`rounded-sm`) on the separator; 4px on step buttons.
- **Cursor**: `cursor-row-resize` for horizontal, `cursor-col-resize` for vertical.
- **Background**: Transparent (no explicit background color set).

## States

| State | Appearance change |
|-------|------------------|
| Default | Visual line is `apt-border`; step buttons are `text-apt-text-muted` |
| Hover | Visual line is `apt-border-strong`; step buttons are `text-apt-text` on hover |
| Keyboard focus | Visual line is `apt-border-strong`; 2px `apt-gold/40` focus ring visible |

## Accessibility

- **Role**: `role="separator"` per ARIA authoring practices for resizable panes.
- **Orientation**: `aria-orientation` matches the `orientation` prop (`horizontal` or `vertical`).
- **Value**: `aria-valuenow` (current ratio as percentage, 0–100), `aria-valuemin` (minimum ratio as percentage), `aria-valuemax` (maximum ratio as percentage), all rounded to the nearest integer.
- **Label**: `aria-label` provided for the separator (default "Resize split", overridable). Step buttons each have an `aria-label` (defaults: "Grow top pane" and "Grow bottom pane" for horizontal, "Grow left pane" and "Grow right pane" for vertical).
- **Keyboard navigation**: Component is focusable (`tabIndex={0}`) and supports keyboard resize: arrow keys (up/down for horizontal, left/right for vertical) adjust by `step`, Home sets to `minRatio`, End sets to `maxRatio`.
- **Dragging alternative**: WCAG 2.2 SC 2.5.7 (Dragging Movements) — step buttons provide a single-pointer, non-drag resize alternative for users who cannot perform sustained drags.
- **Target size**: The 24px grab area (including both the visual line and step buttons) meets WCAG 2.2 SC 2.5.8 (Target Size, Minimum) of at least 24×24px. No target bleeds into adjacent panes.
- **Hidden elements**: `aria-hidden="true"` is applied to the visual line and step button icons, as they are decorative and their roles are expressed via ARIA properties and labels.
- **Focus visible**: Focus ring is only shown on keyboard focus (`:focus-visible`), not on pointer focus, to avoid visual clutter during drag.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| split-divider-001 | separator-role | Component rendered | Element with `role="separator"` is in the DOM |
| split-divider-002 | ratio-change-callback | Pointer at `clientY` = the container's top edge + 50 (per `getBoundingClientRect`); container is 200px tall | `onRatioChange` is called with ratio ≈ 0.25 (50/200) |
| split-divider-003 | ratio-clamp | `minRatio=0.2, maxRatio=0.8`; user drags to ratio 0.05 | `onRatioChange` is called with 0.2 (clamped to minRatio) |
| split-divider-004 | ratio-clamp | `minRatio=0.2, maxRatio=0.8`; user drags to ratio 0.95 | `onRatioChange` is called with 0.8 (clamped to maxRatio) |
| split-divider-005 | horizontal-orientation | `orientation="horizontal"` (default); component rendered | Separator renders as a horizontal line; `aria-orientation="horizontal"` is set; vertical drag is tracked |
| split-divider-006 | vertical-orientation | `orientation="vertical"`; component rendered | Separator renders as a vertical line; `aria-orientation="vertical"` is set; horizontal drag is tracked |
| split-divider-007 | ratio-prop | `ratio=0.5`; component rendered | `aria-valuenow="50"` (50% of the split) |
| split-divider-008 | minmax-ratio-props | `minRatio=0.1, maxRatio=0.9`; component rendered | `aria-valuemin="10"`, `aria-valuemax="90"` |
| split-divider-009 | drag-resize, drag-end-on-release | User drags the separator and releases the mouse mid-drag | Drag ends; ratio stops updating after release |
| split-divider-010 | drag-end-on-release | User drags the separator, then the primary button is released while `pointermove` events continue | Drag ends immediately; subsequent `pointermove` events do not resize |
| split-divider-011 | zero-extent-guard | `containerRef` points to a container with zero height; user attempts to drag | `onRatioChange` is not called; the ratio remains unchanged |
| split-divider-012 | keyboard-shrink | Component is focused; user presses ArrowUp (horizontal) | `onRatioChange` is called with `ratio - step` |
| split-divider-013 | keyboard-shrink | `orientation="vertical"`; component is focused; user presses ArrowLeft | `onRatioChange` is called with `ratio - step` |
| split-divider-014 | keyboard-grow | Component is focused; user presses ArrowDown (horizontal) | `onRatioChange` is called with `ratio + step` |
| split-divider-015 | keyboard-grow | `orientation="vertical"`; component is focused; user presses ArrowRight | `onRatioChange` is called with `ratio + step` |
| split-divider-016 | home-key | Component is focused; user presses Home | `onRatioChange` is called with `minRatio` |
| split-divider-017 | end-key | Component is focused; user presses End | `onRatioChange` is called with `maxRatio` |
| split-divider-018 | visual-line | Component rendered | A 3px line is visible, centered in the 24px grab area, with color `apt-border` |
| split-divider-019 | step-buttons | Component rendered | Two 24px × 24px buttons are rendered and are clickable |
| split-divider-020 | grab-cursor | `orientation="horizontal"`; component rendered | Cursor is `cursor-row-resize` over the separator |
| split-divider-021 | grab-cursor | `orientation="vertical"`; component rendered | Cursor is `cursor-col-resize` over the separator |
| split-divider-022 | grab-area-size | Component rendered with `orientation="horizontal"` | Root element has `height=24px` and `width=100%` of its container |
| split-divider-023 | grab-area-size | Component rendered with `orientation="vertical"` | Root element has `width=24px` and `height=100%` of its container |
| split-divider-024 | grab-area-focusable | Component rendered | Separator is focusable via Tab key |
| split-divider-025 | default-label | Component rendered without `label` prop | `aria-label="Resize split"` is set |
| split-divider-026 | default-label | `label="Custom Resize"`; component rendered | `aria-label="Custom Resize"` is set |
| split-divider-027 | step-button-labels | Component rendered with `orientation="horizontal"` and no custom labels | Step button labels are "Grow top pane" and "Grow bottom pane" (defaults) |
| split-divider-028 | step-button-labels | `orientation="vertical"`, `growTopLabel="Expand left"`, `growBottomLabel="Expand right"`; component rendered | Step buttons have the custom labels |
| split-divider-029 | focus-ring | Component is focused via keyboard; component rendered | A 2px `apt-gold/40` focus ring is visible around the separator |
| split-divider-030 | classname-prop | `className="custom-class"`; component rendered | Root element has class `custom-class` applied |
| split-divider-031 | keyboard-default-prevention | Component is focused; user presses ArrowDown (horizontal) | `event.preventDefault()` is called; the page does not scroll |
| split-divider-032 | step-button-mapping | `orientation="horizontal"`; user clicks the shrink button (▲) | `onRatioChange` is called with `ratio - step` |
| split-divider-033 | step-button-mapping | `orientation="horizontal"`; user clicks the grow button (▼) | `onRatioChange` is called with `ratio + step` |
| split-divider-034 | step-button-mapping | `orientation="vertical"`; user clicks the shrink button (◀) | `onRatioChange` is called with `ratio - step` |
| split-divider-035 | step-button-mapping | `orientation="vertical"`; user clicks the grow button (▶) | `onRatioChange` is called with `ratio + step` |
| split-divider-036 | step-button-pointerdown-guard | User presses the pointer down directly on a step button | The separator's drag does not start; only the button's `onClick` fires |
| split-divider-037 | drag-resize, drag-end-on-release | User is mid-drag (pointer captured); a `pointercancel` event fires (e.g., touch scroll takeover) | Drag ends; subsequent `pointermove` events do not resize |
| split-divider-038 | drag-resize, drag-end-on-release | User is mid-drag; `onLostPointerCapture` fires (capture lost) | Drag ends; subsequent `pointermove` events do not resize |
| split-divider-039 | ratio-clamp | `minRatio=0.2, maxRatio=0.8`; `ratio=0.79`, `step=0.03`; user presses the grow arrow | `onRatioChange` is called with 0.8 (clamped, not 0.82) |
| split-divider-040 | ratio-prop | `ratio=0.333` | `aria-valuenow="33"` (rounded to nearest integer) |
| split-divider-041 | zero-extent-guard | `orientation="vertical"`; `containerRef` points to a container with zero width; user attempts to drag | `onRatioChange` is not called; the ratio remains unchanged |
| split-divider-042 | focus-ring | Component receives focus via a pointer click (not Tab) | No focus ring is visible (`:focus-visible` does not match pointer-triggered focus) |
| split-divider-043 | touch-none, select-none | Component rendered | Separator element has both the `touch-none` and `select-none` CSS classes applied |
| split-divider-044 | container-ref | `containerRef.current` is `null` (not yet mounted); user attempts to drag | `onRatioChange` is not called |
| split-divider-045 | ratio-clamp | `minRatio=0.5, maxRatio=0.5`; user drags or presses any adjustment key | `onRatioChange` is always called with `0.5`, the single fixed value |
| split-divider-046 | keyboard-grow, ratio-clamp | `step=0.5`; `ratio=0.5`; `maxRatio=0.8`; user presses the grow arrow | `onRatioChange` is called with `0.8` (clamped, despite the raw step landing at 1.0) |
| split-divider-047 | keyboard-grow | Component is focused; user presses ArrowDown twice in quick succession | `onRatioChange` is called twice, once per keypress, each computed from the `ratio` prop value current at that event |
| split-divider-048 | drag-resize, keyboard-grow | User is dragging (a `pointermove` fires) while also pressing ArrowDown | `onRatioChange` is called for both the pointermove and the keydown; the ratio reflects whichever fired last |
| split-divider-049 | step-button-pointerdown-guard | A drag is in progress from pointer A; pointer B (a second touch) taps a step button | The step button's `onClick` fires immediately, independent of pointer A's drag |

## Edge Cases

- **Zero container extent**: If the container has zero height (horizontal) or zero width (vertical), drag calculations divide by zero. The component detects this and ignores the drag; the ratio remains unchanged until the container is resized.
- **Pointer cancel / lost capture**: If a gesture is cancelled (touch scroll takeover, window blur) or pointer capture is lost, the component ends the drag. Subsequent `pointermove` events do not resize.
- **Extreme ratios**: If `minRatio = 0` and `maxRatio = 1` (range 0–1), the entire spectrum of split sizes is allowed. If `minRatio = maxRatio`, the split is fixed and resize operations will always clamp to that single value.
- **Very large step**: If `step = 0.5`, each keyboard press moves the split by 50% of the container. The clamping logic ensures the ratio never exceeds `[minRatio, maxRatio]`.
- **Rapid key presses**: Repeated arrow key presses (e.g., held down) will call `onRatioChange` once per `onKeyDown` event, applying step adjustments in sequence. No debouncing is applied; all calls are clamped independently.
- **Simultaneous drag and key input**: If the user holds down an arrow key while dragging, both `pointermove` and `onKeyDown` will call `onRatioChange`. The component does not prevent this, and the ratio will be set by whichever input fired last.
- **Step button during drag**: `setPointerCapture` is scoped to the pointer id that started the drag, so a step-button click from that same pointer cannot occur — its `pointerdown`/`pointerup` are captured by the separator, not the button — until the drag ends. A click from a different pointer (e.g., a second touch) is independent of the drag and applies its `step` immediately.

## Configuration

Not applicable: The component has no configuration beyond its required and optional props. All behavior is controlled via props (`ratio`, `onRatioChange`, `minRatio`, `maxRatio`, `step`, `containerRef`, `orientation`, `label`, `growBottomLabel`, `growTopLabel`, `className`). There are no configuration files, environment variables, or runtime settings to manage.

## Deep Linking

Not applicable: SplitDivider is a layout primitive with no navigation or routing concerns. It does not emit navigable URLs, query parameters, or deep-link states. Deep linking responsibility belongs to the caller's container and routing system.

## Localization

The component accepts all user-facing strings via props (`label`, `growBottomLabel`, `growTopLabel`), leaving localization entirely to the caller. The defaults it falls back to when a prop is omitted ("Resize split", "Grow top/bottom pane", "Grow left/right pane") are hardcoded English fallback strings. Callers SHOULD pass localized strings for every label rather than relying on these defaults.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not implemented in source. The component uses `transition-colors` on the visual line unconditionally and does not respond to `prefers-reduced-motion`. Callers SHOULD override the transition via CSS if reduced motion is required. |
| Increase Contrast | Not implemented in source. The component uses `apt-border` and `apt-border-strong` tokens, which are defined by the design system. Callers relying on increased contrast SHOULD provide theme overrides or use high-contrast token values. |
| Differentiate Without Color | The component distinguishes state primarily by visual cues: the thin line's color/position changes on hover and focus, and the step buttons display directional glyphs (▲/▼, ◀/▶) that persist regardless of color, satisfying WCAG 2.1 SC 1.4.1 (Use of Color) for color-only signalling. Whether the line and the `apt-gold/40` focus ring also meet the 3:1 contrast that SC 1.4.11 (Non-text Contrast) requires depends on the resolved values of the `apt-border`/`apt-gold` tokens, which the source does not resolve or verify — see the `contrast-ratio` compliance check below. |

## Feature Flags

Not applicable: The component has no feature flags, runtime toggles, or conditional behavior paths. All functionality is enabled by default and controlled via props. Feature gating is the caller's responsibility if needed.

## Analytics

Not applicable: The component does not emit analytics events, telemetry, or usage tracking. Event emission (e.g., "split_resized") is the caller's responsibility via callbacks passed to `onRatioChange`.

## Privacy

Not applicable: The component does not collect, store, or transmit personal data. The `ratio` value is layout state provided by the caller and does not represent personally identifiable information. All data flows through callbacks (`onRatioChange`) provided by the caller.

## Logging

Not applicable: The component does not emit log entries, diagnostics, or debugging output. Callers MAY add logging in their `onRatioChange` callback if needed for debugging or monitoring.

## Platform Notes

- **React/Web** (source platform): The component is a React functional component (`SplitDivider`) defined in `split-divider.tsx`. It uses React hooks (`useRef`, `useCallback`) for state management and pointer/keyboard event handlers. Styling is applied via Tailwind CSS classes and `cn()` utility function (className merging). Colors use design-system tokens (`apt-border`, `apt-border-strong`, `apt-gold`, `apt-text`, `apt-text-muted`).
- **SwiftUI**: Use a custom view with `DragGesture` to track pointer drags (SwiftUI's `Divider` is not draggable). Accept the ratio as a `Binding<Double>` supplied by the caller — the component owns no panes or state — and keep only ephemeral `@State` for `isDragging`. Use `.onContinuousHover()` for the hover state color change. Keyboard input is handled via `.onKeyPress()`, or `NSEvent.addLocalMonitorForEvents(matching:handler:)` on macOS. Apply a 24pt width (or height for vertical) and show a thin line centered in it.
- **Compose** (Android/Kotlin): Start from Material 3's `HorizontalDivider`/`VerticalDivider` or a custom `Canvas`-based implementation. Use `Modifier.draggable()` and `Modifier.pointerInput()` to track drag gestures and pointer events. Implement keyboard handling via `Modifier.onKeyEvent()`. Hoist the ratio to the caller (a `Float` parameter plus an `onRatioChange: (Float) -> Unit` lambda, not an internally-owned `MutableState`), so the component owns no panes or state. Apply size constraints (24.dp width/height) and render a thin line in the center.
- **AppKit / UIKit** (macOS / iOS): On macOS, use a custom `NSView` with `NSPanGestureRecognizer` for drags and `NSResponder.interpretKeyEvents()` for keyboard input; report the ratio to the caller via a delegate or closure rather than owning it inside `NSSplitViewController`, which manages its own panes and would contradict this primitive's "owns no panes or state" contract. On iOS, use `UIPanGestureRecognizer` for drags (`UIDragInteraction` is for drag-and-drop, not resizing); keyboard input is less common on iOS but can be handled via `UIKeyCommand`. Render a 24pt divider with a thin line and step buttons.
- **WinUI 3** (Windows): Use `GridSplitter` (from the Community Toolkit's `Sizers` package — it is not part of WinUI 3 itself) or a custom `Control` with pointer and keyboard event handlers. Bind the ratio to a dependency property named `RatioProperty`. Implement `OnPointerPressed`, `OnPointerMoved`, `OnPointerReleased` for drag tracking. Use `OnKeyDown` for keyboard shortcuts (up/down arrows, Home, End). Apply a 24px width (or height for vertical). Render the divider and step buttons using XAML layouts (`StackPanel` for the row/column). Use WinUI 3 tokens and brushes for colors (`ControlStrokeColorDefault`, `ControlStrokeColorSecondary`, `AccentFillColorDefaultBrush`). Ensure the target size meets Microsoft accessibility standards (minimum 24×24px).

## Design Decisions

**Decision**: The entire 24px grab row/column is the drag target, not just the thin 3px visual line.
**Rationale**: WCAG 2.2 SC 2.5.8 (Target Size, Minimum) requires a minimum 24×24px touch target; using the full 24px area keeps pointer and touch users within an accessible target while the visual line itself stays thin for minimal visual intrusion.
**Approved**: pending

**Decision**: Two step buttons provide a non-drag alternative for resizing.
**Rationale**: WCAG 2.2 SC 2.5.7 (Dragging Movements) requires a non-drag alternative for pointer users who cannot perform sustained drags; the step buttons allow incremental resize via single clicks/taps.
**Approved**: pending

**Decision**: Keyboard support covers arrow keys (± `step`) plus Home/End (jump to `minRatio`/`maxRatio`).
**Rationale**: Arrow keys allow incremental adjustment aligned with the separator's axis; Home and End give quick access to the bounds.
**Approved**: pending

**Decision**: Out-of-range ratios are silently clamped to `[minRatio, maxRatio]` rather than rejected with an error.
**Rationale**: Clamping prevents invalid states and simplifies the caller's logic; no validation error is emitted.
**Approved**: pending

**Decision**: Pointer capture (`setPointerCapture`) is used during a drag.
**Rationale**: This is standard practice for resizable elements — it keeps the drag tracked even if the pointer moves outside the separator, and ensures smooth dragging behavior.
**Approved**: pending

**Decision**: The component manages no "collapsed" state for either pane.
**Rationale**: Leaving collapse behavior to the caller gives maximum flexibility in how the split is used.
**Approved**: pending

**Decision**: The ratio is computed from the pointer offset divided by the container's full extent, not from an absolute pixel delta.
**Rationale**: This makes the ratio represent a fraction of space independent of the container's absolute size.
**Approved**: pending

**Decision**: The default `step` is `0.03` (3% per key press).
**Rationale**: This gives responsive keyboard navigation without requiring excessive key presses to traverse the full range; callers can override it for different responsiveness.
**Approved**: pending

**Decision**: The default bounds are `minRatio = 0.2` and `maxRatio = 0.8`.
**Rationale**: Each pane keeps at least 20% of the space by default, preventing either pane from becoming unusably small; callers can override the bounds.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | failed | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | partial | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

These statuses rest on `split-divider.tsx`: the `role="separator"` element with `aria-label`, `aria-orientation`, and `aria-valuenow/min/max`, plus native `<button>` elements and the `onKeyDown` handler, support the passed screen-reader and keyboard checks, and the ARIA roles/states are all standard (semantic-markup). The `apt-border`/`apt-gold` design tokens and the fixed 24px grab area cannot be verified against a numeric 3:1 contrast ratio or a 44×44pt/48×48dp native touch-target minimum from the source alone (partial). `transition-colors` runs unconditionally with no `prefers-reduced-motion` guard in the source (failed). The default `label`, `growBottomLabel`, and `growTopLabel` values are hardcoded English literals, though every one is overridable via props (partial). `separation-of-concerns` passes because the drag/keyboard/clamp logic lives in named callbacks (`commit`, `onPointerMove`, `onKeyDown`, etc.) separate from the JSX they drive, and `unit-test-coverage` passes because `splitDivider.test.tsx` renders it directly and exercises both orientations' drag, keyboard, and step-button behavior.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only names; reformatted Design Decisions; added the Compliance table; fixed the DRY, citation, correctness, and platform-API findings; added missing requirements, edge-case rules, and test vectors; corrected Platform Notes to keep ratio state caller-owned; rewrote Localization and the step-button-during-drag edge case. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
