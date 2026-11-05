---
id: 9e36a0ef-67ef-485d-8ace-68886add841c
title: Unsaved Changes Alert
domain: adhsdk://recipes/unsaved-changes-alert
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Modal alert that prompts the user before discarding unsaved edits, with a
  customizable description of what is at risk.
platforms:
- typescript
- web
tags:
- dialog
- modal
- destructive-action
- form-management
depends-on:
- adhsdk://recipes/alert-modal
related: []
references: []
approved-by: ''
approved-date: ''
---

# Unsaved Changes Alert

## Overview

The Unsaved Changes Alert is a modal dialog that blocks interaction and prompts the user before discarding unsaved edits. It is the canonical prompt for all editable surfaces that risk data loss on exit or dismissal. The component enforces consistency by fixing the title ("Discard unsaved changes?") and button labels ("Discard" and "Stay") — only the description text may be customized when the surface can specifically name what is at risk. The component never saves; the user must return to the surface and save there, keeping the component free of persistence dependencies.

## Behavioral Requirements

- **show-modal-when-open**: Component MUST display a modal dialog when `open` is `true`, blocking all interaction outside the modal until dismissed.
- **hide-modal-when-closed**: Component MUST NOT display when `open` is `false`.
- **fixed-title**: Component MUST display the title associated with the `title` localization key ("Discard unsaved changes?" in `en`) and MUST NOT accept a `title` prop — the string may vary by locale but is never caller-supplied.
- **fixed-button-labels**: Component MUST display the destructive action using the `confirmLabel` key ("Discard" in `en`) and the cancel action using the `cancelLabel` key ("Stay" in `en`), and MUST NOT accept customizable button-label props — the strings may vary by locale but are never caller-supplied.
- **render-description**: Component MUST render the description text in the modal body, including when `description` is the empty string.
- **default-description**: Component MUST use "Your unsaved changes will be lost." as the description when the `description` prop is `undefined`.
- **custom-description**: Component MUST accept an optional `description` prop to override the default description for surfaces that can name what is at risk.
- **discard-callback**: Component MUST call the `onDiscard` callback when the user confirms the destructive action (clicks or taps "Discard").
- **dismissal-outcomes**: Every dismissal path MUST have a defined outcome: clicking "Stay" invokes `onStay`; clicking the close (✕) button invokes `onStay`; clicking or tapping the backdrop/overlay does nothing (pointer dismissal outside a button is disabled); pressing Escape does nothing (see discard-requires-explicit-action). No path other than clicking "Discard" MUST invoke `onDiscard`.
- **discard-requires-explicit-action**: Component MUST ensure neither pressing Enter nor pressing Escape invokes `onDiscard`; discarding requires an explicit click or tap on "Discard". Initial focus MUST land on "Stay" when the modal opens.
- **controlled-visibility**: Component MUST be fully controlled by the `open` prop; it MUST NOT close itself or otherwise change its own visibility in response to `onDiscard` or `onStay` being invoked — the parent MUST set `open` to `false`.
- **no-persistence**: Component MUST NOT persist data; it returns control to the caller to handle persistence on the editing surface.

## Appearance

Not applicable: The component is a wrapper around AlertModal and does not define appearance directly. Visual appearance, spacing, colors, typography, and shadow are delegated to the underlying AlertModal component and inherit its design tokens.

## States

| State | Appearance change |
|-------|-------------------|
| Open | Modal displayed, overlay active, focus trapped inside modal |
| Closed | Modal not displayed |

## Accessibility

