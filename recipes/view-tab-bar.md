---
id: 826184eb-23f0-4ff7-b5f3-dc583fbc8496
title: View Tab Bar
domain: adhsdk://recipes/view-tab-bar
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A content-area tab strip combining client-state buttons and route navigation
  links in a unified, horizontal row.
platforms:
- typescript
- web
tags:
- tabs
- navigation
- client-state
depends-on: []
related:
- adhsdk://recipes/tabs
references: []
approved-by: ''
approved-date: ''
---

# View Tab Bar

## Overview

A flexible tab bar component that renders a horizontal strip combining two independent navigation modes: client-state buttons (triggering state callbacks without navigation) and route links (navigating to external views). The component shares visual styling with the Tabs underline idiom (gold bottom border on the active tab via `tabItemClass`), making mixed compositions read as a unified system. Tabs and links are rendered in separate semantic sections — tabs in a `role="tablist"` and links in a `<nav>` — to maintain correct screen reader hierarchy while preserving visual uniformity through consistent gap spacing and alignment.

## Behavioral Requirements

- **tablist-rendering**: Component MUST render a `role="tablist"` when the `tabs` array has length > 0.
- **nav-links-rendering**: Component MUST render a `<nav aria-label="views">` when the `links` array has length > 0.
- **empty-tabs-omit-tablist**: Component MUST NOT render a `role="tablist"` when the `tabs` array is empty.
- **empty-links-omit-nav**: Component MUST NOT render a `<nav>` when the `links` array is empty.
- **active-tab-marking**: Component MUST set `aria-selected="true"` on the tab whose `value` matches the current `value` prop; all other tabs MUST have `aria-selected="false"`.
- **tab-click-callback**: Component MUST call the `onChange` callback with the tab's `value` when a tab button is clicked.
- **active-link-marking**: Component MUST set `aria-current="page"` on the link whose `active` prop is `true`; other links MUST NOT have this attribute.
- **active-state-attribute**: Component MUST set `data-active=""` (empty string) on both tab buttons and links when they are in the active state; the attribute MUST NOT be present on inactive items.
- **tab-role-attribute**: Component MUST render each tab button with `role="tab"`.
- **icon-tab-label**: Component MUST apply the `title` prop as both the `aria-label` and `title` HTML attribute on each tab button to provide accessible labels when the visible label is an icon.
- **container-class-merge**: Component MUST accept a `className` prop and merge it with its own layout classes on the outermost container element via the `cn()` utility.
- **layout-spacing**: Component MUST lay out both the inner tablist row and the nav row as a flex row with bottom-aligned items and a consistent horizontal gap between them; the outer container MUST apply horizontal padding around the whole strip. (Web implementation: `flex items-end gap-4` on each row, `px-4` on the container — see Appearance.)
- **item-styling**: Component MUST apply one consistent style class to every tab button and link element so all items render uniformly, distinguished only by the active-state attribute. (Web implementation: `tabItemClass` from the Tabs component — see Appearance.)
- **reactnode-labels**: Component MUST accept `ReactNode` for both tab and link labels, supporting text, icons, or composed elements.

## Appearance

- **Container padding**: Horizontal padding `px-4` (typically 16px on the x-axis)
- **Layout**: Flex row with `items-end` alignment and `gap-4` (typically 16px) spacing between items
- **Tab/Link styling**: Applies `tabItemClass` from the Tabs component (shared underline idiom with gold bottom border on active state)
- **Active indicator**: `data-active=""` attribute (empty string) applied to active tabs and links; styling via CSS attribute selector `[data-active]`
- **Font**: Inherits from `tabItemClass` definition (typically mono labels per the underline idiom)
- **No visible disabled state**: Component does not render disabled tabs
- **Min/Max size**: No explicit constraints; tabs and links flex to accommodate content within the flex row

## States

