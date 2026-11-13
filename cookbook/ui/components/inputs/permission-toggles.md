---
id: 00f63479-58b8-47e3-9ac7-7f1b944a5007
title: "Permission Toggles"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Four-button toggle group for CRUD permissions, respecting parent capability ceilings."
platforms:
  - typescript
  - web
tags:
  - permissions
  - crud
  - toggle-group
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Permission Toggles

## Overview

A toggle button group for managing CRUD (Create, Read, Update, Delete) permissions. The component renders four independent toggle buttons, one for each permission type. When a parent permission context is provided, capabilities forbidden by the parent are rendered disabled and visually suppressed, preventing child permissions from exceeding parent permissions. The component emits permission changes via callback; the capability being toggled is always clamped to what the parent allows, but any other capability already present in `value` passes through the emitted object unchanged, even if it already violates `parent` (see **clamp-emitted-values**).

## Behavioral Requirements

- **render-four-buttons**: The component MUST render exactly four toggle buttons, one for each CRUD capability (Create, Read, Update, Delete).
- **enforce-parent-ceiling**: When a `parent` Crud value is provided, the component MUST prevent toggling any capability the parent disallows: the corresponding button MUST be rendered in a disabled state and MUST be visually suppressed (reduced opacity, `not-allowed` cursor), regardless of what `value` holds for that capability.
- **clamp-emitted-values**: The `onChange` callback MUST NOT invert a capability the parent disallows — clicking a parent-blocked button is a no-op and `onChange` is not called for it. This clamp applies only to the capability being toggled: if `value` already contains a capability that violates `parent` (set before mount, or never corrected), toggling a *different*, unblocked capability emits that pre-existing violation unchanged. The component does not retroactively clamp the rest of the object on every emit (see edge case "Value violates parent constraint before mount").
- **disabled-blocks-toggle**: When the `disabled` prop is true, toggling any button MUST have no effect and `onChange` MUST NOT be called.
- **toggle-on-click**: Clicking an enabled, unblocked button MUST invert the corresponding capability in the Crud value.
- **aria-pressed-reflects-on**: Each button MUST have an `aria-pressed` attribute that reflects the button's displayed `on` state (`value[key] && !blockedByParent`), not the raw `value[key]`. A capability blocked by the parent therefore reports `aria-pressed="false"` even when `value[key]` is `true`.
- **title-describes-action**: Each button MUST have a `title` attribute describing its action, built from the capability's raw key — `create`, `read`, `update`, or `delete` — never the single-letter label. When blocked by parent, the title MUST read "\<key\> is not permitted by the parent" (e.g. "create is not permitted by the parent"). When not blocked, the title MUST read "Enable \<key\>" or "Disable \<key\>" (e.g. "Enable create", "Disable read") based on current state.
- **group-role-and-label**: The container MUST have `role="group"` and `aria-label="CRUD permissions"` to announce the collection as a unified control group.
- **single-letter-labels**: Each button MUST display the single-letter label for its capability: C for Create, R for Read, U for Update, D for Delete.

## Appearance

- **Container**: Flex layout with horizontal direction, centered vertical alignment, 4px gap between buttons.
- **Button size**: 28×28px.
- **Border radius**: 6px.
- **Border width**: 1px.
- **Font**: weight 600 (semibold), size 12px.
- **Content alignment**: Label centered both horizontally and vertically within the button.
- **Transition**: Border, background, and text color animate on state change.

### Default (off) state colors:
- **Border**: `apt-border` token.
- **Background**: `apt-bg` token (full opacity).
- **Text**: `apt-text-muted` token.
- **Hover text**: `apt-text` token (brighter on hover).

### Enabled (on) state colors:
- **Border**: `apt-gold` token.
- **Background**: `apt-gold` token at 20% opacity.
- **Text**: `apt-gold-bright` token.

### Disabled or blocked state:
- **Cursor**: `not-allowed`.
- **Opacity**: 40% (0.4).
- **Hover text**: `apt-text-muted` (suppressed hover effect).

## States

