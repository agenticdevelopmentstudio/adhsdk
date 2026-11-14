---
id: 526da033-2f0d-4bd7-b2c2-99faba4783a3
title: "Category Rename Dialog"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Modal dialog for renaming a single category with duplicate-name validation."
platforms:
  - typescript
  - web
tags:
  - dialog
  - rename
  - form
  - validation
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Category Rename Dialog

## Overview

A modal dialog that allows renaming a single category or item. The component validates the new name against existing items to prevent duplicates, accepts async rename operations, and provides error feedback when validation or the rename operation fails. It is used in contexts where a category rename is safe from anywhere (moves nothing, unfiles nothing) and a confirm step prevents accidental changes.

## Behavioral Requirements

- **display-when-open**: Component MUST display a modal dialog when `open` is `true`.
- **render-nothing-when-closed**: Component MUST render `null` when the `node` prop is `null` and has never previously been non-null. Once a non-null `node` has been supplied, the component keeps rendering with the last-held value (via `useLastPresent`) even after `node` reverts to `null`, so the exit animation can complete before unmounting.
- **prefill-current-name**: Component MUST pre-fill the input field with the current node's name when the dialog opens (i.e., when `open` becomes `true` with a non-null `node`); the input is not re-seeded on any other `node` change.
- **require-non-empty-name**: Component MUST reject submission if the trimmed input is an empty string, displaying the error message: `A ${noun} needs a name.`
- **reject-unchanged-name**: Component MUST close without calling `onRename` if the trimmed input matches the original node name using a case-sensitive comparison after trim. A case-only change (e.g., "Inventory" → "INVENTORY") is not considered unchanged and proceeds to validation.
- **validate-duplicate-names**: Component MUST reject submission if the trimmed input name matches any existing node name (case-insensitive), excluding the node being renamed, displaying the error message: `There is already a ${noun} called "${name}".`
- **validate-extra-names**: Component MUST check the `extraNames` array for duplicates (case-insensitive) and reject submission if a match is found, excluding the original node's own name from the `extraNames` check (that exclusion is also compared case-insensitively).
- **accept-enter-key**: Component MUST trigger submission when the user presses Enter within the text input field.
- **show-loading-state**: Component MUST set `disabled={true}` on the input and show a loading state in the confirm button while `onRename` is executing.
- **clear-error-on-input**: Component MUST clear any error message when the user modifies the input text.
- **call-onrename**: Component MUST call `onRename(node, trimmedName)` with the trimmed input after all validation passes.
- **handle-async-rename**: Component MUST support async `onRename` (returns `Promise<void>`), display the error message if the promise rejects, and keep the dialog open on error.
- **call-onrenamed**: Component MUST call `onRenamed(node, trimmedName)` after a successful rename.
- **call-onclose-after-success**: Component MUST call `onClose()` after a successful rename.
- **prevent-close-while-busy**: Component MUST not close the dialog (via the close (`×`) affordance or the Escape key) if a rename operation is in progress (`busy === true`). A backdrop click never closes the dialog at all, regardless of `busy` — the shared `Dialog` primitive disables pointer-based outside dismissal unconditionally.
- **disable-confirm-when-empty**: Component MUST set `disabled={true}` on the confirm button when the trimmed input is an empty string; the confirm button is not otherwise disabled while a validation or operation error is showing.
- **show-error-text**: Component MUST display validation and operation error messages in an error text component.

## Appearance

- **Corner radius**: Deferred to Dialog component implementation.
- **Padding**: Input field uses standard form spacing; error text is displayed inline below the input.
- **Font**: Uses system default input font; error text uses a distinct error-colored variant.
- **Background**: Dialog content uses light/dark mode theme from Dialog component.
- **Foreground/Text**: Input text and dialog content use the `apt-text` foreground token, which resolves per active theme rather than a literal black/white value; error text uses the `apt-red` destructive/error token.
- **Border**: Input field uses standard form input border; dialog has no explicit border.
- **Shadow**: Dialog elevation/shadow deferred to Dialog component implementation.
- **Min/Max size**: Dialog content uses the `max-w-sm` utility — exactly 384px (24rem), not an approximation.

## States

