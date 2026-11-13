---
id: d0cf136a-26ed-4a69-a440-4d056795601e
title: "Privacy Level Select"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Controlled dropdown component for selecting privacy level (only-me, hub, or public) with keyboard navigation and popover UI."
platforms:
  - typescript
  - web
tags:
  - privacy
  - select
  - dropdown
  - popover
  - listbox
depends-on:
  - c61a220c-b63e-4dcd-a12b-715de20f7b5d
  - 2cfe57f0-cdd4-4723-a6e0-2ce4f136ce7f
  - 0f5b7167-b375-4f44-977b-566f720a453d
related: []
references: []
approved-by: ""
approved-date: ""
---

# Privacy Level Select

## Overview

Privacy Level Select is a controlled form component that allows users to choose a privacy level from three options: "Only me" (private to user), "Hub members" (visible to organization members), or "Public" (visible to internet). The component renders a button trigger displaying the current selection and icon, with a popover menu containing the full list. A fourth disabled option ("Team / Org") signals upcoming functionality. The component manages keyboard navigation internally and requires the parent to handle privacy persistence via the `onChange` callback.

## Behavioral Requirements

- **render-trigger-with-current-level**: Component MUST display a button trigger showing the current privacy level's label and icon.
- **render-chevron-icon**: Component MUST display a chevrons-up-down icon (14px) in the trigger, right-aligned, to indicate expandable state.
- **open-popover-on-trigger-click**: Component MUST open the popover menu when the user clicks the trigger button.
- **close-popover-on-selection**: Component MUST close the popover and call `onChange` with the selected level when the user clicks or activates an option.
- **close-popover-on-escape**: Component MUST close the popover when the user presses the Escape key while focused on the listbox.
- **navigate-with-arrow-keys**: Component MUST move focus through options when the user presses ArrowUp or ArrowDown while the popover is open.
- **clamp-navigation-at-bounds**: Component MUST prevent cursor movement beyond the first and last navigable option (only-me, hub, public); the disabled "Team / Org" option MUST NOT be reachable via arrow keys.
- **select-with-enter-or-space**: Component MUST select the currently highlighted option when the user presses Enter or Space while the popover is open.
- **open-popover-with-trigger-keys**: Component MUST open the popover when the user presses ArrowDown, Enter, or Space while focused on the trigger and the popover is closed.
- **display-all-three-enabled-options**: Component MUST render exactly three selectable options: "Only me" (Lock icon), "Hub members" (Users icon), and "Public" (Globe icon), each with a label and description.
- **show-check-on-selected-option**: Component MUST display a gold check mark icon (14px) only on the currently selected option.
- **display-disabled-coming-soon-option**: Component MUST display a fourth option "Team / Org" marked as disabled and visually distinct (40% opacity), with a "Coming soon" badge and description "Visible to members of your organization".
- **highlight-hovered-option**: Component MUST apply a background highlight when the user hovers over an option.
- **highlight-keyboard-focused-option**: Component MUST apply a background highlight to the option currently pointed to by keyboard navigation (cursor state).
- **respect-disabled-prop**: Component MUST prevent opening the popover and make the trigger non-interactive when `disabled={true}`.
- **apply-disabled-styling**: Component MUST render the trigger with reduced opacity (50%) and a `not-allowed` cursor when disabled.
- **focus-listbox-on-open**: Component MUST move focus to the internal listbox surface when the popover opens.
- **reset-cursor-to-value-on-open**: Component MUST set the keyboard cursor to the currently selected level when the popover opens.
- **initialize-null-cursor-to-first-option**: The `move` function seeds a null cursor at index `0`, then applies the arrow's delta (`Math.min(navLevels.length - 1, Math.max(0, idx + delta))`), so if `move` ever ran while `cursor` was still `null`, ArrowDown would move it to the second navigable option (`hub`), and only ArrowUp would move it to the first (`only-me`) — not both directions landing on `only-me`. This path is unreachable through the UI: **reset-cursor-to-value-on-open** sets `cursor` to `value` in the same synchronous handler that sets `open` to `true`, and the listbox surface this component's keydown handler is attached to is unmounted while the popover is closed (the Popover this component composes is the full-featured variant, whose `PopoverContent` MUST be removed from the DOM when closed — see requirements/hide-on-close-unmount ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))) — so there is no closed-popover state in which a keyboard user can focus the listbox and press an arrow key with `cursor` still `null`.
- **read-value-prop**: Component MUST use the `value` prop to determine the current selection and update all visual and focus indicators when `value` changes.
- **call-onchange-with-selected-level**: Component MUST call the `onChange` callback with a `PrivacyLevel` value ('only-me', 'hub', or 'public') when the user commits a selection.
- **support-aria-label**: Component MUST accept an `ariaLabel` prop and apply it to the trigger and listbox for accessible naming.
- **apply-aria-haspopup**: Component MUST set `aria-haspopup="listbox"` on the trigger to indicate a listbox menu is available.
- **apply-aria-expanded**: Component MUST set `aria-expanded` to `true` on the trigger when the popover is open and `false` when closed.
- **apply-aria-activedescendant**: Component MUST set `aria-activedescendant` on the listbox to the ID of the currently highlighted option when the popover is open.
- **apply-role-listbox**: Component MUST set `role="listbox"` on the popover surface to identify it as a listbox container.
- **apply-role-option-to-entries**: Component MUST set `role="option"` on each option (both enabled and disabled) to identify them as listbox options.
- **set-aria-selected**: Component MUST set `aria-selected="true"` on the currently selected option and `aria-selected="false"` on all others.
- **set-aria-disabled-on-coming-soon**: Component MUST set `aria-disabled="true"` on the disabled "Team / Org" option.
- **support-custom-class-name**: Component MUST accept a `className` prop and merge it with the trigger's default classes so caller-provided classes are added to, not swapped in for, the defaults.
- **prevent-default-on-trigger-keys**: Component MUST suppress the browser's default handling of ArrowDown, Enter, and Space when they are used to open the popover from the trigger.
- **prevent-default-on-navigation-keys**: Component MUST suppress the browser's default handling of ArrowUp, ArrowDown, Enter, Space, and Escape while the popover is open (so, for example, the page does not scroll).
- **use-unique-option-ids**: Component MUST generate unique HTML IDs for each option so ARIA linking (`aria-activedescendant`, the option's own `id`) stays correct when multiple instances of the component render on the same page.
- **truncate-trigger-text**: Component MUST truncate the label text in the trigger to prevent horizontal overflow; the icon MUST NOT shrink or be truncated.

## Appearance

- **Trigger Button**:
  - Height: 36px (h-9)
  - Width: full parent width
  - Padding: 12px horizontal, vertical centered (px-3)
  - Font: 14px (text-sm), medium weight for label
  - Background: transparent (input base style from `fieldShellClass`)
  - Foreground/Text: `apt-text` (primary text color)
  - Border: 1px solid `apt-border` (from `fieldShellClass`)
  - Hover: border color lightens to `apt-border-strong`
  - Focus-visible: 2px ring of `apt-gold/25` with border color `apt-gold`
  - Disabled: opacity 50%, cursor not-allowed
  - Gap between content: 8px (gap-2)
  
- **Trigger Content Layout**:
  - Left section: icon (14px, `apt-text-muted` color) + label text
  - Right section: chevron icon (14px, `apt-text-muted` color)
  - Content shrinks but does not wrap; icon remains visible on truncate
  
- **Popover**:
  - Width: 288px (w-72)
  - Padding: 4px (p-1) — options define their own padding
  - Align: start (matches trigger left edge)
  - Background: inherits from Popover component
  
- **Option Button**:
  - Height: auto (py-2)
  - Width: full popover width
  - Padding: 8px horizontal, 8px vertical (px-2 py-2)
  - Border-radius: 6px (rounded-md)
  - Font: 14px (text-sm) for label; 12px for description
  - Label font-weight: medium
  - Label color: `apt-text`
  - Description color: `apt-text-dim` (lighter)
  - Gap between icon and content: 8px (gap-2)
  - Highlighted background: `apt-highlight/15` (15% opacity of highlight color)
  - Text alignment: left
  - Cursor: pointer
  
- **Option Icons**:
  - All icons: 14px (size-[14px])
  - Padding-top: 4px (mt-0.5) to optical center align with text baseline
  - Label icon and privacy icon: `apt-text-muted` color
  - Check icon: gold (`apt-gold`) when checked, otherwise opacity-0
  - Coming-soon option: all icons and text at 40% opacity

- **Coming Soon Badge**:
  - Variant: blue
  - Rendered inline with "Team / Org" label

## States

| State | Appearance change |
|-------|------------------|
| Default | Trigger shows current selection with icon, chevron; popover closed |
| Hover (trigger) | Border color lightens to `apt-border-strong`; cursor pointer |
| Focus (trigger) | 2px ring of `apt-gold/25`, border turns `apt-gold` |
| Open | Popover displayed; trigger `aria-expanded="true"` |
| Keyboard-highlighted option | Option background: `apt-highlight/15`; `aria-activedescendant` points to option ID |
| Hovered option | Option background: `apt-highlight/15` (same as keyboard highlight) |
| Selected option | Check mark visible and gold; icon color `apt-gold` on check |
| Disabled (component) | Trigger opacity 50%, cursor not-allowed, popover will not open |
| Disabled option (Team/Org) | Entire option row at 40% opacity, not keyboard-navigable, `aria-disabled="true"` |

## Accessibility

- **Role**: The trigger is a button with `aria-haspopup="listbox"` and `aria-expanded` state. The popover surface is a `role="listbox"`. Each option is `role="option"`.
- **Labeling**: The component accepts `ariaLabel` (default: "Privacy level") applied to both trigger and listbox. Required for screen reader users to understand the control's purpose.
- **Keyboard navigation**: Arrow Up/Down (navigate options), Enter/Space (select), and Escape (close) are implemented, and ArrowDown/Enter/Space on the trigger open the menu from a closed state. Disabled options are skipped by arrow key navigation. Home/End, letter typeahead, opening via ArrowUp on the trigger, and any custom Tab/blur handling are not implemented — Tab and blur fall through to the browser's native focus handling (see Design Decisions: partial APG listbox keyboard support).
- **Focus management**: Focus moves to the listbox surface when the popover opens (this component's own behavior), and the keyboard cursor initializes to the current value on open. The focused option receives `aria-activedescendant` linking. The popover is non-modal and does not trap focus; returning focus to the trigger when it closes is provided by the Popover component this recipe composes, not implemented here — see accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)).
- **Visual indicators**: Selected option shows a check mark. Highlighted/hovered option shows background color change. Disabled state uses opacity and cursor styling. Focus ring on trigger uses a 2px gold ring.
- **Touch target size**: Option rows are auto-height, not fixed to a minimum. A single 14px/20px line of label text plus 16px of vertical padding (8px top + 8px bottom) yields an actual row height of about 36px — below the 44pt (Apple) / 48dp (Material) guideline; rows that also show a description line are taller in practice, but this has not been measured. See **touch-target-size** in Compliance (`partial`).
- **Screen reader announcements**: Check mark is `aria-hidden="true"` (visual only). All icons are `aria-hidden="true"`. Option descriptions are visible text (not hidden). Disabled affordance is a `div` with `role="option"` and `aria-disabled="true"` so it is announced as disabled and not keyboard-reachable.
- **Color contrast**: Icon colors (`apt-text-muted`) are muted; descriptions use `apt-text-dim` (dimmer). The component relies on the design system's token values to meet WCAG AA contrast; the actual computed contrast ratio of the gold check icon against the `apt-highlight/15` background is not verified from this source. See **contrast-ratio** in Compliance (`partial`).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| privacy-001 | render-trigger-with-current-level | value="only-me" | Trigger displays "Only me" text |
| privacy-002 | render-chevron-icon | Component mounted | Trigger displays chevrons-up-down icon (14px, right-aligned) |
| privacy-003 | open-popover-on-trigger-click | User clicks trigger, popover closed | Popover opens; aria-expanded="true" on trigger |
| privacy-004 | close-popover-on-selection | User clicks "Hub members" option, popover open | Popover closes; onChange called with "hub"; aria-expanded="false" on trigger |
| privacy-005 | close-popover-on-escape | Popover open, user presses Escape | Popover closes; aria-expanded="false" |
| privacy-006 | navigate-with-arrow-keys | Popover open, cursor on "hub", user presses ArrowDown | Cursor moves to "public"; aria-activedescendant updates to "public" option ID |
| privacy-007 | clamp-navigation-at-bounds | Popover open, cursor on "public", user presses ArrowDown | Cursor stays on "public"; does not move to disabled "Team / Org" option |
| privacy-008 | select-with-enter-or-space | Popover open, cursor on "only-me", user presses Enter | Popover closes; onChange called with "only-me" (and nothing else) |
| privacy-009 | open-popover-with-trigger-keys | Trigger focused, popover closed, user presses Space | Popover opens; aria-expanded="true"; cursor initializes to current value |
| privacy-010 | display-all-three-enabled-options | Popover open | Three clickable options rendered: "Only me", "Hub members", "Public" |
| privacy-011 | show-check-on-selected-option | value="hub", popover open | Check icon (gold, 14px) visible only on "Hub members" option |
| privacy-012 | display-disabled-coming-soon-option | Popover open | "Team / Org" option rendered with 40% opacity and "Coming soon" badge |
| privacy-013 | highlight-hovered-option | Popover open, user hovers on "public" option | Option background changes to `apt-highlight/15` |
| privacy-014 | highlight-keyboard-focused-option | Popover open, cursor on "hub" via arrow navigation | Option background changes to `apt-highlight/15` |
| privacy-015 | respect-disabled-prop | disabled={true}, user clicks trigger | Popover does not open; onChange is not called |
| privacy-016 | apply-disabled-styling | disabled={true} | Trigger renders with opacity 50%, cursor not-allowed |
| privacy-017 | focus-listbox-on-open | User opens popover via trigger click | Listbox surface receives focus (can accept keyboard input immediately) |
| privacy-018 | reset-cursor-to-value-on-open | value="public", user clicks trigger to open | Cursor initializes to "public" option (keyboard can select immediately without navigation) |
| privacy-019 | initialize-null-cursor-to-first-option | Cursor forced to null, `move(1)` (ArrowDown) invoked directly against the null-cursor branch | Cursor becomes the second option ("hub"), not "only-me"; `move(-1)` (ArrowUp) from the same null cursor becomes the first option ("only-me") instead — this branch is unreachable through the UI (see Edge Cases) |
| privacy-020 | read-value-prop | value prop changes from "only-me" to "public" externally | Trigger updates to show "Public"; all visual indicators update |
| privacy-021 | call-onchange-with-selected-level | User clicks "hub" option | onChange callback invoked with argument "hub" (string, not object) |
| privacy-022 | support-aria-label | ariaLabel="Profile visibility", rendered | Trigger and listbox both have aria-label="Profile visibility" |
| privacy-023 | apply-aria-haspopup | Component rendered | Trigger element has aria-haspopup="listbox" |
| privacy-024 | apply-aria-expanded | Popover open | Trigger has aria-expanded="true"; when closed, aria-expanded="false" |
| privacy-025 | apply-aria-activedescendant | Popover open, cursor on "hub" | Listbox has aria-activedescendant set to ID of "hub" option |
| privacy-026 | apply-role-listbox | Popover open | Listbox surface has role="listbox" |
| privacy-027 | apply-role-option-to-entries | Popover open | All four options (three enabled + "Team / Org") have role="option" |
| privacy-028 | set-aria-selected | value="only-me", popover open | "Only me" option has aria-selected="true"; others have aria-selected="false" |
| privacy-029 | set-aria-disabled-on-coming-soon | Popover open | "Team / Org" option has aria-disabled="true" |
| privacy-030 | support-custom-class-name | className="custom-class" prop passed | Trigger element includes custom-class in its className |
| privacy-031 | prevent-default-on-trigger-keys | Trigger focused, user presses ArrowDown to open | Browser default behavior is prevented; page does not scroll |
| privacy-032 | prevent-default-on-navigation-keys | Popover open, user presses ArrowUp | Browser default behavior is prevented; page does not scroll |
| privacy-033 | use-unique-option-ids | Component renders multiple times in a page | Each option ID is unique across all component instances |
| privacy-034 | truncate-trigger-text | Trigger width constrained, long label text | Label text truncates with an ellipsis; the icon does not shrink and remains fully visible |

## Edge Cases

- **Null/undefined value**: The component assumes `value` is always a valid `PrivacyLevel` ('only-me', 'hub', or 'public'). No guard against undefined or invalid values is present; the caller MUST provide a valid initial value.
- **Rapid onChange calls**: If parent rapidly updates `value` while the popover is open, the component updates the cursor and trigger display immediately without additional validation.
- **Disabled to enabled transition**: When `disabled` prop changes from `true` to `false`, the component becomes interactive immediately; the popover will open on next trigger click without resetting internal state.
- **Rapid open/close**: If the user rapidly toggles the popover (click trigger, click again), state changes propagate correctly; cursor is reset to current value each time the popover opens.
- **Focus loss before commit**: If the user navigates with arrow keys, then clicks outside the popover before selecting an option, the popover closes without calling `onChange` and the cursor state is discarded.
- **ArrowDown on trigger with closed popover**: User presses ArrowDown on trigger button — popover opens (does not scroll page). Same for Space and Enter.
- **Empty string or whitespace ariaLabel**: If `ariaLabel` is an empty string or whitespace, it is used as-is (no fallback validation); the component will render with that empty/whitespace label.
- **Multiple instances on same page**: Each instance uses `React.useId()` to generate unique IDs; options from different instances will not conflict in ARIA linkage or in the DOM.
- **Disabled option interaction**: The "Team / Org" option is not keyboard-navigable (arrow keys skip it) and has `role="option"` + `aria-disabled="true"` but is a `<div>`, not a button, so it is not clickable (no onClick handler, no pointer events enabled).
- **Hover during keyboard navigation**: If the user navigates with arrow keys while hovering, the highlight state is shared (same `apt-highlight/15` background); the visual result is the same whether cursor or hover caused it.
- **Window resize during popover open**: The Popover component (not this component) handles repositioning; this component makes no special handling.
- **Keyboard navigation null cursor recovery**: The `move` function's null-cursor branch seeds index 0 and then applies the delta, so a hypothetical ArrowDown with a null cursor would land on index 1 ("hub"), and ArrowUp would land on index 0 ("only-me") — not "only-me" for both directions. This branch cannot run through the UI: the listbox surface only exists while the popover is open, and `cursor` is already `value` (never `null`) by the time the popover opens, set in the same synchronous update that sets `open` to `true` — see **initialize-null-cursor-to-first-option**.

## Configuration

Not applicable: the component has no configuration options beyond its props (`value`, `onChange`, `ariaLabel`, `disabled`, `className`). All options, labels, descriptions, and icons are hardcoded.

## Deep Linking

Not applicable: the component is a form control, not a navigable view. Deep linking to privacy levels is the responsibility of the parent page or app.

## Localization

The source hardcodes every label, description, and badge string below as English, with no prop that lets a caller override them — see **string-externalization** and **no-hardcoded-strings** in Compliance (both `failed`). A localized implementation of this ingredient MUST externalize each of these to a locale-aware string resource; the keys below name what an implementation should externalize, using the source's current English text as the default.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `privacy_level_select.option.only_me.label` | Only me | Trigger and option label for the `only-me` level |
| `privacy_level_select.option.only_me.description` | Visible to you alone | Option description text |
| `privacy_level_select.option.hub.label` | Hub members | Trigger and option label for the `hub` level |
| `privacy_level_select.option.hub.description` | Visible to everyone on the Hub | Option description text |
| `privacy_level_select.option.public.label` | Public | Trigger and option label for the `public` level |
| `privacy_level_select.option.public.description` | Visible to anyone on the internet | Option description text |
| `privacy_level_select.option.team_org.label` | Team / Org | Disabled "coming soon" option label |
| `privacy_level_select.option.team_org.description` | Visible to members of your organization | Disabled option description |
| `privacy_level_select.badge.coming_soon` | Coming soon | Badge text on the disabled option |
| `privacy_level_select.aria_label.default` | Privacy level | Default accessible name for the trigger and listbox |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not implemented in source. The component uses no animations; transitions are applied by the Popover component (not in scope here). |
| Increase Contrast | Component relies on design system tokens (`apt-gold`, `apt-highlight`, `apt-text`, etc.) for contrast. If the design system provides high-contrast token overrides, the component will inherit them. No explicit contrast adjustments are coded in the component. |
| Differentiate Without Color | The selected state is indicated by a check mark icon (shape-based, not color-only) and position in the list. The disabled state uses opacity + text styling. Color is not the sole differentiator for any state. |

## Feature Flags

Not applicable: the component has no feature flags. All functionality (three privacy levels, keyboard navigation, popover) is always active when the component is mounted.

## Analytics

Not applicable: the component does not emit analytics events. Event tracking (selection changes, open/close) is the responsibility of the parent component's `onChange` handler and any custom event listeners attached by the consuming application.

## Privacy

- **Data collected**: None. The component does not collect, store, or transmit user data.
- **Storage**: No local storage, cookies, or session storage is used by this component.
- **Transmission**: No network requests or data transmission occurs. The component is purely presentational; the parent is responsible for transmitting the selected value to the backend. See the React/Web Platform Note for the level-to-integer mapping used in that payload.
- **Retention**: No data is retained by the component beyond the component's lifecycle.

## Logging

Not applicable: the component has no logging. Console or error tracking is the responsibility of the parent application.

## Platform Notes

- **SwiftUI**: A SwiftUI implementation would use `Menu` for the trigger/popover pairing, with one `Button` per option whose label is a custom `HStack` (a privacy-icon `Image`, a `VStack` of label + description `Text`, and a conditional checkmark `Image(systemName: "checkmark")`). The disabled "Team / Org" row uses `.disabled(true)` with the "Coming soon" text appended inline. `Menu` supplies its own keyboard handling (arrow-key traversal, Return to select, Escape to dismiss) wherever a hardware keyboard is present, so none of this component's key-event code carries over; VoiceOver announces each `Button` the way the ARIA `option`/`listbox` roles do on web.
- **Compose**: A Jetpack Compose implementation would use Material3's `ExposedDropdownMenuBox` for the trigger together with `DropdownMenu` / `DropdownMenuItem` for the option list — `leadingIcon` for the privacy icon, a `Column` of label + description `Text` composables for `text`, and a `trailingIcon` checkmark when selected. The disabled "Team / Org" item sets `enabled = false` on its `DropdownMenuItem` and appends the "Coming soon" text. `DropdownMenu` provides its own focus and directional-key handling; there is no separate "listbox" role to set — Compose's semantics tree exposes selection instead via `Modifier.semantics { selected = ... }`.
- **React/Web**: Source: `packages/web/packages/ui/src/components/privacy-level-select.tsx`. A controlled React component using `React.useState` for `open`/`cursor`, `React.useRef` for the listbox surface, and `React.useId()` to generate unique per-instance option IDs for ARIA linking. It delegates the popover surface to the `Popover` component ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)) and uses icons from `lucide-react`. Focus is moved to the listbox surface on open via `requestAnimationFrame(() => surfaceRef.current?.focus())`, deferring past the render that shows the popover. Every keyboard handler that this component owns calls `e.preventDefault()` on the keys it handles, to stop the browser's own scroll/default behavior. The trigger and option classes are composed with the `cn()` utility (`clsx` + `tailwind-merge`), so a caller's `className` merges with rather than replaces the defaults; trigger text truncation uses Tailwind's `truncate` utility. Two sibling exports in the same module handle the wire boundary but are not used by the component itself: `PRIVACY_LEVEL_FROM_WIRE(v)` fails closed to `'only-me'` for any unrecognized stored value, and `PRIVACY_AUDIENCE_MASK` maps a level to the integer the `PUT /account/privacy` payload expects.
- **AppKit / UIKit**: AppKit (macOS): use `NSPopUpButton` bound to an `NSMenu` whose `NSMenuItem`s each carry a custom `view` (icon + label + description) via `item.view`; the "Team / Org" item sets `isEnabled = false`. AppKit's menu supplies its own keyboard navigation (arrow keys, type-ahead, Return to select) and highlight rendering, so none of this component's key-event code carries over. UIKit (iOS): use `UIMenu` presented from a `UIButton` (`button.menu = menu; button.showsMenuAsPrimaryAction = true`), with one `UIAction` per option supplying an `image` for the icon and, on iOS 15+, a `subtitle` for the description; the disabled row sets `.attributes = [.disabled]`. Arrow-key navigation is a desktop/web-specific concept and does not apply to iOS touch or VoiceOver rotor interaction; accessibility is provided by `UIAccessibility`, not ARIA roles.
- **WinUI 3**: Use a single `DropDownButton` whose `Flyout` is a `MenuFlyout`, with one `MenuFlyoutItem` per option (an `Icon` for the privacy icon, `Text` for the label, and a second line for the description via a template override); draw the selected item's check indicator from that same template rather than relying on `RadioMenuFlyoutItem`'s built-in glyph, so the disabled row shares the same visual structure as the other three. The "Team / Org" item sets `IsEnabled="False"` and appends the "Coming soon" text. Open the flyout below and left-aligned with the trigger — matching `align="start"` below the trigger on web — via `Placement="BottomEdgeAlignedLeft"`, not `TopEdgeAlignedLeft` (which opens above the trigger). WinUI supplies its own keyboard navigation (Up/Down arrows, automatic focus management) and native disabled-item styling; ARIA roles/states map to WinUI's UIA patterns and properties.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/privacy-level-select.tsx` | unverified |

