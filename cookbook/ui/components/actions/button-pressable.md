---
id: f483dfb7-d60e-4b12-8b17-2eb150b550db
title: "PressableButton"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Client-side pointer-tracking layer that wraps the Base UI Button primitive and reflects a held/pressed state via data-pressed, composing with consumer pointer handlers."
platforms:
  - typescript
  - web
tags:
  - component
  - button
  - pointer-events
  - pressable
  - ui
depends-on: []
related:
  - f3c25236-d72f-4a7b-839a-b7f335b3acd0
references: []
approved-by: ""
approved-date: ""
---

# PressableButton

## Overview

`PressableButton` is the `"use client"` interactivity layer for the shared
`Button` component. It wraps the Base UI `Button` primitive and tracks a
pointer-driven "held" and "pressed" state that CSS `:active` cannot express —
in particular, the case where the pointer is dragged out of the button while
still held, and dragged back in before release. It reflects the pressed state
via a `data-pressed` attribute for the consuming styles to key off of, and it
composes with any pointer handlers the caller supplies rather than replacing
them. It lives in its own module, separate from the plain `button.tsx` module
that computes the visual variant classes, so that module can stay free of a
`"use client"` directive and remain callable from server components. See
[adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0) for the composed component,
its visual variants, and its accessibility surface.

## Behavioral Requirements

Requirements below are phrased over an **active press** — the interval from a
`pointerdown` on the rendered primitive to the earliest of an element-level or
window-level `pointerup`/`pointercancel` — rather than over the internal
`held` state variable. See Design Decisions for why.

- **render-as-forwarded-primitive**: PressableButton MUST render the underlying Base UI `Button` primitive with every prop other than the five intercepted pointer handlers (`onPointerDown`, `onPointerUp`, `onPointerLeave`, `onPointerEnter`, `onPointerCancel`) passed through unchanged.
- **data-slot**: PressableButton MUST set `data-slot="button"` on the rendered primitive.
- **pressed-absent-by-default**: PressableButton MUST leave the `data-pressed` attribute unset on the rendered primitive before any pointer interaction.
- **pressed-on-pointerdown**: PressableButton MUST set `data-pressed=""` on the rendered primitive when a `pointerdown` event is dispatched on it, beginning an active press.
- **pressed-cleared-on-element-pointerup**: PressableButton MUST remove the `data-pressed` attribute when a `pointerup` event is dispatched on the rendered primitive, ending the active press.
- **pressed-cleared-on-pointerleave-during-active-press**: PressableButton MUST remove the `data-pressed` attribute when a `pointerleave` event is dispatched on the rendered primitive during an active press.
- **pressed-restored-on-pointerenter-during-active-press**: PressableButton MUST set `data-pressed=""` again on the rendered primitive when a `pointerenter` event is dispatched on it during an active press.
- **pressed-unaffected-by-pointerenter-outside-active-press**: PressableButton MUST NOT change the `data-pressed` attribute when a `pointerenter` event is dispatched on the rendered primitive outside an active press.
- **pressed-cleared-on-element-pointercancel**: PressableButton MUST remove the `data-pressed` attribute when a `pointercancel` event is dispatched on the rendered primitive, ending the active press.
- **pressed-cleared-on-window-release-during-active-press**: PressableButton MUST remove the `data-pressed` attribute when a `pointerup` or `pointercancel` event is dispatched anywhere on `window` during an active press, regardless of the event's target.
- **window-release-no-effect-outside-active-press**: PressableButton MUST NOT change the `data-pressed` attribute, and MUST NOT throw, in response to a `pointerup` or `pointercancel` event dispatched on `window` outside an active press.
- **forwarded-handler-invoked-when-provided**: PressableButton MUST invoke a caller-supplied `onPointerDown`, `onPointerUp`, `onPointerLeave`, `onPointerEnter`, or `onPointerCancel` prop, when one is provided, every time the corresponding pointer event fires on the rendered primitive.
- **pressed-unaffected-by-keyboard-activation**: PressableButton MUST NOT change the `data-pressed` attribute in response to keyboard activation (Space or Enter).
- **no-pointer-capture**: PressableButton MUST NOT call `setPointerCapture` on any pointer event it handles.
- **no-window-listener-after-unmount**: PressableButton MUST leave no `window` `pointerup` or `pointercancel` listener attached after it unmounts, including when it unmounts during an active press.
## Appearance

Not applicable: PressableButton is a pointer-event tracking layer with no styling of its own; visual appearance (radius, padding, font, colors, borders, shadows, size constraints) is defined in `button.tsx`'s `buttonVariants` and the Base UI `Button` primitive.

