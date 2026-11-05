---
id: 0d85c3a1-c754-4d8b-8aab-6565dfee6100
title: Category Delete Dialog
domain: adhsdk://recipes/category-delete-dialog
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Modal confirmation dialog for deleting a category, with warnings about orphaned
  subcategories.
platforms:
- typescript
- web
tags:
- dialog
- deletion
- confirmation
depends-on: []
related:
- adhsdk://recipes/alert-modal
- adhsdk://recipes/error-text
references: []
approved-by: ''
approved-date: ''
---

# Category Delete Dialog

## Overview

A modal confirmation dialog that appears when the user initiates deletion of a category from a hierarchical category tree. The dialog explains the semantics of category deletion — that the filing is deleted but filed items are not — and lists any subcategories that will be orphaned and also deleted as a result. The component renders nothing until a category has been supplied for deletion.

## Behavioral Requirements

- **renders-dialog-when-open**: The component MUST render a modal dialog when `open` is `true` and a node — current or retained (see **retains-node-name-during-transition**) — is available.
- **renders-nothing-before-first-node**: The component MUST render nothing (return `null`) until a non-null `node` has been supplied at least once. After that, the component keeps rendering using the most recently supplied non-null node, even on renders where the host's `node` prop is `null`.
- **shows-category-name-in-title**: The dialog MUST display the category name in the title as `Delete "{node.name}"?`.
- **shows-main-explanation**: The dialog MUST display text explaining that deletion deletes the category filing only, not items filed under it. The text MUST state "This deletes the category only. Any {itemNoun} filed under it are not deleted — they become uncategorized."
- **shows-orphaned-names-when-present**: When `orphanedNames.length > 0`, the dialog MUST display the list of orphaned subcategory names as a single comma-separated, bold-formatted string, with no truncation regardless of how many names there are.
- **shows-orphaned-items-note**: When `orphanedNames.length > 0`, the dialog MUST also state, immediately after the orphaned names, that the items filed under those subcategories become uncategorized too: "Their {itemNoun} become uncategorized as well."
- **pluralizes-orphaned-message**: When exactly one subcategory is orphaned (`orphanedNames.length === 1`), the message MUST read "This subcategory is filed nowhere else, so it is deleted too:". When more than one is orphaned (`orphanedNames.length > 1`), it MUST read "These subcategories are filed nowhere else, so they are deleted too:".
- **shows-error-when-present**: When `error` is a non-null, non-empty string, the component MUST display it as inline error text within the description. `error` being `null`, `undefined`, or `""` MUST all be treated as "no error."
- **retains-node-name-during-transition**: The component MUST keep displaying the most recently supplied non-null node's name for the remainder of the component instance's lifetime, including on renders after the host clears `node` to `null` to begin the dismissal transition. (See Platform Notes for the React/Web mechanism.)
- **disables-actions-while-busy**: When `busy` is `true`, the component MUST replace both the "Delete" and "Cancel" buttons with a loading indicator and MUST hide the close (`×`) affordance, so no dismissal path remains available until `busy` returns to `false`. (Escape is already blocked unconditionally by **ignores-escape-when-destructive**, and a backdrop click never dismisses the dialog regardless of `busy` — see **calls-oncancel-on-close-affordance**.)
- **calls-onconfirm-on-delete**: When the user clicks the "Delete" button, the component MUST call `onConfirm()`.
- **calls-oncancel-on-cancel**: When the user clicks the "Cancel" button, the component MUST call `onCancel()`.
- **calls-oncancel-on-close-affordance**: When `busy` is `false`, dismissing the dialog via the close (`×`) affordance MUST call `onCancel()`, the same as clicking "Cancel". A backdrop click does not dismiss the dialog at all — the shared `Dialog` primitive disables pointer-based outside dismissal unconditionally, whether or not `busy` is set.
- **ignores-escape-when-destructive**: Because the dialog always renders with `destructive` set, pressing Escape MUST NOT call `onConfirm` or `onCancel`; the dialog MUST remain open.
- **uses-error-tone-styling**: The dialog MUST render with `tone="error"` styling.
- **marks-as-destructive**: The dialog MUST render with the `destructive` flag set. This also forces the error tone and disables the Escape/Enter shortcuts (see **ignores-escape-when-destructive**), signaling to the user that the action is irreversible.
- **bolds-destructive-emphasis**: Within the description, the component MUST render the "are not deleted" phrase and the orphaned-names list in bold; no other text in the description is emphasized.