| State | Appearance Change |
|-------|------------------|
| Off (default) | Muted text, neutral border and background. Hovering brightens text unless disabled. |
| On (enabled) | Gold border and semi-transparent gold background, bright gold text. |
| Disabled (global) | Reduced opacity (0.4), cursor-not-allowed. Hover effect suppressed. |
| Blocked by parent | Reduced opacity (0.4), cursor-not-allowed. Hover effect suppressed. Appears visually off regardless of value. |
| Focused | Receives focus via keyboard navigation. No special visual indicator in source; platform focus styles apply. |

## Accessibility

- **Role**: Each button is a standard `<button>` element. Container has `role="group"`.
- **Pressed state announcement**: Each button MUST use `aria-pressed` to announce whether the permission is enabled or disabled, per **aria-pressed-reflects-on** — the announced state follows the displayed `on` state, not the raw `value`.
- **Labels**: Each button has a visible single-letter label (C, R, U, D) and a `title` attribute providing context (see **title-describes-action**).
- **Keyboard navigation**: Buttons are focusable and activate on Space or Enter (native button behavior). A button that is disabled — globally or because the parent blocks it — uses the native `disabled` attribute, so it is also removed from the tab order; this is native `<button>` semantics, not a separate behavior of this component.
- **Group label**: The container's `aria-label="CRUD permissions"` announces the purpose of the group.
- **Disabled state announcement**: When a button is disabled (either globally or by parent), the native `disabled` attribute is what communicates unavailability to assistive technology — it removes the button from the accessibility tree and the tab order. The reduced opacity and `not-allowed` cursor are visual-only cues for sighted users; they do not themselves communicate anything to assistive technology.
- **minimum-tap-target**: NEEDS REVIEW: Not implemented in source. Buttons are fixed at 28×28px with no mechanism to grow them; Apple HIG and Material Design 3 recommend touch targets of at least 44×44pt / 48×48dp respectively, and whether 28×28px is acceptable for this component or must grow to the platform minimum is undecided (see Design Decision "28×28px button size" for the tradeoff).
- **Color dependency**: Enabled and disabled states are distinguished by color change and opacity. Differentiation also includes cursor style and text content, reducing reliance on color alone.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| perm-001 | render-four-buttons | `value={create: false, read: false, update: false, delete: false}` | Four buttons rendered, labeled C, R, U, D. |
| perm-002 | toggle-on-click | `value={create: false, read: false, update: false, delete: false}`, user clicks C button | `onChange` called with `{create: true, read: false, update: false, delete: false}`. |
| perm-003 | aria-pressed-reflects-on | C button with `value.create === true`, no `parent` | Button has `aria-pressed="true"`. |
| perm-004 | aria-pressed-reflects-on | C button with `value.create === false`, no `parent` | Button has `aria-pressed="false"`. |
| perm-005 | title-describes-action | C button enabled, `value.create === false` | Title reads "Enable create". |
| perm-006 | title-describes-action | C button enabled, `value.create === true` | Title reads "Disable create". |
| perm-007 | enforce-parent-ceiling | `parent={create: false, read: true, update: true, delete: true}`, user clicks C button | Button is disabled. `onChange` not called. |
| perm-008 | clamp-emitted-values | `parent={create: false, read: true, update: true, delete: true}`, `value={create: true, read: true, update: true, delete: true}`, user clicks R button | `onChange` called with `{create: true, read: false, update: true, delete: true}` — the pre-existing `create: true` violation of `parent` passes through unchanged; only the clicked capability (`read`) is inverted. |
| perm-009 | enforce-parent-ceiling | `parent={create: false, read: true, update: true, delete: true}` | C button has the `disabled` attribute set (not focusable, not clickable) and renders in the blocked visual state. |
| perm-010 | title-describes-action | C button blocked by parent | Title reads "create is not permitted by the parent". |
| perm-011 | disabled-blocks-toggle | `disabled={true}`, user clicks any button | No button responds. `onChange` not called. |
| perm-012 | group-role-and-label | Component rendered | Container has `role="group"` and `aria-label="CRUD permissions"`. |
| perm-013 | single-letter-labels | Component rendered | Buttons display text content C, R, U, D. |
| perm-014 | aria-pressed-reflects-on | `parent={create: false, read: true, update: true, delete: true}`, `value.create === true` | C button has `aria-pressed="false"` — it reflects the displayed `on` state, not the raw `value.create`. |
| perm-015 | enforce-parent-ceiling | `parent={create: false, read: false, update: false, delete: false}` | All four buttons render disabled. No click produces an `onChange` call. |
| perm-016 | clamp-emitted-values | `parent` omitted (`undefined`), user clicks any button | Button is enabled; the capability toggles normally; `onChange` called with only that capability inverted. |
| perm-017 | disabled-blocks-toggle, enforce-parent-ceiling | `disabled={true}` and the C button is also blocked by parent | Button is disabled by both conditions; behavior is identical to either condition alone. `onChange` not called. |
| perm-018 | toggle-on-click | `value={create: false, read: false, update: false, delete: false}`, user clicks C three times in rapid succession | `onChange` called three times, once per click, each call reflecting the click-time value of `create`; no debouncing. |
| perm-019 | toggle-on-click | Component unmounted while the border/background/text color transition is in progress | No error is thrown; the interrupted CSS transition has no observable effect on application state. |

