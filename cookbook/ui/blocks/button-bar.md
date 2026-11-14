---
id: 81db83fc-b30c-4ba3-b4d5-572dc8b4e335
title: "Button Bar"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A recessed editing toolbar that renders preset action buttons (New/Delete/Cancel/Save) or custom content."
platforms:
  - typescript
  - web
tags:
  - toolbar
  - editing-actions
depends-on:
  - f3c25236-d72f-4a7b-839a-b7f335b3acd0
related: []
references: []
approved-by: ""
approved-date: ""
---

# Button Bar

## Overview

The Button Bar is a recessed toolbar used for editing actions. It renders either a preset editing flow (Create/Delete/Cancel/Save) or arbitrary custom content (e.g., filters, selection actions). The component manages button enable/disable states based on draft validity and save progress, exposing control over visibility of the Create and Delete buttons to accommodate varying pane layouts.

## Behavioral Requirements

- **render-toolbar-role**: Component MUST render with `role="toolbar"`.
- **toolbar-aria-label**: Component MUST accept and render an `ariaLabel` prop; the default MUST be `"Editing actions"`.
- **children-slot**: Component MUST accept a `children` prop to render arbitrary custom content, which takes precedence over preset actions.
- **preset-actions-flow**: When `children` is not provided and `actions` is provided, the component MUST render the preset editing action flow.
- **create-button**: When rendering preset actions and `showCreate` is `true` and `actions.onCreate` is provided, the component MUST render a button with a leading add icon and a label (default `"New"`, or `actions.createLabel` if provided).
- **delete-button**: When rendering preset actions and `showDelete` is `true` and `actions.onDelete` is provided, the component MUST render a button in the Button component's `destructive-ghost` variant with a leading delete icon and the label `"Delete"`.
- **cancel-button**: When rendering preset actions and `actions` is provided, the component MUST render a button with a leading cancel icon and the label `"Cancel"`.
- **save-button**: When rendering preset actions and `actions` is provided, the component MUST render a button with a leading confirm icon and the label `"Save"` or `"Saving…"` when `actions.saving` is `true`.
- **disable-cancel-by-flag**: The Cancel button MUST be disabled when `actions.canCancel` is `false` or `actions.saving` is `true`. `canCancel` is a required field of `actions` (see Configuration); there is no omitted-value case for it.
- **disable-save-by-flag**: The Save button MUST be disabled when `actions.canSave` is `false` or `actions.saving` is `true`. `canSave` is a required field of `actions` (see Configuration); there is no omitted-value case for it.
- **disable-delete-by-flag**: The Delete button MUST be disabled when `actions.canDelete` is `false` or `actions.saving` is `true`.
- **create-not-disabled-while-saving**: Unlike Delete, Cancel, and Save, the Create button does not receive a `disabled` attribute when `actions.saving` is `true` — it stays enabled and clickable through a save.
- **save-disabled-styling**: When the Save button is disabled, the component MUST switch it to the Button component's `ghost` variant and apply the muted text token (`apt-text-muted`).
- **render-vertical-separator**: When rendering preset actions and a Create button is present, the component MUST render a vertical separator (visual divider, marked `aria-hidden`) between Create and Delete/Cancel buttons.
- **render-spacer**: When rendering preset actions, the component MUST render a flexible spacer between Delete and Save/Cancel groups that expands to fill available horizontal space.
- **leading-content**: Component MUST accept a `leading` prop to render content before the action buttons or children.
- **class-override**: Component MUST accept a `className` prop that is merged with the base styling.
- **invoke-callbacks**: The component MUST invoke `actions.onCreate()`, `actions.onCancel()`, `actions.onSave()`, or `actions.onDelete()` when the respective button is clicked, and MUST NOT invoke a callback while its button is disabled.

## Appearance

- **Layout**: Horizontal flex layout, gap of 1 unit between children
- **Border**: Top and bottom borders (1px), using the `apt-border` color token
- **Background**: Recessed background using the `apt-bg` color token
- **Padding**: Horizontal (px-6 = 24px), Vertical (py-2 = 8px)
- **Button size**: Small (`sm`), as defined by the shared Button component
- **Text color (normal)**: Inherited from Button variant (default text color for ghost and default variants)
- **Text color (disabled Save)**: Muted text using `text-apt-text-muted` token
- **Icon placement**: Inline with text, at the start of the button label (via `data-icon="inline-start"`)
- **Separator width**: 1px, height 5 units (20px)
- **Separator color**: Uses `apt-border` color token