| State | Appearance change | Behavioral change |
|-------|------------------|-------------------|
| Closed | Dialog not rendered or hidden | Input value is not reset; only pre-filled on next open |
| Open (default) | Dialog visible, input focused | Ready for input; error message cleared |
| Focused | Input field has focus outline | User can type or press Enter to submit |
| Loading | Input disabled, confirm button shows loading indicator | All inputs disabled; dialog cannot close |
| Validation error | Error message displayed in red below input | Input remains enabled; confirm button is disabled only when the trimmed input is empty, per **disable-confirm-when-empty** — it stays enabled while a duplicate or operation error is showing, so the user can retry immediately |
| Operation error | Error message displayed below input | Input enabled; user can edit and retry |

## Accessibility

- **Role**: Dialog with role implicit from Dialog component; input field is a text input.
- **Labels**: Input field MUST have `aria-label="New ${noun} name"` for screen readers.
- **Dialog title**: Dialog header contains `<DialogTitle>Rename {noun}</DialogTitle>` for context.
- **Dialog description**: Dialog header contains `<DialogDescription>This renames it everywhere it is used.</DialogDescription>`.
- **Keyboard navigation**: Input auto-focuses on dialog open; Tab moves between input and buttons; Enter submits; Escape closes (if not busy).
- **Error announcement**: Error text MUST be announced to screen readers; both `ErrorText` and its dialog-description variant always render the message with `role="alert"` whenever an error is present.
- **Announce loading state**: While `busy` is `true`, the confirm button SHOULD indicate loading (e.g., via aria-busy or button text change).
- **Minimum touch target**: Dialog buttons (Confirm, Cancel) MUST have touch targets of at least 44×44pt.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| rename-001 | display-when-open | `open={true}`, `node={categoryNode}` | Dialog is visible |
| rename-002 | render-nothing-when-closed | `open={false}`, `node={null}` | Component returns `null` |
| rename-003 | prefill-current-name | `open={true}`, `node={categoryNode}` where `node.name="Inventory"` | Input field displays "Inventory" |
| rename-004 | require-non-empty-name | User leaves input empty, clicks Confirm | Error message: "A category needs a name." |
| rename-005 | reject-unchanged-name | Input shows original name "Inventory", user clicks Confirm | Dialog closes without calling `onRename` |
| rename-006 | validate-duplicate-names | Input: "Armory", `nodes` includes node with `name="Armory"` (different id) | Error: "There is already a category called "Armory"." |
| rename-007 | validate-extra-names | Input: "Taken", `extraNames=["Taken"]` | Error: "There is already a category called "Taken"." |
| rename-008 | accept-enter-key | Input focused with text "NewName", user presses Enter | `onRename` is called (validation passes) |
| rename-009 | show-loading-state | `onRename` is async and pending | Input is disabled; confirm button shows loading state |
| rename-010 | clear-error-on-input | Error displayed, user types in input | Error message is cleared |
| rename-011 | call-onrename | User enters valid name "NewCategory" and submits | `onRename(node, "NewCategory")` is called |
| rename-012 | handle-async-rename | `onRename` returns rejected promise | Dialog remains open; error message displays rejection reason |
| rename-013 | call-onrenamed | Rename succeeds | `onRenamed(node, newName)` is called |
| rename-014 | call-onclose-after-success | Rename succeeds | `onClose()` is called |
| rename-015 | prevent-close-while-busy | User presses Escape while `busy={true}` | Dialog remains open |
| rename-016 | disable-confirm-when-empty | Input value is "", no input has occurred | Confirm button is disabled |
| rename-017 | show-error-text | Validation fails | Error text component displays error message |
| rename-018 | require-non-empty-name | Input is whitespace only ("   "), user clicks Confirm | Trimmed to ""; error message: "A category needs a name." |
| rename-019 | handle-async-rename | `onRename` rejects with a non-`Error` value (e.g., a plain string) | Error message: "Could not rename the category."; dialog remains open |
| rename-020 | prevent-close-while-busy | `busy={true}` | `DialogActions` renders only a loading spinner; Cancel and Confirm buttons are not present to click |
| rename-021 | prevent-close-while-busy | User clicks the dialog backdrop, both while `busy={false}` and while `busy={true}` | `onOpenChange` never fires from the backdrop press in either case (pointer-based outside dismissal is disabled unconditionally); `onClose()` is not called; dialog remains open |
| rename-022 | reject-unchanged-name | Input "INVENTORY" when `node.name` is "inventory" | `onRename(node, "INVENTORY")` is called — a case-only change is not treated as unchanged |
| rename-023 | prefill-current-name | Dialog closes with edited (unsaved) text present; host later reopens it with a different `node` | Input displays the new node's name, not the previous session's edited text |

## Edge Cases