## States

| State | Appearance change |
|-------|------------------|
| Default | `data-pressed` absent; no active press in progress |
| Pressed | `data-pressed=""` present; entered on `pointerdown`, held through `pointerleave`/`pointerenter` cycles while the active press continues |
| Held, Not Pressed | `data-pressed` absent while the active press continues (a later window-level release still ends it) — entered when `pointerleave` fires during an active press, exited by `pointerenter` (returns to Pressed) or by any release (ends the active press, returns to Default) |
| Disabled | Not applicable: PressableButton contains no `disabled` logic; disabling is a concern of the primitive/CSS layer. |
| Focused | Not applicable: PressableButton contains no focus handling; focus state is managed by the Base UI Button primitive. |
| Loading | Not applicable: PressableButton contains no loading-state logic. |

The "Pressed" and "Held, Not Pressed" rows above cover two nested transitions
traceable to the source: while an active press is in progress, a
`pointerleave` clears `data-pressed` (the visual returns to Default while the
press stays active) and a subsequent `pointerenter` restores it, without ever
ending the active press. (Implementation: `button-pressable.tsx` tracks this
with internal `held`/`pressed` `useState` values; see Design Decisions.)

## Accessibility

- Role/trait: Not applicable: PressableButton sets no accessibility role; the role comes from the Base UI Button primitive it wraps.
- Label requirements: Not applicable: PressableButton accepts and forwards label-related props but imposes no label requirements.
- Announce state changes: Not applicable: PressableButton sets no ARIA announcements; `data-pressed` is a plain data attribute for CSS selectors, not an ARIA state.
- Minimum tap target: Not applicable: PressableButton imposes no size constraints; touch target sizing is a concern of the primitive/CSS layer.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| button-pressable-001 | render-as-forwarded-primitive | Render with `variant="secondary"` and `aria-label="Save"` | Rendered element receives `variant="secondary"` and `aria-label="Save"` unchanged |
| button-pressable-002 | data-slot | Render with any props | Rendered element has `data-slot="button"` |
| button-pressable-003 | pressed-absent-by-default | Initial render, no interaction | Rendered element has no `data-pressed` attribute |
| button-pressable-004 | pressed-on-pointerdown | `pointerdown` dispatched on the element | Rendered element has `data-pressed=""` immediately after the event |
| button-pressable-005 | pressed-cleared-on-element-pointerup | `pointerdown` then `pointerup`, both on the element | `data-pressed` absent after `pointerup` |
| button-pressable-006 | pressed-cleared-on-pointerleave-during-active-press | `pointerdown` then `pointerleave`, both on the element | `data-pressed` absent after `pointerleave` |
| button-pressable-007 | pressed-restored-on-pointerenter-during-active-press | `pointerdown`, `pointerleave`, `pointerenter`, all on the element | `data-pressed=""` present again after `pointerenter` |
| button-pressable-008 | pressed-unaffected-by-pointerenter-outside-active-press | `pointerenter` on the element with no prior `pointerdown` | `data-pressed` remains absent after `pointerenter` |
| button-pressable-009 | pressed-cleared-on-element-pointercancel | `pointerdown` then `pointercancel`, both on the element | `data-pressed` absent after `pointercancel` |
| button-pressable-010 | pressed-cleared-on-window-release-during-active-press | `pointerdown` on the element, then `pointerup` dispatched on `window` (not on the element) | `data-pressed` absent after the window `pointerup` |
| button-pressable-011 | pressed-cleared-on-window-release-during-active-press | `pointerdown` on the element, then `pointercancel` dispatched on `window` (not on the element) | `data-pressed` absent after the window `pointercancel` |
| button-pressable-012 | pressed-cleared-on-window-release-during-active-press | `pointerdown` on the element, then `pointerleave` on the element (no `pointerup`), then `pointerup` on `window` | `data-pressed` absent after the window `pointerup`, proving the active press begun by `pointerdown` survived the intervening `pointerleave` |
| button-pressable-013 | window-release-no-effect-outside-active-press | `pointerup` dispatched on `window` with no prior `pointerdown` on the element | No change to `data-pressed` and no error is thrown |
| button-pressable-014 | window-release-no-effect-outside-active-press | `pointerdown` then `pointerup`, both on the element, then a second `pointerup` dispatched on `window` | The second window `pointerup` produces no additional change to `data-pressed` |
| button-pressable-015 | forwarded-handler-invoked-when-provided | Render with an `onPointerDown` spy prop, dispatch `pointerdown` on the element | Spy is called exactly once |
| button-pressable-016 | pressed-unaffected-by-keyboard-activation | Focus the element, press `Enter` (and separately, `Space`), with no pointer event | `data-pressed` remains absent throughout and after activation |
| button-pressable-017 | no-pointer-capture | Spy on `setPointerCapture` before rendering, then dispatch `pointerdown` on the element | The `setPointerCapture` spy is never called |
| button-pressable-018 | pressed-on-pointerdown | `pointerdown` dispatched on the element with no `onPointerDown` prop supplied | No error is thrown; `data-pressed=""` is still set |
| button-pressable-019 | pressed-on-pointerdown | `pointerdown` dispatched twice on the element with no intervening release | `data-pressed=""` remains set after the second `pointerdown`; no error is thrown |
| button-pressable-020 | window-release-no-effect-outside-active-press | `pointerdown` then `pointerup`, both on the element (ending the active press), then `pointercancel` dispatched on the element | `data-pressed` remains absent; no error is thrown |
| button-pressable-021 | pressed-cleared-on-window-release-during-active-press | `pointerdown` with `pointerId` 1 on the element, then `pointerdown` with `pointerId` 2 on the element (no intervening release), then `pointerup` with `pointerId` 1 dispatched on `window` | `data-pressed` is cleared — the window listener ends the active press regardless of which `pointerId` released |
| button-pressable-022 | pressed-unaffected-by-pointerenter-outside-active-press | `pointerdown` then `pointerup` on the element (completing a press), then `pointerenter` on the element | `data-pressed` remains absent after the later `pointerenter`, since the active press already ended |
| button-pressable-023 | forwarded-handler-invoked-when-provided | Render with an `onPointerUp` spy prop, dispatch `pointerdown` then `pointerup` on the element | Spy is called exactly once, on `pointerup` |
| button-pressable-024 | forwarded-handler-invoked-when-provided | Render with an `onPointerLeave` spy prop, dispatch `pointerdown` then `pointerleave` on the element | Spy is called exactly once, on `pointerleave`; `data-pressed` is also cleared |
| button-pressable-025 | forwarded-handler-invoked-when-provided | Render with an `onPointerEnter` spy prop, dispatch `pointerdown`, `pointerleave`, then `pointerenter` on the element | Spy is called exactly once, on `pointerenter`; `data-pressed=""` is also restored |
| button-pressable-026 | forwarded-handler-invoked-when-provided | Render with an `onPointerCancel` spy prop, dispatch `pointerdown` then `pointercancel` on the element | Spy is called exactly once, on `pointercancel`; `data-pressed` is also cleared |
| button-pressable-027 | forwarded-handler-invoked-when-provided, pressed-on-pointerdown | Render with an `onPointerDown` spy prop, dispatch `pointerdown` on the element | Both fire: the spy is called exactly once and `data-pressed=""` is set |
| button-pressable-028 | no-window-listener-after-unmount | Spy on `window.addEventListener` and `window.removeEventListener`, dispatch `pointerdown` on the element, then unmount before any release | Every `pointerup` and `pointercancel` listener added to `window` has been removed; a later `pointerup` on `window` throws no error and calls no state update |
## Edge Cases

