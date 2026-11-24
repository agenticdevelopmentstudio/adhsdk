---
id: 550f00f7-bfb2-415e-9b15-bd5dce015500
title: "Alert & Dialog System"
type: recipe
version: 1.2.4
status: review
language: en
created: 2026-06-26
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The canonical alert/confirm/modal-dialog treatment: shared header + footer-button layout + keyboard policy on the AlertModal/Dialog base."
platforms:
  - typescript
  - web
tags:
  - dialog
  - alert
  - confirm
  - overlay
ingredients:
  - 972be0d0-a9f5-45cd-a23b-c8329410b3d1
  - f3c25236-d72f-4a7b-839a-b7f335b3acd0
depends-on: []
related: []
references:
  - https://base-ui.com/react/components/dialog
  - https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/
approved-by: ""
approved-date: ""
---

# Alert & Dialog System

## Overview

The canonical styled alert / confirm / modal-dialog treatment for ADH. It is
realized by evolving `@adh-sdk/ui`'s existing `AlertModal`
(`packages/web/packages/ui/src/components/alert-modal.tsx`) **backward-compatibly** —
existing call-sites and tests keep working. Larger modal dialogs reuse the same
header + footer-button system on top of the base `Dialog`.

It is one controlled component for two common shapes — **Alert** (single action,
full-width gold `[ OK ]`) and **Confirm** (two actions `[ Cancel ][ OK ]`, equal
width, OK gold) — plus a **destructive** mode (red action, no keyboard shortcuts)
and a caller-configurable keyboard policy. The same header style and footer-button
rules are exposed for composed dialogs so everything looks uniform.

## Ingredients

| Name | rdid | Role | Required | Configuration |
|---|---|---|---|---|
| Dialog | [adhsdk.ingredient.ui.components.overlays.dialog](cookbook:972be0d0-a9f5-45cd-a23b-c8329410b3d1) | Base overlay / focus-trap / portal that the system is built on | yes | reused unchanged |
| Button | [adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0) | Footer action + cancel buttons | yes | `variant="default"` (gold action), `variant="ghost"`/`outline` (cancel), `variant="destructive"` for the destructive action |

## Integration Requirements

- **confirm-mode-trigger**: The modal MUST be in confirm mode (two buttons) exactly when `cancelLabel` is provided (non-null), and in alert mode (one button) otherwise.
- **full-width-single-action**: With one button, the action button MUST be full width of the content area and gold (`Button variant="default"`).
- **equal-width-when-narrow**: With two buttons, when the row is too narrow for both buttons at their natural width, each button MUST get up to an equal share of the row, capped at its own natural width, and any share a button does not use MUST fall to the other button. Cancel is `ghost`/`outline` and OK is gold. (Implementation note: the `DialogActions` default `auto` layout does this with `flex-1 max-w-max`.)
- **natural-width-when-wide**: Once the row has room for both buttons at their natural width, the buttons MUST render at natural width and right-justify (`justify-end`), Cancel then OK; no button is ever stretched past its own natural width.
- **order-cancel-then-action**: The order MUST always be Cancel (left) then the action (right).
- **keyboard-default**: Under `keyboard:"default"`, Escape MUST dismiss via cancel if a cancel button exists (else via the single action), and Enter MUST activate the action.
- **keyboard-none**: Under `keyboard:"none"`, the modal MUST honor no keyboard shortcuts: neither Enter nor Escape acts. Pointer dismissal (backdrop click or the close affordance, if shown) is not a keyboard shortcut and still routes to cancel (confirm mode) or confirm (alert mode).
- **escape-routing**: The modal MUST route Escape through the base dialog's `onOpenChange` handler, using its `reason` value `"escape-key"`: ignore it when keyboard shortcuts are off (`"none"` or `destructive`) or when `busy`, otherwise route it to cancel (confirm mode) or confirm (alert mode). The window key listener MUST handle only keys other than Escape in the key map, so no key fires twice.
- **keyboard-explicit-map**: Under an explicit key→action map, non-Escape keys MUST act only if listed, mapped to the named button (a key mapped to a button that is not present MUST be ignored). Escape MUST additionally always dismiss via cancel if a cancel button exists (else via the single action) whenever the keyboard policy is not `"none"`, regardless of whether Escape is listed in the map or mapped to a different action — see Edge Cases.
- **destructive-forces-none**: When `destructive` is true, the action button MUST render red (`apt-red`) using the `Button` `variant="destructive"` (in alert mode directly, in confirm mode through `DialogActions` `destructive`) and the keyboard policy MUST be forced to `"none"` regardless of `keyboard`.
- **block-dismissal-when-busy**: When `busy` is true, the component MUST block every dismissal path (Escape, backdrop click and the close affordance, by ignoring them in `onOpenChange`) and replace the buttons with a spinner.
- **be-accessible-dialog**: The surface MUST be `role="dialog"` with `aria-modal`, labelled by the title and described by the body; initial focus MUST be the action button in confirm mode regardless of the keyboard policy (the first field for composed form dialogs), except that a `destructive` confirm MUST focus Cancel so Enter cannot land on the delete button; focus MUST be trapped while open and restored to the opener on close.

