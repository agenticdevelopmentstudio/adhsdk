---
id: bba42d5f-8a52-487f-88c5-4f988dfa714b
title: Stat
domain: adhsdk://recipes/stat
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-07-03'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The dashboard figure — a micro uppercase-mono label with a big tone-tinted value, as a row (label left / value right) or a right-aligned column."
platforms:
- typescript
- web
tags:
- component
- stat
- dashboard
- display
- ui
depends-on: []
related:
- adhsdk://recipes/stat-card
references: []
approved-by: ''
approved-date: ''
---

# Stat

## Overview

The stat family in `@adh-sdk/ui` renders one label/value figure in the shared
dashboard grammar: a micro **uppercase mono** caption paired with a big, bold, mono
**value** tinted by a status tone. Two exports ship the same grammar in two shapes:

- `StatRow` — label left, big value right on a shared baseline. The dashboard-card
  form (a stack of these fills an `InfoPanel`).
- `Stat` — the value stacked over its label, right-aligned. The hero-strip form.

Both take the same `StatProps` (`label`, `value`, `tone`, `valueClassName`,
`className`) and share one cva, `statValueVariants`, whose `tone` picks the value's
color from the family status tokens (`neutral`, `muted`, `accent`, `blue`, `orange`,
`success`, `error`). The type `StatTone` is also exported. The label always uses the
micro-caption treatment — smaller and dimmer than the form-field caption, because it
is a display label under/beside a figure, not a field name.

It is a pure presentational primitive: no `"use client"`, no state, no interactivity
— `label` and `value` are `ReactNode`, so the host supplies whatever content each
holds. Extracted from the status board so every site's dashboard figures share one look.

## Behavioral Requirements

- **renders-label-and-value**: The component MUST render both the `label` and the `value`.
- **tints-value-by-tone**: The component MUST color the value from the `tone`'s family status token — `neutral`→`text-apt-text`, `muted`→`text-apt-text-dim`, `accent`→`text-apt-gold`, `blue`→`text-apt-blue`, `orange`→`text-apt-orange`, `success`→`text-apt-green`, `error`→`text-apt-red`.
- **defaults-neutral-tone**: With no `tone`, the component MUST render the value in the neutral text token (`text-apt-text`).
- **value-class-overrides-tone**: The component MUST apply `valueClassName` to the value merged after the tone class through `cn()`'s `tailwind-merge` de-confliction, so a caller MAY override the tone hue. (Plain class concatenation would leave both `text-*` classes in the string and let CSS source order — not merge order — decide the winner.)
- **label-uses-micro-caption**: The component MUST render the label in the micro uppercase-mono caption treatment (small, letter-spaced, dimmed).
- **value-uses-figure-type**: The component MUST render the value in the big mono-bold figure treatment (`font-mono text-lg font-bold leading-none`).
- **row-lays-out-on-baseline**: `StatRow` MUST place the label at the left and the value at the right on a shared baseline (`items-baseline justify-between`).
- **column-right-aligns**: `Stat` MUST stack the value above the label, both right-aligned (`flex-col items-end`).
- **forwards-classname**: The component MUST merge a caller `className` onto the wrapper element.

## Appearance

`StatRow` (dashboard-card form):

```
UPTIME                              99.98%   ← success tint (text-apt-green)
BUILDS · 24H                            12   ← neutral (default)
FAILURES · 24H                           0   ← muted (text-apt-text-dim)
└ micro uppercase-mono label        └ big mono-bold value, right on the baseline
```

`Stat` (hero-strip form):

```
        99.98%     ← value on top, right-aligned, tinted
        UPTIME     ← micro label beneath
```

- Value: `statValueVariants` = `font-mono text-lg font-bold leading-none` + the tone
  color token; `valueClassName` merges after via `cn()`.
- Label: `font-mono text-[10px] uppercase tracking-[0.06em] text-apt-text-dim` — the
  display micro-caption, deliberately smaller/dimmer than the form-field caption.
- `StatRow` wrapper: `flex items-baseline justify-between gap-3`.
- `Stat` wrapper: `flex flex-col items-end gap-px`.
- Color comes entirely from `apt-*` tokens; no raw hex, no `!important`.

## States

