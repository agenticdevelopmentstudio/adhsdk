---
id: f3c25236-d72f-4a7b-839a-b7f335b3acd0
title: "Button"
type: ingredient
version: 1.4.1
status: review
language: en
created: 2026-06-26
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The family button — Base UI primitive with shadcn token variants, a pointer-driven pressed state, and an ancestor-settable minimum touch-target floor."
platforms:
  - typescript
  - web
tags:
  - component
  - button
  - forms
  - ui
depends-on:
  - f483dfb7-d60e-4b12-8b17-2eb150b550db
related:
  - 00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f26a9468-a15c-4cd2-b944-d39221e7eee2
  - f483dfb7-d60e-4b12-8b17-2eb150b550db
references: []
approved-by: ""
approved-date: ""
---

# Button

## Overview

The shared `Button` in `@adh-sdk/ui` — a Base UI button primitive dressed in
the shadcn token vocabulary so every site drawing from `@adh-sdk/ui`
renders one button. It exposes eight visual `variant`s × a size scale, the standard disabled/focus/
invalid states, a **pointer-driven pressed state** that reflects a real press
the way CSS `:active` cannot, and an **ancestor-settable minimum touch-target
floor** that lets a surface raise every descendant button's minimum hit area
without changing any button's `size` prop.

Two exports ship from `@adh-sdk/ui/components/button`:

- `buttonVariants` — the `cva` styling function. It MUST stay callable from
  server components (e.g. `<Link className={buttonVariants()}/>`), so `button.tsx`
  carries no `"use client"` directive.
- `Button` — a thin wrapper that computes the variant classes (server-safe) and
  renders the `"use client"` interactivity layer `PressableButton`
  (`button-pressable.tsx`), which owns the pointer/press hooks.

The pressed visual (a small downward dip plus a subtle darken) is driven by the
`data-pressed` attribute that `PressableButton` toggles, not by `:active` — so the
press correctly clears when the pointer leaves the button while it is still held.

## Behavioral Requirements

*Provenance: `press-on-pointerdown-inside` through `no-pointer-capture` below describe the
observable pointer-tracking behavior of `Button` as rendered — behavior that `Button` gets by
composing the sibling `PressableButton` (`button-pressable.tsx`), which is that contract's
single owner ([adhsdk.ingredient.ui.components.actions.button-pressable](cookbook:f483dfb7-d60e-4b12-8b17-2eb150b550db), see its own
`pressed-on-pointerdown` through `no-pointer-capture` requirements and its
**active press** terminology, called "held" below). This recipe restates them at the `Button`
level only so `Button`'s own Conformance Test Vectors can exercise them end-to-end; do not edit
them here without also checking `button-pressable.md`, and re-verify them here whenever that
recipe's requirements change, since `button.md`'s `depends-on` does not by itself trigger
re-extraction of this file.*

