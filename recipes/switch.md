---
id: 951b86ac-cf75-46ec-9746-d15fcb4618b4
title: Switch
domain: adhsdk://recipes/switch
type: ingredient
version: 1.2.2
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A binary toggle control that displays on/off state with animated visual feedback.
platforms:
- typescript
- web
tags:
- form-control
- toggle
- interactive
depends-on: []
related:
- adhsdk://recipes/label
- adhsdk://recipes/checkbox
- adhsdk://recipes/field
references: []
approved-by: ''
approved-date: ''
---

# Switch

## Overview

A Switch is a binary toggle control that allows users to turn a setting on or off. The component displays its current state through color and animated position changes, with clear visual feedback for checked, unchecked, disabled, and focused states. It supports both controlled and uncontrolled usage patterns.

## Behavioral Requirements

- **toggles-on-click**: The Switch MUST change its checked state when the user clicks or taps it.
- **support-controlled**: The Switch MUST support controlled mode via `checked` prop combined with `onCheckedChange` callback.
- **support-uncontrolled**: The Switch MUST support uncontrolled mode via `defaultChecked` prop.
- **respect-disabled-state**: The Switch MUST prevent state changes when the `disabled` prop is `true`.
- **animate-position**: The Switch thumb MUST animate its horizontal position when transitioning between checked and unchecked states.
- **animate-colors**: The Switch MUST animate color changes when transitioning between checked and unchecked states.
- **render-inline**: The Switch MUST render as an inline-flex element for use within text or form layouts.
- **class-prop**: The Switch MUST accept a `className` prop and merge it with internal styles.
- **toggle-on-space**: The Switch MUST toggle its checked state when it has focus and the user presses Space (optionally, Enter).
- **expose-switch-role**: The Switch MUST expose the ARIA `switch` role via `Switch.Root` so assistive technology can identify it as a toggle and announce the label the consumer provides.

## Appearance