| State | Appearance change |
|---|---|
| `neutral` (default) | value `text-apt-text` |
| `muted` | value `text-apt-text-dim` (de-emphasized figure) |
| `accent` | value `text-apt-gold` |
| `blue` | value `text-apt-blue` |
| `orange` | value `text-apt-orange` |
| `success` | value `text-apt-green` |
| `error` | value `text-apt-red` |
| `valueClassName` override | value hue replaced by the supplied class (wins over tone) |
| Row form (`StatRow`) | label left, value right, shared baseline |
| Column form (`Stat`) | value over label, right-aligned |

No interactive states — the primitive is not focusable, hoverable, or disable-able.

## Accessibility

- Both `label` and `value` render as plain text spans, so assistive tech announces
  them in DOM order: label-then-value for `StatRow`, and value-then-label for `Stat`
  (the value leads the column form visually and in the reading order).
- In the column form (`Stat`), that reading order means a screen reader hears the
  value before it has the label's context (e.g. "3" before "failures · 24h").
  Callers SHOULD group the two for assistive tech when that would be confusing on
  its own — e.g. an `aria-label` on the wrapper combining label and value, or the
  platform's accessibility-element-grouping equivalent — rather than relying on
  reading order alone.
- Tone is conveyed by color only — it carries no ARIA and adds no accessible name;
  the `label` is the sole textual meaning, so callers SHOULD keep the label
  descriptive (e.g. "failures · 24h") rather than leaning on the red tint alone.
- Purely presentational: no role, not focusable, not interactive.
- Color and contrast come from the `apt-*` theme tokens, consistent in light and dark.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | renders-label-and-value, tints-value-by-tone | `<StatRow label="uptime" value="99.9%" tone="success" />` | "uptime" and "99.9%" both present; value carries `text-apt-green` |
| T2 | defaults-neutral-tone, value-uses-figure-type | `<StatRow label="builds · 24h" value="12" />` | value "12" carries `text-apt-text` and the figure type `font-mono text-lg font-bold leading-none` |
| T3 | value-class-overrides-tone | `<StatRow label="env" value="PROD" tone="error" valueClassName="text-apt-blue" />` | value carries `text-apt-blue` and NOT `text-apt-red` |
| T4 | tints-value-by-tone, column-right-aligns | `<Stat label="failures · 24h" value="3" tone="error" />` | value "3" carries `text-apt-red`; label present; wrapper `flex-col items-end` |
| T5 | row-lays-out-on-baseline | `<StatRow label="x" value="1" />` | wrapper carries `items-baseline justify-between` |
| T6 | label-uses-micro-caption | `<Stat label="uptime" value="99.98%" />` | label span carries `text-[10px] uppercase tracking-[0.06em] text-apt-text-dim` |
| T7 | forwards-classname | `<StatRow className="pt-1" .../>` | wrapper carries `pt-1` |
| T8 | renders-label-and-value | `label={<b>N</b>} value={0}` | node label rendered; value `0` rendered (not dropped) |
| T9 | forwards-classname | `<Stat className="pb-2" label="x" value="1" />` | wrapper carries `pb-2` |

## Edge Cases

- `label` and `value` are `ReactNode`: a value of `0` renders as "0" (not treated as
  falsy/blank), and either slot MAY hold a fragment, number, or icon+text.
- `valueClassName` that sets a `text-*` color wins over the tone token because `cn()`
  runs `tailwind-merge`, which drops the earlier conflicting `text-*` class instead of
  leaving both in the string; a class touching only non-color properties leaves the
  tone hue untouched.
- With `tone` left `undefined`, the cva default applies (`neutral`). `StatTone` is a
  closed union of the seven tones, so passing any other string is a compile-time type
  error, not a runtime fallback.
- No truncation or wrapping is imposed — a very long value in `StatRow` competes with
  the label across `justify-between`; the host sizes the container.
- The two forms are separate exports on one grammar: pick `StatRow` inside cards,
  `Stat` for a right-aligned hero strip; there is no orientation prop.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `label` | `ReactNode` | — (required) | The micro uppercase-mono caption. |
| `value` | `ReactNode` | — (required) | The big mono-bold figure. |
| `tone` | `StatTone` | `neutral` | Value tint: `neutral`/`muted`/`accent`/`blue`/`orange`/`success`/`error`. |
| `valueClassName` | `string` | — | Extra classes for the value; merged after the tone class (escape hatch for categorical hues). |
| `className` | `string` | — | Extra classes for the wrapper; merged via `cn()`. |

Exports from `@adh-sdk/ui/components/stat`: `StatRow`, `Stat`, the `StatTone`
type, and the `StatProps` interface.

