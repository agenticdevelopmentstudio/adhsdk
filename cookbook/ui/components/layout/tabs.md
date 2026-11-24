---
id: fb3a0db4-691e-4025-a391-2853908248b5
title: "Tabs"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Tabbed interface component for organizing content into labeled sections with keyboard and mouse navigation."
platforms:
  - typescript
  - web
tags:
  - tabs
  - navigation
  - interface
depends-on: []
related: []
references:
  - https://base-ui.com/react/components/tabs
  - https://www.w3.org/WAI/ARIA/apg/patterns/tabs/
approved-by: ""
approved-date: ""
---

# Tabs

## Overview

Tabs component provides a tabbed interface for organizing related content into labeled sections. A single tab list contains multiple tab buttons; only one tab is active at a time and displays its associated panel. Users can switch between tabs using mouse click, keyboard navigation (arrow keys), or programmatic control. Built as a composition of four primitives: `Tabs` (root container), `TabsList` (tab button container), `TabsTab` (individual tab button), and `TabsPanel` (content panel).

## Behavioral Requirements

- **render-tab-list**: Component MUST render a container for tab buttons with a bottom border line separating tabs from content.
- **render-tabs**: Component MUST render individual clickable tab buttons within the tab list.
- **render-panels**: Component MUST render content panels that display content associated with each tab.
- **default-value**: Component MUST accept a `defaultValue` prop to specify which tab is active on initial render (uncontrolled mode).
- **controlled-value**: Component MUST also support controlled selection via a `value` prop paired with `onValueChange`, so a parent can own the selection.
- **active-indicator**: Component MUST render a 2px accent-colored border at the bottom of the active tab to indicate selection state.
- **disabled-tabs**: Component MUST respect a `disabled` attribute on individual tabs to block click-activation, and a disabled tab MUST look dimmed (50% opacity, no hover response), styled through the `data-disabled` attribute; the tab remains keyboard-focusable. The current web source does not meet the visual half; see the known non-conformance in **Edge Cases**.
- **click-selection**: Component MUST change the active tab when a user clicks any non-disabled tab button.
- **keyboard-tab-navigation**: Component MUST support Left/Right arrow-key and Home/End navigation among tabs, and roving-tabindex Tab-key entry/exit into the tablist, per the WAI-ARIA APG Tabs pattern. In a right-to-left context the Left and Right arrows reverse (Left moves to the next tab, Right to the previous).
- **aria-tab-roles**: Component MUST expose `role="tablist"` on the tab container, `role="tab"` with `aria-selected` on each tab, and `role="tabpanel"` on each panel. Each tab MUST reference its panel's id with `aria-controls`, each panel MUST reference its tab's id with `aria-labelledby`, and a disabled tab MUST carry `aria-disabled="true"`.
- **visible-label**: Each tab MUST contain visible text that describes its panel's content; an `aria-label` is added only when that text is insufficient.
- **hover-emphasis**: Component tabs SHOULD change text color on hover to indicate interactivity (from muted to full contrast).
- **focus-visible-state**: Component tabs MUST show a visible keyboard-focus indicator that is distinct from the hover state (a ring or an underline). The web source shows it on keyboard focus only (`focus-visible:`): full-contrast text, a rounded corner and a 2px `apt-gold/40` ring, on top of `outline-none`; hover has no ring.
- **touch-target**: On touch platforms each tab SHOULD be at least 44px tall. The current web padding (`py-2`) yields about 33px, a known gap; touch implementations SHOULD increase vertical padding or add touch-specific sizing.
- **class-name**: Component MUST accept a customization hook for additional styling on the root container and on each subcomponent (on web, a `className` prop; see Platform Notes).

## Appearance