## Design Decisions

- **Decision**: The component hardcodes exactly three selectable privacy levels (only-me, hub, public) plus a fourth disabled "Team / Org" affordance, rather than accepting a dynamic list of options.
  **Rationale**: Privacy levels are a fixed, app-wide configuration unlikely to change at runtime. The fixed set also bakes in app-specific vocabulary ("Hub members") and a product roadmap item ("Team / Org — Coming soon"), so an app that needs different wording, or a different level set, needs its own fork or a prop-driven variant of this ingredient rather than the ability to reconfigure this one in place.
  **Approved**: pending

- **Decision**: An unrecognized value coming off the wire is converted to `only-me` by the wire-to-level conversion utility (`PRIVACY_LEVEL_FROM_WIRE`; see the React/Web Platform Note), rather than passed through or defaulted to `public`.
  **Rationale**: A deliberate fail-closed choice — a backend value this build doesn't recognize (a pre-migration row, a replica mid-deploy) renders as the most restrictive level rather than risking data exposed as public.
  **Approved**: pending

- **Decision**: The component keeps an internal `cursor` (keyboard-navigation focus) distinct from `value` (the committed selection), and resets `cursor` to `value` every time the popover opens.
  **Rationale**: Lets the user navigate options without committing a change until Enter/Space or a click, while always starting keyboard navigation from the currently selected option.
  **Approved**: pending

