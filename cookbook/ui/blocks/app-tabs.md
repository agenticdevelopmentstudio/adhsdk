---
id: ff445185-2322-4c94-ad9d-3ad27a50677d
title: "App Tabs"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A controlled tab bar component for app-wide navigation with optional icons and a trailing-aligned action item."
platforms:
  - typescript
  - web
tags:
  - navigation
  - tabs
depends-on:
  - fb3a0db4-691e-4025-a391-2853908248b5
related: []
references: []
approved-by: ""
approved-date: ""
---

# App Tabs

## Overview

AppTabs is a controlled tab navigation component used as the top tab bar in the signed-in app. It renders a horizontal list of tabs with optional icons, marking one tab as active based on the `value` prop. It supports an optional `endItem` that appears at the trailing edge, commonly used for user settings or other app-level actions. The component uses semantic button elements styled with a shared tab grammar (`tabItemClass` / `tabListClass`, imported from the `tabs` ingredient — see depends-on) to achieve an underline-mono appearance. Each entry in `items` is an `AppTab` (`{ id: string; label: ReactNode; icon?: ReactNode }`); `endItem` is an `AppTab` extended with an optional `active?: boolean` that drives its own selected state independently of `value`.

## Behavioral Requirements

- **render-items**: The component MUST render each item in the `items` array as an interactive tab.
- **mark-active-tab**: The component MUST mark the tab matching the `value` prop as active, setting `aria-selected="true"` and the `data-active` attribute on that tab only.
- **render-icon-if-provided**: If an `AppTab` in `items` has an `icon` property, the component MUST render it within the tab.
- **render-label**: The component MUST render the `label` ReactNode for each tab.
- **invoke-callback-on-click**: When a user clicks any tab — including `endItem` — the component MUST call `onValueChange` (if provided) with that tab's `id`; `endItem` shares the same click handler as every other item, so clicking it invokes `onValueChange` exactly like any other tab.
- **render-end-item-if-provided**: If `endItem` is provided, the component MUST render it at the trailing edge of the tab bar.
- **respect-end-item-active-state**: The `endItem` tab MUST use its own `active` property independently of the `value` prop; it MUST NOT be marked active based on `value` matching its `id`.
- **apply-role-tablist**: The root container MUST have `role="tablist"`.
- **apply-role-tab-to-items**: Each rendered tab button MUST have `role="tab"`.
- **apply-class-name**: The component MUST apply the `className` prop to the root container if provided.
- **no-content-panels**: The component MUST NOT create or manage content panels; each tab is a self-contained interactive element with no associated panel to show or hide. (The React implementation satisfies this by rendering plain `<button>` elements rather than a Base UI `<Tabs>` component — see Platform Notes.)

## Appearance

Tabs use the shared tab styling defined by `tabItemClass` and `tabListClass` from the `tabs` ingredient (see depends-on).

- **Corner radius**: 0 (no rounding; `tabItemClass` has no `rounded-*` utility).
- **Padding**: `tabListClass` puts a 16px gap between items (`gap-4`); each tab (`tabItemClass`) has 8px vertical / 4px horizontal padding (`py-2 px-1`).
- **Font**: Monospace, 0.8rem (12.8px), tracking-wide letter-spacing (`font-mono text-[0.8rem] tracking-wide`).
- **Background**: Transparent; no fill on the root, list, or individual tabs.
- **Foreground/Text**: Muted gray by default (`text-apt-text-muted`); full-contrast text on hover, focus-visible, or when active (`data-[active]:text-apt-text`).
- **Border**: The list has a 1px bottom border (`border-b border-apt-border`); the active tab shows a 2px gold bottom border (`data-[active]:border-apt-gold`) that overlaps the list's border via a negative margin (`-mb-px`); inactive tabs reserve the same 2px of space with a transparent border.
- **Shadow**: None.
- **Min/Max size**: No explicit width/height constraint; computed tab height is approximately 33px (`text-[0.8rem]`'s ~15px line-height + `py-2`'s 16px total vertical padding + the 2px border).