- **press-on-pointerdown-inside**: The button MUST set `data-pressed` when a pointer is pressed down inside it.
- **release-clears-pressed**: The button MUST clear `data-pressed` on `pointerup`.
- **cancel-clears-pressed**: The button MUST clear `data-pressed` on `pointercancel`.
- **leave-while-held-clears-pressed**: While the pointer is still held, the button MUST clear `data-pressed` when the pointer leaves it.
- **reenter-while-held-restores-pressed**: While the pointer is still held, the button MUST restore `data-pressed` if the pointer re-enters it.
- **release-outside-ends-hold**: The button MUST end the held state when the pointer is released or cancelled anywhere, including outside the button, so the press never sticks.
- **no-pointer-capture**: The button MUST track the press from held + pointer-inside state and MUST NOT call `setPointerCapture`.
- **pressed-visual-from-data-attr**: The button MUST express its pressed appearance (the translate-y dip plus darken) purely from `data-pressed`, never from CSS `:active`.
- **haspopup-suppresses-dip**: A button with `aria-haspopup` (a popup/menu trigger) MUST NOT apply the pressed dip.
- **keyboard-activates**: Space and Enter on a focused button MUST activate it (fire its click), independent of the pointer pressed visual.
- **forwards-consumer-pointer-handlers**: The button MUST still call any consumer-supplied pointer handler (e.g. `onPointerUp`) in addition to its own pressed tracking.
- **stable-public-api**: The button MUST keep its existing API — the `variant`/`size` props, the `buttonVariants` export, and `data-slot="button"` — unchanged.
- **supports-eight-variants**: The button MUST render one of exactly eight `variant` styles — `default`, `outline`, `secondary`, `ghost`, `destructive`, `warning`, `destructive-ghost`, `link`.
- **warning-variant-uses-warning-role**: The `warning` variant MUST render using the theme's `apt-orange` warning-role tokens (`bg-apt-orange/15 text-apt-orange`), visually distinct from the `destructive` variant's tokens.
- **defaults-to-default-variant-and-size**: The button MUST render the `default` variant at the `default` size when `variant`/`size` are not supplied.
- **respects-ancestor-min-height-var**: The button MUST apply `min-height: var(--adh-button-min-height, 0px)`, so an ancestor MAY raise the button's minimum height without the button changing its `size` prop.
- **respects-ancestor-min-width-var**: The button MUST apply `min-width: var(--adh-button-min-width, 0px)`, so an ancestor MAY raise the button's minimum width without the button changing its `size` prop.
- **icon-sizes-square-to-height-floor**: Each `icon`/`icon-xs`/`icon-sm`/`icon-lg` size MUST redefine `--adh-button-min-width` to the current `--adh-button-min-height` value, so an ancestor-raised height floor keeps an icon button square.
- **icon-svgs-non-interactive**: An SVG child of the button MUST NOT receive pointer events (`pointer-events: none`) and MUST NOT shrink in the flex layout (`flex-shrink: 0`).
- **unsized-icon-svgs-scale-with-button-size**: An SVG child that carries no `size-*` class MUST render at `1rem` (16px) square by default, `0.875rem` (14px) at the `sm` size, and `0.75rem` (12px) at the `xs`/`icon-xs` sizes.
- **consumer-classname-precedence**: The button SHOULD apply a consumer-supplied `className` so it can override the variant/size classes it conflicts with, per the project's `cn()` merge convention. (Rationale: see Design Decisions.)

## Appearance

```
┌──────────────────┐        ┌──────────────────┐
│   Button         │   →    │   Button         │  (held: dipped 1px + darkened)
└──────────────────┘        └──────────────────┘
       idle                       data-pressed
```

- Base: `inline-flex` centered, `rounded-lg`, `text-sm font-medium`, `transition-all`,
  `select-none`; focus-visible ring via the `ring`/`border-ring` tokens.