- **Corner radius**: 0 (no rounding)
- **Padding—Tabs root**: flex column with 20px gap (`gap-5`)
- **Padding—TabsList**: bottom padding 0, inline elements with 16px gap horizontally (`gap-4`)
- **Padding—TabsTab**: 8px vertical, 4px horizontal (`py-2 px-1`)
- **Font—TabsTab**: monospace, 0.8rem (12.8px), weight 400 (normal), tracking-wide (letter-spacing increased)
- **Background**: transparent (no fill)
- **Foreground—inactive**: muted gray text (`apt-text-muted`)
- **Foreground—active**: full contrast text (`apt-text`), gold underline (`apt-gold`)
- **Foreground—hover**: full contrast text (`apt-text`)
- **Foreground—disabled**: dimmed to 50% opacity with no hover response, keyed off `data-disabled`. The current source instead uses `disabled:pointer-events-none disabled:opacity-50`, which are Tailwind `:disabled`-pseudo-class selectors, and Base UI's `TabsTab` sets `aria-disabled`/`data-disabled` rather than the native `disabled` attribute (it is `focusableWhenDisabled`), so neither class matches: today a disabled tab keeps full opacity, still responds to hover, and remains keyboard-focusable, with only click-activation blocked (known non-conformance, see **Edge Cases**)
- **Border—TabsList**: 1px bottom border in neutral border color (`apt-border`)
- **Border—active tab**: 2px bottom border in gold (`apt-gold`), positioned at bottom of tab (negative margin `-mb-px` to overlap list border)
- **Shadow**: none
- **Min/Max size**: no size constraints on Tabs root; `TabsTab` renders at approximately 33px tall, assuming an inherited line-height of about 15px (the `text-[0.8rem]` size sets no line-height of its own, so it follows the surrounding context) + `py-2`'s 16px total vertical padding + `border-b-2`'s 2px

## States

| State | Appearance change |
|-------|------------------|
| Default | Text muted gray, no underline (transparent 2px border), bottom border on list visible |
| Active | Text full contrast, gold 2px bottom border, border overrides list border |
| Hover | Text full contrast, no change to border (border state unchanged) |
| Focused | Text full contrast, rounded corner and a 2px `apt-gold/40` ring via `focus-visible:`, distinct from hover; see **focus-visible-state** |
| Disabled | Intended: dimmed to 50% opacity, no hover response; click-activation blocked, keyboard focus still lands on the tab. Current source: no visual change (see **disabled-tabs**) |

## Accessibility