- **Track size**: 36px wide × 20px tall
- **Thumb size**: 16px × 16px, circular
- **Border radius**: fully rounded (track and thumb are both pill/circle shaped)
- **Border**: 1px, transparent (reserves space so applying the focus ring doesn't shift layout)
- **Track padding**: 2px horizontal, 0px vertical, between the track edge and the thumb
- **Track color (unchecked)**: the design system's neutral input-surface color role
- **Track color (checked)**: the design system's accent (gold) color role
- **Thumb color**: the design system's primary text/foreground color role
- **Shadow**: a small drop shadow under the thumb
- **Transition duration**: 150ms for both the track color change and the thumb position change (the source sets no explicit duration override)

## States

| State | Appearance change |
|-------|------------------|
| Unchecked (default) | Track uses the unchecked color; thumb sits at its leftmost position |
| Checked | Track uses the checked color; thumb translates 14px to the right — its full travel within the track |
| Disabled | No visual change (track/thumb keep full opacity, cursor stays `pointer`); toggling is blocked by Base UI's internal guards, not by CSS |
| Focus-visible (keyboard) | 2px focus ring around the track, in the checked color at 40% opacity |
| Checked + Disabled | Checked appearance only; no dimming (see **Disabled**) |

## Accessibility

- **Role**: The underlying base-ui `Switch.Root` renders as a `<span role="switch">` (plus a visually hidden native `<input type="checkbox">` beside it for form semantics); it is not a native button.
- **State announcement**: The component exposes checked state via the `aria-checked` attribute, updated when state changes.
- **Keyboard support**: The component MUST be keyboard accessible via Tab navigation and Space (optionally Enter) to toggle.
- **Minimum tap target**: The outer container (36px × 20px) does not meet the 44×44pt minimum touch target on all platforms; consumers SHOULD wrap the Switch in a larger interactive area for mobile contexts.
- **Disabled communication**: When disabled, base-ui sets `aria-disabled="true"` and `data-disabled` on the `<span>` root and moves it out of the tab order (`tabindex="-1"`); the native HTML `disabled` attribute is applied only to the hidden `<input>`, not the visible root. Because the root never matches the CSS `:disabled` pseudo-class, the `disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50` Tailwind utilities never take effect — the track/thumb keep full opacity and the cursor stays `pointer`. Toggling is still blocked, but by Base UI's internal click/keydown guards, not by `pointer-events: none`.
- **Label association**: The component itself has no text content; a label element or aria-label MUST be provided by the consumer.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| switch-001 | toggles-on-click | Unchecked Switch, user clicks | State changes to checked; callback fires if controlled |
| switch-002 | toggles-on-click | Checked Switch, user clicks | State changes to unchecked; callback fires if controlled |
| switch-003 | support-controlled | Controlled Switch with `checked={true}` and `onCheckedChange`; user clicks, parent does not update `checked` | `onCheckedChange` fires with the toggled value; the rendered state stays at `checked={true}` until the parent prop changes |
| switch-004 | support-uncontrolled | Uncontrolled Switch with `defaultChecked={true}` | Clicking toggles visual state without external callback |
| switch-005 | respect-disabled-state | Disabled Switch, user clicks | State does not change; Base UI's internal disabled guard blocks the click handler (not CSS `pointer-events`) — the root shows no visual change |
| switch-006 | animate-position | Toggle checked → unchecked | Thumb translates from 14px to 0px with a smooth transition |
| switch-007 | animate-colors | Toggle checked → unchecked | Track color transitions from the checked color to the unchecked color smoothly |
| switch-008 | render-inline | Switch rendered in text flow | Component displays as inline-flex (does not break text flow) |
| switch-009 | class-prop | Switch with custom `className="my-custom-class"` | Custom class merges with internal classes; visual result reflects both |
| switch-010 | respect-disabled-state | Disabled Switch (`disabled={true}`), controlled parent flips the `checked` prop | Track color and thumb position still animate to match the new `checked` value — the transition classes are always active and unaffected by `disabled`, which shows no visual change of its own; user clicks remain ignored |
| switch-011 | toggle-on-space | Enabled Switch, user presses Tab to focus then presses Space | State toggles; callback fires if controlled |
| switch-012 | expose-switch-role | Switch rendered with an accessible name | Assistive technology reports role "switch" along with the provided name and current checked state |
| switch-013 | respect-disabled-state | Disabled Switch, focused via Tab, user presses Space | State does not change; no callback fires |
| switch-014 | toggles-on-click | Enabled Switch, user clicks 3 times in rapid succession | Each completed click toggles the state once; three clicks alternate checked/unchecked/checked with no coalesced or dropped toggles |

## Edge Cases

- **Rapid clicks**: Each completed click or tap MUST toggle the state exactly once; see switch-014. Rapid successive clicks are not debounced or coalesced — N completed clicks produce N toggles.
- **Disabled + controlled**: A controlled Switch with `disabled={true}` and an external prop change MUST reflect the new prop value, including its color/position transition, even though user interaction is blocked; see switch-010.
- **Keyboard navigation in focus**: When focused via Tab, pressing Space (optionally Enter) MUST toggle the checked state if not disabled; see switch-011.
- **No label provided**: If the consumer does not provide an associated label or aria-label, the switch will lack semantic meaning for assistive technology; this is a consumer responsibility, not a component defect.
- **Small touch target on mobile**: The 36×20px dimensions are smaller than the 44×44pt touch-friendly target on mobile platforms; consumers SHOULD wrap the Switch or increase the interactive area.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `checked` | boolean | undefined | Controlled state; when present, component is controlled mode |
| `onCheckedChange` | function | undefined | Callback fired when user toggles state; signature: `(checked: boolean) => void` |
| `defaultChecked` | boolean | undefined | Initial state for uncontrolled mode |
| `disabled` | boolean | false | Blocks toggling via Base UI's internal guards; the intended dimmed styling (`disabled:opacity-50` etc.) never applies because the root is a `<span>`, not a native-disabled element — see **Disabled communication** |
| `className` | string | "" | Additional CSS class names merged with component's internal styles |
| `name` | string | — | Form field name; forwarded via `{...props}` to base-ui's `Switch.Root` for native form submission |
| `value` | string | — | Form value submitted when checked; forwarded via `{...props}` to `Switch.Root` |
| `required` | boolean | — | Marks the field required for form validation; forwarded via `{...props}` to `Switch.Root` |
| `readOnly` | boolean | — | Blocks user-driven changes while still reflecting controlled prop updates; forwarded via `{...props}` to `Switch.Root` |
| `inputRef` | Ref | — | Ref to the underlying native input element; forwarded via `{...props}` to `Switch.Root` |

The last five props aren't handled by this wrapper directly — they pass through the `{...props}` spread to base-ui's `Switch.Root`, whose contract defines their exact defaults and behavior.

## Deep Linking

Not applicable: Switch is a form control component with no standalone deep-linking behavior. Deep linking is the responsibility of the containing page or application.

## Localization

Not applicable: Switch has no text content or user-facing strings. Labels and descriptions are provided by the consuming application.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Transitions are applied (transition-colors on the root, transition-transform on the thumb); the component does not check `prefers-reduced-motion` and does not disable or minimize transitions when the user has Reduce Motion enabled. |
| Increase Contrast | The component uses the `apt-gold` (checked) and `apt-input` (unchecked) tokens from the design system; see the open question on increase-contrast. |
| Differentiate Without Color | The Switch communicates state through both color (apt-gold vs. apt-input) and position change (thumb translates 14px right when checked); the position change provides a non-color indicator for users who cannot distinguish colors. |

- **increase-contrast**: NEEDS REVIEW: Not implemented in source. Confirm the `apt-gold` (checked) and `apt-input` (unchecked) tokens meet the WCAG 1.4.11 non-text contrast ratio (3:1) against their surrounding background — `switch.tsx` only assigns these tokens and doesn't resolve or verify their contrast; the switch's state indicator is a non-text UI component, so the 4.5:1 text threshold doesn't apply.

## Feature Flags

Not applicable: No feature flags are implemented in the source component. Feature flags, if needed, would be applied at the application or page level, not the component level.

## Analytics

Not applicable: The component does not emit analytics events internally. Event tracking is the responsibility of the consuming application via the `onCheckedChange` callback.

## Privacy

Not applicable: The Switch component does not collect, store, or transmit data. The component accepts and reflects boolean state only.

## Logging

Not applicable: The component does not perform logging. Debugging state changes is handled through React DevTools or the consumer's own logging.

## Platform Notes

- **React/Web**: Component wraps base-ui's `Switch.Root` and `Switch.Thumb`. Tailwind classes implement the Appearance/States values above: `h-5 w-9` (20×36px track), `size-4` (16px thumb), `px-0.5` (2px horizontal padding), `border border-transparent`, `rounded-full`, `data-[checked]:bg-apt-gold` / `data-[unchecked]:bg-apt-input` (track color tokens), `bg-apt-text` (thumb color token), `shadow-sm`, `transition-colors` / `transition-transform` (150ms default), and `data-[checked]:translate-x-4` / `data-[unchecked]:translate-x-0` for thumb position. Controlled via React props (`checked`, `onCheckedChange`, `defaultChecked`). Forward all remaining props to `SwitchPrimitive.Root` via spread operator.
- **SwiftUI**: Use `Toggle` combined with custom styling to match appearance. Bind to a `@State` variable for controlled behavior. Apply the accent and neutral color tokens conditionally based on toggle state; animate transitions with `.animation(.default)`. Respect `@Environment(\.accessibilityReduceMotion)` to disable or minimize animations when preferred (there is no `AccessibilityOptions.reduceMotion` API).
- **Compose**: Use the `Switch` composable with `checked` and `onCheckedChange` parameters. Style the track and thumb using Material 3 color tokens mapped to the accent and neutral colors. Pass `enabled = false` to `Switch` for the disabled state (there is no `Modifier.disabled()`). Compose has no direct accessibility-service equivalent of iOS's reduce-motion flag; to honor a reduced-motion preference, check the platform's global animation-scale setting and suppress animations when it is zero.
- **UIKit / AppKit**: On iOS, use `UISwitch` unsubclassed — style via `onTintColor` (checked track) and `thumbTintColor` (thumb); avoid subclassing to override `backgroundColor`, since `UISwitch` draws its own chrome and that approach is fragile. On macOS, use `NSSwitch`; it exposes no public API to recolor the track or thumb and instead follows the system accent color, so exact token matching isn't achievable without a custom control. Implement target-action for state-change notifications. Check `UIAccessibility.isReduceMotionEnabled` on iOS to suppress animations when active.
- **WinUI 3**: Use the `ToggleSwitch` control. Bind `IsOn` to a ViewModel property for controlled behavior. Apply custom colors via the `ToggleSwitchFillOn` / `ToggleSwitchFillOff` resources (track) and `ToggleSwitchKnobFillOn` (thumb) — not `ToggleSwitchOnForeground` / `ToggleSwitchOffForeground`, which color the on/off text labels, not the track. Disable via `IsEnabled="false"`. Ensure focus rectangle visibility matches the Ring focus state; use `FocusVisualPrimaryBrush` and `FocusVisualSecondaryBrush` for styling. Check `UISettings.AnimationsEnabled` and suppress animations when false to honor the Reduce Motion preference.

## Design Decisions

**Decision**: Use `inline-flex` rather than `flex` for the outer container.
**Rationale**: Lets the component sit within text and form flows without breaking layout; matches the source constraint and Web semantic expectations.
**Approved**: pending

**Decision**: Include a transparent 1px border on the track.
**Rationale**: Reserves layout space so applying the focus ring doesn't shift surrounding content.
**Approved**: pending

**Decision**: The thumb travels 14px to the right when checked.
**Rationale**: The 36px track leaves 14px of travel once the 1px border, 4px of horizontal padding (2px each side), and the 16px thumb are subtracted (36 − 2 − 4 − 16 = 14). The source's `translate-x-4` Tailwind utility requests 16px (Tailwind's default spacing scale), but the thumb starts already inset by the track's padding, so its visual travel lands exactly at this 14px right-aligned position.
**Approved**: pending

