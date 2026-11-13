---
id: 9f87b4cd-f3a0-482b-830d-c1482ed51bbe
title: "Create Resource Dialog"
type: ingredient
version: 1.2.2
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Modal dialog for creating resources with form validation, unsaved-changes guard, and async error handling."
platforms:
  - typescript
  - web
tags:
  - dialog
  - form
  - modal
  - create
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Create Resource Dialog

## Overview

A reusable modal dialog component for creating new resources. The dialog renders a form via a callback, validates input on save, invokes an async creation function, and guards against accidental data loss via an unsaved-changes alert. The dialog is portal-rendered to the document body to avoid stacking context issues from ancestor overflow constraints or inert state.

## Behavioral Requirements

- **render-modal-dialog**: Component MUST render a modal dialog with `role="dialog"` and `aria-modal="true"` that portals to `document.body`.
- **render-heading**: Component MUST render the provided `heading` prop as an h2 element.
- **render-form-content**: Component MUST render the form via the `renderForm` callback, passing current draft state, onChange handler, and current error message.
- **render-close-button**: Component MUST render a close button (×) labeled "Close" in the top-right corner of the dialog header.
- **render-cancel-button**: Component MUST render a "Cancel" button in the footer.
- **render-save-button**: Component MUST render a "Save" button in the footer that displays "Saving…" text while an async create operation is in progress.
- **disable-save-when-pristine**: Component MUST disable the Save button when the draft state is identical to the blank (pristine) initial state.
- **validate-on-save**: Component MUST call the `validate` callback when Save is clicked, and MUST pass the returned error string (or `null` when valid) to `renderForm` as its third argument on the next render; displaying the message is `renderForm`'s responsibility, not this component's.
- **prevent-save-when-invalid**: Component MUST NOT invoke the `create` callback if `validate` returns a non-null error.
- **invoke-create-on-save**: Component MUST invoke the `create` callback with the validated draft when Save is clicked and validation passes.
- **disable-buttons-while-saving**: Component MUST disable both Cancel and Save buttons while the `create` operation is in progress.
- **invoke-oncreated-on-success**: Component MUST invoke the `onCreated` callback with the result of `create` when the operation succeeds.
- **display-create-error**: When `create` throws, Component MUST derive an error message — the thrown value's `message` property if it is an `Error`, otherwise the string "Failed to create." — and pass it to `renderForm` the same way `validate-on-save` does, for the callback to display.
- **invoke-onsaveerror-on-create-failure**: Component MUST invoke the `onSaveError` callback with the exception when `create` fails, if the callback is provided.
- **guard-close-on-dirty**: Component MUST show the `UnsavedChangesAlert` component when the user attempts to close (via Cancel, ×, or Escape) and the draft has unsaved changes.
- **discard-invokes-onclose**: Component MUST invoke `onClose` when the user chooses Discard in the `UnsavedChangesAlert`. The component does not reset `confirming` on this path, so `UnsavedChangesAlert` itself stays open; it disappears only if the host responds to `onClose` by unmounting the dialog.
- **stay-dismisses-alert**: Component MUST dismiss the `UnsavedChangesAlert` and leave the dialog open with the draft intact when the user chooses Stay; `onClose` MUST NOT be invoked.
- **ignore-backdrop-click**: Component MUST NOT close when the backdrop (overlay background) is clicked.
- **route-escape-through-guard**: Component MUST route Escape key presses through the same close guard as Cancel and ×, respecting the unsaved-changes alert state.
- **escape-active-during-save**: Component MUST evaluate the Escape key handler the same way regardless of the `saving` state; Escape is not disabled while a create operation is in progress, even though Cancel and Save are.
- **support-optional-save-gate**: Component MUST respect the optional `saveEnabled` callback and disable Save if it returns false, in addition to the pristine-state check.
- **render-only-on-client**: Component MUST NOT render on the server; it MUST return `null` when `document` is undefined.
- **use-aria-label**: Component MUST apply the `ariaLabel` prop to the dialog container as `aria-label`.

## Appearance

