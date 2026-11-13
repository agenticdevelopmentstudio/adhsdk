---
id: 0c199036-81c3-47c3-9e79-e4b8187ca69a
title: "Field"
type: ingredient
version: 1.2.1
status: review
language: en
created: 2026-07-03
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The family's standard form row — an uppercase-mono caption over its control, implicitly associated via the shared Label, with a hint or red-mono error below."
platforms:
  - typescript
  - web
tags:
  - component
  - forms
  - field
  - label
  - ui
depends-on: []
related:
  - 781740e8-c83f-40a1-8215-43abfb8d8f56
references: []
approved-by: ""
approved-date: ""
---

# Field

## Overview

The shared `Field` in `@adh-sdk/ui` — the family's standard form row. It stacks
an uppercase-mono caption above whatever control it wraps (`Input`, `Select`,
`Switch`, `Textarea`, or any other primitive passed as `children`), and it renders
the whole row inside the shared `Label` so the caption is **implicitly associated**
with the control: clicking the caption focuses the input, with no `htmlFor`/`id`
wiring at the call site.

Below the control, `Field` renders one line of supporting text: a dim-mono `hint`
by default, or a red-mono `error` that takes the hint's place when present. This is
the one place inline field errors live, so forms across the platform stop
re-implementing (and re-styling) their own error text.

`Field` is presentation-only: it owns no value, no validation, and no state. The
caller supplies the control, the `hint`, and the `error`; `Field` only decides the
layout and which supporting line to show.

## Behavioral Requirements

- **render-caption**: The field MUST render the `label` node as an
  uppercase-mono caption (the shared `fieldCaptionClass`) above its control.
- **associate-label-implicitly**: The field MUST wrap the caption and the
  control in a single shared `Label` so activating the caption focuses the control,
  without the caller supplying `htmlFor`/`id`.
- **render-control**: The field MUST render its `children` (the control)
  between the caption and the supporting line.
- **show-hint-when-no-error**: When `error` is unset and `hint` is provided,
  the field MUST render `hint` below the control in dim mono.
- **show-error-in-place-of-hint**: When `error` is set, the field MUST render
  `error` below the control in red mono and MUST NOT also render `hint`.
- **omit-supporting-line-when-empty**: When neither `error` nor `hint` is
  provided, the field MUST render no supporting line below the control.
- **merge-classname**: The field MUST merge a caller-supplied `className` onto
  its root without dropping its own layout classes.
- **name-error-line**: When `errorId` is provided and `error` is set, the field
  MUST set `errorId` as the `id` of the rendered error line (never the hint line),
  so a control can point its own `aria-describedby` at it.
- **render-inline-layout**: When `layout` is `"inline"`, the field MUST render the
  caption beside the control instead of above it — a right-aligned label column
  sized by the `--apt-field-label-w` custom property, with the control (and any
  sibling children) in one cell and the supporting line in the second column.

## Appearance

```
LABEL CAPTION            ← uppercase mono, apt-text-muted (fieldCaptionClass)
┌───────────────────────┐
│  control (children)    │ ← Input / Select / Switch / Textarea / …
└───────────────────────┘
helper text below         ← hint: dim mono (apt-text-dim)
                          ← OR error: red mono (apt-red), replacing the hint
```

- Root, `layout="stacked"` (default): the shared `Label` as a vertical stack —
  `flex flex-col items-start gap-1.5` — so caption, control, and supporting line
  left-align in a column.
- Root, `layout="inline"`: the shared `Label` as a two-column grid — `grid
  grid-cols-[var(--apt-field-label-w,8rem)_minmax(0,1fr)] items-center gap-x-3
  gap-y-1` — with the caption right-aligned in column 1 (`justify-self-end
  text-right`), the control (and any sibling children) wrapped in one cell in
  column 2 (`flex min-w-0 flex-col gap-2`), and the supporting line also in
  column 2 (`col-start-2`). A group of inline fields shares one label column by
  setting `--apt-field-label-w` once on a wrapper; `FIELD_LABEL_GROUP_CLASS`
  (`[--apt-field-label-w:6.5rem]`) is the one width every inline group in the
  family agrees on, so sibling subtrees read the same source instead of each
  hardcoding a copy of `6.5rem`.