## States

| State | Appearance change |
|-------|------------------|
| Default (all enabled) | Buttons render in their normal variant (ghost for Cancel/Create/Delete, default for Save); text is not muted |
| Saving | Save button shows "Saving…" instead of "Save"; Delete, Cancel, and Save appear disabled with `disabled` attribute; Create does not receive `disabled` and stays clickable; Save text is muted |
| Cancel disabled | Cancel button appears grayed out / disabled |
| Save disabled (valid draft but no dirty changes) | Save button appears in ghost variant with muted text, does not accept clicks |
| Delete disabled | Delete button appears grayed out / disabled |
| Create not disabled (while saving) | Create button remains in its normal enabled appearance and stays clickable (see **create-not-disabled-while-saving**) |

## Accessibility

- **Role**: Toolbar, signaled via `role="toolbar"`
- **Label**: Toolbar MUST have a descriptive `aria-label`; default is `"Editing actions"`
- **Button labels**: Each button (Create, Cancel, Save, Delete) MUST have visible text; icons are decorative (`data-icon="inline-start"` indicates icon placement)
- **Disabled state**: Disabled buttons MUST have the `disabled` HTML attribute set
- **Separator**: Visual separators between button groups MUST be marked `aria-hidden="true"` to prevent screen reader announcements
- **Loading indicator**: When `actions.saving` is `true`, the Save button text changes to `"Saving…"` to provide feedback; this is the accessible indicator of the saving state (not an aria-live region)
- **Keyboard interaction**: Buttons MUST be keyboard accessible and focusable per the shared Button component's implementation
- **Touch target**: Buttons inherit minimum touch target size from the shared Button component (`sm` size); verify this meets at least 44×44pt per platform HIG
- **Semantic structure**: No `aria-pressed`, `aria-checked`, or other state attributes beyond `disabled`; the button text change ("Save" → "Saving…") is the state indicator

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| button-bar-001 | render-toolbar-role | Render ButtonBar with default props | Element has `role="toolbar"` |
| button-bar-002 | toolbar-aria-label | Render ButtonBar with default props | Element has `aria-label="Editing actions"` |
| button-bar-003 | toolbar-aria-label | Render ButtonBar with `ariaLabel="Custom"` | Element has `aria-label="Custom"` |
| button-bar-004 | children-slot | Render with `children={<div>Custom</div>}` | Custom content appears inside toolbar; preset actions are not rendered |
| button-bar-005 | preset-actions-flow, create-button | Render with `actions={{ onCreate: fn, ... }}` and `showCreate={true}` and `actions.onCreate` is defined | Create button with a leading add icon and "New" label renders |
| button-bar-006 | create-button | Render with `actions={{ onCreate: fn, createLabel: "Add" }}` and `showCreate={true}` | Create button renders with label "Add" |
| button-bar-007 | create-button | Render with `showCreate={false}` | Create button does not render |
| button-bar-008 | delete-button | Render with `actions={{ onDelete: fn, ... }}` and `showDelete={true}` and `actions.onDelete` is defined | Delete button with a leading delete icon and "Delete" label renders in the Button component's `destructive-ghost` variant |
| button-bar-009 | delete-button | Render with `showDelete={false}` | Delete button does not render |
| button-bar-010 | cancel-button | Render with `actions={{ onCancel: fn, ... }}` | Cancel button with a leading cancel icon and "Cancel" label renders |
| button-bar-011 | save-button | Render with `actions={{ onSave: fn, ... }}` and `saving={false}` | Save button with a leading confirm icon and "Save" label renders |
| button-bar-012 | save-button | Render with `actions={{ onSave: fn, ... }}` and `saving={true}` | Save button with a leading confirm icon and "Saving…" label renders |
| button-bar-013 | disable-cancel-by-flag | Render with `actions={{ canCancel: false, ... }}` | Cancel button has `disabled` attribute |
| button-bar-014 | disable-cancel-by-flag | Render with `actions={{ canCancel: true, saving: true }}` | Cancel button has `disabled` attribute |
| button-bar-015 | disable-save-by-flag | Render with `actions={{ canSave: false, ... }}` | Save button has `disabled` attribute |
| button-bar-016 | disable-save-by-flag | Render with `actions={{ canSave: true, saving: true }}` | Save button has `disabled` attribute |
| button-bar-017 | disable-delete-by-flag | Render with `actions={{ canDelete: false, ... }}` | Delete button has `disabled` attribute |
| button-bar-018 | disable-delete-by-flag | Render with `actions={{ canDelete: true, saving: true }}` | Delete button has `disabled` attribute |
| button-bar-019 | create-not-disabled-while-saving | Render with `actions={{ onCreate: fn, saving: true }}` and `showCreate={true}` | Create button has no `disabled` attribute and remains clickable |
| button-bar-020 | save-disabled-styling | Render with `actions={{ canSave: false }}` | Save button renders in the Button component's `ghost` variant with the muted text token (`apt-text-muted`) applied |
| button-bar-021 | invoke-callbacks | User clicks Create button | `actions.onCreate()` is invoked |
| button-bar-022 | invoke-callbacks | User clicks Cancel button | `actions.onCancel()` is invoked |
| button-bar-023 | invoke-callbacks | User clicks Save button while `canSave={true}` and `saving={false}` | `actions.onSave()` is invoked |
| button-bar-024 | invoke-callbacks | User clicks Delete button | `actions.onDelete()` is invoked |
| button-bar-025 | invoke-callbacks | User clicks Save button while it is disabled (`canSave={false}`) | `actions.onSave()` is NOT invoked |
| button-bar-026 | leading-content | Render with `leading={<span>Title</span>}` | Leading content renders before action buttons |
| button-bar-027 | class-override | Render with `className="custom-class"` | Custom class is applied to the toolbar element alongside base classes |
| button-bar-028 | render-vertical-separator | Render with `actions={{ onCreate: fn, onDelete: fn, ... }}` and `showCreate={true}` | A vertical separator renders between the Create button and the Delete button |
| button-bar-029 | render-vertical-separator | Render with `showCreate={false}` (or `actions.onCreate` undefined) | No vertical separator renders |
| button-bar-030 | render-spacer | Render with `actions={{ onDelete: fn, ... }}` | A flexible spacer element renders between the Delete button and the Cancel/Save group and expands to fill available horizontal space |
| button-bar-031 | preset-actions-flow, children-slot | Render with neither `actions` nor `children` provided | Toolbar renders with `role="toolbar"` and no buttons or content, only its border/background/padding |