## Edge Cases

- **Parent disallows all capabilities**: `parent={create: false, read: false, update: false, delete: false}`. All four buttons render disabled. User cannot enable any capability. `onChange` is never called. (perm-015)
- **Value violates parent constraint before mount**: `value={create: true, read: true, update: true, delete: true}` but `parent={create: false, read: true, update: true, delete: true}`. The component does not correct the value prop; it only prevents further violations via user interaction. The C button appears off due to the condition `on = value[key] && !blockedByParent`. The parent ceiling is enforced on toggle, not retroactively on render — see **clamp-emitted-values**. (perm-008)
- **Parent is undefined**: When `parent` is not provided, all capabilities are treated as unrestricted. `blockedByParent` is false for all buttons. (perm-016)
- **Disabled and blocked simultaneously**: When `disabled={true}` and a capability is also `blockedByParent`, both conditions suppress the button. The behavior is identical to either condition alone. (perm-017)
- **Rapid clicks**: Clicking a button invokes `toggle()` synchronously, calling `onChange` immediately. Multiple rapid clicks generate multiple `onChange` calls without debouncing. (perm-018)
- **Unmount during transition**: The transition-colors CSS class applies to color changes. If the component unmounts, the transition is interrupted but causes no error. (perm-019)

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` | `Crud` (object with `create`, `read`, `update`, `delete` boolean keys) | Required | Current CRUD permission state. |
| `parent` | `Crud` (optional) | `undefined` | Parent/ceiling permissions. Capabilities forbidden by parent cannot be toggled on. |
| `disabled` | `boolean` | `false` | When true, all buttons are non-interactive. |
| `onChange` | `(next: Crud) => void` | Required | Callback invoked when user toggles a button. The toggled capability's emitted value is clamped to the parent constraint; other capabilities in `value` are passed through unchanged, even if they already violate `parent` (see **clamp-emitted-values**). |

## Deep Linking

Not applicable: This component is a form control, not a navigable page or standalone feature.

## Localization

| String Key | Default (en) | Context |
|-----------|---------------|---------|
| `permissionToggles.group.label` | CRUD permissions | `aria-label` on the container `role="group"` that announces the whole control. |
| `permissionToggles.title.enable` | Enable {capability} | Button `title` when the capability is off and not blocked; `{capability}` is the raw key (create/read/update/delete). |
| `permissionToggles.title.disable` | Disable {capability} | Button `title` when the capability is on and not blocked. |
| `permissionToggles.title.blockedByParent` | {capability} is not permitted by the parent | Button `title` when the capability is blocked by `parent`. |

The single-letter labels (C, R, U, D) are standard CRUD abbreviations and are not translated. The `title` and `aria-label` strings above are hardcoded in English in the source and SHOULD be externalized to the keys above for a localized build.

## Accessibility Options

- **Reduce Motion**: The component applies a `transition-colors` animation when border, background, and text colors change. See Design Decision "Unconditional color transition". No `prefers-reduced-motion` handling exists in source; the transition runs unconditionally and is never suppressed for this preference.
- **Increase Contrast**: The default and enabled state colors (`apt-text-muted`, `apt-text`, `apt-gold`, `apt-gold-bright`) are defined by the design system's color tokens. If the design system provides high-contrast variants, the component inherits them via token substitution. The component itself does not implement contrast overrides.
- **Differentiate Without Color**: Enabled vs. disabled state is distinguished by color, opacity, cursor, and text content. Reliance on color alone is mitigated by opacity change and cursor style, but not fully eliminated. An audit of the `apt-gold` vs. neutral color difference is recommended to confirm sufficient contrast and differentiation for users with color blindness.

## Feature Flags

Not implemented in source. The component has no built-in feature flag mechanism.

## Analytics

Not implemented in source. The component does not emit analytics events. Applications using the component SHOULD track `onChange` calls if analytics are needed.

## Privacy

- **Data collected**: None. The component does not collect, transmit, or log any data.
- **Storage**: None. The component does not persist any data.
- **Transmission**: None. No data leaves the component.
- **Retention**: Not applicable.

## Logging

Not implemented in source. The component does not emit console logs or structured logging.

## Platform Notes

- **React/Web**: Source is a functional React component using TypeScript. Uses `cn()` utility for conditional Tailwind class application. Renders a `<div>` container with a `<button>` element for each CRUD capability. Event handling via `onClick` and native button `disabled` attribute. Styling via Tailwind CSS classes with design system color tokens (`apt-gold`, `apt-border`, `apt-bg`, `apt-text-muted`, `apt-text`, `apt-gold-bright`). No external component dependencies beyond the `cn()` utility and the `crud.ts` module that exports `CRUD_KEYS`, `CRUD_LETTER`, and types.

- **SwiftUI**: Start with an `HStack` containing four `Toggle` elements with `.toggleStyle(.button)`, arranged horizontally with 4pt spacing, so pressed-state semantics come from the control itself. Each button displays a text label and responds to a tap gesture. Use a state variable to track which capabilities are enabled. Parent constraint enforcement requires conditional logic to disable and visually suppress buttons. Use the `.disabled()` modifier and opacity control to suppress blocked capabilities.

- **Compose (Android/Kotlin)**: Start with a `Row` containing four `FilterChip` (or `IconToggleButton`) elements, both of which carry pressed/selected semantics natively. Use `Modifier.size(28.dp)` for button dimensions. Each button displays a single letter. Parent constraint enforcement requires state management and conditional `enabled` parameter. Use `alpha()` or `GraphicsLayer` to reduce opacity of blocked buttons. Accessibility via `semantics { contentDescription = ... }` and the chip's built-in `ToggleableRole`.

- **AppKit / UIKit**: Use `NSStackView` (macOS) or `UIStackView` (iOS) with `distribution = .fillEqually` and `spacing = 4`. Add four `NSButton` or `UIButton` subviews. Size each button to 28×28pt. Parent constraint enforcement requires delegate or closure callbacks to validate state changes and disable buttons conditionally. Use `isEnabled` and `alphaValue` / `alpha` to reflect disabled/blocked state.

- **WinUI 3**: Start with a `StackPanel` with `Orientation="Horizontal"` and `Spacing="4"`. Add four `ToggleButton` elements, which carry `IsChecked`/pressed-state semantics natively. Set each button's `Width="28"` and `Height="28"`. Define a `ControlTemplate` or use `VisualStateManager` to apply styling for Off, On, Disabled, and BlockedByParent states. Parent constraint enforcement requires a `Command` or `Click` event handler to validate changes and set `IsEnabled="False"` for blocked buttons. Use `Foreground` and `BorderBrush` bindings to swap color tokens for on/off states.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/permission-toggles.tsx` | unverified |

