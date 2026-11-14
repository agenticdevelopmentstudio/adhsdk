---
id: 86aedf2f-b353-4770-a6dd-9e29b3d9b76a
title: "Selection Actions"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A toolbar strip of action buttons that operate on selected items, with a destructive Delete behind confirmation."
platforms:
  - typescript
  - web
tags:
  - selection
  - toolbar
  - actions
depends-on:
  - f3c25236-d72f-4a7b-839a-b7f335b3acd0
  - e26e765d-2caa-40f8-a668-661ed2b0632c
related:
  - a8f66760-7db0-4a10-927e-856c2170dd4f
references:
  - https://www.w3.org/TR/WCAG21/
  - https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/
  - https://lucide.dev/guide/packages/lucide-react
approved-by: ""
approved-date: ""
---

# Selection Actions

## Overview

Selection Actions is a toolbar component that renders a configurable strip of action buttons for operating on selected items from a list. Each action is a button that receives the array of currently selected item IDs. The component optionally includes a destructive Delete button that requires user confirmation via a modal before executing the delete callback. Actions without selection requirements (such as "New" actions) remain enabled when no items are selected; actions with selection requirements become disabled. Dividers can visually group related actions.

The component renders no container of its own — it is designed to be placed in a toolbar context such as a `ListHeader`'s `actions` slot, which provides the visual styling and layout.

## Behavioral Requirements

- **render-action-buttons**: The component MUST render each provided action as a `Button` element.
- **duplicate-action-ids**: The component uses each action's `id` as the React list key for its wrapping `Fragment`. A duplicate `id` across actions MUST NOT prevent either action from rendering or from invoking its own `onClick` — React's key collision affects reconciliation identity only, not render count or event wiring. Callers MUST still treat `id` as unique; the component does not deduplicate or otherwise correct a collision.
- **pass-selected-ids-on-action**: When an action button is clicked, the component MUST call the action's `onClick` callback with the array of currently selected IDs.
- **disable-selection-required-actions**: Actions with `requiresSelection: true` MUST be disabled when the `selectedIds` array is empty.
- **keep-standalone-actions-enabled**: Actions without `requiresSelection` or with `requiresSelection: false` MUST remain enabled regardless of selection state.
- **use-ghost-variant-by-default**: Each action button MUST use the `ghost` variant unless the action specifies a different variant.
- **render-divider-before-action**: If an action has `dividerBefore: true`, the component MUST render a vertical separator before that action.
- **divider-separator-role**: Dividers MUST use the ARIA `separator` role with `aria-orientation="vertical"` to communicate grouping to assistive technology.
- **render-delete-button-conditionally**: The Delete button MUST render only if the `onDelete` callback is provided.
- **disable-delete-when-no-selection**: The Delete button MUST be disabled when the `selectedIds` array is empty.
- **use-destructive-ghost-delete-variant**: The Delete button MUST use the `destructive-ghost` variant.
- **include-trash-icon-on-delete**: The Delete button MUST display a Trash2 icon with the label "Delete".
- **delete-requires-confirmation**: When the Delete button is clicked, the component MUST display a confirmation modal before calling the `onDelete` callback.
- **confirm-modal-destructive-style**: The confirmation modal MUST render with destructive styling — the component always passes `destructive={true}` to the modal.
- **confirm-button-label**: The confirmation modal's confirm button MUST use the label "Delete".
- **cancel-button-label**: The confirmation modal's cancel button MUST use the label "Cancel".
- **use-default-delete-message**: If `deleteConfirm` is not provided, the modal MUST display the default title "Delete selected?".
- **use-custom-delete-message**: If `deleteConfirm` is provided with a `title` and optional `description`, the modal MUST use those values instead of the defaults.
- **close-modal-on-cancel**: When the user cancels the delete confirmation modal, the component MUST close the modal without calling `onDelete`.
- **close-modal-on-confirm**: When the user confirms deletion, the component MUST close the modal before invoking `onDelete`.
- **call-ondelete-only-after-confirm**: The `onDelete` callback MUST be called only after the user confirms deletion in the modal.
- **ondelete-selection-argument**: The `onDelete` callback MUST be called with the `selectedIds` array as it stands at the moment of confirmation. The component holds no snapshot of `selectedIds` taken when Delete was first clicked — the confirm handler closes over the current `selectedIds` prop on every render, so a caller that mutates `selectedIds` while the modal is open changes what `onDelete` receives.

