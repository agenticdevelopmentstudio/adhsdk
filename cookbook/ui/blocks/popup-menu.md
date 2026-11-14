---
id: bf49f12b-61cd-4e34-b395-0b6e5fe715a2
title: "Popup Menu"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A focused-item selector dropdown menu with optional All and New entry points."
platforms:
  - typescript
  - web
tags:
  - menu
  - dropdown
  - selector
depends-on:
  - 25de0c8f-b6cb-4e9f-ba30-38afca642232
related: []
references: []
approved-by: ""
approved-date: ""
---

# Popup Menu

## Overview

A dropdown menu for selecting from a list of items, with an optional "All" state representing no focused item and an optional "New…" entry for creating new items. Commonly used as a focused-item selector in a rail UI. The component decouples selection logic from routing; the caller owns the deep link navigation.

## Behavioral Requirements

- **accept-items**: The component MUST accept an array of `PopupMenuItem` objects, each with `id` (string) and `label` (string).
- **accept-selected-id**: The component MUST accept `selectedId` as a string or null; null represents the "All" (nothing focused) state.
- **call-select-callback**: When an item is selected in the dropdown, the component MUST invoke the `onSelect` callback with the item's id (or null for "All").
- **render-all-row-when-enabled**: When `allLabel` is not null, the component MUST render an "All" row in the dropdown as the first item, with the provided label.
- **omit-all-row-when-disabled**: When `allLabel` is null, the component MUST omit the "All" row entirely.
- **render-new-row-when-callback-present**: When the `onNew` callback is provided, the component MUST render a divider followed by a "New…" row at the bottom of the dropdown, and invoke `onNew` when selected.
- **omit-new-row-when-no-callback**: When `onNew` is not provided, the component MUST omit the "New…" row and its divider entirely.
- **display-selected-label-on-trigger**: The trigger MUST display the label of the currently selected item, or the `allLabel` if `selectedId` is null, or an empty string if no "All" label is configured.
- **single-select-item-group**: All `PopupMenuItem` entries, and the "All" row when present, MUST be rendered within one single-selection group, so that choosing one entry deselects any previously selected entry and the currently selected entry is marked as checked.
- **truncate-long-trigger-labels**: Long labels on the trigger MUST be truncated with a visible ellipsis so overflowing text does not spill outside the trigger's bounds.
- **accept-aria-label**: The component MUST accept an `ariaLabel` prop and apply it to the trigger element for assistive technology.
- **hide-icon-from-accessibility**: The trigger's icon (default or custom) MUST be excluded from assistive-technology announcements, so it is not read aloud redundantly alongside the trigger's label.
- **default-affordance-icon**: When no custom `icon` prop is provided, the component MUST render a default dropdown affordance icon indicating that the trigger opens a menu.
- **accept-custom-icon**: The component MUST accept a custom `icon` prop (ReactNode) and render it in place of the default affordance icon.
- **accept-trigger-class-name**: The component MUST accept a `className` prop and merge it with the trigger's built-in classes such that consumer-supplied classes override the defaults.
- **warn-on-sentinel-collision**: If any item in the `items` array has an id equal to the value reserved internally to represent the "All" state, the component MUST log a warning identifying the collision.
- **focus-indicator-contrast**: When the trigger receives keyboard focus, the component MUST replace the default browser focus outline with a visible border-color change meeting WCAG 2.4.7 (focus visible) and 1.4.11 (non-text contrast, 3:1 minimum) against the adjacent surface.

## Appearance