## Deep Linking

None: `Stat`/`StatRow` are pure render functions with no router subscription
and no URL of their own.

## Localization

None applicable: the component contains no hardcoded user-facing strings.
`label` and `value` are both `ReactNode`, supplied entirely by the host.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the source renders static markup with no transition or animation at all. |
| Increase Contrast | Depends on the `apt-*` design tokens driving `TONE_TEXT_CLASS`; the component itself does no `prefers-contrast` handling. |
| Differentiate Without Color | Tone is conveyed by color only, as already noted in Accessibility; there is no non-color indicator, so callers SHOULD keep `label` descriptive rather than relying on the tint. |

## Feature Flags

None: feature-gating a stat display is not a concern of the component; a host
controls whether it renders at all.

## Analytics

None: the source emits no analytics or telemetry; it is a display primitive
only.

## Privacy

None: the component collects and transmits nothing; `label`/`value` are
whatever the host passes in.

## Logging

No logging. `Stat`/`StatRow` are presentational primitives; the meaning of a figure
and any telemetry around it belong to the host, not the display element.

## Platform Notes

- **React/Web**: File `packages/web/packages/ui/src/components/stat.tsx`. No `"use client"` directive — renders static spans with no state or effects, works as a server component. Styled with `apt-*` token utilities registered centrally via `@source`. Demo in `ui-showcase` Topic `stat` (group "Primitives — display"); regenerate `sources.generated.ts` via `gen-sources.py` after source changes.
- **SwiftUI**: Column form (`Stat`) — `VStack(alignment: .trailing, spacing: 4)` with `Text(value).font(.title2).fontWeight(.bold).monospaced()` over `Text(label).font(.caption2).tracking(0.6).textCase(.uppercase).foregroundStyle(.secondary)`; `.tracking` is in points, so 0.6pt approximates the web's `0.06em` at a 10pt label (`.tracking(0.06)` would be roughly 10× too small). Row form (`StatRow`) — `HStack(alignment: .firstTextBaseline) { Text(label)...; Spacer(); Text(value)... }` with the same two text styles. Map `tone` to `Color`: `neutral`→`.primary`, `muted`→`.secondary`, `accent`→a shared gold `Color`, `blue`→`.blue`, `orange`→`.orange`, `success`→`.green`, `error`→`.red`, mirroring the `apt-*` token table rather than hardcoding per view.
- **Compose**: Column form — `Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(4.dp))` (`Modifier.gap` does not exist; a `Column`'s spacing is `verticalArrangement`) with `Text(value, style = MaterialTheme.typography.titleLarge.copy(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Bold))` over `Text(label.uppercase(), style = MaterialTheme.typography.labelSmall.copy(letterSpacing = 0.6.sp), color = MaterialTheme.colorScheme.onSurfaceVariant)`. `String.uppercase()` takes the current `Locale` by default — never call it with an invariant/root locale for user-facing text. Row form — `Row(verticalAlignment = Alignment.Bottom) { Text(label, modifier = Modifier.alignByBaseline()); Spacer(Modifier.weight(1f)); Text(value, modifier = Modifier.alignByBaseline()) }`. Material3's `colorScheme` ships only `error` as a semantic status color, so `neutral`/`muted`/`accent`/`blue`/`orange`/`success` need a small custom tone-color extension mirroring the `apt-*` table; only `error`→`colorScheme.error` is built in.
- **AppKit / UIKit**: Column form — vertical `NSStackView` / `UIStackView` (`alignment: .trailing`) holding value and label `NSTextField` / `UILabel` instances. `.font(.systemFont(ofSize: 18, weight: .bold))` is SwiftUI syntax, not AppKit/UIKit, and `.setMonospaced()` is not an API — instead assign `label.font = NSFont.monospacedSystemFont(ofSize: 18, weight: .bold)` / `UIFont.monospacedSystemFont(ofSize: 18, weight: .bold)` directly to the value's font property. Give the label `.font = .systemFont(ofSize: 11, weight: .regular)`, a dimmed `.textColor`, and uppercase its string with `.uppercased(with: Locale.current)` before assigning it — locale-sensitive, never bare `.uppercased()` for user-facing text. Row form — a horizontal stack view with `alignment: .firstBaseline` (a real `NSStackView.Alignment` / `UIStackView.Alignment` case) instead of vertical. Map `tone` to `NSColor`/`UIColor`: `neutral`→`.labelColor`/`.label`, `muted`→`.secondaryLabelColor`/`.secondaryLabel`, `accent`→a shared gold color asset, `blue`→`.systemBlue`, `orange`→`.systemOrange`, `success`→`.systemGreen`, `error`→`.systemRed`.
- **WinUI 3**: Column form — a `StackPanel` with `Orientation="Vertical"`, `HorizontalAlignment="Right"`, and `Spacing="4"` (the built-in gap property — not `Margin` on each child) holding value and label `TextBlock`s. Set the value's `FontWeight="Bold"`, `FontSize="18"`, and a shared monospace `FontFamily` resource (not a hardcoded `Consolas`, which skips the app's theme); set the label's `FontSize="10"` with a dimmed foreground brush and its text uppercased via `text.ToUpper(CultureInfo.CurrentCulture)` — locale-sensitive, never `ToUpperInvariant()` for user-facing text. Row form — a two-column `Grid` (`Auto`,`*`) with the label in column 0 and the value, `HorizontalAlignment="Right"`, in column 1. Map `tone` to a `Brush`: `neutral`→`TextFillColorPrimaryBrush`, `muted`→`TextFillColorSecondaryBrush`, `accent`→a shared gold brush resource, `blue`→`SystemFillColorAttentionBrush`, `orange`→`SystemFillColorCautionBrush`, `success`→`SystemFillColorSuccessBrush`, `error`→`SystemFillColorCriticalBrush`.