- **Empty name after trim**: If input is whitespace only (e.g., "   "), component trims to "" and rejects with the "needs a name" error, per **require-non-empty-name**.
- **Duplicate check is case-insensitive**: Input "inventory" matches existing node "Inventory" in `commit()`'s `taken` check, which compares via `.toLowerCase()`, per **validate-duplicate-names**.
- **Unchanged name with different casing**: Input "INVENTORY" when current is "inventory" — these differ under the case-sensitive comparison in **reject-unchanged-name**, and the case-only match is excluded from the duplicate check by node id, so `onRename` is called per **call-onrename**.
- **Extra names and node name coincidence**: If `extraNames` contains the original node name, the `extraNames` check in `commit()` excludes it (case-insensitively) from the taken check, per **validate-extra-names** — allowing the user to "rename" to the same name, which then closes silently per **reject-unchanged-name**.
- **Async onRename rejection fallback**: If `onRename` throws or rejects, `commit()`'s `catch` block displays the rejection's `message` when it is an `Error` instance; otherwise it shows the fallback message `Could not rename the ${noun}.`. Displaying an error on rejection is required by **handle-async-rename**; the specific Error/non-Error split is an implementation detail of `commit()`, not a separately named requirement.
- **Dialog close while busy**: The `onOpenChange` callback passed to `Dialog` calls `onClose()` only when `busy` is `false`, so an Escape-triggered or close-affordance-triggered close is blocked while busy, per **prevent-close-while-busy**. A backdrop click never reaches `onOpenChange` at all — the shared `Dialog` primitive sets `disablePointerDismissal` unconditionally — so it is inert whether or not `busy` is set, not merely blocked while busy. The Cancel and Confirm buttons are also removed from the DOM while busy (`DialogActions` renders only a loading spinner), so there is nothing to click.
- **Held node survives target going null**: `useLastPresent(target)` keeps rendering the last non-null node after the host clears `target`, so the exit animation completes before the component unmounts (see **Design Decisions**, "useLastPresent for exit animation"). This is an implementation detail supporting the exit transition, not itself a separately named behavioral requirement.
- **Input re-seeding on re-open**: The `React.useEffect` that seeds `text` only re-seeds when `open` becomes `true` with a non-null `target`, per **prefill-current-name**, so reopening on a `null` target does not restore stale text from a previous session.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `open` | boolean | (required) | Whether the dialog is visible. |
| `node` | CategoryTreeNode &#124; null | null | The category being renamed. `null` renders nothing only until a non-null value has been supplied at least once; after that the component keeps showing the last-held node (via `useLastPresent`) through a `null` reversion, so the exit animation can finish — see **render-nothing-when-closed**. The host may keep the dialog mounted between opens. |
| `nodes` | readonly CategoryTreeNode[] | (required) | The full vocabulary for duplicate-name validation. |
| `extraNames` | readonly string[] | [] | Additional names to treat as taken (e.g., names known to the host but not yet in `nodes`). |
| `noun` | string | (required) | Singular, lowercase term for microcopy (e.g., "category", "folder"). Interpolated into error messages and dialog title. |
| `onRename` | (node, nextName) => void &#124; `Promise<void>` | (required) | Async or sync callback to persist the rename. Receives the node and trimmed new name. |
| `onRenamed` | (node, nextName) => void &#124; undefined | undefined | Optional callback invoked after successful rename with the node and new name. |
| `onClose` | () => void | (required) | Callback invoked when the dialog closes (success, cancel, or unchanged name). |

## Deep Linking

Not applicable: This component is a modal dialog without independent deep-linking behavior. It is shown/hidden by host state, not navigated to directly.

## Localization

| String Key | Default (en) | Context | Notes |
|-----------|-------------|---------|-------|
| dialog.title | `Rename {noun}` | Dialog header title. Interpolated with `noun` prop. | |
| dialog.description | `This renames it everywhere it is used.` | Dialog header description. | Describes consequence of rename. |
| input.label | `New {noun} name` | Input aria-label. Interpolated with `noun` prop. | Screen reader only. |
| error.empty-name | `A {noun} needs a name.` | Validation error for empty trimmed input. Interpolated with `noun` prop. | |
| error.duplicate | `There is already a {noun} called "{nextName}".` | Validation error for duplicate name. Interpolated with `noun` and attempted name. | Case-insensitive comparison. |
| button.confirm | `Rename` | Confirm button label. | |
| button.cancel | `Cancel` | Cancel button label. | |
| error.fallback | `Could not rename the {noun}.` | Fallback error message if `onRename` rejects without an Error. Interpolated with `noun` prop. | |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Dialog open/close transitions should respect `prefers-reduced-motion`. Implemented at Dialog component level. |
| Increase Contrast | Error text color should meet minimum contrast ratio (4.5:1) with background. Dialog component should adjust if theme supports. |
| Differentiate Without Color | Error state MUST NOT be conveyed by color alone; error text label or icon should accompany color change. |

