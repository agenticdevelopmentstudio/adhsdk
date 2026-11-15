---
id: 7185bc91-0646-44c0-b4ea-e59e39946623
title: "Detail Header"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The single header row of a details view, with a claimable API button and help slot on its right that fall back to disabled controls when no pane claims them."
platforms:
  - typescript
  - web
tags:
  - header
  - slots
  - portal
  - detail
depends-on: []
related:
  - 0bba1f5b-bc8d-4f76-b1c9-329b627f7ee8
  - aaebd90e-991f-4133-a12d-0783586eae5a
references: []
approved-by: ""
approved-date: ""
---

# Detail Header

## Overview

Detail Header is the one header row of a details view, plus the small claim system that lets a pane far below the stack put its own controls into that row. Every details view, whether the hub shell's, a feature site's, a dialog's or a console's, shows the same shape on the right of its header: an `API` button and a `?` help button. The pane that knows the endpoint and the help text sits several components below the stack that draws the header, so it claims a slot and portals its control in; what nothing has claimed is drawn disabled, with a tooltip that says why.

The block has four parts: `DetailHeaderProvider`, which a stack mounts around everything it draws and which owns the two slots and the claims on them; `DetailHeaderPortal`, which a pane uses to claim a slot and render a control into it; `DetailHeaderRow`, which draws the strip itself (lead control, tools, title, then the slots); and the two disabled fallbacks, `DisabledApiButton` and `DisabledHelpButton`. It is used by the hierarchical topic detail and hierarchical menu detail layouts and by the panes that put an API or help control in their header.

## Behavioral Requirements

- **row-structure**: The row MUST draw, left to right, the lead control (when given), the tools (when given), the title cell (when given) and then a right-hand group of the header slots.
- **row-hook**: The row MUST carry the attribute `data-slot="detail-header"`.
- **row-chrome**: The row MUST be a single line at least 2.15rem tall, with a bottom border in the theme border color and the navigation background color, and MUST NOT shrink vertically.
- **row-padding**: The row MUST have 8px of padding on both sides, except that when `leadCell` is true and a lead is given it MUST have 8px on the right only, because the lead cell seats itself against the left edge.
- **lead-optional**: The row MUST render no lead when `lead` is undefined, null or false.
- **lead-cell**: When `leadCell` is true and a lead is given, the row MUST seat the lead in a fixed 32px (`w-8`) wide cell that centres it and does not shrink.
- **title-cell**: When `title` is given, the row MUST render `title.cell` in its place in the row and MUST keep it mounted, because a pane's title portals into it.
- **title-spacer**: When `title` is not given, the row MUST render an empty element that fills the free width (`flex-1`) so the slots stay on the far right.
- **slot-group-right**: The row MUST draw the slots in a right-hand group that does not shrink, with 4px between its items.
- **slot-order**: Within the right-hand group the order MUST be the stack's `actions` (when present), the API slot, then the help slot.
- **actions-box**: When the stack supplies `actions` (anything other than undefined, null or false), the row MUST draw them in their own box carrying the attribute `data-adh-detail-actions`, with 4px between items, immediately before the API slot.
- **actions-omitted**: When `actions` is undefined, null or false, the row MUST draw no actions box.
- **actions-not-claimable**: The `actions` MUST be owned by the stack, so no pane can displace them.
- **api-slot**: The row MUST draw an API slot carrying the attribute `data-adh-detail-api-slot` and MUST always draw it.
- **help-slot**: The row MUST draw a help slot carrying the attribute `data-adh-detail-help-slot`, last in the row, and MUST always draw it.
- **api-fallback**: While no pane has claimed the API slot, the API slot MUST hold a disabled API button.
- **help-fallback**: While no pane has claimed the help slot, the help slot MUST hold the stack's `fallbackHelp` when it is given (not null or undefined), else a disabled help button.
- **no-provider-fallback**: When the row is drawn outside any provider, it MUST draw a disabled API button and a disabled help button in the right-hand group, with no slot boxes and no actions.
- **slots-are-state**: The provider MUST hold the two slot elements in state, not in refs, so a claimant re-renders once the slot exists.
- **claim-by-kind**: The provider MUST keep claims separately for the API and help kinds, each as an ordered list of claimant ids.
- **last-claimant-wins**: The owner of a kind MUST be the most recent claimant of that kind, or none when the list is empty.
- **claim-idempotent**: Claiming a kind that the claimant already holds, or releasing one it does not hold, MUST change nothing and MUST NOT cause a re-render.
- **claim-withdraw-own**: A claimant's release MUST remove only its own claim, so a closing pane never strips a control from the pane now open.
- **host-published**: The provider MUST publish a host holding both slot elements, both owners and the claim function, and MUST keep the host object stable while none of those change.
- **portal-claims**: A portal MUST claim its kind when it mounts inside a provider and release it when it unmounts or its kind changes.
- **portal-id**: A portal MUST identify itself to the claim system with an id unique to that portal instance.
- **portal-renders-in-slot**: A portal MUST render its children into the slot of its kind, through a portal, only while it is the owner and the slot element exists.
- **portal-yields**: A portal that is not the owner MUST render nothing, so one header never shows two API buttons or two help buttons.
- **portal-inline**: A portal outside any provider MUST render its children inline, where it is declared.
- **has-header-hook**: `useHasDetailHeader` MUST return true inside a provider and false outside one.
- **header-hook**: `useDetailHeader` MUST return the nearest provider's host, or null outside any provider.
- **disabled-api-button**: The disabled API button MUST be a disabled outline button of the extra-small size, a code icon (14px, hidden from assistive technology) and the text "API".
- **disabled-api-name**: The disabled API button's accessible name MUST be `API — ` followed by the reason, defaulting to "This view has no API endpoint".
- **disabled-api-tooltip**: The disabled API button MUST show the reason as a tooltip on a wrapper element, because a disabled button swallows pointer events.
- **disabled-help-button**: The disabled help button MUST be a disabled plain button carrying a 16px question-circle icon, built from the shared quiet control style, at 40% opacity with a not-allowed cursor and no hover colour change.
- **disabled-help-name**: The disabled help button's accessible name MUST be `About this section — ` followed by the reason, defaulting to "No help for this view".
- **disabled-help-tooltip**: The disabled help button MUST show the reason as a tooltip on a wrapper element.
- **disabled-help-class**: The disabled help button MUST accept an extra `triggerClassName` that is merged last into its classes.