- **Handler prop omitted** (no `onPointerDown`/`onPointerUp`/`onPointerLeave`/`onPointerEnter`/`onPointerCancel` prop supplied): the component MUST NOT throw when the corresponding pointer event fires — `button-pressable.tsx`'s `compose()` helper short-circuits safely via `theirs?.(event)`'s optional chaining.
- **Repeated `pointerdown` without an intervening release** (a second `pointerdown` fires while an active press is already in progress): the component MUST leave `data-pressed` set at `""`  — the state assignment is idempotent and produces no observable change.
- **Release delivered only to `window`, never to the element** (`pointerdown` on the element, the pointer leaves before any element-level `pointerup`, and `pointerup` fires only on `window`): the component MUST still end the active press (`data-pressed` cleared) via the window listener, because `pointerleave` alone does not end it.
- **`pointercancel` delivered while no active press is in progress** (`pointercancel` fires on the element after a prior `pointerup` already ended the active press): the component MUST leave `data-pressed` absent, which is a no-op with no observable change.
- **Multi-pointer overlap**: `button-pressable.tsx` tracks a single `held`/`pressed` pair with no `pointerId` check anywhere in the file, and the `window` release listener ignores the event's target entirely. If a second pointer goes down while the first is still down, a `pointerup`/`pointercancel` from *either* pointer ends the entire active press — the component has no per-pointer identity tracking, so this is documented behavior, not a bug.
- **`pointerenter` after a fully completed press**: once an active press has ended by any release, a later `pointerenter` with no new `pointerdown` MUST NOT set `data-pressed`.
- **Boundary values**: Not applicable — the component has no numeric, length-, or count-bounded input; its only inputs are pointer/keyboard events and arbitrary forwarded props, none of which are constrained to a min/max range in this source.
- **Concurrent access**: Not applicable — pointer events are dispatched serially on the browser's single UI thread, and `held`/`pressed` are local, in-memory React state with no cross-thread or cross-session access path.
- **Error states**: Not applicable — the component has no dependency on a network, database, or file system; it performs no I/O.
- **Offline or disconnected state**: Not applicable — the component performs no network operation, so connectivity has no effect on its behavior.
- **Unmount during an active press**: the `useEffect` cleanup in `button-pressable.tsx` removes the `window` `pointerup`/`pointercancel` listeners when the component unmounts, so no listener remains and a later window release has no effect (see **no-window-listener-after-unmount**).
- **Disabled primitive**: PressableButton has no `disabled` check of its own and sets `data-pressed` on any `pointerdown` it receives. Whether a disabled button receives a `pointerdown` at all is decided by the Base UI `Button` primitive and the browser, not by this component.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `onPointerDown` | `(event: React.PointerEvent) => void` (optional) | `undefined` | Consumer handler invoked when `pointerdown` fires; composed with, never replacing, the component's own `pointerdown` tracking. |
| `onPointerUp` | `(event: React.PointerEvent) => void` (optional) | `undefined` | Consumer handler invoked when `pointerup` fires; composed with, never replacing, the component's own `pointerup` tracking. |
| `onPointerLeave` | `(event: React.PointerEvent) => void` (optional) | `undefined` | Consumer handler invoked when `pointerleave` fires; composed with, never replacing, the component's own `pointerleave` tracking. |
| `onPointerEnter` | `(event: React.PointerEvent) => void` (optional) | `undefined` | Consumer handler invoked when `pointerenter` fires; composed with, never replacing, the component's own `pointerenter` tracking. |
| `onPointerCancel` | `(event: React.PointerEvent) => void` (optional) | `undefined` | Consumer handler invoked when `pointercancel` fires; composed with, never replacing, the component's own `pointercancel` tracking. |
| `...props` | `ButtonPrimitive.Props` | — | All other Base UI `Button` props, forwarded unchanged. |