## Appearance

- **Button size**: small — consistent with toolbar context (see React/Web platform note for the concrete size token)
- **Action button variant**: `ghost` (default) or custom variant from action definition
- **Delete button variant**: `destructive-ghost`
- **Divider styling**: a thin vertical rule using the theme's border color, sized and spaced consistently with the toolbar's other elements (see React/Web platform note for concrete values)
- **Divider orientation**: Vertical
- **Icon**: a trash icon, positioned inline before the "Delete" text (see React/Web platform note for the concrete icon source)
- **No container**: The component renders only buttons, dividers, and the modal — no wrapper element.

## States

| State | Appearance change |
|-------|------------------|
| Default | Action or Delete button is enabled and clickable |
| Disabled (selection-required action, no selection) | Action button is greyed out and non-interactive |
| Disabled (Delete, no selection) | Delete button is greyed out and non-interactive |
| Deleting (confirmation modal open) | Modal overlay appears with destructive styling (see **confirm-modal-destructive-style**) |

## Accessibility

- Role: Buttons are standard `<button>` elements with implicit button role.
- Labels: Each action button uses the text from `action.label` (can be React node). Delete button uses the hardcoded label "Delete".
- Dividers: Separators use ARIA `role="separator"` with `aria-orientation="vertical"` to communicate structural grouping to screen reader users.
- State announcement: Disabled state is implicit in the button's `disabled` attribute; browser and assistive technology automatically announce disabled buttons.
- Touch target: Buttons use the Button component's small size. The Button ingredient's own spec documents that its fixed size-variant heights sit below the Apple HIG 44×44pt and Material 48×48dp minimum touch-target guidance by default, and that a surface must opt in to a larger floor via `--adh-button-min-height`/`--adh-button-min-width` on an ancestor. Selection Actions does not set either variable, so it does not guarantee an accessible tap target on its own; a host that requires one MUST set the floor itself.
- Modal accessibility: The AlertModal component MUST provide its own focus management, role attributes, and keyboard dismissal (Escape key).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| selection-actions-001 | render-action-buttons | actions=[{id:"a1", label:"Archive"}] | Button with text "Archive" is rendered |
| selection-actions-002 | pass-selected-ids-on-action | actions=[{id:"a1", label:"Archive", onClick}], selectedIds=["row1","row2"], user clicks Archive | onClick is called with ["row1","row2"] |
| selection-actions-003 | disable-selection-required-actions | actions=[{id:"a1", label:"Archive", requiresSelection:true}], selectedIds=[] | Archive button is disabled (disabled attribute set) |
| selection-actions-004 | keep-standalone-actions-enabled | actions=[{id:"a1", label:"New", requiresSelection:false}], selectedIds=[] | New button is enabled and clickable |
| selection-actions-005 | use-ghost-variant-by-default | actions=[{id:"a1", label:"Archive"}] | Archive button uses the `ghost` variant |
| selection-actions-006 | render-divider-before-action | actions=[{id:"a1", label:"Archive", onClick, dividerBefore:true}] | A vertical separator element with role="separator" is rendered before the Archive button |
| selection-actions-007 | render-delete-button-conditionally | onDelete undefined | Delete button is not rendered |
| selection-actions-008 | render-delete-button-conditionally | onDelete provided | Delete button is rendered |
| selection-actions-009 | disable-delete-when-no-selection | onDelete provided, selectedIds=[] | Delete button is disabled |
| selection-actions-010 | disable-delete-when-no-selection | onDelete provided, selectedIds=["row1"] | Delete button is enabled |
| selection-actions-011 | use-destructive-ghost-delete-variant | onDelete provided | Delete button uses destructive-ghost variant |
| selection-actions-012 | include-trash-icon-on-delete | onDelete provided | Delete button contains Trash2 icon and text "Delete" |
| selection-actions-013 | delete-requires-confirmation, confirm-modal-destructive-style | onDelete provided, user clicks Delete | AlertModal appears with `destructive` set to `true` |
| selection-actions-014 | use-default-delete-message | onDelete provided, deleteConfirm undefined, user clicks Delete | Modal title is "Delete selected?" |
| selection-actions-015 | use-custom-delete-message | onDelete provided, deleteConfirm={title:"Remove items?"}, user clicks Delete | Modal title is "Remove items?" |
| selection-actions-016 | call-ondelete-only-after-confirm | onDelete provided, selectedIds=["row1"], user clicks Delete then confirms | onDelete is called with ["row1"] |
| selection-actions-017 | close-modal-on-cancel | onDelete provided, user clicks Delete then clicks Cancel | Modal closes, onDelete is not called |
| selection-actions-018 | divider-separator-role | actions=[{id:"a1", label:"Archive", onClick, dividerBefore:true}] | Divider has role="separator" and aria-orientation="vertical" |
| selection-actions-019 | confirm-button-label | onDelete provided, user clicks Delete | Confirmation modal's confirm button label is "Delete" |
| selection-actions-020 | cancel-button-label | onDelete provided, user clicks Delete | Confirmation modal's cancel button label is "Cancel" |
| selection-actions-021 | close-modal-on-confirm | onDelete provided, selectedIds=["row1"], user clicks Delete then confirms | Modal is closed immediately after confirming |
| selection-actions-022 | ondelete-selection-argument | onDelete provided, selectedIds=["row1"], user clicks Delete, selectedIds prop changes to ["row1","row2"] while the modal is open, user confirms | onDelete is called with ["row1","row2"], not ["row1"] |
| selection-actions-023 | duplicate-action-ids | actions=[{id:"a1", label:"Archive", onClickA}, {id:"a1", label:"Rename", onClickB}] | Both "Archive" and "Rename" buttons render and each invokes its own onClick; the shared id is a caller error the component does not correct |

