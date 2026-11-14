---
id: f679a77e-04f7-4e43-b898-6d78a637a760
title: "DialogActions"
type: ingredient
version: 1.4.1
status: review
language: en
created: 2026-07-03
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Two-button dialog footer laid out by CSS: equal-width when narrow, right-justified natural-width when wide, plus initial focus and a busy state."
platforms:
  - typescript
  - web
tags:
  - component
  - dialog
  - actions
  - footer
  - ui
depends-on:
  - f3c25236-d72f-4a7b-839a-b7f335b3acd0
related:
  - 550f00f7-bfb2-415e-9b15-bd5dce015500
  - 972be0d0-a9f5-45cd-a23b-c8329410b3d1
references: []
approved-by: ""
approved-date: ""
---

# DialogActions

## Overview

`DialogActions` (`@adh-sdk/ui`) is the standard footer for a dialog or alert:
a cancel button (optional) and a confirm button, laid out per the rule in
**alert-and-dialog §Layout**, which resolves to one of two shapes according to how
much room the container gives them:

- **equal-width** — each button takes half the row and the row fills the container
  (`[ Cancel ][ Confirm ]`), when the container is narrow.
- **natural-width, right-justified** — the buttons keep their content width and
  hug the right edge, when the container has room for both.

The rule is expressed in CSS rather than measured in JavaScript: each button is
`flex-1 max-w-max` inside a `justify-end` row, so it grows into its share of the
row but never past its natural width, and any leftover space collects on the left.
The layout engine therefore resolves equal-vs-natural during first layout, and the
first painted frame is the final one. The component also sets initial focus on
mount (defaulting to the safe button) and renders a spinner while `busy`.

One symbol ships from `@adh-sdk/ui/components/dialog-actions`: the
`DialogActions` component. There is no exported layout helper — see *Design
Decisions*.

## Behavioral Requirements

- **render-confirm**: The component MUST always render a confirm button labeled with `confirmLabel` that invokes `onConfirm` when activated.
- **render-cancel-when-labeled**: The component MUST render a cancel button that invokes `onCancel` when `cancelLabel` is provided, and MUST omit the cancel button entirely when `cancelLabel` is absent.
- **equal-width-when-narrow**: In `auto` layout with two buttons, when the container is too narrow for both at their natural width, the component MUST give each button up to an equal share of the row, capped at its own natural width, with any share a button doesn't use falling to the other button.
- **natural-width-when-wide**: In `auto` layout with two buttons, when the container has room for both at their natural width, the component MUST hold each at that width and right-justify the row.
- **cap-growth-at-natural-width**: In `auto` layout, no button may be stretched past its own natural width; the space a button declines MUST fall to the other button if it needs it, and otherwise to the left of the row.
- **settle-before-interactive**: The component MUST present its final button geometry on the first frame it paints. It MUST NOT move or resize a button after mount as a result of deciding its own layout — a button that shifts while the dialog is already clickable can swallow the click that was aimed at it.
- **follow-the-container**: The layout MUST be derived from the container's own width, not the viewport's, and MUST re-resolve when the container's width changes.
- **honor-forced-layout**: When `layout` is `equal` or `natural`, the component MUST use that layout regardless of the container's width.
- **focus-initial-on-mount**: When `focusOnMount` is true, the component MUST move focus on mount to the button named by `initialFocus`.
- **default-focus-to-safe-button**: When `initialFocus` is unset, the component MUST default initial focus to the confirm button normally and to the cancel button when `destructive` is true.
- **suppress-focus-on-mount**: When `focusOnMount` is false, the component MUST NOT move focus on mount, leaving the host to place focus.
- **focus-fallback-to-other-button**: When the button named by `initialFocus` is disabled or absent at mount, the component MUST move initial focus to the other button instead; when both are disabled or absent, it MUST leave focus untouched rather than forcing it.
- **quiet-ring-for-destructive-cancel**: When `initialFocus` resolves to `"cancel"`, the cancel button's focus-visible ring MUST use the `--apt-text` token rather than the default accent ring.
- **style-confirm-destructive**: When `destructive` is true, the confirm button MUST render with the destructive variant.
- **show-busy-indicator**: When `busy` is true, the component MUST replace the buttons with a status spinner exposing an accessible working label, MUST ignore `confirmDisabled`, and MUST NOT invoke `onConfirm` or `onCancel`.
- **apply-confirm-disabled**: When `confirmDisabled` is true and `busy` is false, the confirm button MUST be disabled and MUST NOT invoke `onConfirm` when activated.