The handler event type is React's synthetic `React.PointerEvent` (the type `ButtonPrimitive.Props` declares), not the DOM `PointerEvent`.
## Deep Linking

Not applicable: PressableButton is a pointer-event tracking layer with no navigation or routing responsibility.

## Localization

Not applicable: PressableButton renders no user-facing strings.

## Accessibility Options
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: PressableButton contains no motion or transitions. |
| Increase Contrast | Not applicable: PressableButton contains no color or contrast logic. |
| Differentiate Without Color | Not applicable: PressableButton contains no color-dependent signaling. |
## Feature Flags

Not applicable: PressableButton contains no feature-flag logic or conditional behavior.

## Analytics

Not applicable: PressableButton fires no analytics events.

## Privacy

- **Data collected**: None. `button-pressable.tsx` collects no user data; `held` and `pressed` are transient boolean UI state.
- **Storage**: None. `held`/`pressed` live only in in-memory React component state (`useState`) and are never written to disk, cookies, or any storage API.
- **Transmission**: None. This file makes no network calls and sends no data anywhere.
- **Retention**: None beyond the component's lifetime. State resets to `false`/`false` on every fresh mount and is discarded on unmount.

## Logging

Subsystem: N/A | Category: N/A

No logging. `button-pressable.tsx` makes no logging or telemetry calls; state
changes are purely in-memory, and any telemetry belongs in the consumer's own
forwarded pointer handler, not in this file.

## Platform Notes