## Design Decisions

**Decision**: Ship `StatRow` (baseline row) and `Stat` (right-aligned column) as two
separate exports sharing one `StatProps` and `statValueVariants`.
**Rationale**: A dashboard card and a hero strip render the same figure look without a
mode prop.
**Approved**: pending

**Decision**: Bound `tone` to a cva with the seven family status tokens, and give
`valueClassName` as the escape hatch for anything outside that set.
**Rationale**: The `tone` variant covers the common, themable cases; a caller needing
a categorical hue outside that set uses `valueClassName`, which merges after the tone
class — avoiding a variant explosion.
**Approved**: pending

**Decision**: Give the label a distinct micro-caption class instead of reusing the
form-field caption.
**Rationale**: This is a display label under/beside a figure, not a field name, so it
should read as chrome around the number — intentionally smaller and dimmer than the
form-field caption.
**Approved**: pending

**Decision**: Render the value in a big, mono, bold weight with `leading-none`.
**Rationale**: Monospace, bold, large, tight leading keeps columns of figures aligned
and makes the number the visual anchor.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [platform-theming](agenticdevelopercookbook://compliance/platform-compliance#platform-theming) | passed | Platform Compliance |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`contrast-ratio` is partial because `stat.tsx` colors the value and label only
through `apt-*` tokens — no raw hex, no `!important` — without itself asserting a
measured ratio. `semantic-markup` passes because the component renders plain,
non-interactive `<span>`/`<div>` elements with no ARIA misuse. `platform-theming`
passes because every color comes from the shared `apt-*` theme tokens, which the
Appearance section states resolve consistently in light and dark. `StatRow`/`Stat`
are pure presentation over props with no business logic (separation-of-concerns
passed), and `stat.test.tsx` directly renders both and asserts on tone-class output
(unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added the Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics and Privacy sections. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: ground `value-class-overrides-tone` and its Edge Case in `tailwind-merge`, and limit the tone fallback claim to `undefined`; rename the web Platform Notes bullet to `React/Web`, fix inaccurate Compose/AppKit-UIKit/WinUI APIs, add row-form/uppercase-label/tone-color guidance for every native platform, and correct the SwiftUI tracking unit and hardcoded WinUI font; add a SHOULD on grouping value/label for assistive tech; give T6 a concrete input and add a `Stat`+`className` test vector; rewrite Design Decisions in the Decision/Rationale/Approved form; replace the Compliance table's circular/misnamed checks with linked catalog checks. |
| 1.0.2 | 2026-09-22 | Claude Haiku 4.5 | Remove "Not applicable" phrasing from Platform Notes non-web bullets; sharpen translation guidance. |
| 1.0.1 | 2026-09-22 | Claude Haiku 4.5 | Move to review; fix domain URIs and expand Platform Notes to cover all platforms. |
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe; documents StatRow/Stat, the tone grammar, and the label/value treatment. |