## Appearance

Narrow container (no room for both at natural width) → an even split of the row:

```
┌───────────────────────────────┐
│ [   Cancel   ][   Confirm   ]  │   each capped share
└───────────────────────────────┘
```

Wide container (room for both) → natural width, right-justified:

```
┌───────────────────────────────────────────┐
│                        [ Cancel ][ Confirm]│   justify-end
└───────────────────────────────────────────┘
```

Busy:

```
┌───────────────────────────────┐
│                          ◌     │   spinner, right-justified
└───────────────────────────────┘
```

- Row: `flex items-center gap-3`; `w-full justify-end` in `auto`, `w-full` in
  forced-equal, `justify-end` in forced-natural and busy modes.
- Buttons in `auto` carry `flex-1 max-w-max`; forced-equal carries `flex-1`
  (uncapped); forced-natural carries neither.
- Buttons are the shared `Button` at `size="sm"`. Cancel is `variant="outline"`;
  confirm is `destructive` when `destructive`, else `confirmVariant` (default
  `"default"`, the gold primary).
- `data-slot="dialog-actions"` on the row for host styling/targeting.
- Busy spinner: `Loader2` at `size-4 animate-spin`, muted token color.
- No raw hex; no `!important` — buttons carry all color via `Button` variants.

## States

| State | Appearance change |
|---|---|
| Idle, narrow container | even split, `[ Cancel ][ Confirm ]` filling the row |
| Idle, wide container | natural-width, right-justified (`justify-end`) |
| Forced `equal` | always equal-width regardless of container width |
| Forced `natural` | always natural-width right-justified |
| Confirm-only (no `cancelLabel`) | single confirm button, right-justified at its natural width; forced-equal does not stretch it |
| Destructive | confirm renders destructive variant; default initial focus is Cancel |
| Busy | buttons replaced by a `role="status"` spinner; no clicks fire |
| Confirm disabled | confirm button is disabled and does not respond to clicks |

## Accessibility

- Renders the shared, focusable `<button>` primitives, so keyboard activation
  (Space/Enter) works natively.
- Initial focus is placed deliberately: on the confirm button by default, and on
  the cancel button for `destructive` actions so an errant Enter does not confirm
  a dangerous operation, using a quiet `--apt-text` focus ring instead of the
  accent (see **quiet-ring-for-destructive-cancel**) so the ring never reads as an
  alarm color on the safe button. Hosts that focus a form field instead pass
  `focusOnMount={false}`. When the preferred button is disabled or absent at
  mount, focus falls to the other one instead of nowhere (see
  **focus-fallback-to-other-button**).
- The busy spinner is exposed to assistive tech via `role="status"` and
  `aria-label="Working…"`, announcing the in-progress state.
- Color is carried by `Button` variants (theme tokens), keeping contrast
  consistent with the platform's button treatment.
- Touch target: `Button` at `size="sm"` renders `h-7` (28px) by default, below
  the 44×44pt guideline; `DialogActions` does not set the shared
  `--adh-button-min-height`/`--adh-button-min-width` CSS variables itself, so the
  rendered target is whatever the host's surface provides (a surface can raise
  the floor by setting those variables once on itself — see `Button`). See
  **touch-target-size** in Compliance.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-confirm | `confirmLabel="Save"`, click confirm | `onConfirm` called once |