| State | Tab Appearance | Link Appearance |
|-------|----------------|-----------------|
| Active | `data-active=""`, `aria-selected="true"`, gold bottom border via `tabItemClass` | `data-active=""`, `aria-current="page"`, gold bottom border via `tabItemClass` |
| Inactive | No `data-active` attribute, `aria-selected="false"`, underline not visible | No `data-active` attribute, no `aria-current`, underline not visible |
| Focused | Inherits focus styling from `tabItemClass` definition | Inherits focus styling from `tabItemClass` definition |

## Accessibility

- **Semantic structure**: Tabs MUST be wrapped in `role="tablist"`; links MUST be wrapped in `<nav aria-label="views">` to distinguish navigation type and avoid mixing tabs and links in the same tablist.
- **Tab role and state**: Each tab button MUST have `role="tab"` and `aria-selected` reflecting its active state.
- **Link semantics**: Links MUST be rendered as `<a>` elements with `aria-current="page"` on the active link to indicate current page/location.
- **Icon label fallback**: When a tab's visible label is an icon, the `title` prop MUST be provided to populate both `aria-label` and `title` attributes.
- **Keyboard navigation**: Tabs and links MUST be navigable via Tab key (rendered as interactive elements `<button>` and `<a>`) and active tab/link MUST be indicated by `aria-selected` and `aria-current` respectively. The component relies on native Tab-key focus order between the button/anchor elements; it does not implement the WAI-ARIA tabs pattern's arrow-key/Home-End roving-tabindex navigation or an `aria-controls` link to a tabpanel (see Compliance).
- **Screen reader announcement**: The distinction between tabs (client-state buttons) and links (navigation) is preserved in the DOM structure (separate `role="tablist"` and `<nav>`), enabling screen readers to announce the navigation mode correctly.
- **Minimum touch target**: No explicit touch target size constraint in component; implementors MUST ensure tab and link elements meet platform minimum (44×44pt on iOS per Human Interface Guidelines, 48×48dp on Android per Material Design 3, 44×44px on web per WCAG guidance).

## Conformance Test Vectors

| ID | Requirement | Input | Expected |
|----|-------------|-------|----------|
| view-tab-bar-001 | tablist-rendering | `tabs=[{value:"a",label:"Tab A"}]`, `value="a"`, `onChange=()=>{}` | Rendered `<div role="tablist">` containing one `<button role="tab">` |
| view-tab-bar-002 | empty-tabs-omit-tablist | `tabs=[]`, `links=[]` | No `role="tablist"` element in output |
| view-tab-bar-003 | nav-links-rendering | `tabs=[]`, `links=[{href:"/a",label:"Link A"}]` | Rendered `<nav aria-label="views">` containing one `<a href="/a">` |
| view-tab-bar-004 | empty-links-omit-nav | `tabs=[{value:"a",label:"Tab A"}]`, `links=[]` | No `<nav>` element in output |
| view-tab-bar-005 | active-tab-marking | `tabs=[{value:"a",label:"A"},{value:"b",label:"B"}]`, `value="a"` | First tab has `aria-selected="true"`, second has `aria-selected="false"` |
| view-tab-bar-006 | tab-click-callback | `tabs=[{value:"a",label:"A"}]`, `onChange` spy attached | `onChange("a")` called when tab button is clicked |
| view-tab-bar-007 | active-link-marking | `links=[{href:"/a",label:"A",active:true},{href:"/b",label:"B",active:false}]` | First link has `aria-current="page"`, second does not |
| view-tab-bar-008 | active-state-attribute | `tabs=[{value:"a",label:"A"}]`, `value="a"` | Tab button has `data-active=""` attribute |
| view-tab-bar-009 | active-state-attribute | `tabs=[{value:"a",label:"A"}]`, `value="b"` | Tab button does NOT have `data-active` attribute |
| view-tab-bar-010 | tab-role-attribute | `tabs=[{value:"a",label:"A"}]` | Each tab button has `role="tab"` attribute |
| view-tab-bar-011 | icon-tab-label | `tabs=[{value:"a",label:<Icon/>,title:"Icon Label"}]` | Tab button has both `aria-label="Icon Label"` and `title="Icon Label"` attributes |
| view-tab-bar-012 | container-class-merge | `className="custom-class"` | Outermost container div has class `custom-class` applied (via `cn()`) |
| view-tab-bar-013 | layout-spacing | Any valid props | Tablist and nav rows each compute `display: flex`, `align-items: flex-end`, and an equal, non-zero horizontal gap between items; the outer container computes non-zero horizontal padding |
| view-tab-bar-014 | item-styling | Any valid tabs or links | Every tab button and every link resolves to the same style class as each other (identical `className` reference), with only the active item additionally carrying `data-active` |
| view-tab-bar-015 | reactnode-labels | `tabs=[{value:"a",label:<span>Custom</span>}]` | Tab renders ReactNode label content correctly |
| view-tab-bar-016 | empty-tabs-omit-tablist, empty-links-omit-nav | `tabs=[]`, `links=[]`, `className="x"` | Outer container renders with `px-4` and the custom class `x`; no `role="tablist"` element and no `<nav>` element are present |
| view-tab-bar-017 | container-class-merge | `className="custom-class"` | Outer container element has both `px-4` and `custom-class` present simultaneously (merged via `cn()`), not one replacing the other |