## Layout

Single-button alert (button spans the content width):

```
┌───────────────────────────────────┐
│  Title (apt-gold)                  │   ← highlight-color header
│  Body copy, proportional padding.  │
│  [               OK              ] │   ← full-width gold
└───────────────────────────────────┘
```

Two-button confirm (equal width):

```
┌───────────────────────────────────┐
│  Title (apt-gold)                  │
│  Body copy.                        │
│  [    Cancel    ][      OK       ] │   ← equal width; OK = gold
└───────────────────────────────────┘
```

Wide dialog (content wide enough that both buttons fit at their natural width → buttons keep natural width and right-justify):

```
┌─────────────────────────────────────────────────────────┐
│  Title (apt-gold)                                         │
│  … wider content …                                       │
│                              [  Cancel  ][     OK      ]  │
└─────────────────────────────────────────────────────────┘
```

- **Header**: title in the highlight color (`apt-gold`), `font-semibold`. An optional `tone` icon (info/success/error) sits to the left of the title.
- **Size**: width is proportional to content with a sensible default cap (`max-w-md` for alerts; composed dialogs may set their own). Height hugs content.
- **Padding**: consistent interior padding from `--space-*` (≈ `p-6`); footer separated by a `--space` gap; no ad-hoc values.
- **Tokens**: header `apt-gold`; body `apt-text` / `apt-text-muted`; surface `apt-surface`; border `apt-border`. Action gold (`variant="default"`) normally, red (`apt-red`) when destructive; Cancel `ghost`/`outline`. Built on the existing `Dialog` (Base UI). No raw hex; no `!important`.

## Shared State

| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| open | Caller | Dialog | Down | Prop |
| busy | Caller | Footer buttons / dismissal guard | Down | Prop; replaces buttons with a spinner |
| keyboard policy | Caller (`keyboard`, `destructive`) | Key handler | Down | Prop; `destructive` forces `"none"` |
| confirm / cancel intent | Key handler + buttons | Caller (`onConfirm` / `onCancel`) | Up | Callbacks |

## Integration Test Vectors
Verify the visual vectors with Playwright in the UI showcase app: render each variant and exercise the keyboard flows at 375, 768 and 1440 px widths. Vectors T9 to T11 are derived from the source and have no test behind them yet.

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | full-width-single-action | one-button alert | action button full width, gold |
| T2 | equal-width-when-narrow | two buttons, both natural widths within the row's equal share | equal-width `[ Cancel ][ OK ]` |
| T3 | natural-width-when-wide | two buttons, wide content (room for both at natural width) | natural-width, right-justified |
| T4 | keyboard-default | `keyboard:"default"`, Enter then Escape | Enter→confirm; Escape→cancel (or OK if no cancel) |
| T5 | keyboard-none | `keyboard:"none"`, press keys | keys ignored |
| T6 | keyboard-explicit-map | `{ Enter: "confirm" }`, then Escape | Enter→confirm; unlisted keys ignored; Escape still dismisses via cancel (or the action in alert mode) despite not being listed |
| T7 | destructive-forces-none | `destructive: true` | action red; no keyboard shortcuts |
| T8 | block-dismissal-when-busy | `busy: true` | dismissal blocked; spinner replaces buttons |
| T9 | keyboard-explicit-map, escape-routing | `{ Escape: "confirm" }` in confirm mode, press Escape | `onCancel` fires once; `onConfirm` does not (Escape is routed by `onOpenChange`, not the map) |
| T10 | keyboard-none, escape-routing | `keyboard:"none"`, press Escape, then click the backdrop | Escape does nothing; the backdrop click fires `onCancel` (confirm mode) or `onConfirm` (alert mode) once |
| T11 | destructive-forces-none, confirm-mode-trigger | `destructive: true` with no `cancelLabel` | one red button (`variant="destructive"`); Escape and Enter do nothing; backdrop click fires `onConfirm` |
| T12 | be-accessible-dialog | `destructive: true` with `cancelLabel` | Cancel has initial focus; Enter does not activate the delete button |
## Edge Cases