## Design Decisions

**Decision**: The component does not validate or correct the `value` prop against `parent` on mount. Enforcement occurs only during user interaction via the `toggle()` function, and only for the capability being toggled (see **clamp-emitted-values**).
**Rationale**: If `value` violates `parent` on initial render, the button will appear off (due to the `on = value[key] && !blockedByParent` calculation) but the component does not emit a corrected value. This design assumes the caller is responsible for providing a valid initial state; a stricter design would validate on mount and call `onChange` with a corrected value, but this design trusts the caller.
**Approved**: pending

**Decision**: The button size is fixed at 28×28px rather than the 44×44pt (Apple HIG) / 48×48dp (Material Design 3) recommended minimum touch target.
**Rationale**: The component prioritizes space efficiency and density in permission matrices or settings panels where multiple toggles are presented in a compact grid (e.g., a settings table). This is acceptable in that context but not suitable for standalone buttons or contexts where users have dexterity limitations. Implementations should confirm this size against their own accessibility audit and use case.
**Approved**: pending

**Decision**: Blocked capabilities are rendered disabled and visually suppressed (opacity: 0.4) rather than hidden.
**Rationale**: This allows users to understand what permissions exist and why they cannot be enabled. Hiding blocked buttons would require less space but would sacrifice discoverability of the permission structure.
**Approved**: pending