## Appearance

Not applicable: The component delegates all visual styling to the `AlertModal` component, which owns appearance properties including corner radius, padding, font, colors, borders, shadows, and size constraints. The source code does not define appearance directly.

## States

| State | Appearance change |
|-------|------------------|
| Default | Dialog displayed with title, description, and action buttons visible |
| Busy | Delete and Cancel buttons replaced by a loading indicator; all dismissal paths blocked |
| Error | Error text appended to description in red or error color token (per AlertModal styling) |
| Orphaned subcategories present | Additional message block inserted in description listing orphaned category names |
| Orphaned subcategories absent | Orphaned message block not rendered |

## Accessibility

- **role**: The component MUST render as a dialog with `role="dialog"` and `aria-modal="true"` (inherited unchanged from the `Dialog` primitive via `AlertModal`).
- **description**: The component MUST provide an accessible description containing the main explanation text and, when present, the orphaned warning and the error text. The description MUST be associated via `DialogDescription`.
- **button-labels**: Action buttons MUST have explicit labels: "Delete" for the destructive action and "Cancel" for the dismissal action.
- **focus-management**: Focus MUST be managed by the `AlertModal`/`Dialog` primitives — trapped within the dialog and returned to the trigger element on dismissal.
- **semantic-structure**: The description MUST be composed of block-level `<span>` elements rather than `<p>` elements, so the full text remains part of the accessible description exposed via `DialogDescription` instead of being re-parented outside it by the browser's `<p>`-in-`<p>` handling (see Design Decisions).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| category-delete-001 | renders-dialog-when-open | `open={true}`, `node={mockNode}` | Dialog modal appears on screen |
| category-delete-002 | renders-nothing-before-first-node | `open={true}`, `node={null}`, no prior non-null node | Component returns `null`; nothing rendered |
| category-delete-003 | shows-category-name-in-title | `node={{ name: "Projects" }}` | Dialog title shows `Delete "Projects"?` |
| category-delete-004 | shows-main-explanation | `itemNoun="notes"` | Description includes "This deletes the category only. Any notes filed under it are not deleted — they become uncategorized." |
| category-delete-005 | shows-orphaned-names-when-present | `orphanedNames={["Archived", "Draft"]}` | Description includes "Archived, Draft" as a bold string |
| category-delete-006 | pluralizes-orphaned-message | `orphanedNames={["Archive"]}` (length 1) | Message reads "This subcategory is filed nowhere else, so it is deleted too:" |
| category-delete-007 | pluralizes-orphaned-message | `orphanedNames={["Archive", "Draft"]}` (length > 1) | Message reads "These subcategories are filed nowhere else, so they are deleted too:" |
| category-delete-008 | shows-error-when-present | `error="Network error"` | Error text "Network error" appears in the description |
| category-delete-009 | disables-actions-while-busy | `busy={true}` | Delete and Cancel buttons are replaced by a loading indicator; the close affordance is hidden; Escape and a backdrop click never call `onConfirm`/`onCancel` (they don't dismiss regardless of `busy`) |
| category-delete-010 | calls-onconfirm-on-delete | User clicks "Delete" button | `onConfirm()` callback is invoked |
| category-delete-011 | calls-oncancel-on-cancel | User clicks "Cancel" button | `onCancel()` callback is invoked |
| category-delete-012 | retains-node-name-during-transition | Host sets `node={null}` after previously supplying a non-null node | Title and description still show the previous node's name |
| category-delete-013 | uses-error-tone-styling | Default render | Dialog renders with error-tone icon/accent |
| category-delete-014 | marks-as-destructive | Default render | Delete button renders with the destructive visual variant |
| category-delete-015 | role | Default render | Dialog element has `role="dialog"` and `aria-modal="true"` |
| category-delete-016 | shows-error-when-present | `error=""` (empty string) | No error text is rendered |
| category-delete-017 | shows-orphaned-names-when-present | `orphanedNames={[]}` (default) | No orphaned-names block is rendered |
| category-delete-018 | shows-orphaned-items-note | `orphanedNames={["Archive"]}`, `itemNoun="notes"` | Description includes "Their notes become uncategorized as well." |
| category-delete-019 | calls-oncancel-on-close-affordance | `busy={false}`, user clicks the close (`×`) affordance | `onCancel()` callback is invoked |
| category-delete-020 | ignores-escape-when-destructive | User presses Escape | Neither `onConfirm` nor `onCancel` is called; dialog remains open |
| category-delete-021 | bolds-destructive-emphasis | `orphanedNames={["Archive"]}` | "are not deleted" and "Archive" render inside bold elements |
| category-delete-022 | shows-error-when-present | `error={null}` (default) | No error text is rendered |
| category-delete-023 | shows-orphaned-names-when-present | `orphanedNames={["Archive", "Draft", "Notes"]}` | Description includes "Archive, Draft, Notes" with no truncation or ellipsis |
| category-delete-024 | retains-node-name-during-transition | Host sets `open={false}` while a node is retained | Component invokes neither `onConfirm` nor `onCancel`; retained node's name still shown during the dismissal transition |
| category-delete-025 | (edge case: very long names) | `node={{ name: "A".repeat(300) }}` | Full name is rendered unmodified; no truncation logic runs |

## Edge Cases

- **Empty orphanedNames array**: When `orphanedNames` is empty (the default), the orphaned-subcategories message block MUST NOT be rendered; only the main explanation appears. See **shows-orphaned-names-when-present** (vector category-delete-017).
- **No node has ever been supplied**: If `open={true}` but `node={null}` and no non-null `node` has previously been supplied, the component returns `null` and nothing is rendered. See **renders-nothing-before-first-node** (vector category-delete-002).
- **Null, undefined, or empty-string error**: `error` being `null`, `undefined` (both the default), or `""` all render no error text — the error text's truthy guard treats all three as absent. See **shows-error-when-present** (vectors category-delete-016, category-delete-022).
- **More than two orphaned names**: All orphaned names MUST be displayed as a single comma-separated string (`orphanedNames.join(", ")`), with no truncation or ellipsis. See **shows-orphaned-names-when-present** (vector category-delete-023).
- **Busy state blocks Cancel too**: While `busy={true}`, there is no Cancel button to click — both actions are replaced by a loading indicator and the close affordance is hidden. `onCancel` MUST NOT be invoked by any path while `busy` is `true`. See **disables-actions-while-busy** (vector category-delete-009).
- **Backdrop clicks never dismiss**: The shared `Dialog` primitive disables pointer-based outside dismissal unconditionally, whether or not `busy` is set. A backdrop click has no effect and does not call `onCancel`; only the "Cancel" button and, while not busy, the close (`×`) affordance do. See **calls-oncancel-on-close-affordance** (vector category-delete-019).
- **Dialog closed externally**: If the host sets `open={false}` while the dialog is rendering, the underlying `Dialog` MUST run its dismissal transition. Neither `onConfirm` nor `onCancel` is invoked by the component itself; the component continues to show the retained node's name for the duration of that transition. See **retains-node-name-during-transition** (vector category-delete-024).
- **Very long category or subcategory names**: The component performs no truncation or ellipsizing of names; long names wrap or overflow per the container's CSS, delegated entirely to `AlertModal` styling (vector category-delete-025).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `open` | `boolean` | — | Controls whether the dialog is visible. REQUIRED. |
| `node` | `CategoryTreeNode \| null` | — | The category to delete. When `null` and no prior node has been supplied, the component renders nothing. REQUIRED. |
| `orphanedNames` | `readonly string[]` | `[]` | Names of subcategories that will be orphaned by deletion. Optional; an empty array hides the orphaned message. |
| `itemNoun` | `string` | — | The plural, lowercase name of items filed in categories (e.g., "notes", "documents"). Inserted into the main explanation text. REQUIRED. |
| `error` | `string \| null` | `null` | Error message to display, or `null` if no error. Optional. |
| `busy` | `boolean` | `false` | Indicates an async action (e.g., API call) is in progress. Replaces both action buttons with a loading indicator and blocks dismissal when `true`. Optional. |
| `onConfirm` | `() => void` | — | Callback invoked when the user clicks "Delete". REQUIRED. |
| `onCancel` | `() => void` | — | Callback invoked when the user clicks "Cancel" or uses the close affordance while not busy. A backdrop click never invokes it — the shared `Dialog` primitive disables pointer-based outside dismissal unconditionally. REQUIRED. |

## Deep Linking

Not applicable: This is a modal dialog component, not a routable view. It is triggered by parent state, not by deep links or URL parameters.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `categoryDeleteDialog.title.delete` | `Delete "{categoryName}"?` | Dialog title; category name inserted via template string |
| `categoryDeleteDialog.label.main` | `This deletes the category only. Any {itemNoun} filed under it are not deleted — they become uncategorized.` | Main explanation; `itemNoun` is dynamic per host |
| `categoryDeleteDialog.label.orphaned.singular` | `This subcategory is filed nowhere else, so it is deleted too:` | Message when exactly one subcategory is orphaned |
| `categoryDeleteDialog.label.orphaned.plural` | `These subcategories are filed nowhere else, so they are deleted too:` | Message when more than one subcategory is orphaned |
| `categoryDeleteDialog.label.orphaned.items` | `Their {itemNoun} become uncategorized as well.` | Trailing sentence for the orphaned section, required by **shows-orphaned-items-note**; `itemNoun` is dynamic |
| `categoryDeleteDialog.button.delete` | `Delete` | Primary action button label |
| `categoryDeleteDialog.button.cancel` | `Cancel` | Dismissal button label |

Keys are namespaced under `categoryDeleteDialog.*` so they cannot collide with another dialog's `title.delete`/`button.delete`/`button.cancel` keys.

## Accessibility Options

Not applicable: The component does not expose or respond to display accessibility options such as Reduce Motion, Increase Contrast, or Differentiate Without Color. These are handled by the host application's global settings and the `AlertModal` component's implementation.

## Feature Flags

Not applicable: The component is not gated behind feature flags. It is rendered unconditionally by the host based on the `open` prop.

## Analytics

Not applicable: The component does not emit analytics events directly. Event tracking is the responsibility of the host application, which should track user interactions (`onConfirm`, `onCancel`, error states) via its analytics service.

## Privacy

Not applicable: The component does not collect, store, transmit, or retain any user data. It displays user-provided data (category name, orphaned subcategory names, error messages) without modification or logging.

## Logging

Not applicable: The component does not emit structured logs or debug messages. Debugging and error logging are the responsibility of the host application or the `AlertModal` and `DialogErrorText` component implementations.

## Platform Notes

- **React/Web**: `packages/web/packages/ui/src/blocks/category-delete-dialog.tsx`. Wraps `AlertModal` (`adhsdk://recipes/alert-modal`) with `tone="error"` and `destructive={true}`, which forces the error tone and disables `AlertModal`'s Enter/Escape shortcuts (see **ignores-escape-when-destructive**); the shared `Dialog` primitive sets `disablePointerDismissal` unconditionally, so a backdrop click never dismisses the dialog; only the `×` close affordance reaches `onCancel`, through Base UI's non-Escape dismissal path, whenever `busy` is `false`. The description is rendered as a fragment of block-level `<span>` elements to avoid `<p>` nesting violations inside `DialogDescription`. Errors render through `DialogErrorText` (`adhsdk://recipes/error-text`), whose truthy guard treats `null`, `undefined`, and `""` alike as "no error." The `useLastPresent` hook retains the most recently supplied non-null `node` for the component's lifetime, which is what makes **retains-node-name-during-transition** and **renders-nothing-before-first-node** true.
- **SwiftUI**: Present with `.alert(_:isPresented:presenting:actions:message:)`, using a `Button("Delete", role: .destructive)` and a `Button("Cancel", role: .cancel)` — not `confirmationDialog`, which renders as an action sheet on iOS and fits this multi-paragraph warning poorly. Capture the node into a local `@State` the moment the dialog is presented (e.g. in the action that sets `isPresented = true`), and clear that captured state in the dismissal-completion callback, rather than updating state on a timed delay.
- **Compose**: Build as a Material `AlertDialog` with `confirmButton` styled as a destructive red button and `dismissButton` as the cancel action. Hoist the retained node into `remember { mutableStateOf(...) }`, updating it only when a non-null node arrives, mirroring `useLastPresent`. Replace both buttons with a busy indicator while busy, matching **disables-actions-while-busy**; the orphaned-subcategory message is conditionally rendered with `if (orphanedNames.isNotEmpty())`.
- **AppKit / UIKit**: Use `UIAlertController(style: .alert)` for iOS or `NSAlert` for macOS, with a destructive-styled action for Delete. Format the title as `Delete "{name}"?`. Render the description as an `NSAttributedString`/`AttributedString` with bold emphasis limited to the "are not deleted" phrase and the orphaned category names, per **bolds-destructive-emphasis** — no other span is emphasized. Retain the node name in a stored property for the lifetime of the presenting controller, mirroring `useLastPresent`.
- **WinUI 3**: Implement as a `ContentDialog` with `Title = Delete "{name}"?`, `PrimaryButtonText = "Delete"`, `SecondaryButtonText = "Cancel"`. While `busy` is `true`, replace the button area with a busy `Content` template (e.g. a `ProgressRing`) rather than merely disabling the buttons, mirroring `AlertModal`'s WinUI guidance (`adhsdk://recipes/alert-modal#platforms/winui-3`) and matching **disables-actions-while-busy**. `PrimaryButtonClick` invokes `onConfirm`; `SecondaryButtonClick` invokes `onCancel`. `ContentDialog.Closing` fires with `Result == ContentDialogResult.None` for both Escape and light-dismiss, and the two cannot be distinguished there; since this dialog is always destructive, call `onCancel()` for that case rather than trying to block Escape alone, and set `args.Cancel = true` whenever `busy` is `true`. This is a WinUI-specific accommodation — light-dismiss has no web equivalent, since web's `Dialog` primitive disables backdrop dismissal outright (see **calls-oncancel-on-close-affordance**). Retain the node name in a local field for the duration of the dismiss animation, similar to `useLastPresent`.

## Design Decisions

- **Decision**: `itemNoun` is accepted as a plain, host-supplied string; the component does not translate or restructure the sentence around it.
  **Rationale**: Different hosts categorize different things ("notes", "documents"), so only the host knows the right noun; the component supplies just the fixed sentence template `itemNoun` is interpolated into. A localized build MUST still let the translation layer control grammatical gender and plural form for the injected noun, since `itemNoun` is always supplied already pluralized and some locales inflect the surrounding sentence by gender or number — see Localization.
  **Approved**: pending
- **Decision**: The description is built from block-level `<span>` elements rather than `<p>` elements.
  **Rationale**: `AlertModal` wraps the entire description fragment in `DialogDescription`, which Base UI renders as a `<p>`; nesting a `<p>` inside a `<p>` is invalid HTML, so the browser closes the outer element and re-parents the inner content outside it, silently breaking the dialog's accessible description. Block-level spans preserve the same line-break layout without violating that constraint.
  **Approved**: pending
- **Decision**: The component retains the most recently supplied non-null `node` for the lifetime of its component instance (via `useLastPresent`), rather than clearing to a fallback the instant the host sets `node` back to `null`.
  **Rationale**: The host clears `node` at the start of the dismissal transition; unmounting or blanking immediately would make the dialog's fade-out show an empty or generic label instead of the category the user was just looking at. Holding the last value costs nothing the user can observe, since the host — not this component — still owns whether the dialog is open.
  **Approved**: pending
- **Decision**: The component performs no automatic error recovery — it neither retries nor clears the `error` prop itself.
  **Rationale**: Error state is entirely host-controlled; only the host knows whether a retry is appropriate and when the error is no longer relevant.
  **Approved**: pending
- **Decision**: `orphanedNames` is computed by the host, not derived internally from a category tree the component receives.
  **Rationale**: The same tree can be displayed in more than one place (e.g. a sidebar); having the host compute the orphan set ensures the warning always matches the exact tree state the user is looking at, rather than a copy this component might recompute differently.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [plural-forms](agenticdevelopercookbook://compliance/internationalization#plural-forms) | failed | Internationalization |
| [text-expansion-tolerance](agenticdevelopercookbook://compliance/internationalization#text-expansion-tolerance) | partial | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [safe-defaults](agenticdevelopercookbook://compliance/user-safety#safe-defaults) | passed | User Safety |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Statuses rest on `category-delete-dialog.tsx`: the native `Button`/`DialogActions` markup and labeled title/description inherited unmodified from `AlertModal` for screen-reader-support, keyboard-navigable, focus-management, and semantic-markup; the `apt-*` design tokens (whose contrast values this file doesn't itself define) for contrast-ratio and touch-target-size; the absence of any `prefers-reduced-motion` handling in this file, which delegates the open/close transition entirely to `AlertModal`/`Dialog`, for reduced-motion; `DialogTitle`/`DialogDescription` text inherited unmodified for dynamic-type-support; every string (title template, explanation, orphaned messages, button labels) being hardcoded English JSX with no i18n key lookup for string-externalization and no-hardcoded-strings; the binary `=== 1` singular/plural check for plural-forms; the un-truncated, wrapping text with no verified overflow guard for text-expansion-tolerance; plain string interpolation and `Array.prototype.join` with no character filtering for unicode-support; and the conservative defaults (`orphanedNames=[]`, `error=null`, `busy=false`, plus a `destructive` flag that is never caller-configurable) for safe-defaults. Best-practices statuses rest on `CategoryDeleteDialog` composing `AlertModal` with its copy computed from props and its retention logic delegated to the shared `useLastPresent` hook, with no business logic of its own (separation-of-concerns: passed), and on `categoryDeleteDialog.test.tsx` directly rendering the dialog and asserting its behavior (unit-test-coverage: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Backdrop clicks never dismiss (disablePointerDismissal); renamed calls-oncancel-on-backdrop-dismissal -> calls-oncancel-on-close-affordance; fixed busy/edge-case/config/platform-note text (T019). Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case; resolved the null-node/retained-node contradiction; corrected the accessibility role citation from `alertdialog` to the actual `dialog`; picked one busy behavior (both buttons replaced by a loading indicator) and fixed the busy/cancel-edge-case contradiction; added Escape-ignored and backdrop-dismissal requirements; moved React-internal names (`useLastPresent`, `DialogErrorText`, `AlertModal`) out of Behavioral Requirements and into Platform Notes; replaced the SwiftUI "slight delay" retention hack and prescribed `.alert` with a destructive button role; added a requirement for the orphaned-items trailing sentence and namespaced Localization keys under `categoryDeleteDialog.*`; renamed the "no translation" design decision to describe host-supplied `itemNoun` and its gender/plural implications; reformatted Design Decisions to the Decision/Rationale/Approved triple; added a requirement defining which phrases get bold emphasis; added missing test vectors for error/destructive tone, the corrected role, empty-string/null error, empty and long orphaned-name lists, and external close; rewrote Compliance with linked catalog checks and grounded statuses; added `alert-modal` and `error-text` to `related`. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