| T2 | render-cancel-when-labeled | `cancelLabel="Cancel"`, click cancel | cancel button present; `onCancel` called once |
| T3 | render-cancel-when-labeled | no `cancelLabel` | no cancel button in the DOM |
| T4 | equal-width-when-narrow (Playwright) | `auto` in a container narrower than the sum of both buttons' natural widths | both buttons split the row evenly, each capped at its own natural width; row fills the container |
| T5 | natural-width-when-wide (Playwright) | `auto` in a container at least as wide as both buttons' natural widths combined | both at natural width; row right-justified |
| T6 | cap-growth-at-natural-width | `auto` | both buttons carry `flex-1 max-w-max`; the row carries `justify-end` |
| T7 | settle-before-interactive (Playwright) | sample the cancel button's bounding box every frame from before the dialog opens | exactly one distinct box — the final one — for the dialog's whole life |
| T8 | follow-the-container (Playwright) | render narrow (even split), widen the container past the combined natural width of both buttons | layout becomes natural, right-justified |
| T8b | honor-forced-layout | `layout="equal"` in a wide container | equal-width, uncapped; no natural flip when resized |
| T9 | focus-initial-on-mount + default-focus-to-safe-button | mount non-destructive | confirm button is `document.activeElement` |
| T10 | default-focus-to-safe-button | mount with `destructive` | cancel button is `document.activeElement` |
| T11 | suppress-focus-on-mount | mount with `focusOnMount={false}` | neither button receives focus |
| T12 | show-busy-indicator | `busy`, attempt to click | `role="status"` spinner present; no buttons; `onConfirm`/`onCancel` not called |
| T13 | style-confirm-destructive | `destructive` | confirm button uses destructive variant |
| T14 | settle-before-interactive | mount, then fire a window resize | the row's and buttons' class lists are byte-identical before and after |
| T15 | apply-confirm-disabled | `confirmDisabled=true`, click confirm | confirm button disabled; `onConfirm` not called |
| T16 | show-busy-indicator | `confirmDisabled=true` and `busy=true` | spinner renders; buttons not visible; `confirmDisabled` ignored |
| T17 | focus-fallback-to-other-button | mount with `initialFocus="confirm"` where the confirm button is disabled at mount | cancel button is `document.activeElement` |
| T18 | quiet-ring-for-destructive-cancel | mount with `destructive`, inspect the cancel button's focus-visible classes | cancel carries `focus-visible:border-apt-text focus-visible:ring-apt-text/40`, not the default ring token |

## Edge Cases

- **Empty or zero-width labels**: a button with no content collapses to its padding,
  which is its natural width; the cap is simply small and the other button takes the
  slack. There is no "unmeasured" state to guard against, because nothing is measured.
- **Confirm-only**: with no `cancelLabel`, the lone confirm button sits at its natural
  width on the right. Forced-equal still does not stretch it.
- **One button outgrows its half, the other does not**: the small one settles at its
  natural width and the large one takes the remainder, instead of both snapping to an
  even split and truncating the large one. This is the one behavioural difference from
  the previous `2 × Wmax` threshold, and it is strictly the better answer.
- **Boundary width**: there is no threshold to sit exactly on. The row passes
  continuously between the two shapes as the container narrows, so no flicker band
  exists.
- **Busy**: the spinner path renders no buttons at all, so the layout question does
  not arise.
- **Label change**: a longer label changes the button's natural width, and the layout
  engine re-resolves during the same layout pass that reflows the text — there is no
  second pass to observe.
- **Confirm disabled while button has focus**: if the confirm button is focused and
  `confirmDisabled` flips to true, the button is disabled but focus is not moved; the
  next click attempt will fail silently (the button does not fire). The host is
  responsible for moving focus if needed (e.g. to the cancel button). This is a
  deliberate choice, not an oversight — see Design Decisions.
- **Initial focus fallback**: when the preferred button named by `initialFocus` is
  disabled or absent, focus moves to the other button instead of nowhere (see
  **focus-fallback-to-other-button**). When both are missing or disabled, the component
  leaves focus wherever the host dialog already placed it rather than forcing it anywhere;
  it relies on the host dialog's own focus management (for example base-ui's Popup) to keep
  a trap in place.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `confirmLabel` | `string` | — (required) | Confirm button text. |