- **SwiftUI**: A SwiftUI developer would typically start from `ButtonStyle`'s `configuration.isPressed`, which SwiftUI derives from its own gesture recognizer — unlike this source, no manual `pointerdown`/`pointerup`/`pointerleave`/`pointerenter`/`pointercancel` tracking or window-level release listener is usually needed, since SwiftUI's gesture system typically already handles release-outside-the-view.
- **Compose**: A Jetpack Compose developer would typically start from `Modifier.pointerInput` combined with a `MutableInteractionSource`, reading press state via `interactionSource.collectIsPressedAsState()` (backed by `PressInteraction.Press`/`Release`/`Cancel`); Compose's `Interaction` API generally models a held/pressed distinction comparable to this source's `held`/`pressed`, so a manual window-level listener is typically not required.
- **React/Web**: This is the source. `PressableButton` wraps the Base UI `Button` primitive in a `"use client"` module, tracks `held`/`pressed` via `useState`, and reflects `pressed` through the `data-pressed` attribute; a `useEffect` attaches `window` `pointerup`/`pointercancel` listeners only while `held` is `true` to catch release outside the element.
- **AppKit / UIKit**: A UIKit developer would typically start from `UIControl`'s built-in `.isHighlighted` state driven by `touchDown`/`touchUpInside`/`touchDragExit`/`touchDragEnter`, which usually maps closely onto this source's `pointerdown`/`pointerup`/`pointerleave`/`pointerenter` logic. AppKit's `NSButton` has no equivalent live-pressed state and would need a custom `NSView` tracking `mouseDown`/`mouseDragged`/`mouseUp`, mirroring this source's manual approach rather than UIKit's built-in one.
- **WinUI 3**: A Windows developer would typically start from the `Button` control's default `ControlTemplate`, which defines a `"Pressed"` `VisualState` (via `VisualStateManager`) driven by `PointerPressed`/`PointerReleased`/`PointerCaptureLost`/`PointerExited`/`PointerEntered`, so the starting point is usually customizing that template's `Pressed` state rather than re-implementing pointer tracking from scratch. The key difference from this source: WinUI 3's default template typically calls `CapturePointer` on press, retargeting subsequent pointer events to the button, whereas this source deliberately avoids pointer capture (`// No setPointerCapture`) and instead relies on a `window`-level release listener to detect release outside the element — a WinUI 3 port that wants this source's exact leave/re-enter semantics would need to release capture (or avoid relying on it) and track `PointerExited`/`PointerEntered` manually instead.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/button-pressable.tsx` | confirmed (1.1.2) |

## Design Decisions
**Decision**: Requirements are phrased over an **active press** — the interval from a `pointerdown` on the rendered primitive to the earliest of an element-level or window-level `pointerup`/`pointercancel` — rather than over the internal `held` state variable.
**Rationale**: `held` and `pressed` are private `useState` values in `button-pressable.tsx` with no attribute of their own, so a requirement written over `held` can only be proven by indirect inference (for example, dispatching a window-level release afterward and checking that `data-pressed` still cleared). An "active press" is a window defined purely by dispatched events, so an outside test can observe and drive it directly, and `held`/`pressed` stay the implementation detail that satisfies it.
**Approved**: pending

**Decision**: Every Behavioral Requirement is a MUST; none are SHOULD or MAY.
**Rationale**: `button-pressable.tsx` contains no conditional or caller-configurable deviation in its press-tracking logic — every state transition is an unconditional, deterministic response to a specific event, so no permitted alternative behavior exists to write as SHOULD/MAY.
**Approved**: pending

**Decision**: A `window`-level `pointerup`/`pointercancel` listener pair is attached only while an active press is in progress, and torn down as soon as the press resolves (via an element-level release, an earlier window-level release, or unmount).
**Rationale**: `pointerleave` alone does not end an active press (by design, to support re-entry), so a release or cancel landing outside the element would otherwise leave the press stuck forever; the `useEffect` in `button-pressable.tsx` attaches the `window` listeners only while `held` is `true` and removes them the moment it becomes `false` or the component unmounts, so no listener is left attached once the press has resolved. This implementation is what satisfies `#requirements/pressed-cleared-on-window-release-during-active-press`, `#requirements/window-release-no-effect-outside-active-press` and `#requirements/no-window-listener-after-unmount`.
**Approved**: pending

**Decision**: `button-pressable.tsx` never calls `setPointerCapture`.
**Rationale**: Capture would re-target subsequent pointer events to the button and defeat the leave/re-enter detection that the `pointerleave`/`pointerenter` handlers depend on. The doc comment on `PressableButton` states this explicitly ("No `setPointerCapture`").
**Approved**: pending

**Decision**: Keyboard activation (Space/Enter) never changes the pressed visual.
**Rationale**: The pressed visual is intentionally pointer-only; Space/Enter activation is left entirely to the underlying Base UI `Button` primitive and never touches `pressed`. The doc comment on `PressableButton` states this explicitly.
**Approved**: pending