- **Overlay background**: Black with 70% opacity (`bg-black/70`)
- **Overlay layout**: Fixed position, full screen, flex row centered horizontally and top-aligned vertically, with auto scroll for tall content (`fixed inset-0 z-50 flex items-start justify-center overflow-y-auto p-6`)
- **Dialog container**: Rounded corners (12px), border, surface background, shadow, relative positioning, max width 3xl (48rem), top-aligned within the overlay (not vertically centered) with 32px (`my-8`) margin above and below so it can scroll alongside tall form content
- **Dialog padding**: 24px (p-6)
- **Header spacing**: Flex row, space-between alignment, 16px gap (gap-4) between heading and close button
- **Heading**: h2 element, base font size (16px), font-semibold weight, text color
- **Form section**: Rendered via `renderForm` callback
- **Error message**: No dedicated slot in this component; the `error` string is passed to `renderForm` as its third argument, and the callback owns rendering and positioning it
- **Footer**: Flex row, justify-end alignment, 8px gap (gap-2) between Cancel and Save buttons
- **Buttons**: Cancel uses ghost variant at default size; Save uses the default (primary) variant at default size; the close (×) button uses ghost variant at `icon-sm` size (28×28px, `size-7`)

## States

| State | Appearance change |
|-------|------------------|
| Default | Form is empty (pristine), Save button is disabled, no error message visible |
| Dirty | Form has been edited, Save button is enabled (unless saveEnabled returns false), no error message |
| Focused | Keyboard focus is visible on any interactive control (button, form field) |
| Validating (implied) | User clicked Save; inline validation runs synchronously before async operation |
| Saving | Both Cancel and Save buttons are disabled; Save button text changes to "Saving…" |
| Error | `error` is set and passed into `renderForm`, which is responsible for displaying it; Cancel and Save return to their normal enabled state (Save gated by `canSave`) once saving completes, since only the `saving` flag disables them |
| Confirming | UnsavedChangesAlert is displayed as a sibling overlay; dialog remains visible but interaction is focused on the alert |
| Server-side (implied) | Component returns null when document is undefined (SSR context) |

## Accessibility