## Edge Cases

- **No actions provided**: When `actions` is an empty array, no action buttons are rendered (only the Delete button if `onDelete` is provided).
- **No delete callback**: When `onDelete` is undefined, the Delete button does not render at all. The component functions with only custom actions.
- **Empty selected IDs**: When `selectedIds` is an empty array, all selection-required actions are disabled and the Delete button is disabled, but standalone actions remain enabled.
- **Multiple simultaneous selections**: The component receives an array of IDs and passes all of them to action handlers. No limit is enforced on the array length.
- **Rapid action clicks**: Each action handler is called independently when its button is clicked. No debouncing or click prevention is implemented; it is the action handler's responsibility to manage race conditions or duplicate invocations.
- **Duplicate action IDs**: The component uses each action's `id` as its React list key. Action `id`s MUST be unique; a duplicate does not stop either button from rendering or from invoking its own `onClick`, but callers must not rely on stable list identity across renders when ids collide. See **duplicate-action-ids**.
- **Custom action variant**: An action can override the default `ghost` variant by specifying a `variant` property matching Button's variant prop.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `selectedIds` | `string[]` | (required) | Array of IDs of currently selected rows. The caller is responsible for pruning IDs that have left the list. |
| `actions` | `ListAction[]` | `[]` | Array of action definitions. Each action defines an `id`, `label`, and `onClick` handler. Actions may optionally specify `requiresSelection`, `dividerBefore`, and `variant`. |
| `onDelete` | `(selectedIds: string[]) => void` | undefined | Callback invoked after the user confirms deletion. If undefined, the Delete button does not render. |
| `deleteConfirm` | `{ title: string; description?: ReactNode }` | undefined | Custom modal message for the delete confirmation. If undefined, the default title "Delete selected?" is used. |

## Deep Linking

Not applicable: Selection Actions is a toolbar component that operates on state within the current view. It does not navigate to a new destination and does not support deep linking.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded) | "Delete" | Delete button label |
| (none — hardcoded) | "Delete selected?" | Default confirmation modal title, used when `deleteConfirm` is not provided |
| (none — hardcoded) | "Cancel" | Confirmation modal cancel button label |