- When the two natural widths differ enough, the narrower button renders at its own natural width and the wider one absorbs the remaining share, capped at its own natural width, rather than both snapping to an equal split.
- A key mapped to a button that is not rendered is ignored.
- Escape always dismisses via cancel (or, in alert mode, via the action) whenever the keyboard policy is not `"none"` and the modal is not `busy`, even when the explicit map omits Escape or maps it to a different action, because Escape is routed by `onOpenChange` (`escape-routing`) and not by the key map.
- `destructive` overrides any supplied `keyboard` value (forced `"none"`) so a delete is always an explicit click.
- `busy` blocks all dismissal paths and hides the buttons behind a spinner.

## Platform Notes

- **React / Web (TypeScript):** Evolve `packages/web/packages/ui/src/components/alert-modal.tsx`; reuse `packages/web/packages/ui/src/components/dialog.tsx` (Base UI) unchanged. Extend (not replace) `packages/web/packages/ui/src/__tests__/alertModal.test.tsx`. Demo in the UI showcase app (a consumer of this package, outside this repo). The `equal-width-when-narrow` rule is realized by the `DialogActions` default `auto` layout (`flex-1 max-w-max`).
- **SwiftUI / Compose:** Not applicable — web-only shared system.
- **AppKit / UIKit:** Not applicable to this web-only system. A port would use `NSAlert` (AppKit) or `UIAlertController` (UIKit), which supply the focus trap, the button order and the Escape handling; map `destructive` to the platform's destructive button style and `confirm-mode-trigger` to adding a second button.
- **WinUI 3:** Port to a `ContentDialog`: `PrimaryButtonText` is the action and `CloseButtonText` is Cancel, `DefaultButton` set to `Close` for a destructive dialog (the focus rule), `IsPrimaryButtonEnabled` and `ProgressRing` for `busy`, and a `PreviewKeyDown` handler for an explicit key map. `ContentDialog` handles Escape itself, so the `Closing` event is where to apply `escape-routing`.

API. Props of `AlertModal`:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `open` | `boolean` | none (required) | Controlled visibility. |
| `title` | `string` | none (required) | Heading line. |
| `description` | `ReactNode` | none | Body copy. |
| `tone` | `"info" \| "success" \| "error"` | `"info"` | Leading icon and accent. |
| `confirmLabel` | `string` | `"OK"` | Action button label. |
| `confirmVariant` | `Button` variant | `"default"` | Variant of the action button. |
| `onConfirm` | `() => void` | none (required) | Action. Also fired on dismissal in alert mode. |
| `cancelLabel` | `string` | none | Presence turns on confirm mode (`confirm-mode-trigger`). |
| `onCancel` | `() => void` | none | Cancel action. Also fired on dismissal in confirm mode. |
| `busy` | `boolean` | `false` | Replaces the buttons with a spinner and blocks dismissal. |
| `keyboard` | `"default" \| "none" \| Partial<Record<string, "confirm" \| "cancel">>` | `"default"` | Keyboard policy: `"default"` (see keyboard rules), `"none"` (no shortcuts) or an explicit key to action map. |
| `destructive` | `boolean` | `false` | Action button red (`apt-red`); forces keyboard `"none"`. |