- **Decision**: If `disabled` becomes `true` while the popover is already open, the popover is left open; closing it on that transition was not implemented.
  **Rationale**: This is the source's actual behavior. Handling the disabled-while-open transition was left to the parent to manage (for example, by also controlling `open` externally) rather than building it into the component.
  **Approved**: pending

- **Decision**: Hovered and keyboard-focused options share the same highlight style (`apt-highlight/15`).
  **Rationale**: Keeps a single visual rule instead of two, and communicates that both interaction modes have the same effect; a user cannot tell which one produced the highlight.
  **Approved**: pending

- **Decision**: The `move` function's null-cursor branch is unreachable dead code, not a real keyboard-navigation contract: `cursor` is always `value` (never `null`) by the time the listbox surface can receive a keydown, and its direction math (seed at index 0, then apply the delta) would send ArrowDown to `hub` and ArrowUp to `only-me` if it ever ran, not both to `only-me`.
  **Rationale**: **reset-cursor-to-value-on-open** sets `cursor` to `value` in the same synchronous update that opens the popover, and the popover composes the full-featured Popover variant, whose listbox is unmounted while closed — so there is no reachable state where the listbox is focusable and `cursor` is still `null`. The branch is left in place as a defensive fallback rather than removed. See **initialize-null-cursor-to-first-option**.
  **Approved**: pending