None of these three strings can be overridden by the caller. `deleteConfirm` only replaces the modal's `title` and `description`; the Delete button's own label and the modal's Cancel/Confirm labels have no override point in the component's props. Localizing them today requires forking the component; the parent application is not able to localize them through configuration alone.

## Accessibility Options

- **Reduce Motion**: The component itself does not define motion; animation handling is delegated to the Button and AlertModal components. It SHOULD respond to prefers-reduced-motion if those components do.
- **Increase Contrast**: The Button component's styling MUST meet Increase Contrast requirements; Selection Actions adds no additional styling that would interfere.
- **Differentiate Without Color**: Disabled state MUST be communicated via the button's disabled attribute (browser default), not by color alone. Dividers use color; their separating function is structural and announced via ARIA role, not color-dependent.

## Feature Flags

Not applicable: Selection Actions holds only local UI state (whether the delete-confirmation modal is open) and has no conditional features or runtime toggles.

## Analytics

- **action.clicked**: When the user clicks any action button, the parent application MAY emit an analytics event naming the action and selection state. Selection Actions does not emit events internally.
- **delete.initiated**: When the Delete button is clicked, the confirmation modal appears. The parent application MAY track this as an intent-to-delete event.
- **delete.confirmed**: When the user confirms deletion in the modal, the parent application MAY emit an event after `onDelete` is called.
- **delete.cancelled**: When the user cancels the delete confirmation, the parent application MAY track this if needed.

Analytics implementation is the responsibility of the parent application and action handlers; Selection Actions provides no built-in analytics.

## Privacy

Not applicable: Selection Actions does not collect, store, or transmit any data. It operates solely on data provided by the caller (`selectedIds` and `actions`) and passes selection state to action handlers.

## Logging

Not applicable: Selection Actions does not emit logs. Logging of action invocations and delete operations is the responsibility of the parent application and the handlers it provides.

## Platform Notes

- **React/Web**: Selection Actions is implemented as a React functional component (`SelectionActions`) that returns a fragment with Button elements from the shared ui/button component, a `Trash2` icon from `lucide-react`, and an AlertModal from the shared ui/components/alert-modal. Both action buttons and the Delete button use Button's `sm` size. The divider is a `div` with `role="separator"` and `aria-orientation="vertical"`, styled `mx-1 h-5 w-px bg-apt-border` (4px horizontal margin, 20px height at a 16px base, theme border color). The Trash2 icon is placed inline before the "Delete" text with `data-icon="inline-start"`. All styling is applied via Tailwind CSS classes. See `packages/web/packages/ui/src/blocks/selection-actions.tsx`.
- **SwiftUI**: Start from an `HStack` or `ToolbarItemGroup` in the toolbar placement. Render action buttons using SwiftUI's `Button` with `.buttonStyle(.borderless)` (or `.plain`) to match the ghost variant's chromeless appearance. Implement selection-required actions by binding their `disabled` state to `selectedIds.isEmpty`. For the Delete button, bind its `disabled` state to `selectedIds.isEmpty` and use `Button(role: .destructive)` so the system renders it with destructive semantics and tinting. Handle the confirmation with a `.confirmationDialog` that appears when a `@State var confirming: Bool` is true, using `Button(role: .destructive)` for "Delete" and a plain `Button` for "Cancel". Pass the selected IDs array to each action closure.
- **Compose (Kotlin)**: Start with a `Row` modifier on a toolbar lambda. Render action buttons using Compose's `TextButton` composable to match the chromeless ghost variant. Use `enabled` parameter bound to selection state for requiresSelection actions. For Delete, use `TextButton` with `MaterialTheme.colorScheme.error` as its content color, and show a confirmation dialog (`AlertDialog`) when the user taps it, with the confirm button styled using the same error content color. Pass selected IDs to each lambda callback.
- **AppKit / UIKit**: Because the component renders no container of its own (see Design Decisions), host toolbar items as plain buttons inside the caller's existing toolbar group rather than standing up a dedicated `NSToolbar`/`NSToolbarItem` per action. On macOS (AppKit), use `NSButton` with `isBordered = false` (or `.bezelStyle = .toolbar` when the host already manages a toolbar) to match the ghost variant. On iOS (UIKit), implement as a `UIView` containing `UIButton` subviews arranged horizontally in a `UIStackView`. Bind button enabled state to the selection array's `isEmpty` property. For the Delete button, use the system destructive/red appearance and present an `NSAlert` (macOS) or `UIAlertController` (iOS) confirmation dialog with "Delete" and "Cancel" actions.
- **WinUI 3**: Implement as a `StackPanel` with `Orientation="Horizontal"` containing `Button` elements. Use a borderless/`Subtle` style for action buttons and a named destructive style (e.g. a `DeleteButtonStyle` resource using an error/red `Brush`) for the Delete button. Bind the Delete button's `IsEnabled` to a converter evaluating `!(RequiresSelection && SelectedIds.Count == 0)` — enabled unless the action requires a selection and none exists. Show the delete confirmation using `ContentDialog` with `PrimaryButtonText="Delete"`, `CloseButtonText="Cancel"`, and `DefaultButton="Close"` so Enter/gamepad-A does not default onto the destructive action.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/selection-actions.tsx` | unverified |

