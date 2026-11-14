---
id: b3a92adc-a28e-4a33-8120-c33f8f0abdf6
title: "Progress"
type: ingredient
version: 1.2.1
status: review
language: en
created: 2026-07-03
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Two progress bars: a determinate, tintable UI track clamped to 0–100, and a labeled, indeterminate-capable Controls form-field progress bar."
platforms:
  - typescript
  - web
tags:
  - component
  - progress
  - feedback
  - ui
depends-on: []
related:
  - d9b07d1e-b53c-4efa-86f1-82a31ad9f02f
references: []
approved-by: ""
approved-date: ""
---

# Progress

## Overview

This recipe covers two independent components that cookr's name-only grouping merges
under one "progress" row, because they share no source and no API:

- **UI** (`Progress`, source: `packages/web/packages/ui/src/components/progress.tsx`):
  a self-contained determinate progress bar exported from `@adh-sdk/ui`.
- **Controls** (`Progress`/`ProgressProps`, source:
  `packages/web/packages/controls/src/user-settings/components/Progress.tsx`): a labeled,
  indeterminate-capable form-field control exported from
  `@adh-sdk/controls`'s `user-settings` module.

Every requirement, appearance note, configuration option, and test vector below is tagged
with the component (UI or Controls) it describes.

**UI**: a determinate progress bar rendered as a rounded track with an indicator filled to
`value` (a percentage, 0–100). It is a self-contained accessible element
(`role="progressbar"` carrying `aria-valuenow`/`aria-valuemin`/`aria-valuemax`) rather than a
wrapper around a primitive, so it needs no extra runtime dependency.

The fill is a full-width indicator translated horizontally so that a `value` of 0
hides it entirely (`translateX(-100%)`) and a `value` of 100 reveals it fully
(`translateX(-0%)`); the transform animates smoothly. The track uses the
`apt-surface-2` token and the fill defaults to `apt-gold`, but the fill is meant to
be re-tinted per context via `indicatorClassName` — e.g. amber while a job is
building, green once it completes.

A single export ships from `@adh-sdk/ui/components/progress`: the `Progress`
component. It carries `"use client"` (it renders an inline `style` transform) but
holds no internal state — `value` is fully controlled by the consumer.

**Controls**: a labeled form-field control — an `aws-field aws-field--progress` wrapper
around an optional `label`, the `role="progressbar"` track (`aws-progress`/
`aws-progress__bar`), and an optional `hint`. Unlike the UI bar, it supports an
`indeterminate` mode and a configurable `max`, but it does not clamp or round the value
it reports, does not forward arbitrary props, and has no `indicatorClassName` equivalent.
It ships from `@adh-sdk/controls`'s `user-settings` entry point alongside
the package's other settings-panel form controls.

## Behavioral Requirements