## States

| State | Appearance change |
|-------|------------------|
| Default | Tab renders with no active indicator (transparent 2px bottom border). `aria-selected="false"`. `data-active` attribute is absent — React omits a `data-*` attribute whose value is `undefined`. |
| Active | Tab renders with active indicator (2px gold underline). `aria-selected="true"`. `data-active="true"` — React renders the boolean `true` passed to a `data-*` attribute as the string `"true"`. |
| Focused | Managed by browser focus styles and the `focus-visible:text-apt-text` utility (text-color change identical to hover; no separate focus ring, `outline-none`). |
| Disabled | Not supported: `AppTab` has no `disabled` property, and the component never sets a `disabled` attribute on any rendered button. Every tab remains interactive regardless of app state. |

## Accessibility

- **Role**: Tabs are rendered as `<button>` elements with `role="tab"`. The root container has `role="tablist"`.
- **State communication**: Active state is conveyed via the `aria-selected` attribute (`"true"` or `"false"`).
- **Label**: Each tab's label is rendered as visible text content within the button. No additional `aria-label` is present in source; labels are the visible text.
- **Icon handling**: Icons are rendered as visual content within the tab; they are not decorated with `aria-hidden` or labeled in source.
- **Keyboard interaction**: Handled by browser default button keyboard support (Tab to focus, Space/Enter to activate). No custom keyboard navigation (arrow keys, roving tabindex, or `aria-controls`) is implemented in source — this component uses `role="tablist"`/`role="tab"` for visual/semantic styling only, not the full WAI-ARIA APG tabs pattern (compare [adhsdk.ingredient.ui.components.layout.tabs](cookbook:fb3a0db4-691e-4025-a391-2853908248b5), which does implement that pattern via Base UI).
- **Minimum tap target**: `tabItemClass`'s padding (`py-2`, 8px vertical) yields a computed tab height of approximately 33px — below the 44×44pt (iOS) / 48×48dp (Android) platform touch-target minimums. This is a web-only CSS component; those native minimums are not applied by any shared class. Implementations on touch platforms SHOULD increase padding or add touch-specific sizing.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| app-tabs-001 | render-items | `items=[{id:"tab1", label:"Tab 1"}, {id:"tab2", label:"Tab 2"}]` | Both tabs render as buttons; text content matches labels. |
| app-tabs-002 | mark-active-tab | `items=[{id:"tab1", label:"T1"}, {id:"tab2", label:"T2"}]`, `value="tab1"` | Tab with id="tab1" has `aria-selected="true"` and `data-active="true"`; tab with id="tab2" has `aria-selected="false"` and no `data-active` attribute. |
| app-tabs-003 | render-icon-if-provided | `items=[{id:"tab1", label:"Tab", icon:<IconComponent />}]` | Icon is rendered inside the tab button alongside the label. |
| app-tabs-004 | invoke-callback-on-click | `items=[{id:"tab1", label:"T1"}]`, `onValueChange={spy}` | Clicking the tab invokes `onValueChange("tab1")`. |
| app-tabs-005 | render-end-item-if-provided | `endItem={id:"settings", label:"Settings"}` | EndItem renders as a button positioned at the trailing edge of the tab bar, after all `items` tabs. |
| app-tabs-006 | respect-end-item-active-state | `items=[{id:"tab1", label:"Tab"}]`, `value="tab1"`, `endItem={id:"settings", label:"Settings", active: true}` | Tab 1 is active per `value`; endItem is active per its own `active` property; they are independently active. |
| app-tabs-007 | apply-role-tablist | Any valid props | Root `<div>` has `role="tablist"`. |
| app-tabs-008 | apply-role-tab-to-items | Any valid props | Every rendered button has `role="tab"`. |
| app-tabs-009 | apply-class-name | `className="custom-class"` | Root container's class list contains `custom-class`. |
| app-tabs-010 | no-content-panels | Any valid props | All tabs are self-contained `<button>` elements; no `role="tabpanel"` (or equivalent content-panel element) exists anywhere in the rendered output. |
| app-tabs-011 | invoke-callback-on-click | `items=[{id:"tab1", label:"T1"}]`, `endItem={id:"settings", label:"Settings"}`, `onValueChange={spy}` | Clicking `endItem` invokes `onValueChange("settings")`, using the same click handler as any other tab. |
| app-tabs-012 | render-items, render-end-item-if-provided | `items=[]`, `endItem={id:"settings", label:"Settings"}` | The tab list container renders with no item buttons; the endItem button still renders. |
| app-tabs-013 | mark-active-tab | `items=[{id:"tab1", label:"T1"}]`, `value="missing"` | No tab has `data-active`; every tab has `aria-selected="false"`; nothing throws. |
| app-tabs-014 | respect-end-item-active-state | `endItem={id:"settings", label:"Settings"}` with no `active` property | The endItem has `aria-selected="false"` and no `data-active` attribute. |
| app-tabs-015 | render-icon-if-provided | `items=[{id:"tab1", label:"Tab", icon:null}]`, then again with `icon:false` | Nothing renders for the icon slot; the label still renders. |
| app-tabs-016 | invoke-callback-on-click | `items=[{id:"tab1", label:"T1"}]`, no `onValueChange` | Clicking the tab does nothing and does not throw. |
| app-tabs-017 | mark-active-tab | `items=[{id:"a", label:"A"}, {id:"a", label:"B"}]`, `value="a"` | Both tabs have `aria-selected="true"` (duplicate ids are unsupported). |
## Edge Cases