- **Role**: Component uses Base UI which applies `role="tablist"` to `TabsList`, `role="tab"` to each `TabsTab`, and `role="tabpanel"` to each `TabsPanel`.
- **Labels**: see **visible-label**.
- **Focus management**: Tab moves focus into the tablist as a single stop (landing on the active or last-focused tab, per the roving-tabindex pattern); Left/Right arrow keys then move focus between tabs, and Home/End move focus to the first/last tab — disabled tabs remain part of this focus order (`focusableWhenDisabled`) and are not skipped. This is Base UI's implementation of the WAI-ARIA APG Tabs pattern's roving-tabindex model, not standard sequential tab order. See **keyboard-tab-navigation**; RTL arrow-key reversal is documented under Localization.
- **State announcement**: Base UI applies `aria-selected="true"` to the active tab and `aria-selected="false"` to inactive tabs; screen readers announce selection state.
- **Disabled state**: Base UI applies `aria-disabled="true"` and a `data-disabled` attribute to a disabled `TabsTab`; it does not set the native `disabled` HTML attribute, so the tab stays in the keyboard focus order and only click-activation is blocked.
- **Minimum touch target**: see **touch-target**; the current padding yields approximately 33px, below the 44px guidance.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tabs-001 | render-tab-list | Render `<Tabs><TabsList>...</TabsList></Tabs>` | TabsList renders as flexbox container with bottom border |
| tabs-002 | render-tabs | Render `<TabsTab value="a">Label A</TabsTab>` | Tab renders as clickable button with text |
| tabs-003 | render-panels | Render `<TabsPanel value="a">Content</TabsPanel>` | Panel renders with content visible when tab "a" active |
| tabs-004 | default-value | Render `<Tabs defaultValue="b">` with two tabs | Tab "b" is active on initial render, not tab "a" |
| tabs-005 | active-indicator | Activate a tab by click or prop | Active tab shows gold 2px bottom border, inactive tabs show transparent border |
| tabs-006 | disabled-tabs | Render `<TabsTab value="x" disabled>` and click it | Tab does not change active state, is dimmed to 50% opacity with no hover response, and can still receive keyboard focus (the dimming is a known non-conformance of the current web source) |
| tabs-007 | click-selection | Click a non-disabled tab | Active state changes to that tab; associated panel content displays |
| tabs-008 | aria-tab-roles | Inspect rendered DOM | `role="tablist"` on `TabsList`; `role="tab"` with `aria-selected` on each `TabsTab`; `role="tabpanel"` on each `TabsPanel`; each tab's `aria-controls` equals its panel's id, each panel's `aria-labelledby` equals its tab's id, and a disabled tab has `aria-disabled="true"` |
| tabs-009 | hover-emphasis | Hover over an inactive tab | Text color changes from `apt-text-muted` to `apt-text`; border unchanged |
| tabs-010 | focus-visible-state | Tab to a tab via keyboard | Tab receives focus and shows an indicator distinct from the hover state: `focus-visible:ring-2 focus-visible:ring-apt-gold/40` (plus `focus-visible:text-apt-text` and `focus-visible:rounded-sm`), which hover does not apply |
| tabs-011 | class-name | Pass `className="custom-class"` to Tabs/TabsList/TabsTab/TabsPanel | Custom class appended to element via `cn()` utility (Tailwind class merging) |
| tabs-012 | keyboard-tab-navigation | Focus a tab, press Right arrow | Focus moves to the next tab (including a disabled one); selection does not change, since `TabsList`'s `activateOnFocus` defaults to `false` |
| tabs-013 | keyboard-tab-navigation | Focus any tab, press End | Focus moves to the last tab, whether or not it is disabled |
| tabs-014 | controlled-value | Render with `value` and `onValueChange`, click a different tab | `onValueChange` is called with the new tab's value; the active tab only changes once the parent updates `value` in response |
| tabs-015 | default-value | Render `<Tabs>` with no `defaultValue`/`value` and tabs "a", "b" | The tab at index `0` ("a") is active, regardless of tab `value` strings |
| tabs-016 | keyboard-tab-navigation | Focus any tab, press Home | Focus moves to the first tab |
| tabs-017 | keyboard-tab-navigation | Focus is outside the tablist; press Tab, then Tab again | The first Tab lands on the active tab (one stop for the whole list); the second leaves the tablist |
| tabs-018 | keyboard-tab-navigation | Direction rtl (supplied through Base UI's `DirectionProvider`; the `dir` attribute alone is not read); focus a tab and press Left | Focus moves to the next tab; Right moves to the previous |
| tabs-019 | visible-label | Render `<TabsTab value="a">Label A</TabsTab>` | The tab's accessible name is its visible text "Label A" |
| tabs-020 | disabled-tabs | Every `TabsTab` is `disabled`, `defaultValue="b"` | Tab "b" stays selected and its panel displays; clicking another tab changes nothing |
| tabs-021 | render-tab-list | Render `<TabsList />` with no tabs | The list renders, empty; no panel is selected |
| tabs-022 | render-panels | Render `<TabsPanel value="a" />` with no children while tab "a" is active | The panel renders as an empty container without error |
| tabs-023 | click-selection | Click tab "b", then tab "c", then tab "a" in quick succession | Tab "a" is active and its panel displays |
## Edge Cases

- **Empty tabs**: If no `TabsTab` children are provided, `TabsList` MUST still render, empty. With no tab present, no panel is selectable.
- **Single tab**: A single tab with no alternative choice may be confusing to users. Component MUST still render and function correctly; design SHOULD consider whether a single tab adds value.
- **No defaultValue**: If both `defaultValue` and `value` are omitted, Base UI selects the tab at index `0` — not the first tab by string `value`. See **default-value**.
- **All tabs disabled**: If every `TabsTab` is disabled, the tab identified by `defaultValue`/`value` MUST remain selected and its panel MUST still display — `disabled` blocks interaction on that tab, it does not clear the Root's selection state. No tab's selection can be changed by click or keyboard while all are disabled, though keyboard focus can still move among the disabled tabs (`focusableWhenDisabled`).
- **Very long tab labels**: Tab text that exceeds container width may wrap or truncate depending on parent width. Component has no word-wrap or text-overflow rule; it MUST render the label as-is. Implementor SHOULD manage parent width constraints or truncate long labels.
- **Rapid tab switching**: Clicking multiple tabs in quick succession MUST result in the most recently clicked non-disabled tab being active; each click is a synchronous state update, and no debouncing is performed.
- **Null or undefined panel content**: If a `TabsPanel` has no children, it MUST render as an empty container without error.
- **Right-to-left arrow keys**: In a `dir="rtl"` context Left moves to the next tab and Right to the previous, per **keyboard-tab-navigation**.
- **Vertical orientation**: Not supported. `orientation="vertical"` reaches Base UI, but the underline styling is horizontal-only.
- **Known non-conformance (disabled appearance)**: **disabled-tabs** requires a dimmed disabled tab, but the web source's `disabled:` classes never match, because Base UI sets `aria-disabled`/`data-disabled` and not the native `disabled` attribute. Keying the classes off `data-disabled` closes the gap.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `Tabs.defaultValue` | `string \| number` | `0` | Uncontrolled: which tab is active on initial render. Base UI defaults to index `0`, not a specific tab's `value` |
| `Tabs.value` | `string \| number` | — | Controlled: the active tab's value; pairs with `onValueChange` |
| `Tabs.onValueChange` | `(value: string \| number) => void` | — | Called when the user selects a different tab, so a controlled `value` can be updated |
| `Tabs.orientation` | `"horizontal" \| "vertical"` | `"horizontal"` | Passed through to Base UI. Only horizontal is supported: the styling (bottom border, underline) is horizontal-only and is not adapted for vertical |
| `TabsList.activateOnFocus` | `boolean` | `false` | Whether moving focus with arrow keys also changes the selected tab (`true`); by default, arrow keys move focus only and selection requires a separate click/activation |
| `Tabs.className` | `string` | `undefined` | Additional CSS classes merged into the root `Tabs` element via `cn()` |
| `TabsList.className` | `string` | `undefined` | Additional CSS classes merged into the `TabsList` element via `cn()` |
| `TabsTab.value` | `string \| number` | required | Identifies this tab; matched against `TabsPanel.value` to associate content |
| `TabsTab.disabled` | `boolean` | `false` | Blocks click-activation for this tab and should dim it (see **disabled-tabs** for the current visual gap); the tab remains keyboard-focusable |
| `TabsTab.className` | `string` | `undefined` | Additional CSS classes merged into this tab's classes via `cn()` |
| `TabsPanel.value` | `string \| number` | required | Identifies which tab's content this panel renders |
| `TabsPanel.className` | `string` | `undefined` | Additional CSS classes merged into this panel's classes via `cn()` |

## Deep Linking

Not applicable: Tabs component is a UI primitive without built-in deep linking support. URL routing and tab state synchronization SHOULD be implemented at the page or application layer.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| Tab labels | User-provided | Each `<TabsTab>` child is user-provided text; no built-in localization |

## Accessibility Options

- **Reduce Motion**: The hover/focus-visible text-color change uses Tailwind's `transition-colors` utility with no `motion-safe:`/`motion-reduce:` variant, so it does not automatically honor the OS reduced-motion preference — Tailwind's `transition-*` utilities apply unconditionally unless a `motion-*` variant is added. Consumers needing strict reduced-motion compliance should override with a `motion-reduce:transition-none` class.
- **Increase Contrast**: Component text and borders use CSS custom properties (`apt-text`, `apt-gold`, `apt-border`) which SHOULD be overridden in high-contrast themes. Not a component responsibility.
- **Differentiate Without Color**: Component uses both color (gold) and position (border underline) to indicate active state; active state is distinguishable without color alone.

## Feature Flags

Not applicable: Tabs component is a base UI primitive with no feature flag control in source code.

## Analytics

Not applicable: Component emits no built-in analytics events. Analytics instrumentation is the responsibility of the consuming application.

## Privacy

Not applicable: Component processes no user data beyond interaction events (click, focus) which are local to the browser and not transmitted.

## Logging

Not applicable: Component performs no internal logging.

## Platform Notes

- **React/Web**: Component wraps `@base-ui/react/tabs` (`TabsPrimitive`) — see **aria-tab-roles**, **keyboard-tab-navigation**, and **controlled-value**, which this component satisfies by delegating to Base UI's `Tabs.Root` / `Tabs.List` / `Tabs.Tab` / `Tabs.Panel`; `value` and `onValueChange` are passed straight through to `Tabs.Root`, and keyboard behavior follows Base UI's implementation of the WAI-ARIA APG Tabs pattern. Accepts a `className` on the root and each subcomponent for the **class-name** hook. Uses Tailwind CSS utilities for styling. Active state is indicated via the `data-[active]` attribute selector Base UI applies to the selected `Tab`; styling keys off this attribute. The `cn()` utility merges additional `className` props on every subcomponent.

- **SwiftUI**: For in-content tabs (not app-level navigation), use a segmented `Picker(selection:)` bound to a `@State` value, paired with a manual content switch (`if`/`switch` over the selection) to show the associated panel. `TabView` is reserved for app-level/root navigation (tab bar), not in-content component tabs, and `.tabViewStyle(.segmented)` does not exist as an API. No gold color by default; map `apt-gold` to a custom accent `Color`.

- **Compose**: Material 3's `PrimaryTabRow` (or `SecondaryTabRow`) composable — or the plain `TabRow` on older Material versions — containing `Tab` composables. Active tab is managed via `selectedTabIndex: Int` state. Disabled tabs via the `enabled` parameter on `Tab`. Customize the underline indicator via the `indicator` parameter (not `indicatorContent`). No monospace font by default; apply `FontFamily.Monospace`.

- **AppKit / UIKit**: Native `NSTabView` (macOS) or custom `UIView` composition (iOS) provides tabbed interface. iOS typically uses `UISegmentedControl` or custom button stack. Underline indicator requires custom implementation via `CALayer` or view positioning. Disabled state via `isEnabled` property. Focus management via `becomeFirstResponder()` on UIKit and `window.makeFirstResponder(_:)` on AppKit.

- **WinUI 3**: For in-content section tabs, prefer `SelectorBar` (with `SelectorBarItem` entries) or `Pivot`; native `TabView` is designed for closable, document-style tabs (browser-tab UX) and shows close buttons by default — if used for section tabs anyway, set `IsClosable="False"` on each `TabViewItem`. Active item via `SelectedIndex`/`SelectedItem`. Disabled tab via `IsEnabled="False"`. Underline/indicator customization via `SelectorBarItem` styling or `TabViewItemHeaderBackground`; map `apt-gold` to `AccentFillColorDefaultBrush` or a custom brush.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/tabs.tsx` | confirmed (1.1.2) |

## Design Decisions

**Decision**: Use a gold bottom-border underline (an accent indicator) rather than a filled pill or box background for the active tab.
**Rationale**: An underline maintains minimal visual weight and distinguishes the active tab while keeping focus on content; this matches the hub's `/home` tab bar treatment, per the source implementation comment.
**Approved**: pending

**Decision**: Use a monospace font (`font-mono`) with increased letter-spacing (`tracking-wide`) for all tab labels.
**Rationale**: Gives a technical appearance that suits short identifiers or status codes as labels.
**Approved**: pending

**Decision**: Use flex layout with `gap` utilities (`flex flex-col gap-5` on root, `flex items-end gap-4` on `TabsList`) instead of hard-coded margins.
**Rationale**: Provides predictable spacing and alignment without per-child margin bookkeeping.
**Approved**: pending

**Decision**: Shift the active tab's border with a negative margin (`-mb-px`) so its 2px gold border overlaps and visually replaces the `TabsList`'s 1px bottom border.
**Rationale**: Creates a seamless transition from list border to tab underline instead of a visible seam between the two borders.
**Approved**: pending

**Decision**: Build on Base UI's `Tabs` primitive rather than rolling custom tab logic.
**Rationale**: Base UI provides ARIA compliance (**aria-tab-roles**), keyboard navigation (**keyboard-tab-navigation**), and focus management out of the box; building on a headless primitive is more maintainable than reimplementing tab semantics.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on: the source's delegation to Base UI for ARIA roles, keyboard handling, and focus order (screen-reader-support, semantic-markup — passed); the focus indicator distinct from hover (`tabItemClass` adds `focus-visible:text-apt-text focus-visible:rounded-sm focus-visible:ring-2 focus-visible:ring-apt-gold/40`; keyboard-navigable, focus-management — passed); the `rem`-based sizing (`text-[0.8rem]`, `py-2`), which scales with the user's root font size (dynamic-type-support — passed); the `apt-*` color tokens whose actual values aren't visible in this source file (contrast-ratio — partial); the ~33px computed tab height and the `transition-colors` utility with no `motion-reduce:` variant (touch-target-size, reduced-motion — failed); and the absence of any word-wrap/truncation handling for user-provided tab-label text plus the unverified RTL mirroring of the plain flex layout (text-expansion-tolerance — failed, rtl-layout-support — partial); the four exports are thin themed wrappers around Base UI's `Tabs` primitives with no logic of their own (separation-of-concerns passed), and no test file in the web workspace imports `Tabs`/`TabsList`/`TabsTab`/`TabsPanel` from this source — the candidate tests matched by name test unrelated markdown/window-drawer/split-view surfaces (unit-test-coverage was failed; it is now passed: `tabs.test.tsx` covers every vector tabs-001 through tabs-023 with no skips).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.2 | 2026-11-14 | Mike Fullerton | Lint findings applied: disabled and focus-indicator requirements state the intended behavior with the web gaps recorded as known non-conformances, Base UI and className details moved to Platform Notes, named visible-label and touch-target requirements, aria-controls, aria-labelledby and aria-disabled added, RTL arrows moved out of the localization table, eight new test vectors, an orientation row, and corrected compliance statuses and AppKit note. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Fixed disabled-tab styling claims (no opacity/pointer-events change; stays focusable) and replaced invented Tabs.activationMode with real TabsList.activateOnFocus (default false). Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case names and updated every citation; replaced the Base-UI-specific requirement with a platform-neutral ARIA-roles requirement and moved the Base UI dependency into Platform Notes and Design Decisions; added keyboard arrow/Home/End navigation, activation-mode, and controlled value/onValueChange requirements, configuration rows, and test vectors; corrected the padding/gap/height math in Appearance and the touch-target number; fixed the self-contradictory disabled-state description and the unsupported reduced-motion and defaultValue-default claims; corrected the roving-tabindex focus-management text and added an RTL arrow-key note under Localization; replaced gold/`apt-*` token references in normative requirements with semantic role wording (accent indicator, muted/full-contrast text); fixed the SwiftUI, Compose, and WinUI 3 platform-note API names; rewrote Edge Cases as testable MUST/SHOULD statements; reformatted Design Decisions to the three-line Decision/Rationale/Approved form; built out the Compliance table with applicable Accessibility and Internationalization checks; and added Base UI and WAI-ARIA APG references |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from web source |