- **Corner radius**: `rounded-md` — border-radius 0.375rem (6px on Tailwind's default scale)
- **Padding**: vertical `py-[0.4rem]` (6.4px exact, an explicit arbitrary value), horizontal `px-[0.6rem]` (9.6px exact, an explicit arbitrary value)
- **Font**: `text-[0.8rem]` (12.8px exact); weight is not set by the component — it inherits the ambient body font-weight, 400 (regular) via Tailwind's base reset
- **Background (trigger)**: `bg-apt-surface` (semantic color token)
- **Background (dropdown)**: `bg-apt-surface-2` (secondary surface token)
- **Foreground/Text**: `text-apt-text` (semantic text token)
- **Border**: width 1px, color `apt-border` (default), `apt-border-strong` on hover, `apt-gold` on focus
- **Shadow**: none
- **Gap between label and icon**: `gap-2` (8px)
- **Min/Max size**: dropdown has minimum width `min-w-[12rem]` (192px)

## States

| State | Appearance change |
|-------|------------------|
| Default | Border `apt-border`, background `apt-surface`, text `apt-text` |
| Hover | Border strengthens to `apt-border-strong` |
| Focus (keyboard) | Border becomes `apt-gold`, outline removed (`outline-none`) — see **focus-indicator-contrast** |
| Open (dropdown visible) | Dropdown menu renders with background `apt-surface-2`, border `apt-border` |
| Selected item (in dropdown) | Item is marked checked within the single-selection group (styling varies by dropdown implementation) |

## Accessibility

- **Role**: Trigger is a button (`DropdownMenuTrigger`, exposing `aria-haspopup="menu"`). The open dropdown uses the ARIA `menu` pattern: each `PopupMenuItem` and the "All" row are exposed as `menuitemradio` (single-selection semantics — see **single-select-item-group**), and the "New…" row is a plain `menuitem`.
- **Label**: `ariaLabel` prop is required and MUST be provided by the caller; it is applied directly to the trigger.
- **Icon accessibility**: The icon (default affordance icon or custom) MUST be excluded from assistive-technology announcements — see **hide-icon-from-accessibility**.
- **State announcement**: Changes in selection (e.g., item marked as selected) are announced by the dropdown menu's native ARIA attributes.
- **Minimum tap target**: The web trigger is approximately 25.6px tall (12.8px text + 6.4px top padding + 6.4px bottom padding), which meets WCAG 2.5.8's 24×24px minimum target size for web pointer input. Native ports MUST meet their platform's own minimum instead: 44×44pt (Apple, per HIG) or 48×48dp (Android/Windows).
- **Keyboard navigation**: Trigger is focusable via keyboard; dropdown menu handles arrow keys and Enter/Escape per ARIA practices. The focus indicator replaces the default outline with a border-color change — see **focus-indicator-contrast**.
- **Label for items**: Each item displays its `label` prop as visible text; no additional accessible labels are required.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| popup-001 | accept-items | `items=[{id:"a", label:"Item A"}, {id:"b", label:"Item B"}]` | Both items appear in dropdown |
| popup-002 | accept-selected-id, display-selected-label-on-trigger | `selectedId="a"`, item A has label "Item A" | Trigger displays "Item A" |
| popup-003 | accept-selected-id, display-selected-label-on-trigger | `selectedId=null`, `allLabel="All"` | Trigger displays "All" |
| popup-004 | call-select-callback | User clicks item with `id="x"` | `onSelect("x")` is called |
| popup-005 | call-select-callback | User clicks "All" row | `onSelect(null)` is called |
| popup-006 | render-all-row-when-enabled | `allLabel="All"` | "All" row appears as first item in dropdown |
| popup-007 | omit-all-row-when-disabled | `allLabel=null` | No "All" row in dropdown |
| popup-008 | display-selected-label-on-trigger | `selectedId=null`, `allLabel=null` | Trigger displays empty string |
| popup-009 | render-new-row-when-callback-present | `onNew` callback provided | "New…" row appears as the last entry in the dropdown |
| popup-010 | omit-new-row-when-no-callback | `onNew` not provided | No "New…" row in dropdown |
| popup-011 | render-new-row-when-callback-present | User clicks "New…" row | `onNew()` is called |
| popup-012 | single-select-item-group | `selectedId="a"` in the single-selection group | Item A is marked as checked/selected |
| popup-013 | truncate-long-trigger-labels | Label exceeds trigger width | Computed style includes `overflow: hidden`, `text-overflow: ellipsis`, `white-space: nowrap` (Tailwind's `truncate` utility); label renders visually truncated with an ellipsis glyph |
| popup-014 | accept-aria-label | `ariaLabel="Select focus"` | Trigger has `aria-label="Select focus"` |
| popup-015 | default-affordance-icon | No `icon` prop | Default affordance icon (ChevronsUpDown, 13px) is rendered on trigger |
| popup-016 | accept-custom-icon | `icon={<CustomIcon />}` | Custom icon is rendered instead of the default |
| popup-017 | accept-trigger-class-name | `className="w-auto"` | Trigger merges custom class; `w-auto` overrides default `w-full` |
| popup-018 | hide-icon-from-accessibility | Default or custom icon present | Icon has `aria-hidden` attribute |
| popup-019 | warn-on-sentinel-collision | `items=[{id:"__all__", label:"Item"}]` | Console warning logged: `PopupMenu: item id "__all__" collides with the All sentinel` |
| popup-020 | single-select-item-group | `selectedId` changes from `"a"` to `"b"` | Item B becomes checked and item A becomes unchecked (mutual exclusivity) |
| popup-021 | render-new-row-when-callback-present | `onNew` callback provided | A divider (separator) renders between the last item (or "All" row) and the "New…" row |
| popup-022 | render-new-row-when-callback-present | `onNew` provided, `newLabel="Create item"` | The row displays "Create item" instead of the default "New…" |
| popup-023 | focus-indicator-contrast | Trigger receives keyboard focus | Border color changes to the `apt-gold` token and the default outline is suppressed, meeting WCAG 1.4.11's 3:1 non-text contrast minimum against the adjacent surface |
| popup-024 | display-selected-label-on-trigger | `selectedId="zzz"` (no item has this id), `allLabel="All"` | Trigger displays "All" (same fallback path as `selectedId=null`) |
| popup-025 | accept-items | `items=[{id:"a",label:"First"},{id:"a",label:"Second"}]` (duplicate id) | No warning is logged (the sentinel check only fires for `"__all__"`); both entries share the same selection value, so the caller cannot distinguish which was clicked |

## Edge Cases

- **Empty items array**: When `items` is empty, the dropdown renders no selectable items (only "All" and/or "New…" if configured). Behavior is valid; the menu remains functional for "All" or "New" selection.
- **Null selectedId with allLabel omitted**: `selectedId=null` and `allLabel=null` results in trigger displaying an empty string. This is intentional for a plain switcher where one item is always selected; the caller MUST ensure one item is always selected in this mode.
- **selectedId with no matching item**: A `selectedId` absent from `items` falls back to the same display path as `selectedId=null` — the trigger shows `allLabel` (or an empty string if `allLabel` is null). No warning is logged for this case, unlike a sentinel collision (see **warn-on-sentinel-collision**). See test vector popup-024.
- **Duplicate item ids**: The component does not deduplicate or warn when two entries in `items` share an `id` — only a collision with the internal `"__all__"` sentinel is flagged (see **warn-on-sentinel-collision**). Both entries render with the same selection value, so `onSelect` cannot distinguish which one was clicked. Callers MUST ensure item ids are unique. See test vector popup-025.
- **Custom className merge behavior**: The `className` prop is merged such that utility classes in the prop override the component's built-in classes (e.g., `className="w-auto"` overrides `w-full`) — see **accept-trigger-class-name**. This is a feature enabling flexible trigger sizing.
- **Both All and New… present**: Both "All" and "New…" can coexist; selecting "All" (null) followed by "New" calls `onNew()` independently.
- **Rapid selection changes**: If `selectedId` changes between render cycles, the single-selection group updates; the new `selectedId` becomes the checked entry.
- **ariaLabel is required**: The `ariaLabel` parameter is a required TypeScript function parameter with no default or optional marker; TypeScript enforces this at compile time, preventing callers from omitting it.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `items` | `PopupMenuItem[]` | (required) | Array of selectable items; each must have unique `id` and a `label`. |
| `selectedId` | `string \| null` | (required) | The currently selected item's id, or null for "All" (nothing focused). |
| `onSelect` | `(id: string \| null) => void` | (required) | Callback invoked when an item or "All" is selected. |
| `allLabel` | `string \| null` | `"All"` | Label for the "All" (nothing focused) row; omits the row if null. |
| `onNew` | `() => void` | (optional) | Callback invoked when "New…" is selected; if not provided, the row is omitted. |
| `newLabel` | `string` | `"New…"` | Label for the "New…" entry (shown only if `onNew` is provided). |
| `ariaLabel` | `string` | (required) | Accessible label for the trigger button. |
| `icon` | `ReactNode` | (optional) | Custom icon to display on the trigger; defaults to the default affordance icon. |
| `className` | `string` | (optional) | Extra CSS classes for the trigger, merged with built-in classes so consumer classes win. |

## Deep Linking

Not applicable: This component handles selection logic only; the caller owns routing and deep linking behavior.

## Localization

| String Key | Default (en) | Context | Notes |
|-----------|-------------|---------|-------|
| `allLabel` | `"All"` | "All" row label (configurable per instance; no global key). | The default is an English literal for convenience (e.g., quick prototyping); production callers SHOULD pass an already-localized string. |
| `newLabel` | `"New…"` | "New…" row label (configurable per instance; no global key). | Same as `allLabel`: the default is an English literal; production callers SHOULD pass an already-localized string. The ellipsis is the Unicode character U+2026, not three ASCII dots — the exact glyph and any surrounding punctuation are locale-sensitive choices. |
| `ariaLabel` | (caller-provided) | Accessible label for trigger. | No default; the caller MUST provide an already-localized string. |

## Accessibility Options

- **Reduce Motion**: Not applicable; the component has no animation or motion effects of its own.
- **Increase Contrast**: Not explicitly handled. Component uses semantic color tokens (`apt-border`, `apt-gold`, etc.), so contrast is deferred to the design system's token definitions.
- **Differentiate Without Color**: Not explicitly handled. The single-selection group's checked state relies on visual styling; no additional haptic or non-color affordances are provided by PopupMenu itself.

## Feature Flags

Not present in component. Caller may wrap the component in conditional logic to gate its availability.

## Analytics

Not present in component. Caller may wrap `onSelect` and `onNew` callbacks to emit analytics events.

## Privacy

Not applicable: Component handles no personal data; it is a UI control for selection.

## Logging

| Event | Level | Message |
|-------|-------|---------|
| Sentinel collision detected | warn | `PopupMenu: item id "__all__" collides with the All sentinel` |

Subsystem: implicit (browser console); no explicit logger configured in component.

## Platform Notes

- **React/Web (source)**: Implemented in `packages/web/packages/ui/src/blocks/popup-menu.tsx` using React hooks and the shared `dropdown-menu` primitives — `DropdownMenu`, `DropdownMenuTrigger`, `DropdownMenuContent`, `DropdownMenuRadioGroup`, `DropdownMenuRadioItem`, `DropdownMenuSeparator`, `DropdownMenuItem` (see [adhsdk.ingredient.ui.components.overlays.dropdown-menu](cookbook:25de0c8f-b6cb-4e9f-ba30-38afca642232)) — plus lucide-react icons and Tailwind CSS utility classes. The single-selection group (**single-select-item-group**) is implemented with `DropdownMenuRadioGroup`/`DropdownMenuRadioItem`; the internal "All" sentinel value is the string `"__all__"`. The default affordance icon (**default-affordance-icon**) is `ChevronsUpDown` at 13px. Consumer class overrides (**accept-trigger-class-name**) are merged with the `cn()` helper, whose later arguments win. Trigger uses semantic color tokens (`apt-*`) and includes focus/hover state styling. The component is a faithful port of a prior internal resource-selector implementation (see the source file's header comment for provenance).

- **SwiftUI**: Build using a `Picker` with `.pickerStyle(.menu)` bound to the selected id (mapping `nil` through an internal sentinel for the "All" state, per **single-select-item-group**); populate options with `ForEach` over `items`, prepending an "All" option when `allLabel != nil`. Render "New…" as a `Button` below a `Divider` when the `onNew` callback exists. Satisfy **focus-indicator-contrast** with a custom border-color change driven by a `@FocusState` binding — `.focusEffectDisabled()` only suppresses the system focus ring, it does not itself apply styling. Use `.accessibilityLabel()` for `ariaLabel`.

- **Compose (Android)**: Use `ExposedDropdownMenuBox` with a read-only `TextField` (or custom trigger) and an `ExposedDropdownMenu`/`DropdownMenu` containing `DropdownMenuItem` entries. Track the selected id in state and show a check mark or `RadioButton` on the active entry to satisfy **single-select-item-group**. For "All" and "New…", conditionally include a leading `DropdownMenuItem` and a trailing `Divider` + `DropdownMenuItem`. Apply `Modifier` styling (padding, border, background) for appearance, and `Modifier.semantics { contentDescription = ariaLabel }` on the trigger for accessibility.

- **UIKit / AppKit**: Use `NSPopUpButton` (macOS) or `UIMenu` with `UIAction`s (iOS 15+) as the dropdown container — both are native single-selection menu controls satisfying **single-select-item-group**. Render "All" and "New…" as ordinary items, separating "New…" with `NSMenuItem.separator()` on macOS or a display-inline `UIMenu` boundary on iOS. On macOS, rely on `NSPopUpButton`'s built-in focus ring for **focus-indicator-contrast**; on iOS, set `button.accessibilityLabel = ariaLabel` on the trigger.

- **WinUI 3**: Build using a `DropDownButton` as the trigger with a `MenuFlyout` attached; represent items as `RadioMenuFlyoutItem` entries within a shared group to satisfy **single-select-item-group**. For "All" and "New…", conditionally add a `MenuFlyoutSeparator` and a `MenuFlyoutItem`. Apply `VisualStateManager` for Hover, Pressed, and Focused states (border color and background) to satisfy **focus-indicator-contrast**. Set `AutomationProperties.Name` for the trigger's accessible label.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/popup-menu.tsx` | unverified |

## Design Decisions

- **Decision**: Represent the "All" (nothing focused) state as `selectedId: null` rather than as a literal item with a special id.
  **Rationale**: This decouples "All" from the item array and simplifies caller logic (e.g., an API filter can use `itemId ?? 'all'`). The tradeoff is that the "All" row is conditionally rendered, and the single-selection group maps `null` to an internal sentinel value (`"__all__"`) that must not collide with a real item id.
  **Approved**: pending

- **Decision**: When an item id collides with the internal `"__all__"` sentinel, log a warning and continue rendering rather than throwing.
  **Rationale**: This is a fail-soft choice: the collision is surfaced to developers via a console warning, but the "All" row and the colliding item remain indistinguishable at runtime — selecting either yields `selectedId: null` — so the warning flags the problem without preventing the ambiguous selection. See **warn-on-sentinel-collision**.
  **Approved**: pending

- **Decision**: Allow the caller to pass extra classes (`className`) that override the trigger's built-in defaults via `cn()`.
  **Rationale**: This provides layout flexibility without prop explosion (e.g., `className="w-auto"` overrides the default `w-full`). The tradeoff is that a destructive override (e.g., removing the focus-visible border) can break accessibility if the caller is not careful.
  **Approved**: pending

- **Decision**: Always render an affordance icon (the default or a custom one); do not offer a prop to hide it.
  **Rationale**: Keeps the API simpler and the dropdown affordance visually consistent — a design allowing the icon to be hidden was rejected for that reason. The icon is excluded from assistive-technology announcements to avoid redundant readback.
  **Approved**: pending

- **Decision**: Make the "New…" entry's label a string prop (`newLabel`), not a `ReactNode` like `icon`.
  **Rationale**: Keeps the API surface smaller and avoids nested-component complexity. A caller needing richer content in the "New…" row would need a separate render-prop API, which was not built.
  **Approved**: pending

- **Decision**: Selecting "New…" invokes the `onNew` callback only; it does not add an item to `items` or change `selectedId`.
  **Rationale**: The caller owns the logic to create a new item and update state, keeping this component focused on selection only — it has no knowledge of routing or deep linking, which remains entirely the caller's responsibility.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | partial | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | failed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | Security |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Statuses rest on: the source's `aria-label`/`aria-hidden` usage and the underlying `dropdown-menu` primitive's `menu`/`menuitemradio` ARIA roles (screen-reader-support, keyboard-navigable, semantic-markup); the 25.6px trigger height meeting WCAG 2.5.8's 24×24px web minimum (touch-target-size); reliance on the `apt-*` design tokens and the `dropdown-menu` primitive for actual contrast values and focus-trap behavior, which this source cannot itself confirm (contrast-ratio, focus-management); the hardcoded English `allLabel`/`newLabel` defaults (string-externalization); the intentional `truncate` overflow/ellipsis behavior, which contradicts expansion tolerance by design (text-expansion-tolerance); ordinary JS string handling with no Unicode restrictions (unicode-support); and the static, data-free warning message with no interpolated user data (secure-log-output). `popup-menu.tsx` is decoupled from routing — selection is a callback the host wires up, with only view-level derivation (the "All" sentinel and active-label lookup) inline (separation-of-concerns passed); `popupMenu.test.tsx` covers only the trigger's icon and className customization, not `onSelect`, `onNew`, or the sentinel-collision warning (unit-test-coverage partial).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and propagated renames through test vectors and edge cases; merged the duplicate radio-group requirement into single-select-item-group; moved web-specific implementation details (DropdownMenuRadioGroup, cn(), ChevronsUpDown sizing, the "__all__" sentinel) out of Behavioral Requirements and into Platform Notes; added the focus-indicator-contrast requirement and a matching test vector; added edge cases and test vectors for an unmatched selectedId and duplicate item ids; corrected the Accessibility Role to the ARIA menu/menuitemradio pattern; corrected touch-target guidance to WCAG 2.5.8 for web with a native-port minimum; gave exact Appearance pixel values; rewrote Design Decisions in the Decision/Rationale/Approved format and resolved the fail-fast and routing contradictions; replaced non-existent or misused Platform Notes APIs (MaterialDropdownMenu, NSMenuSeparator, .accessibilityElement(), .focusEffectDisabled(), MenuBar) with real native-control APIs; removed the named-app reference from the React/Web note; added dropdown-menu to depends-on; rebuilt the Compliance table with real compliance-catalog checks and links; renamed an Edge Cases heading for clarity. |
| 1.0.1 | 2026-09-22 | Claude Haiku 4.5 | Resolve review markers: confirm ariaLabel enforcement and document actual trigger dimensions |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source |