```ts
type KeyAction = "confirm" | "cancel";

interface AlertModalKeyboardAdds {
  /** "default" (see keyboard rules) | "none" (no shortcuts) | explicit key to action map. */
  keyboard?: "default" | "none" | Partial<Record<string, KeyAction>>;
  /** Destructive: action button red (apt-red); forces keyboard "none". */
  destructive?: boolean;
}
```
## Design Decisions

**Decision**: Evolve the existing `AlertModal` backward-compatibly rather than introduce a new component.
**Rationale**: Defaults preserve today's behavior (`keyboard:"default"`, `destructive:false`), so call-sites that pass only `tone`/`confirmLabel`/`cancelLabel`/`onConfirm`/`onCancel` are unaffected in API while gaining the standardized header and button layout. Smoke-check every existing call-site during implementation so the visual and keyboard change is intended, not a regression.
**Approved**: pending

**Decision**: Destructive mode forces no keyboard shortcuts.
**Rationale**: A destructive action must be a deliberate, explicit click, never Enter-to-confirm.
**Approved**: pending

**Decision**: The header + footer-button system is exposed for composed dialogs.
**Rationale**: Larger dialogs stay visually uniform with alerts and confirms.
**Approved**: pending
## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | Internationalization |

`separation-of-concerns` is passed: `AlertModal` composes two independently-recipe'd ingredients — `Dialog` for the overlay/focus-trap/portal and `Button` for footer actions — rather than reimplementing either. `unit-test-coverage` is partial: `alertModal.test.tsx` exercises the default/none keyboard policies, `destructive`, `busy`, all three button-layout modes, tone, and the closed state, but the `keyboard-explicit-map` behavior (an arbitrary key→action map, and its Escape exception) has no dedicated test even though non-Escape keys are implemented via `alert-modal.tsx`'s `keyMap`. `screen-reader-support` and `focus-management` are passed: the surface is built on Base UI's `Dialog` primitive, which supplies the role, `aria-modal`, labelling, focus-trap, and restore-to-opener machinery `be-accessible-dialog` requires. `keyboard-navigable` is passed: Enter/Escape/explicit-map handling plus the footer buttons' native Tab-then-activate semantics remain available even under `keyboard:"none"`, where only the custom shortcuts are disabled. `touch-target-size` is failed: `Button`'s fixed size-variant heights (`h-6`=24px etc.) sit below the 44×44pt/48×48dp minimum by design, reachable only through an ancestor-set `--adh-button-min-height`/`--adh-button-min-width`, and this recipe never sets either variable on its footer buttons. `contrast-ratio` is partial: the header/body/surface/border tokens (`apt-gold`, `apt-text`, `apt-surface`, `apt-border`) are used consistently in place of raw hex, but their actual rendered contrast is a property of the shared theme file this recipe's own source cannot confirm. `no-hardcoded-strings` is partial: `title`, `description`, and both button labels are caller-supplied props, but `confirmLabel`'s default value `"OK"` is a hardcoded English literal baked into `alert-modal.tsx` rather than sourced from a localization resource.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial conversion from legacy UI spec. |
| 1.1.0 | 2026-07-03 | Mike Fullerton | Rename the `tone` union member `danger`→`error` to match `AlertModalTone` in `alert-modal.tsx`. |
| 1.2.0 | 2026-09-23 | Mike Fullerton | Renamed every requirement to subject-only kebab-case, dropping the old prefix everywhere it is cited. |
| 1.2.1 | 2026-09-24 | Mike Fullerton | Compliance section rewritten as linked checks against the compliance catalog |
| 1.2.2 | 2026-09-24 | Mike Fullerton | Phase 6 lint: status draft to review after lint pass. |
| 1.2.3 | 2026-09-25 | Mike Fullerton | Fixed keyboard-explicit-map requirement (Escape override) and equal/natural-width threshold requirements plus test vectors. |
| 1.2.4 | 2026-11-14 | Mike Fullerton | Added confirm-mode and Escape-routing requirements, corrected the Escape edge case, moved consumer coupling out, added Design Decisions, API table and vectors T9 to T12. |