**Decision**: Animate both the track color and the thumb position rather than switching instantly.
**Rationale**: Matches modern UI expectations for visual feedback and improves perceived responsiveness.
**Approved**: pending

**Decision**: Rely on the design system's color tokens (`apt-gold`, `apt-input`, `apt-text`) rather than hardcoded colors.
**Rationale**: Keeps the component's colors consistent with the rest of the design system; if a token is undefined, the component will fail to display correctly, which is a consumer responsibility.
**Approved**: pending

**Decision**: Support both controlled (`checked` / `onCheckedChange`) and uncontrolled (`defaultChecked`) usage.
**Rationale**: Lets consumers choose based on their own state-management needs; the source does not force one pattern.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | failed | Accessibility |
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | failed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

Statuses rest on what `switch.tsx` itself shows: the fixed 36×20px track (below the 44×44pt minimum) and the absent `prefers-reduced-motion` check are directly visible in the source, while the switch role, keyboard handling, and label association depend on base-ui's `Switch.Root` contract and consumer-supplied props, which this file doesn't itself implement. `separation-of-concerns` passes because `switch.tsx` only themes and composes Base UI's `Switch.Root`/`Switch.Thumb` primitives, with no toggle or focus logic of its own. `unit-test-coverage` fails because no test file in the `ui` package imports or exercises `Switch`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.2 | 2026-09-25 | Mike Fullerton | Corrected disabled mechanism (span aria/data-disabled, no native disabled); added BP checks. |
| 1.2.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: fixed nonexistent Platform Notes APIs; rewrote Appearance/States/test vectors as semantic values with Tailwind mapping confined to React/Web; corrected thumb-travel math to 14px; resolved the disabled cursor/pointer-events conflict and clarified the native disabled attribute; added toggle-on-space and expose-switch-role requirements with vectors; reformatted Design Decisions; rebuilt Compliance with real linked checks; corrected the Increase Contrast WCAG citation; listed forwarded form props in Configuration; populated related ingredients; fixed the 1.0.0 author and an RFC 2119 misuse |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Revise Accessibility Options markers: state facts, keep genuine gaps only; update Platform Notes with Reduce Motion guidance |
| 1.0.0 | 2026-09-22 | Generated | Initial creation, generated from base-ui React source |