- **Empty items array**: If `items` is an empty array, the component renders the tab list container but no tab buttons. EndItem (if provided) still renders.
- **Value not in items**: If `value` does not match any `id` in `items`, no tab is marked active (all have `aria-selected="false"`). This is valid; the component does not error.
- **Missing onValueChange**: If `onValueChange` is undefined, the optional-chaining call (`onValueChange?.(t.id)`) is skipped entirely — clicking is a no-op that does not throw. The tab remains interactive; the component does not guard against a missing callback beyond this optional chaining.
- **Items array mutation**: The component uses `.map()` over `items` on each render. If `items` is mutated (not replaced), the component reflects the current array state on next render.
- **EndItem with no active property**: If `endItem` is provided without an `active` property, it renders with `aria-selected` derived from `!!undefined`, which is false. The endItem tab is not active.
- **Icon is falsy**: If `icon` is `null`, `undefined`, or `false`, nothing is rendered for that slot; the label still renders.

- **EndItem placement in right-to-left layouts**: `endItem` is pushed to the trailing edge with the physical `ml-auto` utility, not a logical one (`ms-auto` / `margin-inline-start`). In a `dir="rtl"` context the class does not mirror, so `endItem` stays on the visual right instead of moving to the trailing (left) edge. See Design Decisions and Platform Notes.
- **Duplicate ids in `items`**: Unsupported; the component does not check. React reports duplicate-key warnings, and every item whose `id` equals `value` is marked active (`t.id === value` is evaluated per item), so several tabs can be active at once.
## Configuration

Not applicable: AppTabs is a controlled component. Configuration is entirely through props (`items`, `value`, `onValueChange`, `endItem`, `className`); no separate configuration object or external settings apply.

## Deep Linking

Not applicable: AppTabs is a navigation component that drives app-wide routing via `onValueChange`; deep linking is handled by the consuming app logic, not within the component.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| Tab labels | User-provided | `label` (on `items` and `endItem`) is a ReactNode supplied by the consumer; the component performs no text generation or translation itself. |
## Accessibility Options