- **renders-progressbar-role** (UI, Controls): The component MUST render an element with `role="progressbar"`.
- **reflects-value-in-valuenow** (UI): The component MUST expose the current percentage as `aria-valuenow`, rounded to an integer.
- **fixed-value-bounds** (UI): The component MUST report `aria-valuemin` as 0 and `aria-valuemax` as 100.
- **clamps-below-zero** (UI): Given a `value` below 0, the component MUST clamp it to 0 and render an empty fill.
- **clamps-above-hundred** (UI): Given a `value` above 100, the component MUST clamp it to 100 and render a full fill.
- **defaults-to-zero** (UI): With no `value` prop, the component MUST render at 0 with an empty fill.
- **fill-tracks-value** (UI): The component MUST size the visible fill proportionally to the clamped value, from empty at 0 to full at 100, by translating a full-width indicator horizontally.
- **indicator-class-tints-fill** (UI): The component MUST apply any `indicatorClassName` to the fill element so a consumer MAY override its color.
- **forwards-track-props** (UI): The component MUST forward arbitrary props (`className`, `aria-label`, `id`, `data-*`) onto the track element.
- **requires-accessible-name** (UI): The consumer MUST supply an accessible name (`aria-label` or `aria-labelledby`) via the forwarded track props; an unnamed `progressbar` fails WCAG 4.1.2 (Name, Role, Value).
- **pairs-tint-with-text-status** (UI): When a consumer uses `indicatorClassName` to encode semantic status (e.g., amber while building, green once complete), the consumer MUST also convey that status via text or `aria-valuetext`, forwarded through the track props, rather than via color alone.
- **honors-shared-reduce-motion** (UI): The fill's transition MUST be expressed as an ordinary class-based `transition`/`duration` utility, never an inline `style` or `!important` override, so the shared `accessibility.css` reduce-motion rule (`html[data-reduce-motion="on"] *`, or the `prefers-reduced-motion` media query when the setting is "auto") can zero its duration without any change to this component.
- **valuemin-fixed-valuemax-configurable** (Controls): The component MUST report `aria-valuemin` as 0 and `aria-valuemax` as the `max` prop (default 100), unlike the UI bar's fixed 0–100 bounds.
- **reports-raw-valuenow** (Controls): Unless `indeterminate` or `value` is `undefined`, the component MUST expose `value` verbatim as `aria-valuenow` — not clamped to the 0–`max` range and not rounded, unlike the UI bar's **clamps-below-zero**/**clamps-above-hundred**/**reflects-value-in-valuenow**.
- **omits-valuenow-without-value** (Controls): With no `value` prop and `indeterminate` not set, the component MUST omit `aria-valuenow` entirely, rather than defaulting it to 0 the way the UI bar's **defaults-to-zero** does.
- **clamps-fill-width-only** (Controls): The component MUST clamp the fill's visual width to the 0–100% range (via `value / max`) even when the value it reports through `aria-valuenow` is out of range or non-numeric-looking.
- **indeterminate-mode** (Controls): The component MUST accept an `indeterminate` boolean prop; when true, it MUST apply the `aws-field--progress-indeterminate` modifier class, omit `aria-valuenow`, and drive the fill's position from the CSS keyframe animation instead of an inline `width` style.
- **accepts-label** (Controls): The component MUST conditionally render an `aws-field__label` element when the `label` prop is provided.
- **accepts-hint** (Controls): The component MUST conditionally render an `aws-field__hint` paragraph when the `hint` prop is provided.
- **custom-wrapper-classname** (Controls): The component MUST append any `className` prop to the wrapper's fixed `aws-field aws-field--progress[ aws-field--progress-indeterminate]` class list.

## Appearance

```
value = 0        ├───────────────────────────────┤   (empty track)
value = 35       ██████████·······················    (gold fill, 35%)
value = 100      ███████████████████████████████     (full fill)
```

- Track: `relative h-2 w-full overflow-hidden rounded-full bg-apt-surface-2`; extra
  classes merge via `cn()` through `className`.
- Indicator: `h-full w-full rounded-full bg-apt-gold` with
  `transition-transform duration-[calc(300ms*var(--apt-anim-scale,1))] ease-out`
  (a nominal 300ms, scaled by the shared dev-only slow-motion switch); positioned
  by an inline `transform: translateX(-{100 - pct}%)`.
- Fill color is token-based (`apt-gold` by default) and overridable through
  `indicatorClassName` (e.g. `bg-apt-green` for complete).
- No raw hex; no `!important`.

**Controls**:

- Wrapper: `aws-field aws-field--progress` div; gains `aws-field--progress-indeterminate`
  while `indeterminate` is true.
- Label: `aws-field__label` div, rendered above the track when `label` is provided.
- Track: `aws-progress` div — height `0.5rem`, `--aws-surface` background, `1px`
  `--aws-border-subtle` border, fully rounded, `overflow: hidden`.
- Fill: `aws-progress__bar` div — height `100%`, `--aws-accent` background, `width`
  transition `120ms`; width set inline as a percentage while determinate.
- Indeterminate animation: the fill's width is fixed at `35%` and slides via the
  `aws-progress-indeterminate` keyframe (`translateX(-100%)` to `translateX(285%)`) over
  `1.2s linear infinite`, rather than resizing.
- Hint: `aws-field__hint` paragraph, rendered below the track when `hint` is provided.

## States