- **Dialog role**: Component uses `role="dialog"` and `aria-modal="true"` to signal a modal dialog to assistive technology.
- **Accessible label**: Component applies `aria-label` from the `ariaLabel` prop to the dialog container.
- **Heading**: The heading is rendered as an h2 element to provide semantic structure.
- **Close button label**: Close button has `aria-label="Close"` to describe its purpose to screen readers.
- **Form labels**: Responsibility for form field labeling and accessibility is delegated to the `renderForm` callback.
- **Error announcement**: The `error` value is handed to `renderForm` for inline display; the component itself uses no ARIA live region, so whether an error reaches assistive technology as an announcement (e.g. via `aria-describedby` or a live region) depends on the host's `renderForm` implementation.
- **Keyboard navigation**: DOM order (and default Tab order) is the close (×) button, then the form fields rendered by `renderForm`, then Cancel, then Save; Escape is handled through the same close guard as Cancel and ×.
- **Focus management**: The source calls no focus API. It does not move focus into the dialog on open, does not confine Tab within it while open, and does not restore focus to the invoking control on close — all three left unhandled for a container that declares `role="dialog"` and `aria-modal="true"`, where the WAI-ARIA Authoring Practices dialog pattern and WCAG 2.1 SC 2.4.3 (Focus Order) call for each.
- **Backdrop interaction**: Backdrop click is intentionally non-interactive to prevent accidental dismissal; this is accessible since keyboard and explicit buttons provide alternatives.
- **Minimum touch target**: Cancel and Save are text buttons at the `default` size (`h-8`, 32px tall, width driven by label + padding). The close (×) button uses `icon-sm` (`size-7`, 28×28px), below the 44×44pt/48×48dp guideline, unless a host surface raises the shared `--adh-button-min-height`/`--adh-button-min-width` CSS variables that `Button` reads for exactly this purpose; this dialog does not set them itself.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|----|---|---|
| create-resource-001 | render-modal-dialog | Component is mounted | Modal dialog renders with `role="dialog"` and `aria-modal="true"` in document.body |
| create-resource-002 | render-heading | heading="New Product" | h2 element renders with text "New Product" |
| create-resource-003 | render-close-button | Component is mounted | Close button (×) is rendered in dialog header with aria-label="Close" |
| create-resource-004 | render-cancel-button | Component is mounted | Cancel button is rendered in footer |
| create-resource-005 | render-save-button | Component is mounted | Save button is rendered in footer with text "Save" |
| create-resource-006 | disable-save-when-pristine | Draft state equals blank state | Save button has disabled attribute |
| create-resource-007 | disable-save-when-pristine | User edits form (draft differs from blank) | Save button is enabled |
| create-resource-008 | validate-on-save | User clicks Save; validate returns "Name is required" | `renderForm` receives error="Name is required" as its third argument on the next render; display is renderForm's responsibility |
| create-resource-009 | prevent-save-when-invalid | User clicks Save; validate returns non-null error | Create callback is not invoked |
| create-resource-010 | invoke-create-on-save | User clicks Save; validate returns null | Create callback is invoked with current draft |
| create-resource-011 | disable-buttons-while-saving | Create callback is in progress | Both Cancel and Save buttons have disabled attribute |
| create-resource-012 | render-save-button | Create operation is in progress | Save button text is "Saving…" |
| create-resource-013 | invoke-oncreated-on-success | Create callback resolves successfully | onCreated callback is invoked with the result; UnsavedChangesAlert is not shown; the component does not close itself (closing after success, e.g. by unmounting, is left to the host) |
| create-resource-014 | display-create-error, disable-buttons-while-saving | Create callback throws Error("Network timeout") | `renderForm`'s error argument becomes "Network timeout" on the next render; `saving` flips to false, so Cancel and Save return to their normal enabled state |
| create-resource-015 | display-create-error | Create callback throws non-Error object | `renderForm`'s error argument becomes "Failed to create." |
| create-resource-016 | invoke-onsaveerror-on-create-failure | Create callback throws; onSaveError is provided | onSaveError callback is invoked with the exception |
| create-resource-017 | guard-close-on-dirty | User clicks Cancel; draft is dirty | UnsavedChangesAlert is shown; dialog is not closed |
| create-resource-018 | guard-close-on-dirty | User clicks ×; draft is pristine | Dialog closes immediately without showing alert |
| create-resource-019 | ignore-backdrop-click | User clicks overlay background | Dialog remains open |
| create-resource-020 | route-escape-through-guard | User presses Escape; draft is dirty | UnsavedChangesAlert is shown |
| create-resource-021 | route-escape-through-guard, stay-dismisses-alert | User presses Escape while alert is open | Alert is dismissed (mapped to Stay); dialog remains open |
| create-resource-022 | route-escape-through-guard | User presses Escape; draft is pristine | Dialog closes without showing alert |
| create-resource-023 | support-optional-save-gate | saveEnabled returns false | Save button is disabled even if draft is dirty |
| create-resource-024 | support-optional-save-gate | saveEnabled returns true and draft is dirty | Save button is enabled |
| create-resource-025 | render-only-on-client | Component is rendered on server (document is undefined) | Component returns null |
| create-resource-026 | discard-invokes-onclose | User clicks Discard in UnsavedChangesAlert | onClose is invoked; UnsavedChangesAlert itself is not dismissed by this click and remains visible unless the host unmounts the dialog in response to onClose |
| create-resource-027 | stay-dismisses-alert | User clicks Stay in UnsavedChangesAlert | UnsavedChangesAlert closes; dialog remains open with the draft unchanged; onClose is not invoked |
| create-resource-028 | escape-active-during-save | User presses Escape while `saving` is true and draft is dirty | UnsavedChangesAlert is shown even though Cancel and Save are currently disabled |
| create-resource-029 | render-form-content | Component is mounted with draft state, an onChange handler, and error=null | `renderForm` is invoked with `(draft, onChange, error)` in that order; its returned content renders between the header and footer |
| create-resource-030 | use-aria-label | ariaLabel="Create Product" | Dialog container element has aria-label="Create Product" |

## Edge Cases

