---
id: 76eee228-2fd5-4524-a84e-d221c2e4c8ad
title: "Category Gear Menu"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Dropdown menu for managing category actions: add, rename, move, file, and delete."
platforms:
  - typescript
  - web
tags:
  - menu
  - dropdown
  - category-management
depends-on:
  - cebee4d7-3d01-440d-a35e-6220957c1603
  - 25de0c8f-b6cb-4e9f-ba30-38afca642232
related: []
references: []
approved-by: ""
approved-date: ""
---

# Category Gear Menu

## Overview

A dropdown menu triggered by a gear icon that presents five actions for managing categories in a hierarchical list. The menu dynamically disables actions based on whether a user has selected an editable target. "Add" is always enabled and creates a new category at the list level. "Rename", "Move", "File", and "Delete" are enabled only when a valid target is selected. Menu items are labeled with the target name when available, so the user reads what will be acted upon.

## Behavioral Requirements

- **render-trigger**: Component MUST render a gear icon trigger labeled with "{Noun} actions" (noun is singular and capitalized; defaults to "Category actions").
- **render-five-items**: Component MUST render five dropdown items corresponding to the actions: "Add {noun}…", "Rename…", "Move…", "Also file in…", and "Delete…".
- **show-target-in-labels**: Component MUST include the target name in menu item labels when `targetName` is not null and `canEditTarget` is true. Label format is `{Verb} "{targetName}"…` for rename, move, and delete, and `{Verb} "{targetName}" in…` for the file action.
- **omit-target-when-not-editable**: Component MUST omit the target name from item labels when `canEditTarget` is false, even if `targetName` is not null; labels use the bare verb form ("Rename…", "Also file in…") in that case.
- **disable-target-actions-when-no-target**: Component MUST disable "Rename", "Move", "File", and "Delete" menu items when `canEditTarget` is false.
- **enable-add-always**: Component MUST keep the "Add {noun}…" item enabled regardless of `canEditTarget`.
- **render-separators**: Component MUST render a visual separator (DropdownMenuSeparator) between "Add" and the target actions, and another separator between "File" and "Delete".
- **invoke-callback-on-action**: Component MUST invoke the `onAction` callback with the action type ("add", "rename", "move", "file", or "delete" — the `CategoryGearAction` union) when a menu item is clicked.
- **respect-disabled-prop**: Component MUST render the trigger as disabled when the `disabled` prop is true.
- **style-delete-destructive**: Component MUST style the "Delete" menu item using the platform's destructive/error styling.
- **align-to-end**: Component MUST align the dropdown menu content to the trailing (end) edge of the trigger; in right-to-left layouts, the trailing edge is the left side.

## Appearance

- **Trigger**: Uses `GearMenuTrigger` component (styling is delegated to that component; source shows only className pass-through and disabled flag).
- **Menu items**: Standard dropdown menu item appearance, inherited from `DropdownMenuItem` component.
- **Delete item**: Styled with the platform's destructive/error treatment (see Platform Notes; `text-apt-red` on web).
- **Separators**: Visual dividers rendered by `DropdownMenuSeparator` component.

## States

| State | Appearance change | Trigger behavior |
|-------|------------------|------------------|
| Default (`canEditTarget=false`) | "Rename", "Move", "File", "Delete" visually disabled (grayed); "Add" enabled | Only Add is functional; the other items do not respond to click |
| Target selected (`canEditTarget=true`) | All five items visible and enabled | User can click any item |
| Disabled | Trigger appears disabled (visual state depends on GearMenuTrigger) | Trigger does not respond to click |
| Menu open | Dropdown content displays below or adjacent to trigger | User can click any enabled item |

## Accessibility