| `onConfirm` | `() => void` | — (required) | Confirm handler. |
| `cancelLabel` | `string` | — | Cancel button text; omit to render confirm only. |
| `onCancel` | `() => void` | — | Cancel handler. |
| `confirmVariant` | `Button["variant"]` | `"default"` | Confirm variant when not destructive. |
| `destructive` | `boolean` | `false` | Confirm uses the destructive variant; default focus moves to Cancel. |
| `busy` | `boolean` | `false` | Replace buttons with a status spinner; suppress clicks. |
| `confirmDisabled` | `boolean` | `false` | Disables confirm when not busy (has no effect when `busy` is true). Defaults to false for backward compatibility. |
| `initialFocus` | `"confirm" \| "cancel"` | `destructive ? "cancel" : "confirm"` | Which button gets focus on mount. |
| `focusOnMount` | `boolean` | `true` | When false, do not auto-focus (host focuses its own field). |
| `layout` | `"auto" \| "equal" \| "natural"` | `"auto"` | `auto` lets CSS resolve the rule per alert-and-dialog §Layout; `equal`/`natural` force one shape. |

## Deep Linking

Not applicable: `DialogActions` is a presentational footer component with no page-level routing or URL patterns. It renders within a dialog provided by its host.

## Localization

All user-facing text comes from caller-supplied props (`confirmLabel`, `cancelLabel`). The component supplies one hardcoded string: the busy spinner's `aria-label="Working…"` (see **show-busy-indicator**). The aria-label is rendered as English only; a host requiring localization must wrap or fork the component to substitute a localized label.

## Accessibility Options

| Option | Behavior |
|---|---|
| Reduce Motion | Not respected. The busy spinner's `animate-spin` (see **show-busy-indicator**) and each button's `transition-all` (from the shared `Button` component) play regardless of `prefers-reduced-motion`. Layout itself never triggers `transition-all` — that is the point of resolving it in CSS before paint (see **settle-before-interactive**) — so the gap is limited to the spinner's rotation and `Button`'s hover/press/variant transitions. |
| Increase Contrast | Delegated: color and contrast are carried entirely by `Button` theme tokens; `DialogActions` renders no colors of its own. |
| Differentiate Without Color | Not applicable: the component carries no color-only affordances — state is also conveyed by the presence/absence of buttons, the `disabled` attribute, and the spinner's `role="status"`. |

## Feature Flags

Not applicable: no feature flag conditions exist in the source code. The component renders all features unconditionally.

## Analytics

Not applicable: `DialogActions` is a presentational footer. No analytics events are fired by the component itself. Event tracking for the action's outcome (success/error) belongs in the host's `onConfirm` and `onCancel` handlers, not in the component.

## Privacy

Not applicable: `DialogActions` collects no user data, stores nothing locally, transmits nothing to a server, and retains no history. All inputs are ephemeral props and all outputs are callback invocations to the host.

## Logging

No logging. `DialogActions` is a presentational footer; success/error telemetry
belongs to the host's `onConfirm`/`onCancel` handlers, not to the component.

## Platform Notes

- **React/Web**: 
  - File: `packages/web/packages/ui/src/components/dialog-actions.tsx`
  - `"use client"` — it uses `useEffect` and refs for the initial-focus placement. It holds no layout state and starts no observers.
  - Depends on the shared `Button` (`./button`) and `Loader2` from `lucide-react`.
  - Demo: `ui-showcase` Topic `dialog-actions` (regenerate `sources.generated.ts` via `gen-sources.py` after source changes).
  - The layout rule is the shared implementation of **alert-and-dialog §Layout**; hosts (e.g. the invitation modal) may force `layout="equal"` per their own spec.