## Appearance

- **Row**: Flex row, items centred, 8px gap (`gap-2`), minimum height 2.15rem, 1px bottom border in the theme border color, background `bg-apt-nav`.
- **Lead cell**: 32px wide, centred contents, does not shrink.
- **Title**: The supplied cell, or an empty flexible spacer that fills the remaining width.
- **Slot group**: Flex row, centred, 4px gap, does not shrink; each slot box is itself a centred flex row.
- **Disabled API button**: Outline, extra-small `Button` with a 14px code icon and the text "API", disabled styling from the button.
- **Disabled help button**: 16px question-circle icon in the quiet control style, 40% opacity, not-allowed cursor.
- **Min/Max size**: Minimum height 2.15rem; the width is whatever the parent gives it.

## States

| State | Appearance change |
|-------|------------------|
| No claimant, in a provider | API slot shows the disabled API button; help slot shows `fallbackHelp` or the disabled help button |
| API claimed | API slot shows the claimant's control; the disabled API button is gone |
| Help claimed | Help slot shows the claimant's control; `fallbackHelp` and the disabled help button are gone |
| Two claimants of a kind | The later one holds the slot; the earlier one renders nothing |
| Claimant unmounts | The slot returns to the previous claimant of that kind, or to the fallback when there is none |
| Outside a provider | Row draws a disabled API button and a disabled help button, with no slot boxes |
| Actions present | The actions box appears immediately before the API slot |
| Hover | Not applicable for the row; the disabled buttons have no hover change |
| Focused (keyboard) | Not applicable for the disabled buttons, which are not focusable; claimed controls bring their own focus style |
| Pressed (active) | Not applicable: the block defines no `:active` style |
| Loading | Not applicable: the block has no loading state |

## Accessibility