- Caption: `fieldCaptionClass` = `font-mono text-[0.7rem] uppercase tracking-wider
  text-apt-text-muted` (the platform's one caption treatment).
- Hint: `font-mono text-[0.7rem] text-apt-text-dim`.
- Error: `font-mono text-[0.7rem] text-apt-red` — same metrics as the hint, red
  tone, occupying the same slot.
- No raw hex; no `!important`; every color is an `apt-*` token.

## States

| State | Appearance change |
|---|---|
| Default (hint only) | caption, control, then dim-mono `hint` |
| Default (no hint, no error) | caption + control only; no supporting line |
| Error | caption, control, then red-mono `error`; the `hint` is suppressed |
| Focused control | caption + control focus is the control's own affordance; `Field` adds none |
| Disabled control | no dimming from `Field` itself; the wrapping `Label` carries `peer-disabled:opacity-50`, but that Tailwind variant only fires for a *sibling* marked `peer` that precedes the styled element — here the control is a *child* of `Label`, not a preceding sibling, so the rule never matches. Any disabled appearance comes from the control's own styling. |

## Accessibility

- The caption and control share one `<label>` element, so the caption is a real,
  programmatic label for the control — clicking it focuses the control and screen
  readers announce the caption when the control is focused.
- The caption text is authored by the caller; it MUST be human-readable label text
  (implicit association carries no `aria-label`).
- The error line is plain text in the label's flow, so it is read with the field;
  it carries no `role="alert"`, so callers that need assertive announcement
  SHOULD add their own `role="alert"` wrapper around the message they pass as
  `error`.
- `errorId` names the rendered error line (never the hint line — see
  **name-error-line**) so the caller's own control can point its
  `aria-describedby` at it. This is the mechanism that connects an error to its
  control: `Field` only makes the target nameable, and the caller wires
  `aria-describedby={errorId}` onto the control it passes as `children`.
- Color is not the only error signal in practice — the message text itself states
  the error — but callers SHOULD keep error copy meaningful for non-visual users.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-caption, associate-label-implicitly | `<Field label="Name"><input/></Field>` | One `<label>` wraps an uppercase-mono "Name" caption and the input; clicking the caption focuses the input |
| T2 | render-control | `children` is an `<Input/>` | The input renders between the caption and any supporting line |
| T3 | show-hint-when-no-error | `hint="Shown to teammates"`, no `error` | A dim-mono hint line renders below the control |
| T4 | show-error-in-place-of-hint | `hint="…"` AND `error="Required"` | A red-mono "Required" renders; the hint is absent |
| T5 | omit-supporting-line-when-empty | neither `hint` nor `error` | No supporting line renders below the control |
| T6 | merge-classname | `className="mt-4"` | Root keeps `flex flex-col …` and adds `mt-4` |
| T7 | render-inline-layout | `<Field label="Name" layout="inline"><input/></Field>` inside a wrapper setting `--apt-field-label-w` | Root renders as `grid grid-cols-[…]`; the caption is right-aligned in column 1; the control and the supporting line both render in column 2 |
| T8 | name-error-line | `<Field label="Name" errorId="name-error" error="Required"><input/></Field>` | The rendered error `<span>` has `id="name-error"`; when only `hint` is set instead, the hint `<span>` receives no `id` |

## Edge Cases

- Both `hint` and `error` set → `error` wins and the hint is not rendered (the
  error occupies the hint's slot, so the row height does not jump).
- For a field that already shows a `hint`, `error` toggling on/off swaps the
  single supporting line rather than stacking two lines, so validated forms
  don't reflow by an extra row. A field with no `hint` at all has no supporting
  line to begin with (**omit-supporting-line-when-empty**), so it gains a whole
  line the first time an `error` appears — the stable-height guarantee only
  holds once a `hint` is already occupying the slot.
- `label` is a `ReactNode`, so a caption may include an inline glyph or badge; it is
  still rendered with the caption treatment.
- Empty-string `hint`/`error` renders nothing (falsy), same as omitting it.
- The control is whatever `children` the caller passes; `Field` imposes no control
  type and forwards no value/validation.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `label` | `ReactNode` | — (required) | The caption text, rendered uppercase-mono above the control. |
| `children` | `ReactNode` | — (required) | The control (e.g. `Input`/`Select`/`Switch`/`Textarea`). |
| `hint` | `ReactNode` | — | Dim-mono helper line below the control; shown only when `error` is unset. |
| `error` | `ReactNode` | — | Red-mono inline error; when set, replaces `hint` in the same slot. |
| `errorId` | `string` | — | Names the error line for a control that points `aria-describedby` at it. |
| `layout` | `"stacked" \| "inline"` | `"stacked"` | Caption above the control (default) or beside it in a fixed-width right-aligned column for grouped rows. |
| `className` | `string` | — | Extra classes merged onto the root `Label` via `cn()`. |

## Deep Linking

Not applicable: Field is a presentational primitive without its own routing or deep-link targets.

## Localization

Field renders whatever caption, hint, and error text the caller provides — the
copy itself is localized by the caller and the form owning the field, not by
`Field`. The one thing `Field` itself does to that text is the caption's
uppercase treatment (`fieldCaptionClass`'s `uppercase`, and the equivalent
native transform on each platform). Casing is a locale-sensitive operation
(for example the German `ß`/`SS` expansion, or Turkish dotted/dotless `i`), so
that transform MUST use the user's current locale on every platform — never an
invariant- or culture-insensitive uppercase call — even though the transform
itself is applied by `Field`, not the caller.

## Accessibility Options

Not applicable: Field's mono treatment (caption, hint, error) does not respond to display preferences like reduced motion or increased contrast; the control nested inside may do so, but that is independent of Field.

## Feature Flags

Not applicable: Field is a core presentational block with no feature flag.

## Analytics

Not applicable: Field is presentation-only and forwards no events or telemetry; analytics belong to the control and the owning form.

## Privacy

Not applicable: Field renders layout and labels supplied by the caller; it collects no user data.

## Logging

No logging. `Field` is a presentational primitive; value changes, validation, and
any telemetry belong to the control and the owning form, not to `Field`.

## Platform Notes

- **React / Web (TypeScript):** `packages/web/packages/ui/src/blocks/field.tsx`, exported via `@adh-sdk/ui/blocks/field`. Composes the shared `Label` (`components/label`) and the `fieldCaptionClass` from `lib/typography`. The `inline` layout uses CSS Grid with `--apt-field-label-w` custom property for label column width; stacked layout is a vertical flexbox. Server-safe with no `"use client"` directive.

- **SwiftUI:** Compose with `VStack` for stacked layout, or `HStack` with a fixed-width label column and `Spacer` for inline layout (the fixed width is the platform's equivalent of `--apt-field-label-w`, shared by a group rather than owned by one field). Wrap the caption and control in a `LabeledContent`, or apply `.accessibilityLabel(caption)` directly to the control, so the control's accessible name carries the caption without the caller wiring an id — this is the mechanism behind **associate-label-implicitly**. Render the caption in a monospaced font at the same small size as the hint/error (matching `font-mono text-[0.7rem]`), transformed with `.uppercased()` — locale-sensitive, using the current locale, not a title-case/"capitalized" style and never `Locale(identifier: "en_US_POSIX")` — with `tracking(.wide)` if available. Render hint or error text in the same monospaced size below/beside the control, coloring the error with the semantic red token. Substitute SwiftUI's `@Environment(\.isEnabled)` for peer-disabled dimming, since SwiftUI has no sibling-selector equivalent.

- **Compose (Kotlin):** Build with `Column` for stacked layout, or a `Row` with a `weight(1f)` modifier on the control column for inline layout (the label column's fixed width mirrors `--apt-field-label-w`, shared across a group). Apply `Modifier.semantics { contentDescription = caption }` to the control (or nest both in a construct that exposes one merged semantics node) so the control's accessible description carries the caption — the mechanism behind **associate-label-implicitly**. Style the caption with `Typography.labelSmall` in uppercase mono, at the same size as hint/error text. Render hint in a `Text` with reduced opacity and error in `MaterialTheme.colorScheme.error` — not a further-reduced-opacity error, which reads as *less* prominent than the hint it replaces. Use `Modifier.alpha()` or the `enabled` parameter for disabled dimming.

- **AppKit / UIKit:** On iOS, compose with `UIStackView` axis `.vertical` (stacked) or `.horizontal` (inline, with a fixed-width label view mirroring `--apt-field-label-w`). Render the caption as a plain, non-interactive `UILabel` with system font `.caption1`, uppercase and tracked, in the same size as the hint/error label — never a `UIButton` or `systemBlue` tint, which would make a label read as a tappable link. Give the caption `isUserInteractionEnabled = true` and a `UITapGestureRecognizer` that calls `becomeFirstResponder()` on the wrapped control, so tapping the caption focuses the control without looking like a button. Set the control's `accessibilityLabel` to the caption text (or group caption + control as one `accessibilityElements` cluster) — the mechanism behind **associate-label-implicitly**, since UIKit/AppKit has no implicit `<label>` wrapping. On macOS, use `NSStackView` with the same treatment; an `NSTextField` (non-editable, non-bezeled) plays the caption's role, with a click gesture recognizer standing in for tap-to-focus. Both platforms dim by graying the stack's `isEnabled` or the individual control's alpha — there is no peer-selector equivalent to substitute.

- **WinUI 3:** Use `StackPanel` orientation `Vertical` (stacked) or `Horizontal` (inline) as root. Render the caption as a `TextBlock` with a monospaced `FontFamily` (not `FontWeight.SemiBold`, which reads as emphasis rather than the mono caption treatment), `FontSize` matching the hint/error text, uppercase (transformed using the current culture, never `CultureInfo.InvariantCulture`), `CharacterSpacing` approximating the tracking-wide treatment, and `Foreground` bound to a muted design-token brush. For inline, size the label column from a shared resource (e.g. a `x:Double` resource keyed the same way `--apt-field-label-w` is shared across a group) rather than a hardcoded `Width="104"`, and right-align via `HorizontalAlignment="Right"`. Set `AutomationProperties.LabeledBy` on the control to point at the caption `TextBlock` — the mechanism behind **associate-label-implicitly** — since WinUI has no implicit label/control pairing. Below or beside the control, add a secondary `TextBlock` for hint (dimmed via a muted brush) or error (bound to a semantic error-red brush), at the same font and size as the caption. Bind `StackPanel.IsEnabled` or the individual control's `IsEnabled`; WinUI 3 applies opacity automatically when controls are disabled.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/field.tsx` | unverified |

## Design Decisions

**Decision**: Wrap the whole row in one shared `Label` rather than pairing an
`htmlFor`/`id`.
**Rationale**: Implicit association removes per-call id wiring and makes the
caption a real click target, while keeping every caption on the one
`fieldCaptionClass` treatment.
**Approved**: pending

**Decision**: `error` occupies the same slot as `hint` (one supporting line, not
two).
**Rationale**: Once a `hint` is already occupying the slot, the row height
stays stable as validation toggles, and forms get a single, consistent place
for inline errors instead of re-inventing error text; a field with no `hint`
at all still gains a line the first time an `error` appears (see the Edge
Cases qualification of **omit-supporting-line-when-empty**).
**Approved**: pending

**Decision**: `Field` owns no value or validation.
**Rationale**: It stays a reusable layout primitive over any control;
optimize-for-change keeps validation policy in the form, not the row.
**Approved**: pending

**Decision**: Hint and error are mono at the same `0.7rem` metrics.
**Rationale**: Error and hint read as the same "supporting text" rhythm,
differing only by the `apt-red` tone that signals the error.
**Approved**: pending

**Decision**: `layout` prop controls caption placement (stacked above or inline
beside).
**Rationale**: Grouped inline forms (e.g., categories and tags rows) align
captions by sharing the `--apt-field-label-w` custom property, reducing
per-call coupling while keeping the default stacked layout simple and
no-config.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`screen-reader-support` rests on the shared `Label` giving the control a
meaningful, programmatic name from the caption (**associate-label-implicitly**)
and on `errorId` naming the error line for `aria-describedby`
(**name-error-line**); `semantic-markup` rests on `Field` composing native
`<label>` and text elements rather than custom ARIA roles.
`separation-of-concerns` passes: `field.tsx` has no logic beyond choosing
which layout classes to apply and composes `Label`/`FieldFootnote` rather
than reimplementing them. `unit-test-coverage` passes — `field.test.tsx`
asserts both `layout="inline"` and the default `"stacked"` layout, covering
the caption's right-alignment and the footnote's grid-column placement in
each.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Restored on-main 1.0.0 Change History row (authorized); added missing separation-of-concerns/unit-test-coverage Compliance rows. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case and add requirements/test vectors for `errorId` and inline layout, correct the disabled-state and row-height claims to what the source does, fix platform notes (label-association mechanism, SwiftUI casing, Compose error color, WinUI width/font, no tappable AppKit/UIKit caption), rebuild Compliance from the catalog, and complete Design Decisions' Approved lines. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Add the inline layout option, plus platform notes for all five platforms. |
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe for the shared Field form row. |