- **Decision**: The popover panel has a fixed width of 288px (`w-72`) that does not respond to the trigger's width or the viewport.
  **Rationale**: Keeps the option descriptions wrapping consistently regardless of where the component is placed on the page.
  **Approved**: pending

- **Decision**: The options render as a custom ARIA `listbox` rather than a native `<select>`.
  **Rationale**: Each option is a rich row — an icon, a label, and a description line, plus a disabled "coming soon" row with a badge — that a native `<select>`'s `<option>` elements cannot render, so the custom listbox is the minimum needed to meet the visual requirement.
  **Approved**: pending

- **Decision**: The listbox implements only part of the APG listbox keyboard pattern — Arrow Up/Down, Enter/Space, and Escape — and leaves out Home/End, letter typeahead, opening via ArrowUp on the trigger, and any custom Tab/blur handling.
  **Rationale**: This is the implemented scope; Tab and blur fall through to the browser's native focus handling, and Home/End/typeahead were not built. See the Accessibility section's Keyboard navigation note for the resulting gap.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | partial | Accessibility |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | passed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | failed | Internationalization |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | Platform Compliance |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | partial | Platform Compliance |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`screen-reader-support`, `keyboard-navigable`, `semantic-markup`, `text-expansion-tolerance`, `unicode-support`, and `platform-design-language` pass because the source's ARIA roles/states, full Arrow/Enter/Space/Escape handling, unclipped wrapping option text, and plain JS-string label handling are all visible directly in `privacy-level-select.tsx`. `dynamic-type-support`, `contrast-ratio`, `touch-target-size`, and `focus-management` are `partial`: text sizes are rem-based Tailwind classes that scale with browser zoom but aren't verified against OS-level dynamic type; token colors are resolved outside this file; the actual option-row height (a 20px line plus 16px of padding, about 36px) falls under the 44pt/48dp guideline; and focus trapping plus return-to-trigger on close are delegated to the Popover component rather than implemented here. `string-externalization` and `no-hardcoded-strings` fail because every label, description, and badge string is hardcoded English with no override prop (see Localization); `rtl-layout-support` fails because the option rows use the literal `text-left` class instead of the logical `text-start`. `native-controls-preference` is `partial`: the component uses a custom ARIA listbox instead of `<select>`, which Design Decisions justifies with the rich icon+label+description rows a native control can't render. `PrivacyLevelSelect` is a presentational, controlled picker with no network calls — `onChange` is the caller's to wire up (separation-of-concerns passed); `privacy-level-select.test.tsx` exercises only the `PRIVACY_WIRE_VALUE`/`PRIVACY_LEVEL_FROM_WIRE`/`PRIVACY_AUDIENCE_MASK` conversion maps in the same file, not the component's own rendering, keyboard navigation, or selection commit (unit-test-coverage partial).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed every requirement to subject-only kebab-case and updated all citations across the test vectors, edge cases, and design decisions; rewrote several requirements platform-neutral and moved their implementation mechanics (`requestAnimationFrame`, `e.preventDefault()`, `React.useId()`, `cn()`) into the React/Web Platform Note; resolved the reset-cursor/null-cursor contradiction by renaming and grounding **initialize-null-cursor-to-first-option** instead of removing it; corrected privacy-008's expected outcome and the truncate-trigger-text wording; reformatted every Design Decision to Decision/Rationale/Approved and added ones justifying the custom listbox and the partial keyboard scope; rebuilt Compliance as a catalog table across Accessibility, Internationalization, and Platform Compliance, with touch-target, contrast, focus-management, and native-controls now `partial` and the hardcoded-string checks `failed`; replaced Localization's "Not applicable" with a string-key table; corrected the WinUI 3 note to one control and the right placement, rescoped the Android note to real Compose APIs, split AppKit and UIKit coverage, and added a true SwiftUI note; added `depends-on` citations for Popover, Badge, and Input; and left `modified` unquoted |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Fixed #requirements->#accessibility fragment link and rewrote null-cursor requirement/test vector/edge case to match unreachable-branch reality. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