- **disabled-reason-in-name**: A disabled control MUST carry its reason in its accessible name (`API — This view has no API endpoint`, `About this section — No help for this view`), so a screen-reader user hears why it is unavailable.
- **tooltip-on-wrapper**: The reason MUST also be a tooltip, placed on a wrapper, because a disabled button receives no pointer events.
- **icon-decorative**: The code icon on the disabled API button MUST be hidden from assistive technology, and the text "API" carries the meaning.
- **disabled-skipped**: The disabled buttons are native disabled buttons and MUST be skipped by the Tab order.
- **claimed-controls**: A claimed control keeps whatever role and name its claimant gives it; the block adds no semantics around the slots.
- **header-landmark**: NEEDS REVIEW: Not implemented in source. The row is a plain `div` with no heading or landmark role, so assistive technology gets no region named for the header; settling it needs a decision on whether the title cell carries the heading and whether the row should be a `header` landmark.
- **touch-target-size**: NEEDS REVIEW: Not implemented in source. The disabled help button is a 16px icon in the quiet control style and the API button is the extra-small size; both disabled, but claimed controls reuse the same slot and any enabled control placed there inherits a small header. Settling it needs the rendered size of the quiet control and extra-small button at the production theme and a decision on the platform minimum for header controls.
- **contrast-ratio**: NEEDS REVIEW: Not implemented in source. The disabled controls are drawn at reduced opacity on `bg-apt-nav`; disabled controls are exempt from contrast requirements, but the enabled claimed controls are not, and whether the theme tokens meet 3:1 needs measured values.

## Conformance Test Vectors

Vectors dh-001 to dh-003 are derived from `detailHeaderActions.test.tsx`, which checks that `detailActions` lands inside `[data-slot="detail-header"]` immediately before `[data-adh-detail-api-slot]`, with no toolbar strip and exactly one link. The remaining vectors follow from the source; `PersonaEditor.test.tsx`, `buttonBarApiSlot.test.tsx` and `detailTitle.test.tsx` use the block through their panes.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dh-001 | actions-box, row-hook, slot-order (test: detail actions land in the header) | Provider with `actions` holding one link, a row | The actions box is inside `[data-slot="detail-header"]` and immediately precedes `[data-adh-detail-api-slot]` |
| dh-002 | actions-box (test: no toolbar strip) | Same | No separate toolbar strip exists above or beside the row |
| dh-003 | actions-box (test: exactly one link) | Same | Exactly one link is in the document |
| dh-004 | api-fallback, help-fallback | Provider, no claimants, no `fallbackHelp` | API slot holds a disabled API button; help slot holds a disabled help button |
| dh-005 | help-fallback | Provider with `fallbackHelp` set, no claimants | Help slot holds `fallbackHelp`, not the disabled help button |
| dh-006 | portal-claims, portal-renders-in-slot | Provider; a portal of kind api with a button | The button is inside `[data-adh-detail-api-slot]`; the disabled API button is gone |
| dh-007 | last-claimant-wins, portal-yields | Two api portals mounted in order A then B | Only B's control is in the slot; A renders nothing; exactly one API control is present |
| dh-008 | claim-withdraw-own | A then B mounted; B unmounts | A's control reappears in the slot |
| dh-009 | claim-withdraw-own | A then B mounted; A unmounts | B's control stays in the slot |
| dh-010 | portal-claims | The only api portal unmounts | The disabled API button returns |
| dh-011 | portal-inline, has-header-hook, header-hook | A portal and a hook probe outside any provider | The portal's children render inline; `useHasDetailHeader` is false; `useDetailHeader` is null |
| dh-012 | has-header-hook, header-hook | The same probe inside a provider | `useHasDetailHeader` is true; `useDetailHeader` returns a host |
| dh-013 | no-provider-fallback | A row outside any provider | A disabled API button and a disabled help button; no `data-adh-detail-api-slot` |
| dh-014 | actions-omitted | `actions` is undefined, then null, then false | No actions box in any case |
| dh-015 | lead-optional, lead-cell, row-padding | `lead` given with `leadCell`; then without `leadCell`; then no lead | Lead in a 32px cell with right padding only; lead inline with side padding; no lead and side padding |
| dh-016 | title-cell, title-spacer | A row with `title`; then without | The title cell is rendered in the row; then an empty flexible spacer |
| dh-017 | disabled-api-name, disabled-api-tooltip | `DisabledApiButton` with no reason; then reason "Pick an endpoint" | Name and tooltip read "API — This view has no API endpoint" and "This view has no API endpoint"; then "API — Pick an endpoint" and "Pick an endpoint" |
| dh-018 | disabled-help-name, disabled-help-tooltip, disabled-help-class | `DisabledHelpButton` with no reason and `triggerClassName="x"` | Name "About this section — No help for this view"; tooltip "No help for this view"; the button's classes include "x" |
| dh-019 | slots-are-state, portal-renders-in-slot | A portal mounted in the same commit as the provider | The control reaches the slot after the slot element mounts (it does not stay invisible) |
| dh-020 | claim-idempotent | Claim the same id and kind twice, release an unheld id | The claim list is unchanged; no extra re-render |
| dh-021 | claim-by-kind | One api claimant and one help claimant | Each slot holds its own claimant's control; the kinds do not interfere |
| dh-022 | portal-claims | A portal's `kind` prop changes from api to help | The api claim is released and the help claim is made |