| State | Appearance change |
|---|---|
| Empty (`value` ≤ 0) | Indicator fully translated out (`translateX(-100%)`); `aria-valuenow` = 0 |
| Partial (0 < `value` < 100) | Indicator revealed proportionally; `aria-valuenow` = rounded value |
| Full (`value` ≥ 100) | Indicator fully revealed (`translateX(-0%)`); `aria-valuenow` = 100 |
| Transitioning | Fill animates between positions via `transition-transform` (300ms ease-out) |
| Tinted (`indicatorClassName`) | Fill color overridden (e.g. amber while building, green when done) |
| Indeterminate (Controls, `indeterminate` prop) | Fill width fixed at 35%, sliding continuously via the `aws-progress-indeterminate` keyframe; `aria-valuenow` omitted |

## Accessibility

**UI**:

- Renders `role="progressbar"` with `aria-valuemin` 0, `aria-valuemax` 100, and
  `aria-valuenow` set to the rounded, clamped percentage — so assistive technology
  announces determinate progress.
- It is a determinate bar only; there is no indeterminate mode (see the Controls
  component below for the toolkit's indeterminate progress control).
- The component carries no built-in visible or accessible label. Consumers MUST
  pass an `aria-label` (or `aria-labelledby`) — the demo labels each bar
  ("Build progress", "Complete") — since an unnamed `progressbar` fails WCAG
  4.1.2 (Name, Role, Value); see **requires-accessible-name** and T8.
- Purely presentational otherwise: not focusable and not interactive; progress is
  driven by the consumer's `value`.

**Controls**:

- Renders `role="progressbar"` with `aria-valuemin` 0 and `aria-valuemax` set to `max`;
  `aria-valuenow` is the raw, unrounded `value` (or omitted when `indeterminate` or when
  `value` is `undefined`) — see **reports-raw-valuenow** and **omits-valuenow-without-value**.
- Does support an indeterminate mode (the `indeterminate` prop); see
  **indeterminate-mode** and States.
- The optional `label` renders as a plain `aws-field__label` div with no
  `id`/`aria-labelledby` pairing to the `role="progressbar"` element, so it is not
  programmatically associated with the progress bar the way the UI bar's forwarded
  `aria-label` is. A screen reader announces this component's progress bar with no
  accessible name unless a consumer supplies one out of band.
- Purely presentational otherwise: not focusable and not interactive; progress is driven
  by the consumer's `value`.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | renders-progressbar-role, fixed-value-bounds | UI: render `<Progress value={35} />` | element has `role="progressbar"`, `aria-valuemin="0"`, `aria-valuemax="100"` |
| T2 | reflects-value-in-valuenow, fill-tracks-value | UI: `value={35}` | `aria-valuenow="35"`; indicator transform `translateX(-65%)` |
| T3 | defaults-to-zero | UI: render `<Progress />` (no `value`) | `aria-valuenow="0"`; indicator transform `translateX(-100%)` |
| T4 | clamps-below-zero | UI: `value={-40}` | `aria-valuenow="0"`; transform `translateX(-100%)` |
| T5 | clamps-above-hundred | UI: `value={140}` | `aria-valuenow="100"`; transform `translateX(-0%)` |
| T6 | reflects-value-in-valuenow | UI: `value={35.6}` | `aria-valuenow="36"` (rounded) |
| T7 | indicator-class-tints-fill | UI: `value={100} indicatorClassName="bg-apt-green"` | fill element carries `bg-apt-green` and NOT `bg-apt-gold` (`cn()` runs `tailwind-merge`, which drops the conflicting `bg-*` utility) |
| T8 | forwards-track-props, requires-accessible-name | UI: `aria-label="Sync" id="p1"` | track element carries `aria-label="Sync"` and `id="p1"` |
| T9 | honors-shared-reduce-motion | UI: render `<Progress value={35} />` under `html[data-reduce-motion="on"]` | computed `transition-duration` on the indicator resolves to `0.001ms` (the shared `accessibility.css` override), superseding the nominal `calc(300ms*var(--apt-anim-scale,1))` duration |
| T10 | clamps-below-zero, clamps-above-hundred (see **non-finite-value-handling** under Edge Cases) | UI: `value={NaN}` | `aria-valuenow="NaN"`; transform `translateX(-NaN%)` — `Math.min`/`Math.max` return `NaN` when either operand is `NaN`, so this one non-finite value passes through unclamped |
| T11 | pairs-tint-with-text-status | UI: `value={100} indicatorClassName="bg-apt-green" aria-valuetext="Complete"` | fill element carries `bg-apt-green`; track element carries `aria-valuetext="Complete"`, conveying the status alongside the color tint rather than through color alone |
| T12 | clamps-above-hundred (see **non-finite-value-handling** under Edge Cases) | UI: `value={Infinity}` | `aria-valuenow="100"`; transform `translateX(-0%)` — identical to T5; `Math.min`/`Math.max` treat `Infinity` as an ordinary large number |
| T13 | clamps-below-zero (see **non-finite-value-handling** under Edge Cases) | UI: `value={-Infinity}` | `aria-valuenow="0"`; transform `translateX(-100%)` — identical to T4 |
| T14 | accepts-label, accepts-hint | Controls: `<Progress label="Sync" hint="Uploading" value={40} />` | wrapper renders an `aws-field__label` reading "Sync" and an `aws-field__hint` reading "Uploading"; progressbar has `aria-valuenow="40"` |
| T15 | valuemin-fixed-valuemax-configurable | Controls: `<Progress value={5} max={10} />` | `aria-valuemin="0"`, `aria-valuemax="10"`; fill width `50%` |
| T16 | reports-raw-valuenow, clamps-fill-width-only | Controls: `<Progress value={-40} />` | `aria-valuenow="-40"` (not clamped); fill width `0%` (width clamped to the 0–100% range) |
| T17 | reports-raw-valuenow, clamps-fill-width-only | Controls: `<Progress value={140} max={100} />` | `aria-valuenow="140"` (not clamped); fill width `100%` (width clamped) |
| T18 | reports-raw-valuenow | Controls: `<Progress value={35.6} />` | `aria-valuenow="35.6"` (not rounded, unlike the UI bar's T6) |
| T19 | omits-valuenow-without-value | Controls: render `<Progress />` (no `value`) | `aria-valuenow` is omitted entirely (unlike the UI bar's T3, which defaults to `"0"`); fill width `0%` |
| T20 | indeterminate-mode | Controls: `<Progress indeterminate />` | wrapper carries `aws-field--progress-indeterminate`; `aria-valuenow` omitted; fill element has no inline `width` style |

## Edge Cases

- `value` below 0 or above 100 is clamped, never overflowing the track; `aria-valuenow`
  reflects the clamped value. (UI)
- Omitting `value` renders an empty (0%) bar rather than erroring. (UI)
- Fractional values are allowed for the fill width, but `aria-valuenow` is rounded to
  an integer, so `35.6` announces as `36`. (UI)
- There is no indeterminate state in the UI bar — a value is always supplied, defaulting
  to 0. The Controls component below does have an indeterminate mode.
- `indicatorClassName` that also sets a background token overrides the default gold
  fill; a class that only tweaks other properties leaves the gold in place. (UI)
- **non-finite-value-handling** (UI) — `Math.min`/`Math.max` treat `±Infinity` as
  ordinary numbers, so `value={Infinity}` clamps to 100 and `value={-Infinity}` clamps
  to 0 exactly like any other out-of-range finite value (T12, T13) —
  **clamps-below-zero**/**clamps-above-hundred** hold for both. Only `value={NaN}`
  escapes the clamp, because `Math.min`/`Math.max` return `NaN` whenever either operand
  is `NaN`: `aria-valuenow` becomes the literal string `"NaN"` and the fill's `transform`
  becomes `translateX(-NaN%)` (T10). `-NaN%` is not a valid CSS `<length-percentage>`
  token, so a browser drops that declaration; the fill keeps its default (untransformed,
  full-width) layout and paints as a full bar while `aria-valuenow` announces `NaN` to
  assistive technology.
- The Controls `Progress` does not clamp or round `aria-valuenow` the way the UI bar
  does: it reports the raw `value` prop verbatim (negative, over-`max`, or fractional),
  while only the fill's *width* is clamped to the 0–100% range via
  `Math.max(0, Math.min(100, ...))`. So `value={-40}` reports `aria-valuenow="-40"` with
  an empty (`0%`) fill, and `value={140} max={100}` reports `aria-valuenow="140"` with a
  full (`100%`) fill (T16, T17).
- With no `value` and `indeterminate` false, the Controls `Progress` omits
  `aria-valuenow` entirely (unlike the UI bar's **defaults-to-zero**), because its `pct`
  expression short-circuits to `undefined` when `value` is `undefined` (T19).
- The Controls `Progress`'s visible `label` is not programmatically associated with its
  `role="progressbar"` element (no `aria-labelledby`/`id` pairing) — see Accessibility.
- The Controls `Progress`'s indeterminate animation (`aws-progress-indeterminate`) is a
  plain CSS `@keyframes` rule with no `prefers-reduced-motion`/reduce-motion guard in
  `user-settings/styles.css`, unlike the UI bar's **honors-shared-reduce-motion**.

## Configuration

**UI**:

| Option | Type | Default | Description |
|---|---|---|---|
| `value` | `number` | `0` | Percentage complete, 0–100; clamped to that range. |
| `indicatorClassName` | `string` | — | Extra classes for the fill element (e.g. `bg-apt-green`); merged via `cn()`. |
| `className` | `string` | — | Extra classes for the track element; merged via `cn()`. |
| `...props` | `React.ComponentProps<"div">` | — | Any native div props (incl. `aria-label`, `id`, `data-*`) are forwarded onto the track. |

**Controls**:

| Option | Type | Default | Description |
|---|---|---|---|
| `label` | `ReactNode` | — | Optional label rendered above the track in an `aws-field__label` div. |
| `hint` | `ReactNode` | — | Optional hint text rendered below the track in an `aws-field__hint` paragraph. |
| `value` | `number` | — | Raw progress value; reported verbatim as `aria-valuenow` (not clamped or rounded) and used to compute the clamped fill width. Omitted from `aria-valuenow` when `undefined` or when `indeterminate`. |
| `max` | `number` | `100` | Upper bound used for the fill-width calculation and `aria-valuemax`; `aria-valuemin` is always `0`. |
| `indeterminate` | `boolean` | — | Switches to the indeterminate animation, applies `aws-field--progress-indeterminate`, and omits `aria-valuenow`. |
| `className` | `string` | — | Extra classes appended to the wrapper's `aws-field aws-field--progress[ aws-field--progress-indeterminate]` class list. |

## Deep Linking

Not applicable: Progress is a presentational primitive with no deep-linking semantics or navigation behavior.

## Localization

Not applicable: Progress has no user-facing strings to localize; all content is supplied by the consumer.

## Accessibility Options

| Option | Behavior |
|---|---|
| Reduce Motion | Not driven by `--apt-anim-scale` — that CSS custom property is a dev-only 10x-slow-motion debug switch, unrelated to accessibility. The fill's transition is an ordinary class-based utility (see **honors-shared-reduce-motion**), so the shared `accessibility.css` reduce-motion rule (`html[data-reduce-motion="on"] *`, or the OS `prefers-reduced-motion` media query when the setting is "auto") overrides its duration to near-zero without any change to this component (T9). |
| Increase Contrast | The Increase Contrast setting overrides `--color-on-surface`/`--color-outline*`/the focus-ring width (`accessibility.css`) — it does not touch `apt-gold`/`apt-surface-2`, so this component's colors are unaffected by that setting either way. `apt-gold`/`apt-surface-2` resolve per-theme through `--color-primary`/`--color-surface-container-high` (`tailwind.css`), and shipped themes do not converge on one pairing: the always-on `adh.css` base (and its close siblings) resolves them to `#c4a35a` on `#1c1c24` (a measured ~7.0:1), but other shipped themes remap those tokens to their own palette — the Monokai theme resolves the same pair to `#f92672` on `#3a3b33`, a measured ~3.0:1, below the WCAG 1.4.11 non-text 3:1 minimum. So the default fill/track pairing is not guaranteed to meet 3:1 under every shipped theme; meeting that minimum for a given theme — the default pairing or an `indicatorClassName` re-tint — is a theme/consumer responsibility, since `progress.tsx` applies whatever class and token values it is given without checking contrast. |
| Differentiate Without Color | The progress amount itself is conveyed via fill width and horizontal translation, not color alone. When `indicatorClassName` is used to encode semantic status (amber while building, green once complete), that status MUST also be conveyed via text or `aria-valuetext` — see **pairs-tint-with-text-status**. |

## Feature Flags

Not applicable: Progress is a stateless primitive shipped without feature gate requirements.

## Analytics

Not applicable: Progress is a presentational primitive with no internal events. Analytics around progress tracking belong to the consumer component.

## Privacy

Not applicable: Progress stores no user data and collects no information.

## Logging

No logging. `Progress` is a presentational primitive; the meaning of a value and any
telemetry around a job's progress belong to the consumer, not the bar.

## Platform Notes

- **Web/TypeScript**: Two files. `packages/web/packages/ui/src/components/progress.tsx` (UI) carries `"use client"` because it renders an inline `style` transform, but holds no internal state — `value` is fully controlled by the consumer. Demo in `ui-showcase` Topic `progress` (regenerate `sources.generated.ts` after source changes via `gen-sources.py`). `packages/web/packages/controls/src/user-settings/components/Progress.tsx` (Controls) is a plain function component with no client directive; it ships from the `user-settings` entry point of `@adh-sdk/controls`.
- **SwiftUI**: Start from `ProgressView(value: clampedValue, total: 100)` with the `.linear` `progressViewStyle` (or a custom `ProgressViewStyle` only if the track/fill need token colors the default style doesn't expose); clamp the incoming value to 0–100 before computing `clampedValue`, mirroring `#requirements/clamps-below-zero` and `#requirements/clamps-above-hundred`, and round it the same way as `#requirements/reflects-value-in-valuenow` before exposing it through `accessibilityValue`. `ProgressView` already draws and animates its own fill — no compositor translation modifier is needed; tint via `.tint(_:)` or the style's tint color. For the Controls variant's `indeterminate` prop, use `ProgressView()` with no `value`/`total` — SwiftUI's own indeterminate spinner — instead of computing a fraction; its `label`/`hint` map to `ProgressView(_:value:total:)`'s label and a `Text` caption below.
- **Compose**: Clamp the incoming value to 0–100 first, mirroring `#requirements/clamps-below-zero` and `#requirements/clamps-above-hundred`, then use `LinearProgressIndicator` with `progress = clampedValue / 100f` (the composable takes a 0–1 `Float`, not 0–100); round that same clamped value the way `#requirements/reflects-value-in-valuenow` does before exposing it through `Modifier.semantics { progressBarRangeInfo = ... }`. Tint via the `color`/`trackColor` parameters. `LinearProgressIndicator` already draws and animates its own fill — no `Modifier.graphicsLayer()` translation is needed. For the Controls variant's `indeterminate` prop, use `LinearProgressIndicator()` with no `progress` argument — Compose's own indeterminate mode — instead of computing a fraction; `label`/`hint` map to a `Text` above/below the indicator.
- **AppKit / UIKit**: `NSProgressIndicator` (AppKit) defaults to `isIndeterminate = true` — set it to `false` (and `style = .bar`) to get a determinate bar. `UIProgressView` (UIKit) is determinate-only by default, no flag needed. Clamp the incoming value to 0–100 before setting `doubleValue` (AppKit) or the 0–1 `progress` (UIKit), mirroring `#requirements/clamps-below-zero` and `#requirements/clamps-above-hundred`, and round it the same way as `#requirements/reflects-value-in-valuenow` before exposing it via `accessibilityValue`. Configure either with a custom tint and animate progress updates on the main thread. For the Controls variant's `indeterminate` prop, leave `NSProgressIndicator.isIndeterminate = true` (AppKit's native indeterminate mode) or substitute a `UIActivityIndicatorView` (UIKit, which has no built-in indeterminate progress bar); `label`/`hint` map to a caption `NSTextField`/`UILabel`.
- **WinUI 3**: Use `ProgressBar` with `Maximum=100`, `Value=clampedValue`; clamp the incoming value to that 0–100 range before assigning `Value`, mirroring `#requirements/clamps-below-zero` and `#requirements/clamps-above-hundred`, and round it the same way as `#requirements/reflects-value-in-valuenow` before exposing it through the automation peer's `RangeValuePattern`. Tint the fill by setting the `Foreground` brush (not `ProgressBarTemplate`/`TemplateBinding`, which isn't how `ProgressBar` fill color works). `ProgressBar` already animates value changes on its own — no custom `Storyboard`/`DoubleAnimation` is needed. For the Controls variant's `indeterminate` prop, set `ProgressBar.IsIndeterminate=True` (WinUI's own indeterminate mode) instead of computing `Value`; `label`/`hint` map to a `TextBlock` above/below the bar.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/controls/src/user-settings/components/Progress.tsx` | unverified |
| web | `packages/web/packages/ui/src/components/progress.tsx` | unverified |

## Design Decisions

**Decision**: The bar owns its own `role="progressbar"` + `aria-value*` attributes
rather than wrapping a headless progress primitive.
**Rationale**: Progress is simple enough that the ARIA is trivial, and avoiding
an extra runtime dependency keeps the shared bundle lean.
**Approved**: pending

**Decision**: The indicator is a full-width element translated with
`translateX(-{100 - pct}%)` rather than animated via a width change.
**Rationale**: The fill animates on the compositor (`transition-transform`) and
stays crisp on its rounded ends.
**Approved**: pending

**Decision**: `value` is clamped to 0–100 inside the component.
**Rationale**: An out-of-range value from a consumer can never overflow the
track or produce a nonsensical `aria-valuenow`.
**Approved**: pending

**Decision**: The fill defaults to the `apt-gold` token but exposes
`indicatorClassName` as a dedicated recoloring hook.
**Rationale**: Context can recolor the fill (amber building → green done)
without a variant explosion.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`separation-of-concerns` passes for both components: `progress.tsx` (UI) and
`Progress.tsx` (Controls) each take only display props (`value`/`max` or
`indeterminate`) and render markup, with no data fetching or business logic.
`unit-test-coverage` is `partial`: the Controls `Progress` is exercised
directly (`user-settings`'s component test suite renders it determinate and
indeterminate), but no test in the `ui` package renders `progress.tsx`
directly — the only test importing from `blocks/progress-modal` exercises a
different component (`ProgressModal`), not this one.

`semantic-markup` and `reduced-motion` rest on `progress.tsx` (UI): the
`role="progressbar"` + `aria-valuemin`/`aria-valuemax`/`aria-valuenow` attributes, and
the class-based (non-inline, non-`!important`) `transition`/`duration` utility that lets
the shared `accessibility.css` reduce-motion rule zero its duration. `contrast-ratio` is
`partial`: `apt-gold`/`apt-surface-2` resolve per-theme through `--color-primary`/
`--color-surface-container-high`, and while the always-on `adh.css` base resolves them
to `#c4a35a`/`#1c1c24` (a measured ~7.0:1), at least one shipped theme (Monokai,
`#f92672`/`#3a3b33`) resolves the same pairing to ~3.0:1, below the WCAG 1.4.11
non-text 3:1 minimum — so the default pairing is not guaranteed to meet it under every
shipped theme. This check does not apply to the Controls component, which has no
`indicatorClassName`-equivalent tint and fills from `--aws-accent` instead of
`apt-gold`/`apt-surface-2`.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Split UI/Controls coverage, indeterminate mode, Monokai contrast, NaN clamp; restored 1.0.0 row. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: corrected the Reduce Motion/Increase Contrast claims and cited the measured contrast ratio; fixed the SwiftUI/Compose/AppKit/WinUI 3 platform notes to use each platform's native progress control and API correctly; documented the unclamped non-finite `value` edge case; raised the accessible-name guidance from SHOULD to MUST; rebuilt the Compliance table with canonical linked checks; reformatted Design Decisions to the Decision/Rationale/Approved form; added `progress-modal` to `related`; fixed the States/T5 transform string mismatch; added test vectors for reduce motion, non-finite input, and the tailwind-merge fill override; corrected the 1.1.0 Change History entry's wording and author; scoped the measured contrast ratio to the default token pairing and made re-tinted contrast a consumer responsibility; added a requirement (and test vector) that a color-only status tint be paired with text or `aria-valuetext`; mapped each non-web platform's clamping and rounding onto the shared clamp/round/valuenow requirements. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Add missing template sections (Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics, Privacy); update platform notes to cover all target platforms; correct domain URI. Drafted by Claude Haiku 4.5. |
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe; documents the self-contained determinate Progress bar. |