**Decision**: The `onChange` callback is invoked synchronously during the click handler, with no debouncing, throttling, or asynchronous state updates.
**Rationale**: Rapid clicks generate rapid emissions by design; applications that need to batch or debounce permission changes should do so in their own state management, keeping this component simple and predictable.
**Approved**: pending

**Decision**: Capabilities are abbreviated to single-letter labels (C, R, U, D) rather than full words.
**Rationale**: This minimizes visual space and assumes the user understands CRUD as a standard concept in permission modeling. Full-text labels (Create, Read, Update, Delete) would require more space and, unlike the letters, would need translation.
**Approved**: pending

**Decision**: Unconditional color transition — the `transition-colors` class animates border, background, and text color on every state change, with no check of `prefers-reduced-motion` (or the platform equivalent).
**Rationale**: The transition is a color-only change with no motion or translation, which may already be acceptable under reduced-motion guidance; this has not been decided, and the source provides no mechanism to suppress the transition either way.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source's DOM output: native `<button>` elements, `role="group"`, and `aria-pressed` give correct roles/states with no custom ARIA needed (semantic-markup, keyboard-navigable passed); accessible names are single letters and color-token contrast values are set by the design system, neither of which this recipe can fully verify (screen-reader-support, contrast-ratio partial); the fixed 28×28px button size is below the 44×44pt minimum (touch-target-size failed); `transition-colors` is applied unconditionally with no `prefers-reduced-motion` check (reduced-motion failed); and the `title` and `aria-label` strings are hardcoded English literals in the source with no localization mechanism (string-externalization, no-hardcoded-strings failed); the parent-clamp rule (`if (parent && !parent[key]) return`) is computed inline inside the `toggle()` handler rather than an extracted helper (separation-of-concerns: partial), while `permissionToggles.test.tsx` asserts on value reflection, toggle emission, parent-forbidden clamping, and `disabled` behavior (unit-test-coverage: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.2 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: passed). |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; corrected the title-text token to the raw capability key instead of the letter; made aria-pressed's relationship to the displayed `on` state explicit with a new test vector; corrected clamp-emitted-values to describe the actual (per-key, not whole-object) clamp scope and rewrote its test vector to check the onChange payload; merged the redundant blocked-capability-visual requirement into enforce-parent-ceiling and changed its test vector to assert observable state instead of a CSS opacity value; converted Compliance and Localization to the required table formats; reformatted Design Decisions into Decision/Rationale/Approved form and resolved the tap-target-size and reduced-motion gaps into it, keeping one review marker per gap in Accessibility Options; rewrote Appearance in px values and moved Tailwind class names into the React/Web platform note; named a single native toggle control per platform in Platform Notes; corrected the claim that opacity/cursor communicate unavailability to assistive technology; and added conformance test vectors for the previously untested edge cases. |
| 1.0.1 | 2026-09-22 | Mike Fullerton | Revision pass: clarify Reduce Motion gap, fold Compliance concerns into earlier sections |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