## Edge Cases

- **Two claimants of a kind**: The later claimant holds the slot and the earlier renders nothing. See dh-007.
- **Closing pane**: When the claimant that holds a slot unmounts, the slot returns to the previous claimant, not to the fallback, as long as one remains. See dh-008.
- **Claimant mounted before the slot exists**: The slot is state, not a ref, so the provider re-renders when the slot element mounts and the portal then draws. See dh-019.
- **Outside any provider**: Portals render inline and the row draws disabled buttons; nothing throws. See dh-011 and dh-013.
- **No title**: An empty flexible spacer keeps the slots on the far right. See dh-016.
- **Empty actions**: Undefined, null and false draw no box; the number 0 and the empty string are not excluded by the check and draw an empty or text box.
- **Fallback help is null**: `fallbackHelp` of null or undefined falls through to the disabled help button, because the fallback uses nullish coalescing.
- **Unstable `actions` or `fallbackHelp`**: Both are in the provider's state memo, so a new element each render republishes the context to every consumer each render; hosts that care should keep them stable.
- **Same id claimed twice**: A repeated claim or release is a no-op and causes no render. See dh-020.
- **Concurrent access**: Claims are held in React state and updated by a functional update, so simultaneous claims and releases within one commit are applied in order and none is lost.
- **Error states and offline**: Not applicable: the block makes no network or storage calls; a claimed control's own errors belong to its claimant.

## Configuration

`DetailHeaderProvider`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `fallbackHelp` | `ReactNode` | `undefined` | The stack's own help, shown in the help slot while no pane claims it. |
| `actions` | `ReactNode` | `undefined` | Controls about the whole view, drawn just left of the API and help pair on every header row the stack draws; not claimable. |
| `children` | `ReactNode` | (required) | Everything the stack draws, so panes below can claim the slots. |

`DetailHeaderRow`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `lead` | `ReactNode` | `undefined` | The stack's control for the detail: a cover toggle or a Back button. |
| `leadCell` | `boolean` | `false` | Seats `lead` in a fixed 32px wide cell so a cover toggle lines up with the rails' toggles. |
| `tools` | `ReactNode` | `undefined` | The stack's other controls for the detail, beside `lead` (such as the cover-all control). |
| `title` | `DetailStripTitle` | `undefined` | Names what the detail shows; its `cell` is a pane's hoisted title or the stack's own. |

`DetailHeaderPortal`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `kind` | `"api" \| "help"` | (required) | Which slot to claim. |
| `children` | `ReactNode` | (required) | The control to draw in the slot. |

`DisabledApiButton`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `reason` | `string` | "This view has no API endpoint" | Tooltip and the tail of the accessible name. |

`DisabledHelpButton`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `reason` | `string` | "No help for this view" | Tooltip and the tail of the accessible name. |
| `triggerClassName` | `string` | `undefined` | Extra classes merged last into the button. |