## Edge Cases

- **Empty tabs and empty links**: When both `tabs` and `links` arrays are empty, the component renders only the outer container with the specified `className` and `px-4` padding; no tablist or nav is rendered. This is valid but produces an empty visual bar (see view-tab-bar-016).
- **Single tab or link**: A single-item array renders correctly. As with any size array, whether the item is active is a controlled matter — it renders active only when the caller's `value` (for a tab) or the item's `active` prop (for a link) says so; the component does not choose an initial active item itself.
- **Icon-only labels without title**: If a tab's `label` is an icon and no `title` prop is provided, the tab will not have an accessible aria-label; this is a conformance gap that testing MUST catch. The component does not validate or warn about this condition.
- **No tab matches the current value**: If `value` does not equal any `tabs[].value`, no tab is marked active (`data-active` absent, `aria-selected="false"` on every tab); this is a valid but likely-unintended caller state (see view-tab-bar-009).
- **Duplicate tab values**: If the `tabs` array contains two items with the same `value`, both are marked active simultaneously when that value equals the current `value` prop (`aria-selected="true"` and `data-active=""` on each) — the component does not deduplicate or pick a single active match. React also emits a duplicate-key warning in development, since the source uses `t.value` as the React `key`.
- **Very long labels**: Labels that exceed the flex row width will cause the row to overflow horizontally unless the parent container has overflow handling or responsive truncation. The component does not constrain label width.

## Configuration

| Option | Type | Default | Required | Description |
|--------|------|---------|----------|-------------|
| `tabs` | `ViewTabItem[]` | — | Yes | Array of tab items, each with `value`, `label`, and optional `title` |
| `value` | `string` | — | Yes | The currently active tab value. It MUST match one of the `tabs[].value` entries for a tab to render as active; if none match, no tab is marked active (see Edge Cases) |
| `onChange` | `(value: string) => void` | — | Yes | Callback invoked when a tab button is clicked, receiving the clicked tab's value |
| `links` | `ViewTabLink[]` | `[]` | No | Array of link items, each with `href`, `label`, and optional `active` boolean |
| `className` | `string` | — | No | Additional CSS class(es) to apply to the outer container via `cn()` |

## Deep Linking

Route links in the component support standard `href` navigation:

| Platform | Behavior |
|----------|----------|
| Web | Links render as plain `<a href>` elements with no router integration point (no `renderLink`/`asChild` prop). Clicking triggers the browser's default navigation (a full page load) unless an ancestor of the component intercepts anchor clicks itself. The component does not handle routing; it passes through the `href` as provided. |

## Localization

Labels are provided as `ReactNode` props (text, icons, or composed elements). The component does not perform any string localization. Callers MUST provide locale-specific labels via the `label` prop.