## Feature Flags

Not applicable: Component has no feature flag integration in source code.

## Analytics

Not applicable: Component has no analytics or telemetry integration in source code. Privacy and Feature Flags confirm the same — there is no instrumentation to report on. A host that wants to track opens, renames, cancels, or errors should add that instrumentation in a host-level recipe, not here.

## Privacy

- **Data collected**: Component does not collect any telemetry or analytics data independently. Host is responsible for any analytics instrumentation.
- **Storage**: Component stores only local state (input text, error message, busy flag) in React state, no localStorage or server storage.
- **Transmission**: Component does not transmit data directly. The `onRename` callback is invoked by the host to transmit renamed node data via host's API.
- **Retention**: Local state is discarded when component unmounts. No persistent data is retained.

## Logging

Not applicable: Component has no logging implementation in source code. Host is responsible for any error or event logging via callbacks.

## Platform Notes

- **React/Web**: The source (`category-rename-dialog.tsx`) uses Dialog, Input, and DialogActions from a shared UI component library. Customization points are the Dialog component's styling props (e.g., `className="max-w-sm"`), Input component behavior (autoFocus, disabled, aria-label), and ErrorText rendering. Validation logic is co-located with the component; duplicate checking happens in-memory before the async `onRename` call to prevent corrupting duplicates on the server.

- **SwiftUI**: Start with a `.sheet` modifier controlling visibility via the `open` binding — `.confirmationDialog` cannot host a `TextField` and should not be used here. (A `.alert` with a `TextField` in its actions closure, supported since iOS 16, is also viable for a single-field prompt.) Use a `TextField` for input with an `.onSubmit` handler for Enter key, bound to a `@State` variable. Implement duplicate validation before calling the async `onRename` closure. Use a `.disabled()` modifier on the TextField and confirm button while an async operation is pending. Display validation errors in a separate Text view styled with `.foregroundStyle(.red)` (not the deprecated `.foregroundColor`).

- **Compose (Kotlin)**: Use a `Dialog` composable for the modal. Place a `TextField` (or `OutlinedTextField`) inside the dialog, with a `FocusRequester` requesting focus in a `LaunchedEffect` to autofocus it. Set `KeyboardOptions(imeAction = ImeAction.Done)` and handle submission in the field's `KeyboardActions(onDone = { ... })`, rather than a raw `onKeyEvent` handler. Manage duplicate validation and async `onRename` in a ViewModel using coroutines. Disable the TextField and confirm button while the rename operation is in-flight (use a `LaunchedEffect` or `rememberCoroutineScope`). Display error messages in a `Text` composable below the input with red text color.

- **AppKit / UIKit**: `NSAlert` (macOS) and `UIAlertController` (iOS) can host a single text field via `addTextField()`, but neither supports updating an inline error label inside an already-presented alert — re-presenting the alert to show an error is a poor substitute and loses the user's in-progress input. Prefer a custom sheet or modal view controller with its own `TextField`/`UITextField` and an error label that can be shown or hidden in place. Implement a target-action handler for the return key (or a text field delegate) to trigger validation and submission. Block the close button and Escape/dismiss gesture while an async operation is pending by disabling dismissal on the view controller. If the host requires the native alert specifically, state plainly that it cannot meet **show-error-text** for operation/validation errors surfaced after the alert is already presented.