- **Role**: Trigger element MUST have a button role; menu MUST have a menu role and menu items MUST have menuitem role (provided by DropdownMenu and DropdownMenuItem components).
- **Label**: Trigger MUST be labeled "{Noun} actions" to describe its purpose to assistive technology users.
- **Disabled state announcement**: Disabled menu items MUST be announced as disabled to assistive technology.
- **Touch target**: GearMenuTrigger MUST provide a minimum touch target of 44×44 CSS px on web, 44×44pt on iOS/macOS, or 48×48dp on Android.
- **Keyboard navigation**: Menu MUST support arrow keys and Enter/Space to select items (delegated to DropdownMenu component).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| cgm-001 | render-trigger | Default render | Trigger displays labeled "Category actions" |
| cgm-002 | render-five-items | Menu opened | Five items are visible: "Add category…", "Rename…", "Move…", "Also file in…", "Delete…" |
| cgm-003 | show-target-in-labels | targetName="Q3", canEditTarget=true | `Rename "Q3"…`, `Move "Q3"…`, `Also file "Q3" in…`, `Delete "Q3"…` |
| cgm-004 | omit-target-when-not-editable | targetName="Q3", canEditTarget=false | "Rename…", "Move…", "Also file in…", "Delete…" (target name omitted); "Add category…" unaffected |
| cgm-005 | disable-target-actions-when-no-target | canEditTarget=false | "Rename", "Move", "File", "Delete" items are disabled; "Add" is enabled |
| cgm-006 | enable-add-always | canEditTarget=false, no target | "Add category…" is enabled and clickable |
| cgm-007 | render-separators | Menu opened | Two visual separators present: one after "Add", one before "Delete" |
| cgm-008 | invoke-callback-on-action | Click "Add category…" | onAction("add") is called |
| cgm-009 | invoke-callback-on-action | Click `Delete "Q3"…` with canEditTarget=true | onAction("delete") is called |
| cgm-010 | respect-disabled-prop | disabled=true | Trigger is visually disabled and does not open menu |
| cgm-011 | style-delete-destructive | Menu opened | "Delete" item uses the platform's destructive/error styling (e.g., red text via `text-apt-red` on web) |
| cgm-012 | align-to-end | Menu opened, LTR locale | Menu content aligns to the right edge of the trigger |
| cgm-013 | align-to-end | Menu opened, RTL locale | Menu content aligns to the left edge of the trigger (its trailing edge under RTL) |
| cgm-014 | render-trigger | noun="item" | Trigger displays "Item actions"; the "Add item…" item is present |

## Edge Cases