## Edge Cases

- **Missing `actions` and no `children`**: If neither `actions` nor `children` is provided, the toolbar renders with only the border, background, and padding applied; no buttons or content. This is not an error state; it is a valid composition for a pane that implements its own button logic elsewhere. Behavior: MUST render an empty recessed bar.
- **Both `actions` and `children` provided**: When both are present, `children` takes precedence and `actions` is ignored. Behavior: MUST render only the custom children and suppress the preset action flow.
- **`onCreate` not provided but `showCreate={true}`**: The Create button MUST NOT render (checked by the guard `showCreate && onCreate && (...)` in the source). Behavior: MUST skip the Create button and separator.
- **`onDelete` not provided but `showDelete={true}`**: The Delete button MUST NOT render (same guard logic). Behavior: MUST skip the Delete button.
- **`canDelete` not provided**: The Delete button defaults to `undefined`, which is falsy in the context of `!canDelete`. Behavior: MUST render the Delete button as disabled if `onDelete` is provided and `showDelete` is true.
- **`saving` not provided**: Defaults to `false`. Buttons do not appear disabled due to saving state. Behavior: MUST treat as no save in progress.
- **Click while `disabled={true}`**: Native HTML `disabled` attribute prevents click events from firing. Behavior: MUST not invoke the callback.
- **Rapid clicks while saving**: Once `saving={true}`, the Save button is disabled. If the user clicks very quickly before the parent updates `saving={true}`, the second click does not fire because the button is disabled. Behavior: MUST rely on the HTML `disabled` attribute for race condition protection.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `actions` | `ButtonBarActions` (optional) | `undefined` | Preset editing actions object. When provided and `children` is not provided, the preset action flow renders. |
| `showCreate` | `boolean` | `true` | Controls visibility of the Create button when rendering preset actions. |
| `showDelete` | `boolean` | `true` | Controls visibility of the Delete button when rendering preset actions. |
| `leading` | `ReactNode` | `undefined` | Content to render before action buttons or children (e.g., a pane title). |
| `children` | `ReactNode` | `undefined` | Arbitrary content that overrides preset actions when provided. |
| `ariaLabel` | `string` | `"Editing actions"` | Accessible label for the toolbar. |
| `className` | `string` | `undefined` | Additional CSS classes merged with base styling. |