- **SwiftUI**: Use `@FocusState` to set initial focus — assign it from `.onAppear` (or via `.defaultFocus(_:_:)` where the host is inside a `NavigationStack`/`Group` that supports it); `focusedValue` only *reads* the ambient focus, it does not move it. `HStack` + `Spacer` cannot express "grow to your share but stop at natural width," so implement the capped-growth layout with a custom `Layout` that measures each button's ideal size and caps its allotted width, or switch between an equal-width and a natural-width `HStack` with `ViewThatFits`. For busy state, replace buttons with a spinner showing a status label.
- **Compose**: Put both buttons in a `Row(horizontalArrangement = Arrangement.End)` and give each `Modifier.weight(1f, fill = false)` — `fill = false` is what caps a button's growth at its own measured width once there is room, matching `max-w-max`; plain `weight(1f)` stretches the button to fill its whole share instead. Manage focus via `FocusRequester`. Replace with a `CircularProgressIndicator` for busy state.
- **AppKit / UIKit**: Use `NSStackView` (AppKit) or `UIStackView` (UIKit) with `distribution = .fillEqually` for the forced-equal layout, and `.fill` with each button's content-hugging priority raised (so the stack does not stretch it past its intrinsic width) for natural-width — `.fillProportionally` caps nothing and is the wrong mode for either shape. Manage focus via first responder. Replace buttons with a loading spinner for busy state.
- **WinUI 3**: A horizontal `StackPanel` does not stretch its children, so `HorizontalAlignment="Stretch"` will not produce equal widths. Use a `Grid` with star-sized columns (or a custom panel) for equal-width, and set each button's `MaxWidth` to its desired natural width to cap growth for natural-width. Set focus via `Focus()` on `UIElement`. Replace buttons with `ProgressRing` for busy state; set `AutomationProperties.Name` for the busy label.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/dialog-actions.tsx` | unverified |

## Design Decisions

- **Decision**: The button-row layout is driven by the container's own width and the
  buttons' content, not a viewport media query.
  **Rationale**: A media query can only see the viewport, not the width the row
  actually has inside its container, which is what determines whether both buttons
  fit at natural width.
  **Approved**: pending