The constants `NO_API_ENDPOINT` and `NO_HELP` hold the two default reasons. `DetailHeaderHost` has `apiSlot`, `helpSlot`, `apiOwner`, `helpOwner` and `claim(id, kind, claimed)`.

## Deep Linking

Not applicable: the block is a layout and claim mechanism with no route; the pages and panes that use it own their URLs.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `detail_header.no_api_endpoint` | "This view has no API endpoint" | Default reason for the disabled API button |
| `detail_header.no_help` | "No help for this view" | Default reason for the disabled help button |
| `detail_header.api_label` | "API" | Visible text of the disabled API button |
| `detail_header.api_disabled_name` | "API — {reason}" | Accessible name of the disabled API button |
| `detail_header.help_disabled_name` | "About this section — {reason}" | Accessible name of the disabled help button |

The accessible names are built by concatenating an English prefix, an em dash and the reason, so a translator cannot reorder them. The two reasons are overridable through props; the prefixes and the "API" text are not. The row uses `pr-2` and `px-2` plus a left-to-right order of lead, tools, title and slots, with no logical-direction classes beyond those, so a right-to-left layout would draw the slots at the physical right edge unless the host mirrors the row.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the source defines no animation or transition. |
| Increase Contrast | Not handled: no contrast-preference branch; disabled controls rely on opacity. |
| Differentiate Without Color | The disabled state is carried by the native disabled attribute, the not-allowed cursor and the reason in the name, not by hue. |

## Feature Flags

Not applicable: the source has no flag lookup.

## Analytics

Not applicable: the source emits no events.

## Privacy

- **Data collected**: None.
- **Storage**: None; the claims are in-memory component state.
- **Transmission**: None.
- **Retention**: None.

## Logging

Not applicable: the source performs no logging.

## Platform Notes