### `ButtonBarActions` shape

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `onCreate` | `() => void` | No | `undefined` | Called when the Create button is clicked. Omit together with `showCreate={false}` for panes that don't create here; the Create button and its separator do not render without it. |
| `createLabel` | `string` | No | `"New"` | Overrides the Create button's label. |
| `onCancel` | `() => void` | Yes | — | Called when the Cancel button is clicked. |
| `canCancel` | `boolean` | Yes | — | Enables the Cancel button when `true` (and `saving` is `false`). |
| `onSave` | `() => void` | Yes | — | Called when the Save button is clicked. |
| `canSave` | `boolean` | Yes | — | Enables the Save button when `true` (and `saving` is `false`); also drives the `ghost`-variant/muted-text swap when disabled. |
| `saving` | `boolean` | No | `false` | While `true`, disables Delete/Cancel/Save and changes the Save label to `"Saving…"`; Create is not disabled by this flag (see **create-not-disabled-while-saving**). |
| `onDelete` | `() => void` | No | `undefined` | Called when the Delete button is clicked. Omit together with `showDelete={false}` for panes that don't delete here; the Delete button does not render without it. |
| `canDelete` | `boolean` | No | `undefined` (falsy) | Enables the Delete button when `true` (and `saving` is `false`); an omitted value renders Delete as disabled whenever it is shown. |

## Deep Linking

Not applicable: This component is an editing toolbar with no independent deep-linking semantics. Navigation is the responsibility of the buttons' click handlers and the parent page logic.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `button_bar.create_label` | "New" | Label for the Create button; overridable via `actions.createLabel`. This is the only preset label the component lets a consumer replace. |
| `button_bar.cancel_label` | "Cancel" | Label for the Cancel button; hardcoded in source, not currently wired to a string key. |
| `button_bar.save_label` | "Save" | Label for the Save button when not saving; hardcoded in source, not currently wired to a string key. |
| `button_bar.saving_label` | "Saving…" | Label for the Save button while a save is in flight; hardcoded in source, not currently wired to a string key. |
| `button_bar.delete_label` | "Delete" | Label for the Delete button; hardcoded in source, not currently wired to a string key. |
| `button_bar.toolbar_label` | "Editing actions" | Default `aria-label` for the toolbar; a consumer can override the whole string via `ariaLabel`, but the source has no keyed-translation lookup for the default value itself. |

This table names the strings the component would need to externalize to be fully localizable; today only `createLabel` is an injectable prop. See the Compliance section below for the resulting `string-externalization`/`no-hardcoded-strings` status.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | The Button Bar itself renders no motion or animated transitions; the Save label's text change ("Save" → "Saving…") is a text swap, not an animation, and needs no Reduce Motion accommodation. Buttons composed within it SHOULD follow the shared Button component's own Reduce Motion behavior (accessibility-options ([adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0))), which is that component's concern, not this one's. |
| Increase Contrast | Buttons inherit Increase Contrast behavior from the shared Button component. The muted text color (`text-apt-text-muted`) for disabled Save button MUST maintain sufficient contrast when Increase Contrast is enabled. |
| Differentiate Without Color | Buttons MUST be distinguishable without relying on color alone; the disabled state is indicated by both color and the HTML `disabled` attribute. The destructive-ghost variant for Delete MUST be distinguishable via shape, icon, or other non-color properties. |