**Decision**: Consumer-supplied pointer handlers are composed with the component's own tracking, never replaced, and the order in which the two run is not a contract.
**Rationale**: `compose()` in `button-pressable.tsx` calls both the caller's handler and the component's own tracking logic, so passing e.g. `onPointerUp` does not silently disable press tracking and the component does not silently disable a caller's handler. Today `compose()` calls the caller's handler first, but both calls happen synchronously within the same event-handler tick and React defers the actual `data-pressed` DOM mutation regardless of which ran first, so no outside-observable effect distinguishes the two orders and a black-box Conformance Test Vector cannot prove one. A port may run them in either order.
**Approved**: pending

**Decision**: This ingredient is the single owner of the press-tracking behavioral contract for `button-pressable.tsx`; [adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0) depends on it.
**Rationale**: Two independent decompositions of the same source drift as the source changes, so one document owns the contract and the other points to it. The decomposition here is deliberately atomic and independently testable.
**Approved**: pending

**Decision**: `platforms` is `[typescript, web]`, matching [adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0) and `copy-button`.
**Rationale**: The component is written in TypeScript and runs in the browser, so both platform tags apply, and keeping the same pair across the button family lets tooling group them.
**Approved**: pending

**Decision**: Add the tags `pointer-events` and `pressable`.
**Rationale**: The established family vocabulary (`component`, `button`, `ui`) is kept, and these two tags are added because this ingredient's scope — the interaction layer alone, apart from `Button`'s visual variants — is not covered by any existing tag in the family.
**Approved**: pending

**Decision**: Appearance, Accessibility (role/label/announce/tap-target), States (Disabled/Focused/Loading), Deep Linking, Localization, Accessibility Options, Feature Flags, and Analytics are marked not applicable, not incomplete.
**Rationale**: `button-pressable.tsx` is purely a pointer-tracking behavior layer; it owns no styling, no ARIA semantics, no routing, no strings, no flags, and no telemetry. Those concerns belong to `button.tsx` (styling) and the Base UI `Button` primitive (semantics).
**Approved**: pending

**Decision**: Keep `title: PressableButton` — the exported symbol name — even though the file is `button-pressable.md`.
**Rationale**: Cookbook file-naming convention requires a kebab-case filename derived from what the component is, while `title` is documented as a human-readable label; sibling ingredients (e.g. `Button`/`button.md`) already let the two diverge in case. Noting the export name here avoids ambiguity for a reader who sees only the frontmatter.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The three accessibility statuses are `partial` because this component adds no semantics of its own and none were verified here: `button-pressable.tsx` forwards every prop other than the five intercepted pointer handlers unchanged (so any `aria-*`/label props a caller supplies reach the rendered element untouched), registers no keyboard handling (Space/Enter activation stays with the underlying Base UI `Button` primitive), and reflects press state via the plain `data-pressed` data attribute rather than any ARIA role or state. Role, label and keyboard behavior belong to the primitive and `button.tsx`; see the Compliance results in [adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0).
Best-practices statuses reflect that the held/pressed pointer state machine
is inlined in this component's own render rather than separated apart from
it — splitting the file from `button.tsx` keeps interactivity apart from the
plain module, but not apart from this file's own rendering
(separation-of-concerns: partial) — and that `buttonPressable.test.tsx`
covers all 28 conformance vectors of `PressableButton`
(unit-test-coverage: passed).
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: restated requirements over the observable `data-pressed`/active-press contract instead of the internal `held` state, renamed all requirements to subject-only kebab-case, replaced the ad hoc Compliance table with real accessibility checks, reformatted Design Decisions to the three-line form, cited `button-pressable.tsx` directly instead of "the source comment", softened unreferenced cross-platform API claims to "typically", dropped the untestable handler-ordering requirement in favor of a Design Decision, fixed the invalid `setPointerCapture` test vector, added a States row and two edge cases for multi-pointer overlap and post-release re-entry, declared this recipe the single owner of the press-tracking contract, and linked the Accessibility Options reference |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: failed). |
| 1.1.2 | 2026-11-14 | Mike Fullerton | Lint fixes: re-rated the three accessibility checks partial and pointed to Button, removed the handler-ordering claim from Configuration, merged the compose decisions, rewrote Design Decision rationales to describe the design rather than the authoring passes, reconciled the platforms decision, said ingredient instead of recipe, removed template residue, typed handlers as React.PointerEvent, and added an unmount requirement, a disabled-primitive edge case and vectors for the other four forwarded handlers. |