- Variants: `default`, `outline`, `secondary`, `ghost`, `destructive`, `warning`,
  `destructive-ghost`, `link` — all expressed in shadcn theme tokens (the
  button's established vocabulary), never raw colors. `destructive-ghost` is a
  borderless destructive action, used by `ButtonBar` / `ListWithDetailsPane`.
  `warning` is one step down the status spectrum from `destructive`, for
  consequential-but-not-destructive actions (e.g. an ownership transfer). Each
  variant's resting tokens and the hover/active tokens layered on top of them:

  | Variant | Resting tokens | Hover / active tokens |
  |---|---|---|
  | `default` | `bg-primary text-primary-foreground` | `hover:bg-primary-bright` |
  | `outline` | `border-input bg-input/30` | `hover:bg-input/50 hover:text-foreground`, `aria-expanded:bg-muted aria-expanded:text-foreground` |
  | `secondary` | `bg-secondary text-secondary-foreground` | `hover:bg-secondary/80`, `aria-expanded:bg-secondary aria-expanded:text-secondary-foreground` |
  | `ghost` | (transparent) | `hover:bg-muted/50 hover:text-foreground`, `aria-expanded:bg-muted aria-expanded:text-foreground` |
  | `destructive` | `bg-destructive/15 text-destructive` | `hover:bg-destructive/25`, `focus-visible:border-destructive/40 focus-visible:ring-destructive/40` |
  | `warning` | `bg-apt-orange/15 text-apt-orange` | `hover:bg-apt-orange/25`, `focus-visible:border-apt-orange/40 focus-visible:ring-apt-orange/40` |
  | `destructive-ghost` | `text-destructive` | `hover:bg-destructive/10 hover:text-destructive`, `aria-expanded:bg-destructive/10 focus-visible:border-destructive/40 focus-visible:ring-destructive/40` |
  | `link` | `text-primary underline-offset-4` | `hover:underline` |

- Sizes: `xs`, `sm`, `default`, `lg`, plus `icon`/`icon-xs`/`icon-sm`/`icon-lg`,
  mapped to their height/width utility:

  | `size` | Utility | Rendered dimension |
  |---|---|---|
  | `xs` | `h-6` | 24px tall |
  | `sm` | `h-7` | 28px tall |
  | `default` | `h-8` | 32px tall |
  | `lg` | `h-9` | 36px tall |
  | `icon-xs` | `size-6` | 24×24px |
  | `icon-sm` | `size-7` | 28×28px |
  | `icon` | `size-8` | 32×32px |
  | `icon-lg` | `size-9` | 36×36px |
- Pressed: `data-[pressed]:not-aria-[haspopup]:translate-y-px` plus
  `data-[pressed]:not-aria-[haspopup]:brightness-95`.
- Min/Max size: `min-height: var(--adh-button-min-height, 0px)` and
  `min-width: var(--adh-button-min-width, 0px)` — both default to `0px`, so the
  button's rendered height/width comes solely from its `size` variant's fixed
  `h-*`/`size-*` utility unless an ancestor sets one or both variables. The
  `icon*` sizes redefine `--adh-button-min-width` to `var(--adh-button-min-height,0px)`
  rather than emitting a second `min-w-*` utility, because `buttonVariants` is
  also called bare (no `cn`/tailwind-merge pass) where two competing arbitrary
  `min-width` utilities would be resolved by unpredictable CSS source order.
- Icon SVGs: `pointer-events-none`, `shrink-0`; an SVG with no `size-*` class
  gets `size-4` (1rem) by default, `size-3.5` (0.875rem) at `sm`, `size-3`
  (0.75rem) at `xs`/`icon-xs`.
- No raw hex; no `!important`.

## States

| State | Appearance change |
|---|---|
| Idle | the resting variant appearance |
| Hover | variant hover treatment (e.g. `hover:bg-primary-bright`) |
| Focus-visible | focus ring (`ring-3 ring-ring/50`, `border-ring`) |
| Pressed (pointer held inside) | `data-pressed` set → dips `translate-y-px` + `brightness-95` |
| Held but pointer left | `data-pressed` cleared → returns to the resting look while still armed |
| Disabled | `pointer-events-none`, `opacity-50` |
| Invalid (`aria-invalid`) | destructive border + ring |
| Popup trigger (`aria-haspopup`) | no pressed dip even while held |

## Accessibility

- Renders a real, focusable `<button>` (Base UI primitive); keyboard activation
  (Space/Enter) works natively and is independent of the pointer pressed visual.
- The button has no built-in accessible name of its own — the label comes from
  whatever the consumer passes as `children` (text or an icon plus visually
  hidden text) or an explicit `aria-label`/`aria-labelledby` forwarded through
  `...props`; an icon-only button with no such label renders with no accessible name.
- The pressed state is a purely visual affordance via `data-pressed`; it adds no
  ARIA semantics and never overrides `aria-pressed`/`aria-expanded` a consumer sets.
- Focus is shown with a visible `focus-visible` ring built from theme tokens.
- Disabled and invalid states map to the native `disabled`/`aria-invalid`
  attributes, which assistive technology announces natively.
- Minimum tap target: the fixed size-variant heights (`h-6`=24px, `h-7`=28px,
  `h-8`=32px, `h-9`=36px; `size-6`/`size-7`/`size-8`/`size-9` for icon sizes) are
  all below the Apple HIG 44×44pt and Material 48×48dp minimum touch-target
  guidance by default — the component does NOT guarantee an accessible tap
  target on its own. A surface MUST opt in to a larger floor by setting
  `--adh-button-min-height` and/or `--adh-button-min-width` (both default
  `0px`) on an ancestor when the context requires it (per
  [adc.guideline.cookbook.ui.platform-design-languages](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f26a9468-a15c-4cd2-b944-d39221e7eee2)).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | press-on-pointerdown-inside | `pointerdown` on the button | `data-pressed` present |
| T2 | release-clears-pressed | `pointerdown` then `pointerup` | `data-pressed` absent |
| T3 | leave-while-held-clears-pressed | `pointerdown` then `pointerleave` | `data-pressed` absent |
| T4 | reenter-while-held-restores-pressed | after T3, `pointerenter` (still held) | `data-pressed` present |
| T5 | forwards-consumer-pointer-handlers | `pointerdown` with `onPointerDown` prop | consumer handler called once AND `data-pressed` present |
| T6 | release-outside-ends-hold | `pointerdown`, `pointerleave`, window `pointerup` | hold ends; a later `pointerenter` does NOT re-press |
| T7 | keyboard-activates (Playwright) | focus, press Enter/Space | click fires; no pointer dip |
| T8 | haspopup-suppresses-dip (Playwright) | `pointerdown` on `aria-haspopup` button | no `translate-y-px` dip |
| T9 | cancel-clears-pressed | `pointerdown` then `pointercancel` | `data-pressed` absent |
| T10 | no-pointer-capture | `pointerdown` on the button | `element.hasPointerCapture(pointerId)` is `false` throughout |
| T11 | stable-public-api | render `<Button variant="secondary" size="lg" data-testid="b"/>` | root node has `data-slot="button"`; no runtime error |
| T12 | supports-eight-variants, warning-variant-uses-warning-role | render `<Button variant="warning">` | class list includes `bg-apt-orange/15` and `text-apt-orange` |
| T13 | defaults-to-default-variant-and-size | render `<Button/>` with no props | class list includes `bg-primary` and `h-8` |
| T14 | respects-ancestor-min-height-var | render `<Button size="sm"/>` under an ancestor with `style="--adh-button-min-height:44px"` | computed `min-height` is `44px` |
| T15 | icon-sizes-square-to-height-floor, respects-ancestor-min-width-var | render `<Button size="icon"/>` under an ancestor with `style="--adh-button-min-height:44px"` | computed `min-width` is `44px` |
| T16 | icon-svgs-non-interactive | render `<Button><svg data-testid="icon"/></Button>` | svg computed `pointer-events` is `none`; computed `flex-shrink` is `0` |
| T17 | unsized-icon-svgs-scale-with-button-size | render default-size `<Button><svg data-testid="icon"/></Button>` (svg has no `size-*` class) | svg renders at 16×16px |
| T18 | consumer-classname-precedence | render `<Button className="bg-brand-500"/>` | class list includes `bg-brand-500`; class list does not include `bg-primary` |
| T19 | respects-ancestor-min-width-var | render `<Button size="default"/>` (non-icon) under an ancestor with `style="--adh-button-min-width:120px"` | computed `min-width` is `120px` |
| T20 | pressed-visual-from-data-attr | render `<Button/>`, trigger native `:active` (e.g. `mousedown` without a `pointerdown` event reaching the pressed-tracking handler) without `data-pressed` being set | class list does not include `translate-y-px`/`brightness-95`; computed `transform` shows no dip |
| T21 | unsized-icon-svgs-scale-with-button-size | render `size="sm"` `<Button><svg data-testid="icon"/></Button>` (svg has no `size-*` class) | svg renders at 14×14px |
| T22 | unsized-icon-svgs-scale-with-button-size | render `size="xs"` (and separately `size="icon-xs"`) `<Button><svg data-testid="icon"/></Button>` (svg has no `size-*` class) | svg renders at 12×12px |

## Edge Cases

- Release outside the button: a window `pointerup`/`pointercancel` listener
  (attached only while held) ends the hold, so the press never sticks after the
  pointer is released off the button. (MUST — T6.)
- Popup/menu triggers (`aria-haspopup`) deliberately skip the dip so opening a
  menu doesn't look like a press. (MUST — T8.)
- Keyboard activation never sets `data-pressed` — the pressed look is pointer-only. (MUST — T7.)
- A consumer's own pointer handler is composed, not replaced. (MUST — T5.)
- `disabled` buttons receive no pointer events (`pointer-events-none`), so they
  never enter the pressed state. (MUST.)
- No ancestor sets `--adh-button-min-height`/`--adh-button-min-width`: both
  default to `0px`, which imposes no floor beyond the size variant's own fixed
  `h-*`/`size-*` height/width — the button is exactly as large as its size
  variant, no larger. (MUST.)
- An icon-size button (`icon`/`icon-xs`/`icon-sm`/`icon-lg`) whose ancestor
  raises only `--adh-button-min-height`: `--adh-button-min-width` follows it
  automatically, so the button stays square without the ancestor also setting
  a width variable. (MUST — T15.)
- An SVG child that already carries an explicit `size-*` class: the
  `:not([class*='size-'])` selector excludes it from the default icon sizing
  rule, so the button MUST NOT override an explicitly sized icon.
- **Null and empty input**: `children` may be omitted or empty; the Base UI
  primitive MUST NOT throw and renders with no visible label (see
  Accessibility for the resulting accessible-name gap). `variant`/`size`
  omitted resolve to the `default`/`default` `cva` defaults (MUST — T13).
  `className` omitted is a no-op in the `cn()` merge.
- **Boundary values**: not applicable in the numeric sense — `variant` and
  `size` are fixed string enumerations, not numeric ranges. A value outside
  the `VariantProps<typeof buttonVariants>` union is a TypeScript compile-time
  error, not a runtime boundary condition.
- **Concurrent access**: not applicable — the button is a single, synchronously
  rendered DOM element with no state shared across sessions, tabs, or threads;
  the pressed-tracking state is local to one `PressableButton` instance.
- **Error states**: not applicable — the button has no network, database, or
  file-system dependency; it renders synchronously from its props.
- **Offline or disconnected state**: not applicable — the button performs no
  network operation of its own.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `variant` | `"default" \| "outline" \| "secondary" \| "ghost" \| "destructive" \| "warning" \| "destructive-ghost" \| "link"` | `"default"` | Visual style. |
| `size` | `"xs" \| "sm" \| "default" \| "lg" \| "icon" \| "icon-xs" \| "icon-sm" \| "icon-lg"` | `"default"` | Size/shape. |
| `className` | `string` | — | Extra classes merged via `cn()`. |
| `disabled` | `boolean` | `false` | Disables the button. |
| `...props` | `Base UI Button.Props` | — | All native button props (incl. `onClick`, pointer handlers, `aria-*`, `render`) are forwarded. |

`buttonVariants({ variant, size, className })` is also exported for styling a
non-button trigger (e.g. a `<Link>`); it stays server-callable.

## Deep Linking

Not applicable: Button is a UI primitive without its own route or navigation target.

## Localization

Not applicable: Button renders consumer-provided text or icons; no built-in strings to localize.

## Accessibility Options

Not applicable: Button responds to theme tokens that may reflect platform accessibility settings, but the component itself does not directly implement WCAG Rule 15 display options (Reduce Motion, Increase Contrast, Differentiate Without Color).

## Feature Flags

Not applicable: Button is a shared UI primitive rendered everywhere; feature flagging belongs to higher-level features that may conditionally render it.

## Analytics

Not applicable: Button emits no analytics events; click tracking and interaction telemetry belong to the consumer's `onClick` handler or parent component, not the primitive.

## Privacy

- **Data collected**: None. The component receives only rendering props
  (`variant`, `size`, `className`, forwarded native button props) and pointer
  events used solely to toggle a local `data-pressed` attribute.
- **Storage**: None. No state is persisted; pressed tracking is transient
  render state that disappears on unmount.
- **Transmission**: None. The component makes no network calls and sends no
  data anywhere.
- **Retention**: Not applicable — nothing is stored.

## Logging

No logging. Button is a presentational primitive; click semantics and any
telemetry belong to the consumer's handler, not the button.

## Platform Notes

- **SwiftUI**: Start from `Button` with a custom `ButtonStyle`/`PrimitiveButtonStyle`
  per `variant` — SwiftUI's `ButtonStyleConfiguration.isPressed` already reflects
  the real press state natively, so unlike the web the pressed-tracking hooks in
  `button-pressable.tsx` have no equivalent to port; map `size` to explicit
  `frame(minWidth:minHeight:)` values as the counterpart to
  `--adh-button-min-width`/`--adh-button-min-height`.
- **Compose**: Start from `Button`/`OutlinedButton`/`TextButton` per `variant`,
  reading press state from a `MutableInteractionSource`'s `PressInteraction`
  (native, unlike the DOM pointer tracking this component hand-rolls); use
  `Modifier.defaultMinSize()`, set from a `CompositionLocal`, as the counterpart
  to the CSS custom-property floor.
- **React/Web**: This recipe's home platform — `button.tsx` (variants,
  server-safe) plus `button-pressable.tsx` (`"use client"` pointer tracking),
  as documented above.