## Feature Flags

Not applicable: This is a presentational UI component with no feature-flag integration in the source code. Feature flags are the responsibility of the parent component logic that calls ButtonBar.

## Analytics

Not applicable: This component does not fire analytics events. Analytics instrumentation is the responsibility of the callbacks provided in the `actions` prop (`onCreate`, `onCancel`, `onSave`, `onDelete`); the parent page logic MUST wrap these callbacks with analytics tracking if needed.

## Privacy

Not applicable: This component does not collect, store, or transmit personal data. It is a stateless presentation component.

## Logging

Not applicable: The component does not emit logs. Logging (if needed) is the responsibility of the callbacks provided by the parent component.

## Platform Notes

- **Web/React**: The component is defined in `packages/web/packages/ui/src/blocks/button-bar.tsx`. It composes the shared Button component ([adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0)), rendering each icon inline via `data-icon="inline-start"` with a Lucide React icon: `Plus` for Create, `Trash2` for Delete (using Button's `destructive-ghost` variant), `X` for Cancel, and `Check` for Save. The Save button uses Button's `default` variant when enabled and switches to its `ghost` variant with the `text-apt-text-muted` class when disabled; Create and Cancel use `ghost`. The styling uses Tailwind utility classes with design tokens (`apt-bg`, `apt-border`, `apt-text-muted`). The toolbar role and aria-label are applied via the root `div`. The separator is a 1px × 20px div with `aria-hidden="true"`.

- **SwiftUI**: Compose an HStack with equal spacing and a Divider between the Create and Delete groups, mirroring the source's conditional rendering (a separate `EditingActions` view). The Save button's background switches to the accent/tint color when `canSave` is `true` and `saving` is `false`, matching the source's `default`-vs-`ghost` variant swap; when `saving` is `true`, its label reads "Saving…" and it is disabled — the source has no progress indicator, so none is required here. Apply `.accessibilityElement(children: .contain)` and `.accessibilityLabel("Editing actions")` to the HStack; SwiftUI has no built-in "toolbar" accessibility role to assign.

- **Compose**: Build with Row and Spacer, in the source's order: Create (if shown) | Divider | Delete (if shown) | Spacer | Cancel + Save. The Save button switches to a primary/accent-tinted style when `canSave` is `true` and `saving` is `false`, and to a muted/outlined style when disabled, matching the `default`-vs-`ghost` swap; while `saving` is `true` it shows the label "Saving…" and is disabled — the source shows no loading indicator, so none is required here. Use the Material 3 Button variants (Filled, Outlined, Tonal) aligned to the design system. Apply `Modifier.semantics { contentDescription = "Editing actions" }` to the root Row.

- **AppKit / UIKit**: For iOS, use a custom view built from `UIButton` (or `UIBarButtonItem`s in a bottom toolbar) laid out in the source's order. The Save button is tinted with the accent color when `canSave` is `true` and `saving` is `false`, and shows muted/plain styling when disabled, matching the `default`-vs-`ghost` swap; while `saving` is `true` its title reads "Saving…" and it is disabled — the source shows no activity indicator, so none is required here. For macOS, use an `NSView` with `NSButton` instances (or an `NSToolbar`), respecting the recessed appearance. Neither UIKit nor AppKit has a dedicated "toolbar" accessibility role for a custom container; rely on each button's own `accessibilityLabel` and, if the platform needs a single accessible element, set `accessibilityLabel` on the container view to "Editing actions".

- **WinUI 3**: Implement using a Grid with `ColumnSpacing` and a `SolidColorBrush` for the recessed background. Use the Button control with Style set to a custom theme for the "ghost" and "default" variants. The separator is a Rectangle with a thin stroke. The Save button uses the accent-color style when `canSave` is `true` and `saving` is `false`, and the muted "ghost" style when disabled, matching the `default`-vs-`ghost` swap; while `saving` is `true` its content reads "Saving…" and all buttons are disabled — the source defines no keyboard accelerators, so none is required here (a consumer wanting Enter/Escape shortcuts can add a `KeyboardAccelerator` to a button's `KeyboardAccelerators` collection). Apply `AutomationProperties.Name = "Editing actions"` to the root Grid for UI Automation accessibility.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/button-bar.tsx` | unverified |

## Design Decisions

**Decision**: Derive the Save button's inert-ness from a single source of truth, `saveDisabled = !canSave || saving`, and key its variant, `disabled` attribute, and muted-text styling all off that one value.
**Rationale**: This ensures a button that reads "Saving…" is guaranteed to have `disabled={true}`, and a disabled Save button is guaranteed to show muted text and the ghost variant — preventing the visual inconsistency of a "gold, enabled-looking button" that reads "Saving…" and ignores clicks.
**Approved**: pending

**Decision**: Make the preset editing action flow (Create/Delete/Cancel/Save) optional and composable: consumers either pass `actions` for the preset flow or `children` for their own button logic, with `children` taking precedence; the separator between Create and Delete renders only when Create is shown.
**Rationale**: This accommodates both simple panes (single-record editors with no Create/Delete) and complex list toolbars (filters, selection actions) without orphaned visual dividers when Create is hidden.
**Approved**: pending

**Decision**: Default `ariaLabel` to `"Editing actions"`, default `saving` to `false`, and treat an omitted `canDelete` as falsy.
**Rationale**: The toolbar stays accessible and labeled even if a consumer forgets to set `ariaLabel`; the `saving` default reduces boilerplate for panes with no async save logic; and the `canDelete` default lets consumers omit it entirely when delete is never available.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source as documented above: every preset button always pairs its icon with visible text, and the toolbar carries an `aria-label`, grounding `screen-reader-support` as passed; composing the shared Button's native `<button>` (which the Button recipe's `keyboard-activates` requirement covers) grounds `keyboard-navigable` as passed; the shadcn theme tokens used throughout Appearance (no raw hex) ground `contrast-ratio` as partial, since the tokens' actual contrast values are defined outside this component; using the Button component exclusively at its `sm` size, with no ancestor `--adh-button-min-height`/`--adh-button-min-width` override, grounds `touch-target-size` as failed — the same shortfall the Button recipe documents for that size; `role="toolbar"`, the `aria-hidden` separator, and native `disabled` mapping ground `semantic-markup` as passed; and the Localization section's finding that only `createLabel` is an injectable prop — Cancel, Save, Saving…, Delete, and the default aria-label are hardcoded — grounds both internationalization checks as failed. Security, Privacy and Data, and User Safety are omitted: the component collects no data, makes no network calls, produces no logs, and renders no links (see Privacy and Logging above). `separation-of-concerns` is passed because `button-bar.tsx` holds no state or business logic of its own — the consumer owns the draft/dirty/valid state and the bar only renders the resulting flags through the shared `Button`; `unit-test-coverage` is passed on `buttonBar.test.tsx`, which renders `ButtonBar` directly and asserts the Delete-disabled-while-saving, New-button-omission, and Save-button disabled/variant/class behaviors with real DOM queries.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from web implementation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed every requirement to subject-only kebab-case with no `must-` prefix; moved Lucide/Tailwind/DOM implementation specifics out of Behavioral Requirements and Conformance Test Vectors into the Web/React Platform Note; added the `ButtonBarActions` field table (required/optional/defaults); added the `save-disabled-styling` variant swap and unified the Delete/Save variant wording between requirements and vectors; fixed the Rapid-clicks edge case's `saving={false}`/`saving={true}` typo; corrected wrong native Platform Note APIs (UIKit/SwiftUI toolbar-role claims, SwiftUI HStack/VStack mismatch, WinUI `ColumnSpacing`, `KeyboardAccelerator`) and removed invented spinner/keyboard-shortcut behavior the source does not implement; reformatted Design Decisions into Decision/Rationale/Approved entries; built the Compliance table against the real catalog; corrected Localization to show only `createLabel` as consumer-injectable; added Button's domain to `depends-on`; fixed test-vector-to-requirement mapping, removed duplicate vectors, and added vectors for the separator, spacer, empty bar, and disabled-click cases; softened the Reduce Motion claim to match the Button recipe's own posture. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Create is never disabled while saving; requirement renamed create-not-disabled-while-saving, States/button-bar-019/saving row corrected. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