- **Blank state is taken as given**: `blank` is passed as the lazy initializer to both `useState<TInput>(blank)` and the `pristine` baseline. The component MUST accept whatever it returns — including `null`, `undefined`, or an empty object — without inspecting, validating, or sanitizing it. Supplying a usable initial draft is the host's contract, and an unusable one surfaces only through `renderForm` or `validate`.
- **`validate` throws**: `save()` calls `validate(draft)` before and outside the `try` block, which wraps only `create`. An exception thrown by `validate` therefore propagates out of the Save click handler uncaught: no inline error is set, `setSaving(true)` is never reached, `onSaveError` is not called, and the dialog stays open with the draft intact. Implementations MUST NOT throw from `validate`; the contract is to return an error string or `null`.
- **Async error handling**: The `create` callback may throw; the component catches any exception, derives an error message from it (the Error's `message`, or a default string otherwise), and passes it to `renderForm` on the next render.
- **Empty error from validate**: If `validate` returns an empty string or null, it is treated as success. An empty string is falsy in JavaScript and will not trigger the error display.
- **Rapid successive saves**: If the user clicks Save while a create operation is in progress, the button is disabled, preventing a second invocation.
- **Unmount while saving**: The Escape `keydown` listener is added via `useEffect` and removed on unmount. If the component unmounts while `create` is still pending, the promise still settles, and the resulting `setSaving`/`setError` calls run against an unmounted component; React 18+ silently ignores such state updates (no warning, no throw). `onCreated` and `onSaveError`, however, are plain function calls rather than state updates, so they still fire even though the dialog is gone.
- **Draft state mutations**: Dirty-checking compares `JSON.stringify(draft)` to `JSON.stringify(pristine)` — exact structural equality for plain JSON-serializable data, including nested objects and arrays, but with known false-dirty and false-clean cases: **false-dirty** — two objects with identical values but keys inserted in a different order serialize to different strings; **false-clean** — properties whose value is `undefined` or a function are dropped entirely by `JSON.stringify`, and `Map`/`Set` instances always serialize to `{}` regardless of contents, so changes to such fields are invisible to the dirty check.
- **Callback identity during an in-flight save**: `validate`, `create`, `onClose`, `onCreated`, `renderForm`, `saveEnabled`, and `onSaveError` are read directly from props inside `save()` and `requestClose()`, which are plain functions re-created every render — so a click always uses the callbacks current as of that render, with one exception: once `save()` starts awaiting `create(draft)`, it has already captured `onCreated`, `onSaveError`, and `draft` from the render at click time. If the host swaps in new callback instances while that create is in flight, the pending call still completes using the values captured when Save was clicked.
- **Portal target**: The client-only check (`typeof document === "undefined"`) guards against SSR. Once the component is running in a browser, `document.body` already exists by the time React can mount anything, so this path does not arise in practice; if `createPortal` were ever given a non-element container, React throws synchronously rather than failing silently.
- **Non-deterministic `blank`**: `blank` is invoked twice — once for `draft` and once for the `pristine` baseline — and `dirty` compares the two results with `JSON.stringify`. A `blank` that returns a fresh identifier, timestamp, or other varying value on each call MUST be avoided: the two initial values differ, so the dialog reports itself dirty at mount, Save is enabled before any edit, and the Discard/Stay alert is raised on the first close.
- **Focus on open and close**: The source calls no focus API, so focus stays on whatever element opened the dialog, Tab can leave the dialog for content behind the overlay, and nothing restores focus when the dialog closes. This is also documented in Accessibility, under Focus management.

## Configuration

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `ariaLabel` | string | Yes | — | Accessibility label for the dialog container |
| `heading` | string | Yes | — | Dialog heading/title rendered as h2 |
| `blank` | () => TInput | Yes | — | Factory function that returns the initial pristine state for the form |
| `validate` | (draft: TInput) => string \| null | Yes | — | Validation function; returns null if valid, error message string if invalid |
| `create` | (draft: TInput) => `Promise<TResult>` | Yes | — | Async resource creation function; throws on error |
| `onClose` | () => void | Yes | — | Callback invoked when the dialog is closed without a successful create: directly via Cancel, ×, or Escape while the draft is pristine, or via Discard in the `UnsavedChangesAlert` after confirming a dirty draft. Never invoked after `onCreated` fires. |
| `onCreated` | (result: TResult) => void | Yes | — | Callback invoked when create succeeds |
| `renderForm` | (draft: TInput, onChange: (next: TInput) => void, error: string \| null) => ReactNode | Yes | — | Render function for form fields; receives draft state, onChange handler, and error message |
| `saveEnabled` | (draft: TInput) => boolean | No | undefined | Optional gate function; returns true to enable Save beyond the pristine check, false to disable |
| `onSaveError` | (err: unknown) => void | No | undefined | Optional telemetry callback invoked when create fails; the error is also displayed inline |

## Deep Linking

Not applicable: This component is a reusable container for form creation and does not define its own deep-linking routes. Deep linking is the responsibility of the host application.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `button.cancel` | "Cancel" | Cancel button label |
| `button.save` | "Save" | Save button label (default state) |
| `button.saving` | "Saving…" | Save button label while async operation is in progress |
| `button.close` | "Close" | Close button aria-label |
| `error.createFailed` | "Failed to create." | Fallback error message when `create` throws a non-`Error` value |

All five strings above are hardcoded literals in the component's source, not read from a localization resource; the `String Key` column is this recipe's proposed externalization scheme, not the source's current behavior — an implementation that must localize them needs to introduce a resource lookup itself. The `heading` prop is application-provided and not localized by the component.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | No transition or animation is applied. The overlay and the dialog card carry only static layout, color, and shadow classes — no `transition-*`, `animate-*`, or keyframe class appears on either — so the dialog appears and disappears instantly. Nothing to disable under Reduce Motion. |
| Increase Contrast | No explicit contrast requirements are defined in the source. Component styling defers to theme tokens (apt-text, apt-surface, apt-border); theme implementation is responsible for contrast ratios. |
| Differentiate Without Color | No color-only differentiators are used; buttons are labeled and error messages are text-based. |

## Feature Flags

Not implemented: Component behavior is fully enabled; no feature flags gate functionality.

## Analytics

Not implemented: Component does not emit analytics events; telemetry for creation failures is handled via the `onSaveError` callback, which is the responsibility of the host application.

## Privacy

Not applicable: Component does not collect, store, or transmit data. It renders a form and passes the draft to the `create` callback; all data handling is the responsibility of the host.

## Logging

Not implemented: Component does not emit logs. Errors from `create` are surfaced inline to the user and optionally passed to `onSaveError`.

## Platform Notes

- **SwiftUI**: Start from `.sheet(isPresented:)` on macOS or `.fullScreenCover(isPresented:)` on iOS, with the dialog body built from a `@ViewBuilder` closure standing in for `renderForm`. Hold `draft`, `pristine`, `error`, `saving`, and `confirming` in `@State` on the presented view, and drive Save's `.disabled(saving || !canSave)` from the same `dirty && saveEnabled` expression. Run `create` from a `Task` and catch into the inline error text. Express the Discard/Stay guard with `.confirmationDialog` carrying a `.destructive` Discard button and a `.cancel` Stay button. What differs from the source: SwiftUI has no portal, and a sheet already presents outside the host's view hierarchy, so there is no stacking-context or `inert` ancestor problem to escape; and SwiftUI dismisses a sheet on Escape and on the interactive swipe-down by default, so set `.interactiveDismissDisabled(true)` and route Escape yourself through a button carrying `.keyboardShortcut(.cancelAction)` to preserve the rule that only Save, Cancel, or × dismisses.

- **Compose**: Start from `Dialog` with `DialogProperties(dismissOnClickOutside = false, dismissOnBackPress = false)` — both set false is what reproduces the source's inert backdrop and guarded Escape — wrapping a `Surface(shape = RoundedCornerShape(12.dp))` that holds a title `Text` styled `MaterialTheme.typography.titleMedium`, the caller's `@Composable` form slot, and a `Row(horizontalArrangement = Arrangement.End)` of `TextButton("Cancel")` and `Button("Save")`. Keep `draft`, `error`, `saving`, and `confirming` in `remember { mutableStateOf(...) }`, and launch `create` from `rememberCoroutineScope().launch` with try/catch. Show the Discard/Stay guard as a second `AlertDialog` composed as a sibling of the first, not nested inside it. What differs from the source: hardware Back is the Escape analogue, so intercept it with `BackHandler(enabled = true) { requestClose() }`; and `Dialog` renders into its own window already, so no portal equivalent is needed.

- **React/Web**: This is the source platform. `packages/web/packages/ui/src/blocks/create-resource-dialog.tsx` is a client component (`"use client"`) built on `useState`, `useEffect`, and `createPortal` into `document.body`; `../components/button` supplies Cancel, Save, and the `icon-sm` ghost ×, and `../components/unsaved-changes-alert` supplies the Discard/Stay alert. Specific to this file: the portal target is `document.body` and nothing narrower, because a `fixed` overlay left inside the pane that opened it inherits that pane's `inert` and `aria-hidden` in narrow mode as well as any ancestor stacking context or `overflow: hidden`; `UnsavedChangesAlert` is rendered as a sibling of the overlay rather than nested inside it, for the same reason; the window-level `keydown` listener exists because `UnsavedChangesAlert` is `destructive` and blocks Escape itself; and the `typeof document === "undefined"` guard returns `null` so the component is inert during SSR. Styling is Tailwind utilities over the `apt-border`, `apt-surface`, and `apt-text` theme tokens.

- **AppKit / UIKit**: On macOS start from an `NSPanel` run as a sheet via `beginSheet(_:completionHandler:)` on the document window; on iOS start from a `UIViewController` presented with `modalPresentationStyle = .formSheet`. Put the form in a child view controller supplied by the caller, and the Cancel/Save pair in a trailing-aligned `UIStackView`. Reproduce the guard on iOS by setting `isModalInPresentation = true` so pull-to-dismiss cannot discard a dirty draft, and implementing `presentationControllerDidAttemptToDismiss` to raise a `UIAlertController` with a `.destructive` Discard action and a `.cancel` Stay action; on macOS gate `endSheet(_:)` behind the same alert. What differs from the source: Escape arrives through the responder chain — `cancel(_:)` on macOS, a `UIKeyCommand` bound to `UIKeyCommand.inputEscape` on iOS — rather than a global `keydown` listener, and both frameworks confine focus within a modal presentation automatically, which the web source does not do.

- **WinUI 3**: Start from `ContentDialog` with `PrimaryButtonText="Save"`, `CloseButtonText="Cancel"`, `DefaultButton="Primary"`, and a `Grid` in its `Content` holding the form. Bind `IsPrimaryButtonEnabled` with `x:Bind CanSave, Mode=OneWay` to a view-model property computed as `IsDirty && (SaveGate?.Invoke(Draft) ?? true)`. Reproduce the guarded close by handling `Closing`: take the `ContentDialogClosingDeferral`, and while `IsDirty` is true set `args.Cancel = true` and show a second `ContentDialog` carrying the Discard/Stay choice, completing the deferral only on Discard — this is what stops the Cancel button and the built-in Escape from discarding a half-filled form. Reproduce the async Save by handling `PrimaryButtonClick`: set `args.Cancel = true`, take a `ContentDialogButtonClickDeferral`, await the create call, and `Hide()` only on success; on failure set an `ErrorMessage` property bound to an `InfoBar` with `Severity="Error"` inside the dialog content and leave the dialog open. Drive the "Saving…" label and both disabled buttons from an `IsSaving` property, and express the Default, Dirty, Saving, and Error appearances as `VisualState` entries in a `VisualStateGroup` on the content root. Set `XamlRoot` from the invoking element: this is WinUI's equivalent of the source's portal, attaching the dialog to the window's popup root rather than the invoking element's subtree, so no ancestor clipping or stacking context applies. Map the `apt-border`, `apt-surface`, and `apt-text` token values to `ThemeResource` entries under `ResourceDictionary.ThemeDictionaries` so light and dark both resolve.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/create-resource-dialog.tsx` | unverified |

## Design Decisions

**Decision**: Render the dialog through `createPortal` into `document.body`, not inline in the tree that opened it.
**Rationale**: Ancestors of the open button may set `overflow: hidden`/`overflow: auto` or own a stacking context that clips a `fixed`-positioned descendant; in this app's hierarchical pane stack, ancestors above the focused pane are also marked `inert` and `aria-hidden` in narrow mode, which would block keyboard and screen-reader interaction with the dialog if it stayed a descendant. Portaling to `document.body` escapes both constraints.
**Approved**: pending

**Decision**: Leave focus unmanaged — no focus moved into the dialog on open, no focus trap while it is open, and no focus restored to the invoking control on close.
**Rationale**: The source implements none of this and records no rationale for the omission; it is documented here as an absent feature, not a decision. See the Focus management entry in Accessibility for what the source does and does not handle. Escape, Cancel, and × still give keyboard users an unambiguous way to close the dialog, so the omission does not leave it unreachable by keyboard.
**Approved**: pending

**Decision**: Compare draft to pristine state with `JSON.stringify` rather than a structural-equality library or a manual dirty flag.
**Rationale**: This is simple and handles nested objects and arrays out of the box. The trade-off is serialization cost on every state change, plus the false-dirty/false-clean cases recorded under Edge Cases (key order, `undefined`/function-valued fields, `Map`/`Set` contents). A future optimization could switch to a structural comparison library or a custom dirty-flag pattern.
**Approved**: pending

**Decision**: Run the unsaved-changes guard only on close (Cancel, ×, Escape), never on Save.
**Rationale**: A validation failure on Save should let the user correct the field and retry without an extra confirmation step; routing only the close paths through `UnsavedChangesAlert` avoids that churn while still protecting against losing a dirty draft.
**Approved**: pending

**Decision**: Run `validate` synchronously and completely before starting the async `create` call; leave any server-side check (uniqueness, availability) to `create` itself.
**Rationale**: Synchronous validation gives immediate feedback for client-side problems (empty fields, format violations) without a network round trip. `saveEnabled` is itself synchronous — `(draft) => boolean`, called on every render — but a host can still surface the result of an async pre-check (e.g. a debounced identifier-availability probe) through it: the host runs the check, stores the boolean result in its own state, and `saveEnabled` reads that state; the host's re-render is what feeds the async result in, not `saveEnabled` awaiting anything itself.
**Approved**: pending

**Decision**: Make `onSaveError` optional, and keep inline error display independent of it.
**Rationale**: The callback exists for telemetry/logging; the error is shown inline regardless of whether a host supplies it, so implementations that don't need telemetry can omit it with no loss of user-facing behavior.
**Approved**: pending

**Decision**: Keep `renderForm` a pure composition seam — it receives only `draft`, `onChange`, and `error`, and owns everything about how fields (and, per the Appearance and Accessibility entries above, the error message itself) are rendered.
**Rationale**: This keeps the dialog free of any specific form library or field structure, so it works for any domain form the host wants to compose into it.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Statuses rest on the source: interactive elements carry meaningful labels and the correct `role`/`aria-modal`/`aria-label` (screen-reader-support, semantic-markup); every action is reachable through native buttons and a global Escape handler (keyboard-navigable); no code moves, traps, or restores focus (focus-management, documented above under Focus management); and the close button's `icon-sm` size measures 28×28px against the 44×44/48×48 guideline unless a host raises `--adh-button-min-height`/`--adh-button-min-width` (touch-target-size). All five user-visible strings ("Cancel", "Save", "Saving…", "Close", "Failed to create.") are hardcoded literals in the component rather than resource lookups (string-externalization, no-hardcoded-strings). separation-of-concerns passes because the dialog owns only dirty-tracking, save orchestration, and the close guard, delegating all field presentation to the host's `renderForm` and the confirm/discard UI to `UnsavedChangesAlert`. unit-test-coverage is partial: `createResourceDialogExit.test.tsx` covers only the close-guard paths (Cancel/Discard/Stay); no test in the repo exercises the save flow (`display-create-error`, `invoke-onsaveerror-on-create-failure`, `support-optional-save-gate`, and related requirements).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.2 | 2026-09-25 | Mike Fullerton | Renamed discard-closes-dialog to discard-invokes-onclose; T026 now reflects that the alert stays open unless the host unmounts; wrapped Promise<TResult> in a code span. |
| 1.2.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirement names to subject-only kebab-case and added three requirements (plus vectors) for the alert's Discard/Stay outcomes and Escape-during-save; corrected the unmount-while-saving, callback-identity, draft-mutation, and portal-target Edge Cases to match actual React/DOM behavior; corrected touch-target size, keyboard tab order, and error-display ownership (delegated to renderForm) across Accessibility, States, and Appearance; removed the async claim from the saveEnabled design decision and explained the host re-render mechanism instead; reformatted every Design Decision to the Decision/Rationale/Approved form; added a real Compliance table; added the missing fallback-error localization entry and noted the strings are hardcoded; corrected two test vectors and added five more |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Answer the blank-state, validate-throw, and Reduce Motion questions from the source; keep modal focus management as the one open gap; rewrite Platform Notes to the template's five bullets with concrete per-platform guidance |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