Not implemented in source. The component does not respond to Increase Contrast or Differentiate Without Color — it relies on the `apt-*` design tokens for color regardless of contrast mode. The hover/active text-color change uses Tailwind's `transition-colors` utility with no `motion-reduce:` variant, so it has no explicit reduced-motion handling; the transition animates colour only, with no movement (see `reduced-motion` in Compliance).

## Feature Flags

Not applicable: No feature flags or conditional behavior is present in source.

## Analytics

Not implemented in source. The component does not emit analytics events; event tracking is the responsibility of the consuming app via the `onValueChange` callback.

## Privacy

Not applicable: AppTabs does not collect, store, or transmit any user data. It is a pure presentational component.

## Logging

Not applicable: No logging is implemented in the component source.

## Platform Notes

- **React/Web**: Defined in `packages/web/packages/ui/src/blocks/app-tabs.tsx`. Exported as `AppTabs`. Renders plain `<button type="button">` elements — not a Base UI `<Tabs>` component (see **no-content-panels**) — styled with `tabItemClass` and `tabListClass` imported from the shared tab-grammar component ([adhsdk.ingredient.ui.components.layout.tabs](cookbook:fb3a0db4-691e-4025-a391-2853908248b5)). Uses React's `onClick` for tab selection and a managed `value` prop for active-state control; `endItem` is pushed to the trailing edge via the `ml-auto` utility class (LTR-only — see Edge Cases).
- **SwiftUI**: Use a custom `HStack` of `Button`s with an underline indicator — not `TabView`, which owns app-level/root navigation and associated panels, and not a segmented `Picker` — matching the source's plain-button, no-panel design (see **no-content-panels**). Track the active tab with the equivalent of the `value` prop and apply the underline styling equivalent of the shared tab grammar. The `endItem` property translates to a trailing `Spacer()` followed by the settings/action button, with its own independent `active` binding.
- **Compose**: Use Material 3's `PrimaryTabRow` (or `SecondaryTabRow`) with `Tab` composables instead of hand-rolled `Button`s in a `Row` — it provides the tab-row affordance without requiring an associated `Pager`/content panel (see **no-content-panels**). Drive `selectedTabIndex` from the equivalent of `value`, and call the equivalent of `onValueChange` from each `Tab`'s `onClick`. `PrimaryTabRow` and `SecondaryTabRow` give every `Tab` equal width and take a single `selectedTabIndex`, so a `Spacer(Modifier.weight(1f))` inside them has no effect and they cannot show two tabs active at once. Put the `endItem` outside the tab row, in a `Row` beside it, or build the bar as a custom `Row` of `Tab`s, with its own independent selected state.
- **UIKit / AppKit**: Create a custom view — not a Base UI-equivalent tab control — using a horizontal stack (`UIStackView` on iOS, `NSStackView` on macOS) of plain buttons; `NSSegmentedControl` implies a single mutually-exclusive control surface and does not model an independent `endItem`, so it does not fit. Manage active state via a data property and update the UI on value changes. The `endItem` property would be positioned at the trailing edge with a spacer.
- **WinUI 3**: Use `NavigationView` in Top mode, or `SelectorBar` with `SelectorBarItem` entries — not native `TabView`, which is designed for closable, document-style tabs (browser-tab UX) and carries close-button semantics that don't fit app navigation (see **no-content-panels**). Bind the selected item to the equivalent of `value`/`onValueChange`. Apply Fluent 2 underline-mono styling via control templates or `SelectorBarItem` styling. For the `endItem`, add it as a trailing element outside the main list, positioned with `HorizontalAlignment="Right"` and left to `FlowDirection` to mirror in RTL (do not switch it to `"Left"`, which would mirror it twice), with its own independent selected state.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/app-tabs.tsx` | confirmed (1.1.2) |

## Design Decisions

**Decision**: Render tabs as plain `<button type="button">` elements rather than a Base UI `<Tabs>` component or other abstracted tab control.
**Rationale**: These are navigation-style tabs with no associated content panels, so the composite ARIA tabs/tabpanel pattern that a `<Tabs>` primitive implements does not apply; see **no-content-panels**.
**Approved**: pending