| String Key | Source | Context |
|-----------|--------|---------|
| N/A | Caller-provided `tabs[].label` and `links[].label` | User-facing tab and link text |
| `aria-label="views"` | Hardcoded in component | Semantic label for the navigation section |

The `aria-label="views"` string above is a literal in the component source (`view-tab-bar.tsx`); it is not exposed as a prop, so callers cannot override or localize it (see Compliance).

## Accessibility Options

The component uses standard ARIA attributes and does not detect or respond to platform accessibility settings.

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not implemented in source. Component does not apply `prefers-reduced-motion`; animation behavior depends on `tabItemClass` styling (caller's responsibility). |
| Increase Contrast | Not implemented in source. Contrast is determined by `tabItemClass` styling (caller's responsibility to ensure WCAG AA compliance). |
| Differentiate Without Color | Not implemented in source. Active state is indicated by `data-active` attribute and `aria-selected`/`aria-current`; visual styling via `tabItemClass` (caller's responsibility). |

## Feature Flags

Not implemented in source. No feature flags control the component's availability or behavior.

## Analytics

Not implemented in source. The component does not emit analytics events; callers MUST attach event handlers or wrap `onChange` to emit analytics if needed.

## Privacy

The component collects no data. The `onChange` callback and link `href` are controlled by the caller. The component stores no internal state beyond rendering.

## Logging

Not implemented in source. No logging or debug output is emitted.

## Platform Notes

- **React/Web**: Use this component as provided. Tabs are rendered as `<button role="tab">` elements with `aria-selected` state; links are rendered as `<a>` elements within `<nav aria-label="views">`. The outer container applies `flex items-end gap-4` layout with `px-4` padding. Import `tabListClass` and `tabItemClass` from the shared Tabs component to ensure visual consistency. The source is in `packages/web/packages/ui/src/blocks/view-tab-bar.tsx`.

- **Swift/SwiftUI**: Build the row with `HStack(alignment: .bottom, spacing: 16)` to match the `items-end` + `gap-4` behavior, and apply `.padding(.horizontal, 16)` to the outer `HStack` to match `px-4`. There is no SwiftUI `role` modifier or `.spacing()` modifier on a view — render the tab buttons as `Button` views wrapped in a container with `.accessibilityElement(children: .contain)`, and mark the active one with `.accessibilityAddTraits(.isSelected)` (SwiftUI's nearest equivalent to `aria-selected`). Render route links with `Link` or `NavigationLink`, each with `.accessibilityLabel` set for the "views" grouping. Apply the platform's equivalent of the shared underline idiom (a conditional border/underline modifier keyed off the active state) in place of `tabItemClass`.

- **Kotlin/Compose**: Use `Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(16.dp))` for both the tab row and the link row. Give the tab row `Modifier.selectableGroup()`, and give each tab `Modifier.selectable(selected = ..., role = Role.Tab) { onChange(...) }` — use `Role.Tab`, not `Role.Button`, so accessibility services announce it correctly. Render links as plain `Text`/`ClickableText` composables (no tab role) inside their own `Row`. Use `LazyRow` if the tab/link list can grow long. Apply the platform's equivalent underline/border active-state styling in place of `tabItemClass`.

- **AppKit / UIKit**: On AppKit, use an `NSStackView` (`.orientation = .horizontal`, `.alignment = .bottom`, `spacing = 16`) of `NSButton`s — or an `NSSegmentedControl` — for the client-state tabs; avoid `NSTabView`, which owns and switches its own content panes rather than acting as a stateless button row. Put the route links in a second `NSStackView` of link-styled `NSButton`s (or `NSTextField`s with a link attribute). On UIKit, use `UISegmentedControl` or a custom `UIStackView` of `UIButton`s (wrapped in a `UIScrollView` if the row can overflow) for the tabs, wired to a delegate/`UIAction` equivalent to `onChange`; use a second `UIStackView` of `UIButton`s for the links. Both platforms should apply the platform's equivalent underline/border active-state styling in place of `tabItemClass`, and match `.bottom` alignment with 16pt spacing/padding.

- **WinUI 3**: Use `SelectorBar` with `SelectorBarItem` elements for the client-state tabs, wiring `SelectorBar.SelectionChanged` to the equivalent of `onChange` — `SelectorBar`, not `TabView`, since `TabView` is built for closable document tabs and its `SelectionChanged` targets the whole control rather than a single stateless item. For route links, use a `NavigationView` in `PaneDisplayMode="Top"` or a row of `HyperlinkButton` elements. Apply `Orientation="Horizontal"` and `VerticalAlignment="Bottom"` on the containing `StackPanel`, with `Spacing="16"` for the gap and `Padding="16,0"` for the horizontal padding. Style the active tab with the platform's equivalent of the gold bottom-border underline idiom, driven off the selected state.

## Design Decisions

- **Decision**: Tabs are wrapped in `role="tablist"` and links in `<nav>`, as two separate ARIA sections rather than one combined list.
  **Rationale**: Tabs are interactive controls that change application state without navigation, while links perform navigation; screen readers must distinguish between these two interaction modes. The visual `gap-4` spacing and flex alignment make both groups appear as one unified row despite their semantic separation.
  **Approved**: pending

- **Decision**: The `title` prop for icon-only tabs is optional rather than required.
  **Rationale**: Icons are common in tab bars, and providing accessible labels for icon-only tabs requires an `aria-label`. Not every tab is icon-only, so the prop is optional, but callers MUST provide it for any tab with an icon label to maintain accessibility compliance.
  **Approved**: pending

- **Decision**: Active state is signaled with `data-active=""` (an empty-string attribute) rather than `data-active="true"`.
  **Rationale**: The presence of the attribute, regardless of value, indicates the active state — matching the CSS attribute-selector convention (`[data-active]`) used throughout the rest of the Tabs component family.
  **Approved**: pending

- **Decision**: The component holds no internal state; it is fully controlled via `value` and `onChange`.
  **Rationale**: Callers MUST manage the `value` state externally and call `onChange` to update it. This lets the parent manage complex logic (e.g., an unsaved Config draft that must survive a tab switch) without the component imposing its own state model.
  **Approved**: pending

- **Decision**: `links` is optional and defaults to an empty array.
  **Rationale**: Route navigation is not needed by every tab bar. Some use cases have tabs only, links only, or both.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

Screen-reader-support, keyboard-navigable, and semantic-markup are `partial` because the source provides `role`, `aria-selected`, `aria-current`, and `title`/`aria-label` for icon tabs, but implements only native Tab-key focus (no arrow-key/Home-End roving tabindex, no `aria-controls` linking a tab to a panel) and does not enforce a `title` when a tab's label is icon-only (see Edge Cases); contrast-ratio, touch-target-size, and dynamic-type-support are `partial` because those depend entirely on the externally-defined `tabItemClass`, which this source does not define; no-hardcoded-strings and string-externalization are `failed` because the `aria-label="views"` string is a literal in `view-tab-bar.tsx` with no prop to override or localize it. `separation-of-concerns` passes because the component is a controlled, pure presentation layer over `tabs`/`value`/`links` with no business logic; `unit-test-coverage` fails because no test exercises it.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case; reformatted Design Decisions to Decision/Rationale/Approved; rewrote Compliance as a real, linked check table instead of an ad hoc "Passed" list; corrected the SwiftUI/Compose/AppKit-UIKit/WinUI 3 platform notes to real native APIs; resolved the onChange/value contradiction between Configuration and Edge Cases; rewrote the incoherent duplicate-value, single-item, and impossible-null-href edge cases; fixed the Deep Linking claim that contradicted the plain-`<a>` source; added the Tabs recipe to `related`; dropped "scrollable" from the summary (no overflow handling exists); removed the undefined "Rule 15" reference; reworded the layout/item-styling requirements and vectors to assert observable/computed outcomes instead of literal Tailwind class strings; added test vectors for the both-empty-arrays case and for `className`/`px-4` merging. |