- **SwiftUI**: Source platform is web, so this is translation guidance. Replace the portal with SwiftUI preferences: a `PreferenceKey` per kind whose reduce keeps the last value, and `.overlayPreferenceValue` or `.onPreferenceChange` at the header to read the winning control, which gives last-claimant-wins for free. The row is an `HStack(spacing: 8)` with a `frame(minHeight: 34)`, a `Divider` (or bottom border overlay) and a background colour. The fallbacks are `Button` views with `.disabled(true)`, `.help(reason)` and `.accessibilityLabel("API — \(reason)")`.
- **Compose**: Use a `CompositionLocal` holding a small state object (`mutableStateListOf` of claimant ids per kind) and a `DisposableEffect` keyed on a remembered id for claim and release, matching **portal-claims**. The control is rendered by the header reading the last claimant's `@Composable` lambda out of that state; there is no portal, so store the lambda with its id. The row is a `Row` with `Modifier.heightIn(min = 34.dp)` and a bottom border drawn with `drawBehind`. The fallbacks are `OutlinedButton(enabled = false)` and `IconButton(enabled = false)` with `Modifier.semantics { contentDescription = ... }`; tooltips use `TooltipBox`.
- **React/Web**: `packages/web/packages/ui/src/blocks/detail-header.tsx`, a client component using React context, `createPortal` from `react-dom`, `useId`, `useCallback`, `useMemo` and `useState`; the buttons use `Button`, `quietControlClass`, `cn` and lucide `Code2` and `CircleHelp`, and the title type comes from `./detail-title`. It is used by `hierarchical-topic-detail.tsx` and `hierarchical-menu-detail.tsx` (which draw the row and mount the provider) and by panes such as the resource detail header actions, `PersonaEditor` and the integrations and messaging panes (which claim slots).
- **AppKit / UIKit**: On macOS use an `NSToolbar` or a custom `NSStackView` header, with the two slots as `NSStackView` arranged-subview placeholders and a small coordinator object that keeps an ordered array of claimants per kind and installs the last one's view; the fallbacks are `NSButton`s with `isEnabled = false` and `toolTip`. On iOS use a `UIStackView` header with the same coordinator, fallbacks as `UIButton`s with `isEnabled = false`, `accessibilityLabel` of "API — reason", and a pointer-hover `UIToolTipInteraction` or a long-press hint for the tooltip.
- **WinUI 3**: Build the row as a `Grid` with `MinHeight="34"`, `BorderThickness="0,0,0,1"`, `BorderBrush="{ThemeResource DividerStrokeColorDefaultBrush}"` and `Background="{ThemeResource LayerFillColorDefaultBrush}"`, three columns `Auto` (lead and tools in a `StackPanel Orientation="Horizontal"`), `*` (the title cell, or an empty `Border`) and `Auto` (a horizontal `StackPanel Spacing="4"` holding actions, then two `ContentPresenter` slots named `ApiSlot` and `HelpSlot`). Claims live in a `HeaderClaimService` held in a resource or injected `DataContext`, which keeps an ordered list of owner ids per kind and sets each `ContentPresenter.Content` to the last claimant's control, clearing it to the fallback when the list empties. The fallbacks are `Button` with `IsEnabled="False"` and `ToolTipService.ToolTip` on an enclosing `Border`, because a disabled `Button` does not show its own tooltip on pointer hover; set `AutomationProperties.Name="API — reason"`. The visual states are the stock `Button` states, and the disabled state's `Opacity` is set to 0.4 for the help icon through a `VisualState` setter on `Disabled`. `AutomationProperties.AccessibilityView="Raw"` hides the code icon, and the `Grid` can take `AutomationProperties.LandmarkType="Custom"` if the header-landmark question is settled in favor of a landmark.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/detail-header.tsx` | confirmed (1.0.1) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Panes claim a slot and portal their control into the header rather than the stack drawing the control.
**Rationale**: The source explains that the pane that knows the endpoint and the help text is several components below the stack that draws the header, so the pane claims a slot and portals in; the stack cannot know either.
**Approved**: pending

**Decision**: The last claimant of a kind wins, and an unmount withdraws only its own claim.
**Rationale**: The source says this is the same rule as the detail title, and it keeps a closing pane from stripping the header out from under the pane now open; it also guarantees one header never shows two API buttons.
**Approved**: pending

**Decision**: The two slot elements are held in state, not in refs.
**Rationale**: The source explains that a ref lands during commit without a re-render, so the provider would publish null on the mount that matters and every claimant would stay invisible.
**Approved**: pending

**Decision**: Every header always draws the API and help pair, disabled with a stated reason when nothing is claimed.
**Rationale**: The source says every header keeps the same `[API][?]` shape on its right and says why there is nothing to open, so the layout never shifts and the user is told why a control is unavailable.
**Approved**: pending

**Decision**: The disabled tooltips sit on a wrapper element, and the reason is repeated in the accessible name.
**Rationale**: The source comment states that a disabled button swallows pointer events, so the tooltip lives on a wrapper; the reason in the name is what a screen-reader user hears in place of the tooltip.
**Approved**: pending

**Decision**: The stack's `actions` live in their own box and are not claimable.
**Rationale**: The source says the stack that owns the view owns these, so no pane below can displace them, and a server-rendered node arrives as a child of a client component, which React flagged as a keyless list child when it sat bare beside the two slots.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Screen-reader support is partial because disabled controls carry their reason in the name but the row exposes no landmark or heading (see the open question on `header-landmark`). Keyboard passes because every control is a native button and the disabled ones are skipped. Semantic-markup is partial for the same landmark reason. Touch-target-size and contrast-ratio are partial because the sizes and token values are not in this source (see the open questions on `touch-target-size` and `contrast-ratio`). The two string checks fail because the "API" text, the name prefixes and the default reasons are English literals, with only the reasons overridable; rtl-layout-support is partial because the row relies on physical padding and a fixed left-to-right order. Separation-of-concerns passes because the block owns only slots and claims, while panes own the controls and the stack owns the row's contents. Unit-test-coverage passes: `detailHeader.test.tsx` carries a test for every vector (dh-001 to dh-022), covering claim ordering, withdrawal, the no-provider fallbacks, the disabled buttons and the row layout, and `detailHeaderActions.test.tsx` covers the actions box through real stacks.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (detailHeader.test.tsx, 22 of 22 vectors); unit-test-coverage now passed. |