**Decision**: Give `endItem` its own `active` property, evaluated independently of the `value` prop.
**Rationale**: Allows an app-level action (e.g., Settings) that is visually styled as a tab but logically independent of the main tab selection.
**Approved**: pending

**Decision**: Keep the component fully controlled — selection state lives in `value`/`onValueChange`, not internal state.
**Rationale**: Lets the parent app orchestrate navigation and keep tab selection synchronized with routing.
**Approved**: pending


**Decision**: Route a click on `endItem` through the same `onValueChange` callback as every other tab, passing its `id`, even though `endItem` never becomes active from `value`.
**Rationale**: The source has one click handler for all tabs, so a consumer tells the end action apart by its `id` and handles it (for example by opening settings) rather than by storing it as the selected value; a separate callback was not added.
**Approved**: pending

**Decision**: Place `endItem` with the physical `ml-auto` utility, which is LTR-only, rather than a logical margin utility.
**Rationale**: This is how the source places it; in a `dir="rtl"` context it stays on the visual right instead of moving to the trailing edge (see the endItem placement edge case).
**Approved**: pending
## Compliance

| Check | Status | Category | Basis |
|-------|--------|----------|-------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility | Plain `<button>`s with visible text and `aria-selected`. |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility | Tab and Space/Enter work on buttons, but `role="tablist"` users expect arrow keys and roving tabindex, which are absent. |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility | `role="tab"`/`role="tablist"` without `aria-controls`, `tabpanel` or roving tabindex. |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility | `text-[0.8rem]` is in rem, so it follows the browser font size, but nothing else adapts. |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility | The `apt-*` colour token values are not visible in this source file. |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility | Computed tab height is about 33px. |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | partial | Accessibility | `transition-colors` animates colour only, with no movement, but has no `motion-reduce:` variant. |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization | Labels are consumer-supplied `ReactNode`s. |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization | No text processing that would reject Unicode. |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | failed | Internationalization | No wrap or truncation handling for long labels. |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | failed | Internationalization | `endItem` uses the physical `ml-auto` utility. |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices | Pure presentation over `items`/`value`/`onValueChange`, with no embedded state. |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices | `appTabs.test.tsx` covers all 17 conformance vectors. |
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.2 | 2026-11-14 | Mike Fullerton | Regraded keyboard-navigable and reduced-motion to partial with a per-row Basis column, recorded endItem's shared onValueChange and LTR-only placement as Design Decisions, moved the placement note from Localization to Edge Cases, added a duplicate-id edge case and vectors app-tabs-012 to app-tabs-017, and corrected the Compose and WinUI 3 endItem notes. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case names and updated every citation; replaced the React/Base-UI-specific plain-button requirement with a platform-neutral no-content-panels requirement and moved the implementation detail into Platform Notes; documented that endItem shares invoke-callback-on-click's handler and that Disabled is unsupported (no `disabled` property exists) rather than "undefined"; changed "right edge" to "trailing edge" throughout and documented the `ml-auto` endItem placement as LTR-only under Localization; gave concrete Appearance values and a real computed touch-target height instead of "defined by shared tab grammar" and an unsupported native touch-target claim; fixed the `data-active` attribute-value contradiction in States; rewrote the `ml-auto` and `cn()`-merging test vectors to assert observable outcomes and added an endItem-click vector; fixed the missing-onValueChange edge case to describe optional chaining rather than a throwing call; corrected the SwiftUI, Compose, WinUI 3, and AppKit/UIKit platform notes to controls that don't imply owned content panels; reformatted Design Decisions to the three-line Decision/Rationale/Approved form; added the tabs ingredient to depends-on; and built out the Compliance table with applicable Accessibility and Internationalization checks |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from source. |