- **WinUI 3**: Use `ContentDialog` for the modal. Place a `TextBox` control inside the dialog with `IsEnabled` binding to reflect the busy state. Handle the `KeyDown` event on the TextBox to detect Enter and trigger submission. Implement duplicate validation in code-behind or via a ViewModel (MVVM pattern). Disable the `IsPrimaryButtonEnabled` property on the dialog's primary button (Rename) while async operations are pending, and handle the `ContentDialog.Closing` event to set `args.Cancel = true` while busy, so Escape and the system close affordance are blocked the same way **prevent-close-while-busy** blocks them on web. Display validation errors in a `TextBlock` below the TextBox, styled with a `Foreground` of `{ThemeResource SystemFillColorCriticalBrush}` (the current, non-legacy critical-fill brush).

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/category-rename-dialog.tsx` | unverified |

## Design Decisions

**Decision**: Duplicate validation happens in-component, before `onRename` is called, rather than being left to the server.
**Rationale**: The duplicate check in `commit()` (the `taken` computation) runs before the async `onRename` call, preventing a generic CRUD update — which takes no uniqueness lock — from creating a duplicate and breaking every read that keys on the name.
**Approved**: pending

**Decision**: The component holds the `node` prop's value via `useLastPresent(target)` rather than reading `target` directly.
**Rationale**: If the component unmounted the instant `target` became `null`, the Dialog's `open → false` exit transition would be cut off before it started. Holding the last non-null value one render longer lets the transition finish.
**Approved**: pending

**Decision**: The `React.useEffect` that seeds the input text runs only when `open` becomes `true` with a non-null `target` — not on every `target` change.
**Rationale**: Seeding from `target` on every change, rather than only on open, would let a `target` update while the dialog is reopening on `null` restore stale text from the previous session.
**Approved**: pending

**Decision**: The duplicate check in `commit()` compares names with `.toLowerCase()` to ignore case, but the error message displays the user's typed name exactly as entered, not a normalized version.
**Rationale**: Case-insensitive comparison catches near-duplicates like "inventory" vs. "Inventory" across different nodes, while echoing the user's own input keeps the error message trustworthy. This does not prevent a case-only rename of the node's own name — "inventory" → "INVENTORY" still calls `onRename`, since it differs from the case-sensitive check in **reject-unchanged-name** and is excluded from the duplicate check by node id (see the corresponding edge case). Note also that `.toLowerCase()` is a locale-sensitive transform (for example, Turkish's dotless "ı"); ports to other platforms should use the platform's locale-aware lowercasing for this comparison, not an invariant-culture call.
**Approved**: pending

**Decision**: Enter, handled in the `Input`'s `onKeyDown`, commits the form; Escape is handled by the `Dialog` component itself, not by the input.
**Rationale**: This matches the common web dialog pattern where the primary field commits on Enter and the container owns Escape-to-close.
**Approved**: pending

**Decision**: Submitting without changing the name closes the dialog via `onClose()` — the early return in `commit()` when the trimmed input equals `node.name` — without calling `onRename`.
**Rationale**: This avoids a no-op server round-trip for a rename that would change nothing.
**Approved**: pending

**Decision**: The duplicate error message, set in `commit()`'s `taken` branch, includes the user's attempted name in quotes.
**Rationale**: This lets the user see exactly what they tried to use.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on: the source's `onKeyDown`/`onOpenChange` handling, `aria-label`, and `role="alert"` usage plus the base-ui `Dialog`'s own focus trap (Accessibility, passed/partial where pixel sizing and motion-reduction can't be confirmed from source); the literal `${noun}`-style template strings baked into `commit()` and the JSX with no i18n resource lookup, despite Unicode-safe `.trim()`/`.toLowerCase()` string handling (Internationalization); the empty/duplicate-name validation in `commit()` running with no explicit sanitization step (Security, partial); the dialog composes `Dialog`/`Input`/`ErrorText`/`useLastPresent` from lower tiers and delegates the vocabulary it validates against to `category-tree`, keeping its own file to orchestration and the rename form (separation-of-concerns); and `categoryRenameDialog.test.tsx` asserts the duplicate-name guard, the async `onRename` failure path, and the close/cancel flows (unit-test-coverage).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Backdrop clicks never fire onOpenChange (disablePointerDismissal), busy or not; corrected prevent-close-while-busy, rename-021, and the busy edge case to stop framing backdrop as busy-gated. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case (dropped `must-` prefix) everywhere they're cited; replaced line-number citations with source symbol/function names; reformatted Design Decisions into Decision/Rationale/Approved form and corrected the case-only-rename claim; rewrote Compliance as real catalog checks with a plain Category column; marked Analytics "Not applicable" to match Privacy/Feature Flags/Logging; fixed the render-null, confirm-disabled, and extra-names-case-insensitivity ambiguities; added test vectors for whitespace input, the non-Error rejection fallback, busy-state backdrop/cancel, case-only rename, and re-seeding on reopen; unified localization placeholders on `{noun}`/`{nextName}`; grounded Appearance's foreground and max-width claims in theme tokens; and corrected the SwiftUI, Compose, AppKit/UIKit, and WinUI 3 platform notes' APIs |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
