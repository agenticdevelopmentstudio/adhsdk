---
id: e26e765d-2caa-40f8-a668-661ed2b0632c
title: "AlertModal"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Controlled alert/confirm modal on Dialog — tone icon, one- or two-button footer, busy spinner, configurable dismissal and keyboard policy, destructive mode."
platforms:
  - typescript
  - web
tags:
  - dialog
  - alert
  - confirm
  - modal
  - base-ui
depends-on:
  - 972be0d0-a9f5-45cd-a23b-c8329410b3d1
  - f679a77e-04f7-4e43-b898-6d78a637a760
  - f3c25236-d72f-4a7b-839a-b7f335b3acd0
related:
  - 972be0d0-a9f5-45cd-a23b-c8329410b3d1
  - f679a77e-04f7-4e43-b898-6d78a637a760
  - 550f00f7-bfb2-415e-9b15-bd5dce015500
references:
  - https://www.w3.org/TR/WCAG21/
  - https://base-ui.com/react/components/dialog
approved-by: ""
approved-date: ""
---

# AlertModal

## Overview

`AlertModal` (`packages/web/packages/ui/src/components/alert-modal.tsx`) is a
generalized, centered modal alert/confirm built on the shared `Dialog`
primitive. It renders one primary button (**alert mode**) when no
`cancelLabel` is supplied, or a primary + secondary pair via `DialogActions`
(**confirm mode**) when `cancelLabel` is supplied. Visibility is fully
controlled by the parent through the `open` prop. A leading tone icon
(`info`/`success`/`error`) can be shown in the title, the footer can be
replaced by a busy spinner, dismissal (Escape/✕ — backdrop/outside clicks never
dismiss the modal at all; see Edge Cases) can be disabled entirely, and the
keyboard shortcut policy (`Enter`/`Escape`) is configurable
per instance, including a `destructive` mode that forces the error tone and
disables keyboard shortcuts.

## Behavioral Requirements