- **role**: Role is `dialog` (inherited from AlertModal's underlying `Dialog` wrapper over base-ui's plain, non-alert `Dialog` primitive — not `alertdialog`; the package's own tests query this prompt by role `dialog`).
- **label-requirement**: The modal's accessible name is its title, "Discard unsaved changes?".
- **description-requirement**: The description prop provides the accessible description of what will be lost. Implementations MUST associate the description text with the modal using `aria-describedby` or equivalent, even when the description is the empty string (see render-description).
- **keyboard-navigation**: Focus MUST be trapped inside the modal while it is open. Neither Enter nor Escape MUST invoke `onDiscard` (discard-requires-explicit-action); every dismissal path's outcome is defined in dismissal-outcomes.
- **button-labels**: Both buttons MUST have accessible labels; "Discard" and "Stay" are the required labels.
- **minimum-touch-target**: Per [Apple HIG: Layout](https://developer.apple.com/design/human-interface-guidelines/layout) and [Material Design: Accessible design](https://m3.material.io/foundations/accessible-design/overview), both buttons MUST have a touch target of at least 44×44 pt (iOS) or 48×48 dp (Android); per [WCAG 2.5.5 Target Size (Enhanced)](https://www.w3.org/WAI/WCAG21/Understanding/target-size.html), the web target is at least 44×44 CSS px.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| unsaved-001 | show-modal-when-open | `open={true}` | Modal dialog is visible; overlay blocks interaction outside the modal |
| unsaved-002 | hide-modal-when-closed | `open={false}` | Modal dialog is not rendered or is hidden |
| unsaved-003 | fixed-title | Any props | Modal title displays "Discard unsaved changes?" |
| unsaved-004 | fixed-button-labels | Any props | Destructive button is labeled "Discard"; cancel button is labeled "Stay" |
| unsaved-005 | render-description | `description="Staged users will not be saved."` | Description text "Staged users will not be saved." appears in modal body |
| unsaved-006 | default-description | No `description` prop (`undefined`) | Description text "Your unsaved changes will be lost." appears in modal body |
| unsaved-007 | custom-description | `description="Composed invitation cannot be sent."` | Description is overridden with "Composed invitation cannot be sent." |
| unsaved-008 | discard-callback, controlled-visibility | User clicks "Discard" button | `onDiscard` callback is invoked once; modal remains open until the parent sets `open` to `false` |
| unsaved-009 | dismissal-outcomes | User clicks "Stay" button | `onStay` callback is invoked once |
| unsaved-010 | dismissal-outcomes, discard-requires-explicit-action | User presses Escape key while modal is open | Nothing happens; Escape does not dismiss the modal, invoke `onDiscard`, or invoke `onStay` |
| unsaved-011 | discard-requires-explicit-action | User presses Enter key while modal is open | Nothing happens; Enter does not invoke `onDiscard` |
| unsaved-012 | no-persistence | Either callback invoked | No network request or persistence operation occurs; caller retains responsibility for persistence |
| unsaved-013 | dismissal-outcomes | User clicks the close (✕) button | `onStay` callback is invoked once; the modal does not close itself |
| unsaved-014 | dismissal-outcomes | User clicks or taps the backdrop/overlay outside the modal | Nothing happens; neither `onDiscard` nor `onStay` is invoked, and the modal remains open |
| unsaved-015 | discard-requires-explicit-action | Modal is closed (`open={false}`) and immediately reopened (`open={true}`) | Initial focus lands on the "Stay" button |
| unsaved-016 | render-description | `description=""` | Modal still renders an empty description region; the default description text is NOT shown |
| unsaved-017 | controlled-visibility | Parent sets `open` to `false` while the modal is displayed | Modal closes; neither `onDiscard` nor `onStay` is invoked as a result of that transition |
| unsaved-018 | render-description | `description` exceeds the modal's content width | Text wraps within the modal body without breaking layout; no horizontal overflow |
| unsaved-019 | controlled-visibility | `onDiscard`/`onStay` omitted at a call site (TypeScript) | Compilation fails; the props are required, not optional, and the component defines no runtime fallback for their absence |

## Edge Cases

- **Empty description**: When `description=""` is passed explicitly, the JS default parameter does not apply (defaults apply only to `undefined`), so the empty string is forwarded to AlertModal unchanged. Because the value is non-`null`, AlertModal still renders the description region and associates `aria-describedby` with it — the modal does NOT fall back to the default text. See unsaved-016.
- **Null or undefined description**: When `description` is not provided or is `undefined`, the component MUST use the default description "Your unsaved changes will be lost."
- **Very long description**: When `description` exceeds the modal's content width, the text SHOULD wrap within the modal body without breaking layout. See unsaved-018.
- **Required callbacks**: `onDiscard` and `onStay` are required props (see Configuration), not optional — the component defines no no-op or undefined-callback handling because the type system does not allow either to be omitted. See unsaved-019.
- **Rapid re-opens**: When the modal is closed (`open={false}`) and immediately re-opened (`open={true}`), the modal MUST display correctly with focus reset to the "Stay" button (per discard-requires-explicit-action). See unsaved-015.
- **Open toggle during interaction**: When the `open` prop is externally set to `false` while the modal is displayed, the modal MUST close, and that transition alone MUST NOT invoke `onDiscard` or `onStay` — the component holds no internal state and does not react to its own prop changes by firing callbacks. See unsaved-017.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `open` | `boolean` | — (required) | Whether the alert is visible. The component is fully controlled by this prop (controlled-visibility). |
| `onDiscard` | `() => void` | — (required) | Invoked when the user confirms discarding unsaved changes. |
| `onStay` | `() => void` | — (required) | Invoked when the user cancels and stays, from any dismissal path that resolves to Stay (dismissal-outcomes). |
| `description` | `string` | `"Your unsaved changes will be lost."` | Overrides the default description sentence naming what is at risk. |

## Deep Linking

Not applicable: This is a modal dialog component with no page-level URL or navigation semantics. Deep linking is not applicable.

## Localization

These are fixed per-locale keys, never a caller-supplied string (see fixed-title, fixed-button-labels).

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| title | Discard unsaved changes? | Modal title; fixed, not customizable |
| confirmLabel | Discard | Destructive action button; fixed, not customizable |
| cancelLabel | Stay | Cancel action button; fixed, not customizable |
| defaultDescription | Your unsaved changes will be lost. | Default modal description when not overridden |

## Accessibility Options

Appearance is delegated entirely to AlertModal (see Appearance), so these behaviors are AlertModal's to define, not this component's:

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not owned by this component; see [AlertModal Accessibility Options](adhsdk://recipes/alert-modal#accessibility-options) for its reduced-motion behavior. |
| Increase Contrast | Not owned by this component; see [AlertModal Accessibility Options](adhsdk://recipes/alert-modal#accessibility-options) for its contrast behavior. |
| Differentiate Without Color | Not owned by this component; the destructive styling comes from AlertModal's `destructive` prop — see [AlertModal Accessibility Options](adhsdk://recipes/alert-modal#accessibility-options). |

## Feature Flags

Not applicable: The component is a standard UI element with no feature flag gating or conditional behavior.

## Analytics

Not applicable: The component does not emit analytics events; parent surfaces are responsible for tracking modal interactions if needed.

## Privacy

- **Data collected**: None; the component collects no personal or sensitive data.
- **Storage**: No data is stored by this component.
- **Transmission**: No data is transmitted.
- **Retention**: N/A.

## Logging

Not applicable: The component does not perform logging; parent error handling or debugging is the responsibility of the caller.

## Platform Notes

- **React/Web**: Implemented in React using the Next.js `"use client"` directive. Source: `packages/web/packages/ui/src/components/unsaved-changes-alert.tsx`. It wraps `AlertModal` (`packages/web/packages/ui/src/components/alert-modal.tsx`) with `destructive` set. `destructive` is what makes discard-requires-explicit-action true: it forces `AlertModal`'s keyboard handling off entirely, so neither Enter nor Escape reach the confirm/cancel key map, and it sets `initialFocus="cancel"` in the two-button footer, so focus opens on "Stay". `AlertModal`'s underlying `Dialog` also sets `disablePointerDismissal`, so a backdrop/overlay click does not close the modal either — only the "Discard"/"Stay" buttons or the ✕ close button (which routes to `onCancel`/`onStay`) do (dismissal-outcomes). The `description` prop passes straight through to `AlertModal`'s `description` prop; every other `AlertModal` prop (`title`, `confirmLabel`, `cancelLabel`) is fixed in source.
- **SwiftUI**: Take a `Binding<Bool>` for `open` from the caller — do not own `@State` internally, since visibility is controlled by the parent (controlled-visibility). Present with `.alert(_:isPresented:actions:message:)`, supplying `Button("Discard", role: .destructive) { onDiscard() }` and `Button("Stay", role: .cancel) { onStay() }`. Title is fixed to "Discard unsaved changes?"; `message:` carries the customizable description.
- **AppKit / UIKit**: Use `UIAlertController` with `preferredStyle: .alert`. Add two `UIAlertAction`s: one with `style: .destructive` labeled "Discard" invoking `onDiscard`, and one with `style: .cancel` labeled "Stay" invoking `onStay`. Present modally with `present(_:animated:completion:)`. Manage visibility via a view controller property or presentation controller, driven by `open` (controlled-visibility).
- **Compose**: Use `AlertDialog` with `onDismissRequest = onStay` — dismissing via the back gesture or an outside touch maps to Stay, matching dismissal-outcomes; the destructive action must never fire on dismiss. Title is a fixed `Text("Discard unsaved changes?")`; `text` carries the customizable description. Provide `confirmButton = { TextButton(onClick = onDiscard) { Text("Discard") } }` and `dismissButton = { TextButton(onClick = onStay) { Text("Stay") } }`. Style the destructive button's content color with `MaterialTheme.colorScheme.error`, not a hardcoded red.
- **WinUI 3**: Use `ContentDialog` with `Title` fixed to "Discard unsaved changes?" (as a string resource if localizing) and `Content` bound to the description text. `ContentDialog` has no `IsOpen` property — show it with `await dialog.ShowAsync()` when `open` becomes `true`, and call `dialog.Hide()` when the parent sets `open` to `false` (controlled-visibility). Set `PrimaryButtonText="Discard"`, `CloseButtonText="Stay"`, and `DefaultButton="Close"` so the default action lands on Stay, not Discard (discard-requires-explicit-action). Map the `ContentDialogResult` from `ShowAsync()`: `Primary` → `onDiscard()`; anything else (`None`/`Secondary`, i.e. the close button or a system dismissal) → `onStay()`. Use the platform's destructive text style for the primary button instead of a hardcoded red `Background`.

## Design Decisions

1. **Decision**: The title "Discard unsaved changes?" and the button labels "Discard" and "Stay" are fixed and not customizable.
   **Rationale**: This is a consistency guarantee across all surfaces using this component — every editable surface asks the same question in the same words, preventing fragmentation of the user experience and keeping it familiar.
   **Approved**: pending

2. **Decision**: `description` is the single customizable prop; the title and button labels are not.
   **Rationale**: "What our prompt says" is shared knowledge, while "what is at risk on this surface" is the surface's own. Overriding `description` lets a surface be specific (e.g., "Staged users will not be saved" vs. "Composed invitation cannot be sent") while keeping a consistent question-and-answer structure. A surface with nothing more specific to say passes nothing and receives the default.
   **Approved**: pending

3. **Decision**: The component never saves or persists data itself.
   **Rationale**: Keeps it decoupled from any specific persistence mechanism (localStorage, server API, IndexedDB, etc.) and reusable across surfaces with different storage strategies; persisting changes remains the surface's responsibility, not the alert's.
   **Approved**: pending

4. **Decision**: Setting `destructive` on the underlying AlertModal disables its keyboard shortcuts entirely and sets initial focus to "Stay", so neither Enter nor Escape can invoke Discard.
   **Rationale**: Losing edits must be a deliberate click or tap, not a keyboard accident (discard-requires-explicit-action).
   **Approved**: pending

5. **Decision**: The alert is a modal dialog that traps focus and blocks interaction outside itself, including pointer dismissal via the backdrop.
   **Rationale**: The user cannot make further changes while the prompt is open — the choice is binary and immediate, and only clicking a button ("Discard", "Stay", or ✕) resolves it (dismissal-outcomes).
   **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | failed | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

The accessibility statuses rest on the source's use of Base-UI's Title/Description/Popup primitives, native `<button>` elements, and the explicit initial-focus effect in `dialog-actions.tsx` (focus-management, screen-reader-support, semantic-markup, keyboard-navigable pass), weighed against the `sm` button size (`h-7`, 28px, in `button.tsx`) falling short of the 44×44/48×48 minimum (touch-target-size fails) and the theme-token-dependent colors this repo cannot resolve statically (contrast-ratio partial); the internationalization statuses rest on the literal inline strings in `unsaved-changes-alert.tsx` (`title="Discard unsaved changes?"`, `confirmLabel="Discard"`, `cancelLabel="Stay"`) with no localization-resource lookup. `separation-of-concerns` passes because the component is pure presentation delegating to `AlertModal` with no business logic, and `unit-test-coverage` passes on `unsavedChangesAlert.test.tsx`'s exercise of its buttons, callbacks, description override, focus, and Escape handling.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Accessibility role corrected from alertdialog to dialog, matching AlertModal's base-ui Dialog primitive and the package's own tests. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; restated discard-requires-explicit-action and dismissal-outcomes as observable behavior and moved AlertModal wiring into React/Web Platform Notes; added controlled-visibility requirement and a props Configuration table; reformatted Design Decisions to Decision/Rationale/Approved; added a Compliance table; corrected SwiftUI/Compose/WinUI 3 platform notes; expanded Edge Cases and Conformance Test Vectors; delegated Accessibility Options to AlertModal; cited specific touch-target guidance and added a web target; added depends-on and fixed frontmatter date formatting |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