- **Decision**: The equal-vs-natural rule is resolved in CSS (`flex-1 max-w-max` in a
  `justify-end` row), not measured and flipped in JavaScript after mount.
  **Rationale**: A prior implementation rendered the row equal-width, then read each
  button's natural width in a layout effect by moving it to `position: fixed; left:
  -9999px`, and flipped the row via `setState`. Reading `getBoundingClientRect()`
  mid-effect forced a reflow, which gave each button a resolved *previous* width and
  so armed `Button`'s `transition-all`; the flip became a ~150ms animation that
  started only once the dialog was already on screen and clickable. Instrumented in
  Chromium, Cancel travelled 268px to the right while shrinking from 198px to 64px —
  and it held the wrong position for four frames (55ms → 122ms) before the slide
  began, long enough to look settled. A click aimed there landed on bare dialog
  surface after the button had left, and the dialog just sat there, apparently
  ignoring you. It surfaced as a rare e2e flake; it was a real defect for anyone
  quick with a mouse. The general lesson: deciding your own layout after you are
  already interactive is a race with your user — a declarative rule the engine
  resolves before the first paint has no such window.
  **Approved**: pending

- **Decision**: No layout helper (the old `decideActionLayout(containerWidth,
  maxButtonWidth)`) is exported.
  **Rationale**: That helper existed so the equal/natural threshold could be
  unit-tested without a real layout. With the rule expressed in CSS there is no
  threshold left to test in isolation — the contract is now the class list
  (asserted in unit tests) plus the settled geometry (asserted in the browser).
  **Approved**: pending

- **Decision**: Non-destructive confirmations default initial focus to Confirm;
  destructive ones default it to Cancel.
  **Rationale**: An accidental Enter should not trigger a dangerous confirm, so the
  safe button is focused by default. `focusOnMount={false}` yields focus to hosts
  that want to focus a form field instead.
  **Approved**: pending

- **Decision**: A destructive dialog's default-focused Cancel button uses the
  `--apt-text` (on-surface foreground) focus ring instead of the theme's accent
  ring.
  **Rationale**: `Button`'s default focus ring resolves `--ring` to the accent
  color, which is right for a ring the user asked for by tabbing but wrong for one
  painted by us on mount, before the user has chosen anything. Several themes'
  accents are red (`gruvbox`, `monokai`, `terminal-split` among them), and a
  destructive dialog is the only kind that focuses Cancel by default, so on those
  themes the safe button would wear the same alarm color as the destructive button
  beside it — inverting the one signal the pair exists to carry. `--apt-text` is
  guaranteed to contrast with the dialog's surface in every theme and is not a
  color any theme uses to mean danger.
  **Approved**: pending

- **Decision**: Rendering the spinner in place of both buttons (rather than
  disabling them) is how `busy` is handled.
  **Rationale**: Replacing the buttons keeps the in-flight state simple to reason
  about and prevents a double-submit; there is no disabled-button state that has to
  stay synchronized with the spinner.
  **Approved**: pending

- **Decision**: `confirmDisabled` defaults to `false`.
  **Rationale**: The prop exists to support dirty-gating (e.g. disabling Save until
  a form changes), but defaulting it to `true` would change the behavior of every
  existing caller, which expects confirm to be enabled whenever the dialog is idle.
  **Approved**: pending

- **Decision**: When `confirmDisabled` flips to `true` while the confirm button
  holds focus, the component does not move focus away.
  **Rationale**: The focus-placement effect runs once, on mount (its deps are
  `focusOnMount` and `initialFocus`), by design — re-running it whenever
  `confirmDisabled` changes would risk yanking focus out from under whatever the
  user is doing elsewhere in the dialog. Moving focus reactively on every
  disablement is left to the host, which already owns the surrounding dialog's
  focus semantics (see the "Confirm disabled while button has focus" edge case).
  **Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | passed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The passed/failed statuses rest on: native `<button>` elements plus the `role="status"`/`aria-label` spinner and `Button`'s theme-token colors (screen-reader-support, keyboard-navigable, semantic-markup, contrast-ratio — passed); the deliberate, source-verified focus placement and fallback logic (focus-management — passed); the `size="sm"` button's actual `h-7` (28px) height with no `--adh-button-min-height` set by this component (touch-target-size — failed); the unconditional `animate-spin`/`transition-all` with no `prefers-reduced-motion` check (reduced-motion — failed); the hardcoded `aria-label="Working…"` (string-externalization, no-hardcoded-strings — failed); the flex-based natural-width growth and unprocessed prop strings, which impose no truncation and no encoding assumptions (text-expansion-tolerance, unicode-support — passed); and, where the source cannot tell you, Tailwind's rem-based type scale (dynamic-type-support) and the browser's native flexbox handling of `justify-end` under `dir="rtl"` (rtl-layout-support), neither of which this component tests directly (both — partial). `separation-of-concerns` is partial because the initial-focus effect and the button-grow layout derivation are both implemented inline inside `DialogActions` rather than extracted; `unit-test-coverage` passes because `dialogActions.test.tsx` imports `DialogActions` directly and exercises its behavior with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe; documents the measured equal-vs-natural layout, initial focus, resize re-measure, and busy state. |
| 1.1.0 | 2026-07-27 | Mike Fullerton | Layout moved from a measure-then-flip layout effect to a pure CSS rule (`flex-1 max-w-max` in a `justify-end` row). Removes the post-paint 268px slide that could swallow a click aimed at Cancel. Drops the exported `decideActionLayout` helper and the `ResizeObserver`. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Complete ingredient recipe: add `confirmDisabled` requirement (see **apply-confirm-disabled**), fill all template sections (Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics, Privacy) with "not applicable" explanations, expand Platform Notes to cover all platforms, add touch target guidance, and update Change History. |
| 1.3.0 | 2026-09-22 | Mike Fullerton | Remove localization review marker; aria-label is implemented in source as hardcoded English, no decision to be made by reviewer. |
| 1.4.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case and updated every citation; merged the duplicate busy/confirmDisabled requirement into **show-busy-indicator**; reworded **equal-width-when-narrow** and rewrote T4/T5/T8 to match the natural-width-capped behavior instead of the retired `2 × Wmax` threshold; added requirements and test vectors for the initial-focus fallback and the destructive-cancel quiet focus ring; reformatted Design Decisions into Decision/Rationale/Approved and added one covering focus not moving when confirm disables late; corrected the touch-target claim and dropped the unverified "39 themes" figure in favor of the three named themes; replaced stale source-line citations with requirement-name citations; fixed the SwiftUI, Compose, AppKit/UIKit, and WinUI 3 platform notes; documented the spinner/button animations and their lack of Reduce Motion support in Accessibility Options; and rebuilt Compliance as a linked table using passed/failed/partial. |
| 1.4.1 | 2026-09-25 | Mike Fullerton | Fixed both-disabled focus edge case: leaves focus wherever the host dialog placed it, not forced to <body>/no trap; shortened summary to fit 160 chars. Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: passed). |