- **render-title**: The component MUST render the `title` prop inside the dialog's `DialogTitle`.
- **render-description-when-provided**: The component MUST render `description` inside a `DialogDescription` when `description` is not `null`/`undefined`.
- **omit-description-when-absent**: The component MUST NOT render a `DialogDescription` element when `description` is `null` or `undefined`.
- **show-tone-icon-by-default**: The component MUST render the tone icon leading the title when `showIcon` is `true`, which is the default.
- **hide-tone-icon-when-disabled**: The component MUST omit the tone icon when `showIcon` is `false`.
- **mark-tone-icon-decorative**: The component MUST render the tone icon with `aria-hidden`.
- **map-tone-to-icon-and-color**: The component MUST render the `Info` icon with `text-apt-blue` for `tone="info"`, the `CheckCircle2` icon with `text-apt-green` for `tone="success"`, and the `TriangleAlert` icon with `text-apt-red` for `tone="error"`.
- **force-error-tone-when-destructive**: The component MUST use the `"error"` tone's icon and color whenever `destructive` is `true`, regardless of the value of the `tone` prop.
- **render-alert-mode-when-no-cancel-label**: The component MUST render a single, full-width confirm button in the footer (alert mode) whenever `cancelLabel` is `null` or `undefined`.
- **render-confirm-mode-when-cancel-label-set**: The component MUST render `DialogActions`, with both a cancel and a confirm button, whenever `cancelLabel` is not `null`/`undefined`.
- **invoke-onconfirm-on-confirm-click**: Activating the confirm button MUST call `onConfirm` exactly once.
- **invoke-oncancel-on-cancel-click**: In confirm mode, activating the cancel button MUST call `onCancel` exactly once.
- **tolerate-missing-oncancel**: In confirm mode, when `onCancel` is not provided, any action that would otherwise invoke it (cancel-button activation, a dismissed Escape, or pointer dismissal) MUST be a no-op — no error is thrown.
- **default-confirm-label-ok**: The component MUST default the confirm button's label to `"OK"` when `confirmLabel` is not provided.
- **default-busy-label-working**: The component MUST label the alert-mode busy spinner with `aria-label="Working…"`.
- **style-confirm-destructive-in-alert-mode**: In alert mode, the component MUST render the confirm button with the `"destructive"` variant when `destructive` is `true`.
- **apply-confirm-variant-in-alert-mode**: In alert mode, when `destructive` is `false`, the component MUST render the confirm button with `confirmVariant` if provided, and with the `"default"` variant otherwise.
- **show-busy-spinner-in-alert-mode**: In alert mode, when `busy` is `true`, the component MUST replace the confirm button with a spinner element exposing `role="status"` and `aria-label="Working…"`.
- **forward-busy-to-dialog-actions**: In confirm mode, the component MUST forward the `busy` prop to `DialogActions`.
- **forward-destructive-to-dialog-actions**: In confirm mode, the component MUST forward the `destructive` prop to `DialogActions`.
- **set-initial-focus-by-destructiveness**: In confirm mode, the component MUST set `DialogActions`' `initialFocus` to `"cancel"` when `destructive` is `true`, and to `"confirm"` otherwise.
- **hide-close-affordance-when-busy-or-non-dismissible**: The component MUST hide `DialogContent`'s `×` close affordance (`showClose`) whenever `busy` is `true` or `dismissible` is `false`.
- **default-dismissible-true**: The component MUST treat the dialog as dismissible by default (`dismissible` defaults to `true`).
- **block-dismissal-when-busy**: The component MUST block every dismissal path that can reach `handleOpenChange` (Escape, ✕, programmatic close) while `busy` is `true`; backdrop/outside clicks are already unreachable regardless of `busy` (see Edge Cases).
- **block-dismissal-when-non-dismissible**: The component MUST block every dismissal path while `dismissible` is `false`.
- **route-escape-to-cancel-in-confirm-mode**: When keyboard shortcuts are enabled and the dialog is not blocked from closing, an Escape-driven close (Base UI close reason `"escape-key"`) MUST call `onCancel` in confirm mode.
- **route-escape-to-confirm-in-alert-mode**: When keyboard shortcuts are enabled and the dialog is not blocked from closing, an Escape-driven close MUST call `onConfirm` in alert mode.
- **block-escape-when-keyboard-disabled**: The component MUST NOT call `onConfirm` or `onCancel` for an Escape-driven close when `keyboard` is `"none"` or `destructive` is `true`.
- **route-close-button-regardless-of-keyboard-policy**: A non-Escape close reason that reaches `handleOpenChange` (in practice only the ✕ affordance's `close-press`, or a programmatic close — backdrop/outside clicks never reach it at all, since the underlying `Dialog` hard-disables pointer dismissal and `AlertModal` never overrides that; see Edge Cases) MUST call `onCancel` in confirm mode or `onConfirm` in alert mode whenever the dialog is not busy and is dismissible, regardless of the `keyboard` policy's value.
- **invoke-confirm-on-enter-under-default-keyboard**: Under `keyboard="default"` (and `destructive` `false`), pressing `Enter` MUST call `onConfirm` exactly once and MUST call `preventDefault` on the triggering event.
- **ignore-all-keys-when-keyboard-none**: When `keyboard` is `"none"`, the window keydown listener MUST NOT invoke `onConfirm` or `onCancel` for any key.
- **force-keyboard-none-when-destructive**: The component MUST treat keyboard shortcuts as disabled whenever `destructive` is `true`, regardless of the value of the `keyboard` prop.
- **honor-explicit-keyboard-map**: When `keyboard` is an explicit key→action map and `destructive` is `false`, pressing a key present in the map MUST invoke the mapped action (`"confirm"` → `onConfirm`, `"cancel"` → `onCancel`).
- **ignore-unmapped-keys-in-explicit-map**: When `keyboard` is an explicit key→action map, pressing a key absent from the map MUST NOT invoke `onConfirm` or `onCancel`.
- **scope-keydown-listener-to-open-and-not-busy**: The window `keydown` listener MUST be attached only while `open` is `true` and `busy` is `false`, and MUST be removed otherwise.
- **forward-open-state-to-dialog**: The component MUST forward the `open` prop to the underlying `Dialog` root.
- **forward-content-class-name**: The component MUST forward `contentClassName` to `DialogContent`'s `className`.

## Appearance

- **Corner radius**: Not applicable — owned by `DialogContent` via the Dialog recipe ([adhsdk.ingredient.ui.components.overlays.dialog](cookbook:972be0d0-a9f5-45cd-a23b-c8329410b3d1)).
- **Padding**: Not applicable — owned by `DialogContent` via the Dialog recipe.
- **Font**: Title weight/size are inherited from `DialogTitle` (unmodified here); `AlertModal` only overrides the title's text color and adds a leading-icon layout (`flex items-center gap-2 text-apt-gold`).
- **Background**: Not applicable — owned by `DialogContent` via the Dialog recipe.
- **Foreground/Text**: Title text is `text-apt-gold`. Tone icon color is `text-apt-blue` (info), `text-apt-green` (success), or `text-apt-red` (error/destructive). Busy spinner (alert mode) is `text-apt-text-muted`.
- **Border**: Not applicable — owned by `DialogContent` via the Dialog recipe.
- **Shadow**: Not applicable — owned by `DialogContent` via the Dialog recipe.
- **Min/Max size**: Not applicable — sizing is owned by `DialogContent` and can be overridden via the `contentClassName` prop.
- **Icon size**: Tone icon is `size-5 shrink-0`; busy spinner (alert mode) is `size-4 animate-spin`.
- **Confirm button (alert mode)**: `size="sm"`, `className="w-full"` (full width of the footer).

## States

| State | Appearance change |
|-------|------------------|
| Alert mode (`cancelLabel` unset) | Single full-width confirm button in the footer |
| Confirm mode (`cancelLabel` set) | `DialogActions` renders cancel + confirm buttons |
| Busy, alert mode | Confirm button replaced by a `role="status"` `Loader2` spinner (`aria-label="Working…"`); dismissal blocked |
| Busy, confirm mode | `busy` forwarded to `DialogActions`, which replaces its own buttons with a status spinner; dismissal blocked |
| `destructive=true` | Tone icon/color forced to error; confirm button (alert mode) renders `"destructive"` variant; keyboard shortcuts forced off; in confirm mode, initial focus defaults to cancel |
| `dismissible=false` | `×` close affordance hidden; Escape/✕/programmatic close all blocked (backdrop/outside clicks are already unreachable regardless of `dismissible`) |
| `showIcon=false` | Leading tone icon omitted from the title |
| `keyboard="none"` | `Enter` ignored by the keydown listener; Escape-driven close blocked without invoking either callback |

## Accessibility

- Dialog role, `aria-modal`, focus trap, and focus restoration to the opener are inherited unchanged from the `Dialog` primitive ([adhsdk.ingredient.ui.components.overlays.dialog](cookbook:972be0d0-a9f5-45cd-a23b-c8329410b3d1)); `AlertModal` does not re-derive or override them.
- The dialog MUST be labelled by `title` (via `DialogTitle`) and, when provided, described by `description` (via `DialogDescription`).
- The tone icon is decorative: it is rendered with `aria-hidden` and never substitutes for a text label.
- The alert-mode busy spinner exposes `role="status"` and `aria-label="Working…"`; confirm-mode busy is forwarded to `DialogActions`, which applies the identical `role="status"` / `aria-label="Working…"` treatment ([adhsdk.ingredient.ui.components.overlays.dialog-actions](cookbook:f679a77e-04f7-4e43-b898-6d78a637a760)).
- Both footer buttons are the shared `Button` component, which renders a real, focusable `<button>` — keyboard activation (Space/Enter) is native ([adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0)).
- Minimum touch/click target size, minimum contrast ratio, and other platform-specific accessibility requirements are inherited from the `Button` component and the shared design-token stylesheet; see [adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0) and the WCAG 2.1 AA reference in [adc.guideline.cookbook.ui.platform-design-languages](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f26a9468-a15c-4cd2-b944-d39221e7eee2).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| T1 | render-title | `title="Delete file?"` | `DialogTitle` contains "Delete file?" |
| T2 | render-description-when-provided | `description="This cannot be undone."` | `DialogDescription` renders the text |
| T3 | omit-description-when-absent | `description` omitted | no `DialogDescription` in the DOM |
| T4 | show-tone-icon-by-default | `showIcon` omitted | tone icon renders next to the title |
| T5 | hide-tone-icon-when-disabled | `showIcon={false}` | no tone icon in the DOM |
| T6 | mark-tone-icon-decorative | any tone, icon shown | icon element has `aria-hidden` |
| T7 | map-tone-to-icon-and-color | `tone="success"` | `CheckCircle2` renders with `text-apt-green` |
| T8 | force-error-tone-when-destructive | `tone="info"`, `destructive={true}` | `TriangleAlert` renders with `text-apt-red`, not the info icon |
| T9 | render-alert-mode-when-no-cancel-label | `cancelLabel` omitted | one full-width confirm button, no cancel button |
| T10 | render-confirm-mode-when-cancel-label-set | `cancelLabel="Cancel"` | `DialogActions` renders cancel + confirm |
| T11 | invoke-onconfirm-on-confirm-click | click confirm | `onConfirm` called once |
| T12 | invoke-oncancel-on-cancel-click | confirm mode, click cancel | `onCancel` called once |
| T13 | default-confirm-label-ok | `confirmLabel` omitted | confirm button text is "OK" |
| T14 | style-confirm-destructive-in-alert-mode | alert mode, `destructive={true}` | confirm button uses `"destructive"` variant |
| T15 | apply-confirm-variant-in-alert-mode | alert mode, `destructive={false}`, `confirmVariant="outline"` | confirm button uses `"outline"` variant |
| T16 | show-busy-spinner-in-alert-mode, default-busy-label-working | alert mode, `busy={true}` | confirm button absent; `role="status"` spinner with `aria-label="Working…"` present |
| T17 | forward-busy-to-dialog-actions | confirm mode, `busy={true}` | `DialogActions` receives `busy={true}` |
| T18 | forward-destructive-to-dialog-actions | confirm mode, `destructive={true}` | `DialogActions` receives `destructive={true}` |
| T19 | set-initial-focus-by-destructiveness | confirm mode, `destructive={true}` | `DialogActions` receives `initialFocus="cancel"` |
| T19b | set-initial-focus-by-destructiveness | confirm mode, `destructive={false}` | `DialogActions` receives `initialFocus="confirm"` |
| T20 | hide-close-affordance-when-busy-or-non-dismissible | `dismissible={false}` | `DialogContent` receives `showClose={false}` |
| T20b | hide-close-affordance-when-busy-or-non-dismissible | `dismissible={true}`, `busy={true}` | `DialogContent` receives `showClose={false}` |
| T21 | default-dismissible-true | `dismissible` omitted | `×` close affordance present (not busy) |
| T22 | block-dismissal-when-busy | `busy={true}`, press Escape | `handleOpenChange` returns without invoking `onConfirm`/`onCancel`; `open` is left unchanged by the component |
| T23 | block-dismissal-when-non-dismissible | `dismissible={false}`, press Escape | `handleOpenChange` returns without invoking `onConfirm`/`onCancel`; `open` is left unchanged by the component |
| T24 | route-escape-to-cancel-in-confirm-mode | confirm mode, `keyboard="default"`, press Escape | `onCancel` called once |
| T25 | route-escape-to-confirm-in-alert-mode | alert mode, `keyboard="default"`, press Escape | `onConfirm` called once |
| T26 | block-escape-when-keyboard-disabled | `keyboard="none"`, press Escape | neither callback called; dialog stays open |
| T27 | route-close-button-regardless-of-keyboard-policy | `keyboard="none"`, confirm mode, click ✕ | `onCancel` called once |
| T27b | route-close-button-regardless-of-keyboard-policy | `keyboard="none"`, confirm mode, click backdrop | nothing happens: `onOpenChange` never fires, `onCancel` not called, dialog stays open |
| T28 | invoke-confirm-on-enter-under-default-keyboard | `keyboard="default"`, press Enter | `onConfirm` called once; event `preventDefault` called |
| T29 | ignore-all-keys-when-keyboard-none | `keyboard="none"`, press Enter | neither callback called |
| T30 | force-keyboard-none-when-destructive | `destructive={true}`, `keyboard="default"`, press Enter | `onConfirm` not called via the keydown listener |
| T31 | honor-explicit-keyboard-map | `keyboard={{ k: "confirm" }}`, press `k` | `onConfirm` called once |
| T32 | ignore-unmapped-keys-in-explicit-map | `keyboard={{ k: "confirm" }}`, press `j` | neither callback called |
| T33 | scope-keydown-listener-to-open-and-not-busy | `open={false}`, press Enter | neither callback called (listener not attached) |
| T34 | forward-open-state-to-dialog | `open={true}` | `Dialog` root receives `open={true}` |
| T35 | forward-content-class-name | `contentClassName="sm:max-w-lg"` | `DialogContent` receives that `className` |
| T36 | tolerate-missing-oncancel | confirm mode, `onCancel` omitted, click cancel | `onCancel?.()` is a no-op; no error thrown |

## Edge Cases

- **Null/empty `title`**: `title=""` renders an empty `DialogTitle` node; the source performs no fallback or validation. MUST behave this way (no guard exists).
- **Empty-string `cancelLabel`**: `isConfirm` is computed as `cancelLabel != null`, a loose-equality check that excludes only `null`/`undefined`. `cancelLabel=""` is not `null`, so it MUST trigger confirm mode and render a cancel button with a blank label — this is a boundary case a naive reader would expect to fall back to alert mode, and it does not.
- **`keyboard` object containing an `"Escape"` entry**: an explicit key→action map is used verbatim by the keydown listener (it is not restricted to `Enter`). If the caller's map includes `Escape`, that keypress invokes the mapped action from the window listener AND separately reaches Base UI's `onOpenChange` with reason `"escape-key"`, which also routes to `onCancel`/`onConfirm` — the two paths both fire for the same keypress. This is observed, defective behavior, not a guaranteed contract: the intended contract is that the window keydown listener ignores `"Escape"` so `onOpenChange` remains the single Escape path. See Design Decisions.
- **`keyboard` explicit-map key matching**: the keydown listener looks up `keyMap[e.key]` directly, so matching is against the raw `KeyboardEvent.key` string, exact and case-sensitive (e.g. a map entry for `"Escape"` does not match `"escape"`).
- **`onCancel` omitted in confirm mode**: `onCancel` is optional; the handler calls it as `onCancel?.()`, so activating cancel (button, Escape, or pointer dismissal) with no `onCancel` supplied is a no-op — no error is thrown, and the dialog remains open until the parent changes `open` itself.
- **Concurrent access**: Not applicable — `AlertModal` is a client-side, single-render UI component; all state (`open`, `busy`, etc.) is owned by the parent and passed down as props.
- **Error states**: the source does not catch or otherwise handle exceptions thrown by `onConfirm` or `onCancel`. Such an exception MUST propagate uncaught out of the event handler to the caller's own error boundary; `AlertModal` performs no retry, logging, or user-facing error display of its own.
- **Offline/disconnected state**: Not applicable — `AlertModal` makes no network requests itself; any network operation lives in the caller-supplied `onConfirm`/`onCancel` handlers, outside this component's scope.
- **`busy` and `dismissible={false}` combined**: both flags independently block dismissal (`handleOpenChange` returns early on `busy || !dismissible`); the two conditions are redundant, not additive, and produce identical blocked behavior.
- **Backdrop/outside clicks never dismiss the modal, under any combination of props**: `AlertModal` renders the shared `Dialog` ([adhsdk.ingredient.ui.components.overlays.dialog](cookbook:972be0d0-a9f5-45cd-a23b-c8329410b3d1)) without overriding its `disablePointerDismissal`, which the `Dialog` recipe hard-sets. Base UI therefore never calls `onOpenChange` for an outside press, so `handleOpenChange` never runs and neither `onConfirm` nor `onCancel` fires. Only the ✕ affordance (`close-press`, when shown) and Escape (`escape-key`) can reach `handleOpenChange` — `dismissible`, `busy`, and `keyboard` only gate what happens once one of those two reasons arrives, they do not enable backdrop dismissal.
- **`destructive={true}` with an explicit `keyboard` map**: `destructive` forces `keyboardEnabled` to `false` regardless of the map, so `force-keyboard-none-when-destructive` MUST take precedence over `honor-explicit-keyboard-map`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `open` | `boolean` | — (required) | Controlled visibility, owned by the parent. |
| `title` | `string` | — (required) | Heading line. |
| `description` | `React.ReactNode` | — | Body copy; omitted renders no `DialogDescription`. |
| `tone` | `"info" \| "success" \| "error"` | `"info"` | Sets the leading icon + accent color. |
| `confirmLabel` | `string` | `"OK"` | Primary button label. |
| `confirmVariant` | `Button["variant"]` | `undefined` (→ Button's `"default"`) | Visual variant of the primary button in alert mode when not destructive. |
| `onConfirm` | `() => void` | — (required) | Primary action; also the effective dismiss action in alert mode. |
| `cancelLabel` | `string` | — | Presence switches the component to confirm mode. |
| `onCancel` | `() => void` | — | Cancel action; also the effective dismiss action in confirm mode. |
| `busy` | `boolean` | `false` | Replaces the action buttons with a spinner and blocks dismissal. |
| `dismissible` | `boolean` | `true` | Whether Escape/✕ may close the modal (backdrop/outside clicks never close it, regardless of this prop — see Edge Cases). |
| `keyboard` | `"default" \| "none" \| Partial<Record<string, "confirm" \| "cancel">>` | `"default"` | Keyboard shortcut policy. An explicit map is matched against `KeyboardEvent.key` exactly, case-sensitively. |
| `destructive` | `boolean` | `false` | Forces the error tone visual and forces `keyboard` to behave as `"none"`. |
| `contentClassName` | `string` | `undefined` | Forwarded to `DialogContent` for width/size overrides. |
| `showIcon` | `boolean` | `true` | Whether to show the tone icon in the title. |

## Deep Linking

Not applicable — `AlertModal` is a presentational modal component with no deep-linkable state of its own.

## Localization

The strings `"OK"` (default confirm label) and `"Working…"` (busy spinner label) are hardcoded in English in `alert-modal.tsx` with no i18n key lookup. The `title`, `description`, `confirmLabel`, and `cancelLabel` props accept caller-supplied strings, permitting localization at the call site. A full i18n framework integration would require centralizing string keys and moving them to a shared resource file.

## Accessibility Options

Not applicable — `AlertModal` is a presentational component that inherits behavior from `Dialog`, which does not expose per-instance configuration for platform accessibility features such as Reduce Motion, Increase Contrast, or Differentiate Without Color. Implementations MUST rely on platform-level media query support (e.g., `prefers-reduced-motion`) and shared CSS utilities in the Button and Dialog recipes.

## Feature Flags

Not applicable — `AlertModal` contains no feature flag logic. Feature gating (if needed) belongs in the caller's decision to render the component.

## Analytics

Not applicable — `AlertModal` is a presentational component. Any success/failure telemetry for the actions invoked by `onConfirm` or `onCancel` belongs in the caller's handlers, not in the component itself.

## Privacy

- **Data collected**: None. `alert-modal.tsx` contains no data collection, storage, or transmission code.
- **Storage**: Not applicable — the component holds no persistent state.
- **Transmission**: Not applicable — the component makes no network calls.
- **Retention**: Not applicable.

## Logging

Not applicable — `AlertModal` is a presentational component and issues no log calls in this source. Any success/error telemetry belongs to the caller's `onConfirm`/`onCancel` handlers.

## Platform Notes

- **SwiftUI**: Not applicable — no SwiftUI implementation is in scope for this recipe.
- **Compose**: Not applicable — no Compose implementation is in scope for this recipe.
- **React/Web**: `packages/web/packages/ui/src/components/alert-modal.tsx`, `"use client"`, built on `@base-ui/react/dialog` via the shared `Dialog` primitive ([adhsdk.ingredient.ui.components.overlays.dialog](cookbook:972be0d0-a9f5-45cd-a23b-c8329410b3d1)). Renders `DialogActions` ([adhsdk.ingredient.ui.components.overlays.dialog-actions](cookbook:f679a77e-04f7-4e43-b898-6d78a637a760)) in confirm mode and the shared `Button` ([adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0)) in alert mode.
- **AppKit / UIKit**: Not applicable — no AppKit/UIKit implementation is in scope for this recipe.
- **WinUI 3**: Start from `ContentDialog` (Fluent 2's modal primitive). In alert mode, render a single `PrimaryButtonText` button; in confirm mode, add `SecondaryButtonText` and set `SecondaryButtonClick` to invoke cancel. Replace buttons with a custom busy `Content` template (a `ProgressRing` inside a `StackPanel`) when busy. `IsPrimaryButtonEnabled` only disables the primary button — it does not block light-dismiss or Escape — so blocking dismissal while `busy` or `!dismissible` requires handling `ContentDialog.Closing` and setting `args.Cancel = busy || !dismissible`; hide the close button via a custom template override. For keyboard policy: `ContentDialog` has no built-in per-instance `Escape`/`Enter` remapping, so attach a `KeyDown` handler to the dialog when `keyboard` is an explicit map or `"none"`; when `keyboard="default"`, defer to the default behavior (Enter → `PrimaryButton`, Escape → cancel/dismiss, subject to the same `Closing` guard). The `destructive` flag changes the primary button's styling to danger/red and forces the keyboard handler to block all key actions.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/alert-modal.tsx` | unverified |

## Design Decisions

- **Decision**: Treat the explicit-keyboard-map double-fire on `Escape` as an unintended discrepancy, not a contract. The component's own doc comment states "The window keydown listener handles Enter only, so there is no double-fire path," but that is only true for `keyboard="default"` — when `keyboard` is an explicit object, the keydown listener dispatches on *any* key present in it, including a caller-supplied `"Escape"` entry, which then ALSO reaches Base UI's `onOpenChange` (reason `"escape-key"`), invoking the mapped callback twice for one keypress. The intended contract is that the window keydown listener ignores `"Escape"` entirely, leaving `onOpenChange` as the single Escape path.
  **Rationale**: The source's own comment already asserts single-path Escape handling; the explicit-map branch that bypasses this is a gap between stated intent and implementation, not a deliberate design choice, so it is recorded as a defect to close rather than ratified as behavior. See `honor-explicit-keyboard-map` and the matching Edge Cases entry.
  **Approved**: pending
- **Decision**: `destructive={true}` bundles two independent effects — forcing the error tone (icon + color) and forcing the keyboard policy to behave as `"none"` — from a single boolean, rather than exposing separate `tone`/`keyboard`-disable overrides.
  **Rationale**: A destructive action is exactly the case where an accidental Enter/Escape keypress is most costly, so pairing the visual warning with suppressed keyboard shortcuts is safer than letting a caller opt into one effect without the other; the coupling is accepted as a safety default rather than split into finer-grained props.
  **Approved**: pending
- **Decision**: The busy-state spinner (`role="status"` / `aria-label="Working…"`) is implemented twice — inline via `Loader2` in alert mode, and delegated to `DialogActions` in confirm mode — instead of both modes delegating to one shared busy-indicator ingredient.
  **Rationale**: The two code paths currently produce identical visual/accessible output, but the duplication is unresolved technical debt rather than an intentional choice; noted here so a future pass can extract a shared busy-indicator ingredient both modes call.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.user-safety.safe-defaults](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dd43bec7-e292-559a-81e3-c0cf59156abe) | passed | User Safety |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on: `alert-modal.tsx`'s extensive Enter/Escape/pointer requirements and the native `Button`/`DialogActions` markup for keyboard-navigable, screen-reader-support, and semantic-markup; the inherited, unmodified `Dialog` focus trap plus the `initialFocus` prop for focus-management; the `apt-*` design tokens (whose actual contrast values and geometry this file doesn't itself define) for contrast-ratio and touch-target-size; the hardcoded `"animate-spin"` busy spinner with no `prefers-reduced-motion` handling in this file for reduced-motion; the title/description text inherited unmodified from `DialogTitle`/`DialogDescription` for dynamic-type-support; the Localization section's own statement that `"OK"` and `"Working…"` are hardcoded with no i18n key lookup for no-hardcoded-strings and string-externalization; and the conservative defaults (`dismissible=true`, `busy=false`, `destructive=false`) for safe-defaults. Best-practices statuses reflect that the keyboard-map and `handleOpenChange` dismiss-routing logic is inlined in the component rather than separated apart from rendering (separation-of-concerns: partial), and that `alertModal.test.tsx` directly renders `AlertModal` and asserts alert, confirm, busy, and destructive behavior (unit-test-coverage: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Renamed pointer-dismissal requirement to route-close-button-regardless-of-keyboard-policy; corrected backdrop-never-dismisses behavior and test vectors. Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; reformatted Design Decisions to the Decision/Rationale/Approved triple; resolved the Escape double-fire contradiction between Edge Cases and Design Decisions; added `default-busy-label-working` and `tolerate-missing-oncancel` requirements with test vectors; added missing test vectors for the `initialFocus` default branch and the busy-only `showClose` branch; clarified explicit-keyboard-map key-matching semantics; corrected the WinUI 3 dismissal guidance; fixed an unbalanced backtick in Platform Notes; trimmed `tags` to five; added `references`; rewrote Compliance with linked catalog checks and legal statuses. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial recipe extracted from `packages/web/packages/ui/src/components/alert-modal.tsx`. |