- **AppKit / UIKit**: Start from `NSButton`/`UIButton`. `UIControl` already
  tracks touch-down/drag-exit/drag-enter natively, so the
  leave-while-held/reenter-while-held semantics this component re-implements
  for the DOM map directly to `.touchDragExit`/`.touchDragEnter` instead of
  custom pointer-event listeners. The 44×44pt Apple HIG minimum this recipe's
  `--adh-button-min-height`/`--adh-button-min-width` vars exist to opt into on
  the web is the default expectation here.
- **WinUI 3**: Start from the `Button` control restyled via a `Style`/
  `ControlTemplate`; Fluent 2's `CommonStates` `VisualStateGroup` already models
  `Pressed`/`PointerOver`/`Normal` (and pointer-exit reverting to `Normal`)
  through the `VisualStateManager`, so the `PointerPressed`/`PointerReleased`/
  `PointerExited`/`PointerEntered` handlers only need to drive state transitions,
  not hand-track a `data-pressed`-equivalent attribute the way `button-pressable.tsx`
  does for the DOM. Fluent 2's control sizing tokens differ from this component's
  Tailwind height scale (`h-6`/`h-7`/`h-8`/`h-9`), so a Windows implementation
  MUST re-derive its size scale from Fluent 2 tokens rather than copying the
  pixel values.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/button.tsx` | unverified |

## Design Decisions

**Decision**: Split the client boundary; keep `buttonVariants` server-safe.
**Rationale**: The pressed state needs React hooks, but `buttonVariants` must remain a plain server-callable function. So the stateful interactivity lives in a sibling `"use client"` `PressableButton`, and `button.tsx` stays a non-client module that re-exports the variants and renders the client layer.
**Approved**: pending

**Decision**: Drive the pressed visual from `data-pressed`, not CSS `:active`.
**Rationale**: CSS `:active` does not clear when the pointer leaves a held button, so it cannot express "released visual while still armed." Tracking held + pointer-inside in JS and reflecting it via `data-pressed` gives the precise behavior, and matches the `data-[pressed]` token pattern already used elsewhere in the library.
**Approved**: pending

**Decision**: Never call `setPointerCapture`.
**Rationale**: Capture would re-target subsequent pointer events to the button and defeat the leave/re-enter detection; tracking held state plus a window release listener is simpler and reversible.
**Approved**: pending

**Decision**: Keep press feedback subtle and token-only.
**Rationale**: The dip (`translate-y-px`) is kept and a `brightness-95` darken added — variant-agnostic and free of color literals, so it reads as pressed on every variant without per-variant color rules.
**Approved**: pending

**Decision**: `warning` reuses the M3 warning role instead of minting a new alias.
**Rationale**: The variant reads the `apt-orange` role that every theme already defines (exposed by `@adh-sdk/themes`), rather than minting a second color alias — it needs no new token and no per-theme work.
**Approved**: pending

**Decision**: Make the minimum size ancestor-settable instead of prop-drilled.
**Rationale**: `--adh-button-min-height` and `--adh-button-min-width` default to `0px`, so nothing changes anywhere until an ancestor sets them; a surface that needs a bigger hit target (`button.tsx`'s own comments cite shipr's dialogs, where the buttons were reported as too small) sets the pair once on itself and every descendant button grows, whatever its `size` — including buttons nested components render that the surface never names. The alternative was passing `size="lg"` down through every dialog and button bar, which is the same decision made in a hundred places and is why it drifted in the first place. The tradeoff, documented honestly in Accessibility above: the default floor is `0px`, so none of the fixed size variants meet the 44×44pt/48×48dp guidance on their own — a surface MUST opt in.
**Approved**: pending

**Decision**: `icon*` sizes redefine `--adh-button-min-width` rather than emitting a second utility.
**Rationale**: Redefining the variable to the height var (rather than emitting a second `min-w-*` utility) matters because `buttonVariants` is also called bare (`<Link className={buttonVariants()}/>`), where no tailwind-merge runs to resolve two conflicting arbitrary `min-width` utilities — which one would win there is decided by CSS source order, i.e. by nothing anyone can see from the call site.
**Approved**: pending

**Decision**: Make `className` merge precedence a SHOULD, not a MUST.
**Rationale**: `buttonVariants({ variant, size, className })` passes the consumer's `className` through `cva`/`cn`, which is the project's general override convention rather than a rule specific to this component; a valid deviation would be a call site that intentionally does not want overridable classes, which is why it is a SHOULD.
**Approved**: pending

**Decision**: Document the `--adh-button-min-*` / `apt-orange` prefix mismatch as-is rather than normalizing it.
**Rationale**: `--adh-button-min-height`/`--adh-button-min-width` and the `apt-orange` warning-role token both belong to the `@adh-sdk` package family, but use different abbreviated prefixes (`adh` vs `apt`). Reconciling the two is a source-code naming change outside the scope of this recipe pass, so the recipe records the tokens exactly as `button.tsx` and the theme package expose them.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Statuses rest on the source as documented above: `keyboard-activates` and the native Base UI `<button>` (T7) ground `keyboard-navigable`; the Accessibility section's accessible-name gap (label comes from consumer `children`/`aria-label`, absent for an unlabeled icon-only button) grounds `screen-reader-support` as partial; the shadcn theme tokens used throughout Appearance (no raw hex) ground `contrast-ratio` as partial, since the tokens' actual contrast values are defined outside this component; the Accessibility section's explicit statement that the fixed size-variant heights fall below the 44×44pt/48×48dp guidance by default grounds `touch-target-size` as failed; `disabled`/`aria-invalid`/`aria-haspopup` mapping to native attributes grounds `semantic-markup` as passed; and the Localization section's "no built-in strings to localize" grounds both internationalization checks as passed. Security, Privacy and Data, and User Safety are omitted: the component collects no data, makes no network calls, produces no logs, and renders no links (see Privacy and Logging above). `separation-of-concerns` passes: server-safe styling (`buttonVariants`) is split from the client-only pointer/press behavior, which itself lives in the sibling `PressableButton` rather than `button.tsx` (see the Provenance note above). `unit-test-coverage` is partial — `button.test.tsx` covers pointerdown/pointerup, leave-while-held/re-enter, and handler forwarding, but not `pointercancel`, the window-wide release, `no-pointer-capture`, `haspopup-suppresses-dip`, or keyboard activation.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial recipe; documents the pointer-driven pressed state added to the shared Button. |
| 1.1.0 | 2026-07-03 | Mike Fullerton | Add the `destructive-ghost` variant (seven total) and fix the `default` hover to `hover:bg-primary-bright`, matching `button.tsx`. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Add the `warning` variant (eight total) and the ancestor-settable `--adh-button-min-height`/`--adh-button-min-width` touch-target floor; document icon SVG auto-sizing; restore the Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics, and Privacy sections required by the template; fix `domain` to the `agenticdevelopercookbook://` scheme; expand Conformance Test Vectors and Edge Cases to cover every MUST/SHOULD requirement and the five completeness categories. |
| 1.3.0 | 2026-09-22 | Mike Fullerton | Complete Deep Linking, Localization, Accessibility Options, Feature Flags, and Analytics sections as not applicable per source fidelity; set status to review. |
| 1.4.0 | 2026-09-22 | Mike Fullerton | Lint pass: moved the `references` entry to `related`; rewrote Compliance as a link/status/category table against the real catalog; reformatted Design Decisions into Decision/Rationale/Approved triples and relocated the pointer-tracking provenance caveat inline above Behavioral Requirements; renamed `should-preserve-consumer-classname-precedence` to `consumer-classname-precedence` everywhere it's cited; added a size-to-utility table and a per-variant hover/active token table; made T18's expectation a concrete class-list assertion and added test vectors for a non-icon min-width floor, `:active`-absence, and sm/xs icon scaling; named `button.tsx` as the source of the shipr's-dialogs citation and dropped the uncitable "~40-site" figure; documented the `adh`/`apt` token-prefix mismatch as a Design Decision. |
| 1.4.1 | 2026-09-25 | Mike Fullerton | Linked to button-pressable.md as pointer-contract owner; provenance note no longer a stale hedge. |