- **Null targetName**: When targetName is null (no selection), labels use the bare verb form without a target name reference (e.g., "Rename…" instead of `Rename "{name}"…`).
- **Omitted noun**: When the `noun` prop is not provided, the default parameter substitutes "category" (lowercase in item labels, capitalized to "Category" in the trigger label).
- **Empty string noun**: When `noun=""` is passed explicitly, the default parameter does not apply (defaults only substitute for `undefined`, not for an empty string), so the noun stays empty: item labels read "Add …" and the trigger label reads " actions" (leading space, no noun).
- **Custom noun**: When noun is provided (e.g., "tag", "note"), labels and trigger are updated accordingly (e.g., trigger reads "Tag actions", add reads "Add tag…").
- **Disabled with no target**: When both disabled=true and canEditTarget=false, the trigger is disabled and all target-specific actions are also disabled in the UI.
- **Rapid clicking**: The component does not debounce. Each click on an enabled item invokes `onAction` once, so clicking a menu item multiple times before the menu closes invokes the callback that many times; hosts MUST tolerate repeated identical calls.
- **Dynamic targetName change**: If targetName prop changes while menu is open, labels reflect the new target immediately.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| targetName | string &#124; null | null | The name of the selected category row to display in action labels. When null, labels do not include a target. |
| canEditTarget | boolean | false | Whether the target-specific actions (rename, move, file, delete) are available. Controls the disabled state of four menu items. |
| noun | string | "category" | Singular, lowercase noun used in labels and trigger title. E.g., "tag", "item", "note". Capitalized in trigger label. |
| onAction | (action: "add" &#124; "rename" &#124; "move" &#124; "file" &#124; "delete") => void | (required) | Callback invoked when any menu item is clicked. Receives the action type — the `CategoryGearAction` union: "add", "rename", "move", "file", or "delete". |
| disabled | boolean | false | When true, the trigger is disabled and the menu cannot be opened. |
| className | string | undefined | Optional CSS class to apply to the trigger element (passed to GearMenuTrigger). |

## Deep Linking

Not applicable: This is a UI component block for inline menu rendering, not a routable feature. Deep linking is managed by the host application.

## Localization

Applicable. The component currently builds every label by concatenating a verb, an optional quoted target name, and a suffix (`labelFor`) at render time, and capitalizes the noun for the trigger label. Concatenation breaks in languages whose word order differs from English, so each label MUST be authored as a single, whole, localized template string with named placeholders — never assembled from separately translated fragments:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| category_gear_menu.trigger_label | "{noun} actions" | Trigger label; `{noun}` is the capitalized noun |
| category_gear_menu.add | "Add {noun}…" | Add item label |
| category_gear_menu.rename | "Rename…" | Rename item label, no target |
| category_gear_menu.rename_target | 'Rename "{target}"…' | Rename item label, with target |
| category_gear_menu.move | "Move…" | Move item label, no target |
| category_gear_menu.move_target | 'Move "{target}"…' | Move item label, with target |
| category_gear_menu.file | "Also file in…" | File item label, no target |
| category_gear_menu.file_target | 'Also file "{target}" in…' | File item label, with target |
| category_gear_menu.delete | "Delete…" | Delete item label, no target |
| category_gear_menu.delete_target | 'Delete "{target}"…' | Delete item label, with target |

The trigger label's initial-letter capitalization of `noun` is a casing transform and therefore locale-sensitive: implementations MUST apply the current locale's casing rules (e.g., a locale-aware title-case call), never an invariant-culture uppercasing call, since which letters change case — and whether capitalization applies at all — varies by language.

## Accessibility Options

Not applicable: The source code does not check or respond to accessibility display options such as Reduce Motion or Increase Contrast. Implementations SHOULD respect platform accessibility display options at the host level.

## Feature Flags

Not applicable: No feature flags are defined in the component source.

## Analytics

Not applicable: The component does not emit analytics events. Event tracking is the responsibility of the host application that calls the onAction callback.

## Privacy

Not applicable: The component does not collect, store, or transmit any data.

## Logging

Not applicable: No logging is implemented in the component.

## Platform Notes

- **React/Web**: Use the `DropdownMenu`, `DropdownMenuContent`, `DropdownMenuItem`, and `DropdownMenuSeparator` primitives, which provide ARIA menu semantics (roles, keyboard navigation) out of the box; `GearMenuTrigger` provides the icon trigger. Render the menu content with `align="end"` so it tracks the trigger's trailing edge under both LTR and RTL. Apply the platform's destructive/error text class (`text-apt-red`) to the delete item.
- **SwiftUI**: Start with SwiftUI's `Menu` control, using a gear icon from `Image(systemName: "gearshape.fill")` as the trigger. Render all five items unconditionally and apply `.disabled(!canEditTarget)` to the four target actions — never omit them conditionally, since omitting rather than disabling contradicts **disable-target-actions-when-no-target**. Use `Button(role: .destructive)` for the delete item so the platform applies its own destructive styling. Include the target name in action labels using string interpolation when available.
- **Compose**: Build from Compose's `DropdownMenu` and `DropdownMenuItem` composables. Use Material Design 3 Menu specs for spacing and elevation. Apply conditional *enabled* states based on `canEditTarget` — disable, never omit, the four target items. Use the app's error color token (e.g. `MaterialTheme.colorScheme.error`) for the delete item text. Icon rendering uses Compose Material Icons (gear icon).
- **AppKit / UIKit**: On macOS (AppKit), use `NSMenu` with `NSMenuItem` for each action; set the menu's `autoenablesItems = false` and set each item's `isEnabled` explicitly so the four target items can be disabled, and style the delete item's destructive state with an attributed title using `NSColor.systemRed` (AppKit has no destructive-role menu attribute). On iOS (UIKit), use `UIMenu` and `UIAction`; set `.attributes = .disabled` on the four target actions when `canEditTarget` is false, and `.attributes = .destructive` on the delete action so the system applies its own destructive styling. The gear icon comes from `UIImage(systemName: "gearshape.fill")`.
- **WinUI 3**: Use `MenuFlyout` with `MenuFlyoutItem` controls. Bind the `IsEnabled` of "Rename", "Move", "File", and "Delete" items to the `canEditTarget` property. Use a `MenuFlyoutSeparator` between logical groups. Set `Foreground` to the app's error color resource (e.g. `{ThemeResource SystemFillColorCriticalBrush}`) for the delete item. Position the menu with `Placement="BottomEdgeAlignedRight"`, which anchors to the trigger's trailing edge and mirrors correctly under RTL layouts.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/category-gear-menu.tsx` | unverified |

## Design Decisions

**Decision**: The menu exposes two distinct verbs, Move and File, rather than a single combined action.
**Rationale**: Move rewrites the filing the user walked in through — one place becomes another — while File adds a second filing without touching the first, which is the only way to expose the DAG's ability for a category to live in two branches at once; the label reads "Also file … in" rather than a word like "Duplicate" because it names the graph operation (adding a filing), and "Also" signals that the original filing is kept.
**Approved**: pending

**Decision**: The component is intentionally stateless (a "dumb" component): it makes no decisions about what is editable, when dialogs open, or what data is valid.
**Rationale**: All of that logic lives in the host, which tracks the current selection and can update the target independently of the menu's own lifecycle; if the menu instead closed over the target at registration time, a rename would leave it acting on stale data after the rename completed.
**Approved**: pending

**Decision**: The "Add" action is always enabled, regardless of `canEditTarget`.
**Rationale**: Add creates a new category at the list's own level (a new root in the root list), a question the current selection cannot answer, so there is no selection state that should ever disable it.
**Approved**: pending

**Decision**: Action labels include the target's name when one is available (e.g. `Rename "Q3"…`) rather than a bare verb.
**Rationale**: The menu can be opened from a header that is not the current selection; without the name, a bare "Rename…" would leave the user guessing whether the action applies to the header, the selected row, or something else.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The screen-reader, keyboard, and semantic-markup statuses rest on the `DropdownMenu`/`DropdownMenuItem`/`GearMenuTrigger` primitives this component composes, each with its own recipe; touch-target-size and contrast-ratio are partial because the concrete size and color-token values live in those child recipes, not in this source; the internationalization statuses rest on `labelFor` and the JSX literals in `category-gear-menu.tsx`, which build every label from hardcoded English fragments with no localization resource lookup. Best-practices statuses rest on the component being, in the source's own words, "deliberately DUMB" — composing `DropdownMenu` primitives and reporting the chosen action via `onAction`, with no data access or business rule of its own (separation-of-concerns: passed) — and on `categoryGearMenu.test.tsx` directly rendering `CategoryGearMenu` and asserting its behavior (unit-test-coverage: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case throughout (bullets, test vectors, edge cases); fixed the "file" and "delete" item label text to match `labelFor`'s actual output ("Also file in…" / "Delete…") and corrected the resulting States/Configuration/test-vector text; added the `omit-target-when-not-editable` requirement and test vector for the `targetName`-set-but-`canEditTarget`-false case; resolved the States "Default" contradiction with the Configuration default; reworded `style-delete-destructive` and `align-to-end` to name platform-native destructive styling and trailing-edge/RTL alignment instead of a hardcoded color or "(right)", and added an RTL test vector; corrected cgm-012's expectation and requirement mapping; restructured Design Decisions into Decision/Rationale/Approved form and clarified the Move-vs-File rationale; defined `CategoryGearAction` inline in Configuration; marked Localization applicable with whole-string templated keys and a note on locale-sensitive casing; added a Compliance table; dropped source-only implementation detail (Radix/relative-path mention, "no debouncing in source") from Platform Notes and Edge Cases in favor of spec language; corrected Platform Notes (SwiftUI/UIKit native destructive controls instead of ad hoc color, SwiftUI disables rather than conditionally renders, AppKit enable/destructive guidance, WinUI 3 `Placement`/theme-resource names); gave the touch-target minimum per platform; split the "Empty noun" edge case into omitted-prop vs. empty-string behavior; added `gear-menu-trigger` and `dropdown-menu` to `depends-on`. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