## Design Decisions

**Decision**: The component renders only its children (buttons and dividers) in a Fragment, with no container element of its own; it relies on the parent (ListHeader's actions slot) to provide layout and styling context.
**Rationale**: This keeps the component flexible and prevents nesting issues in toolbar contexts.
**Approved**: pending

**Decision**: The `requiresSelection` property defaults to `false` (or is omitted), meaning actions are enabled by default.
**Rationale**: This allows "New" and other standalone actions to work without requiring a selection; actions that genuinely need a selection must explicitly declare `requiresSelection: true`.
**Approved**: pending

**Decision**: Delete is always behind a confirmation modal, never immediate.
**Rationale**: This reflects the destructive nature of deletion and aligns with common UX patterns for irreversible actions.
**Approved**: pending

**Decision**: Dividers use the ARIA `separator` role rather than being purely visual.
**Rationale**: This ensures users of assistive technology understand the structural grouping of action buttons.
**Approved**: pending

**Decision**: The component does not manage retry, undo, or error handling for action callbacks.
**Rationale**: Each action handler (and the `onDelete` callback) is fully responsible for managing its own error states, async operations, and side effects. This keeps Selection Actions lightweight and composable.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The `passed` accessibility statuses rest on the standard `<button>` elements, the `role="separator"`/`aria-orientation="vertical"` divider markup in `selection-actions.tsx`, and the delegation of modal focus handling to AlertModal (its own recipe); `touch-target-size` and `no-hardcoded-strings` are `failed` because the source renders `sm`-sized buttons without opting into Button's `--adh-button-min-height`/`--adh-button-min-width` floor, and hardcodes "Delete", "Cancel", and "Delete selected?" with no override besides `deleteConfirm.title`/`description`. `separation-of-concerns` passes: the component owns only action rendering and the confirm/cancel flow's open state, delegating the modal itself to `AlertModal`. `unit-test-coverage` passes: `selectionActions.test.tsx` renders `SelectionActions` directly and covers action enablement, the selected-ids argument, dividers, and the confirm/cancel delete flow.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case and updated every citation; added requirements for the confirm modal's destructive styling, confirm/cancel button labels, closing on confirm, and the onDelete selection argument; replaced the impossible "modal already visible" edge case with a duplicate-action-id edge case and vector; populated depends-on, related, and references; moved web-only Appearance details into the React/Web platform note; corrected the SwiftUI, Compose, AppKit/UIKit, and WinUI 3 platform notes to real APIs; rewrote Localization to list the component's unoverridable hardcoded strings instead of "Not applicable"; dropped the "stateless" claim from Feature Flags; reformatted Design Decisions into Decision/Rationale/Approved form; and rebuilt Compliance as a linked table reflecting that touch-target-size and no-hardcoded-strings fail. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added missing duplicate-action-ids requirement; K20c dangling ref now resolves. |
