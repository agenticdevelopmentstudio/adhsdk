---
id: a105b6cf-307d-4156-8b73-468f627f3c9b
title: Checkbox
domain: adhsdk://recipes/checkbox
type: ingredient
version: 1.4.2
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A controllable checkbox or switch input supporting labeled form fields with
  hints and visual state feedback.
platforms:
- typescript
- web
tags:
- form
- input
- checkbox
depends-on: []
related:
- adhsdk://recipes/switch
references: []
approved-by: ''
approved-date: ''
---

# Checkbox

## Overview

A controlled checkbox input component available in two visual modes: checkbox or switch toggle. The component supports optional label and hint text, disabled state, and keyboard focus management. Built for use in forms where binary (true/false) choices are needed.

The recipe covers two source files that together make up "Checkbox": the form-field **wrapper** (`packages/web/packages/controls/src/user-settings/components/Checkbox.tsx`), which owns `value`/`onChange`, label/hint, and DOM association; and the styled **primitive** (`packages/web/packages/ui/src/components/checkbox.tsx`), a thin skin over `@base-ui/react/checkbox` that owns the visual indicator, focus ring, and `checked`/`onCheckedChange`/`defaultChecked`. Every requirement, appearance note, configuration option, and test vector below is tagged with the layer (Wrapper or Primitive) it describes, since the two components have distinct props and do not share an API.

## Behavioral Requirements

- **controlled-value** (Wrapper): The component MUST accept a `value` prop of type boolean that reflects the current checked state (`Checkbox.tsx`, `value` prop on `CheckboxProps`).
- **change-callback** (Wrapper): The component MUST accept an `onChange` callback that is invoked with the new boolean value when the user toggles the input (`Checkbox.tsx`, `onChange` prop; the input's `onChange={(e) => onChange(e.target.checked)}` handler).
- **switch-appearance** (Wrapper): The component MUST support an `appearance` prop set to `'switch'` to render a switch-mode toggle with `role="switch"` on the input (`Checkbox.tsx`, `appearance` prop; `role={appearance === 'switch' ? 'switch' : undefined}`).
- **check-appearance** (Wrapper): The component MUST support an `appearance` prop set to `'check'` to render a checkbox-mode input without the switch role (`Checkbox.tsx`, same `role` expression).
- **default-appearance** (Wrapper): The component MUST default the `appearance` prop to `'switch'` when not specified (`Checkbox.tsx`, `appearance = 'switch'` default parameter).
- **disabled-state** (Wrapper, Primitive): The component MUST accept a `disabled` prop that prevents user interaction when true (`Checkbox.tsx`, `disabled` prop; `disabled={disabled}` on the input). The Wrapper's native `<input>` carries the standard `disabled` attribute directly. The Primitive (`checkbox.tsx`) forwards `disabled` to Base UI's `CheckboxPrimitive.Root`, which renders as a `<span role="checkbox">`: the native `disabled` attribute lands only on Base UI's hidden companion `<input>`, so the `disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50` Tailwind utilities written on `CheckboxPrimitive.Root` never match, and the control is NOT visibly dimmed. Base UI instead marks the span `aria-disabled`/`data-disabled` and gives it `tabindex="-1"`, and blocks toggling internally via its own click guard rather than via CSS.
- **optional-label** (Wrapper): The component MUST conditionally render a label element when the `label` prop is provided as a ReactNode (`Checkbox.tsx`, `label` prop; `{label && <span className="aws-checkbox__label">{label}</span>}`).
- **optional-hint** (Wrapper): The component MUST conditionally render a hint element when the `hint` prop is provided as a ReactNode (`Checkbox.tsx`, `hint` prop; `{hint && <p className="aws-field__hint">{hint}</p>}`).
- **label-input-association** (Wrapper): The component MUST use a `htmlFor` attribute on the label element to associate it with the input's `id`, generating a unique ID when no explicit `id` is provided (`Checkbox.tsx`, `fieldId = id ?? generatedId` from `useId()`; `<label htmlFor={fieldId}>` and `<input id={fieldId}>`).
- **visual-indicator** (Primitive): The primitive MUST render a visual checkmark indicator that appears only when checked (`checkbox.tsx`, `CheckboxPrimitive.Indicator` wrapping a Lucide `Check` icon). The wrapper's own `<span className="aws-checkbox__indicator aws-checkbox__indicator--{appearance}">` (`Checkbox.tsx`) has no icon child; its checked appearance is applied entirely by stylesheet rules outside these two files.
- **checked-without-color** (Primitive): The primitive MUST signal the checked state by the `Check` glyph in addition to the `apt-gold` fill, so the state is distinguishable without relying on color alone (`checkbox.tsx`, `data-[checked]:bg-apt-gold` on the Root; the `Check` icon in the Indicator).
- **focus-ring** (Primitive): The primitive MUST display a visible focus indicator when the input receives keyboard focus (`checkbox.tsx`, `focus-visible:ring-2 focus-visible:ring-apt-gold/25` on the Root; React/Web renders this as a 2px ring at 25% opacity using the `apt-gold` token).
- **custom-classname** (Wrapper, Primitive): The component MUST accept a `className` prop and apply it to its root container — the wrapper's outer `<div>` (`Checkbox.tsx`, `cls` array joined with `.filter(Boolean).join(' ')`) and, independently, the primitive's `CheckboxPrimitive.Root` (`checkbox.tsx`, `className={cn(..., className)}`).
- **custom-id** (Wrapper): The component MUST accept an `id` prop that is passed to the input element for label association (`Checkbox.tsx`, `id` prop; `fieldId = id ?? generatedId`).
- **controlled-and-uncontrolled** (Primitive): The primitive MUST accept `checked` and `onCheckedChange` props for controlled mode, or `defaultChecked` for uncontrolled mode, per the `@base-ui/react/checkbox` `Checkbox.Root` API that `CheckboxPrimitive.Root` forwards (`checkbox.tsx`, `React.ComponentProps<typeof CheckboxPrimitive.Root>`). The wrapper exposes only the controlled `value`/`onChange` pair and does not forward `defaultChecked`; see Design Decision 3.
- **hint-description-association** (Wrapper, SHOULD): The component SHOULD associate the hint text with the input via `aria-describedby` (or the platform equivalent, e.g. WinUI's `AutomationProperties.DescribedBy`) so assistive technology announces the hint when the input receives focus. Neither source file wires this association today (see Design Decision 4); implementations SHOULD add it.

## Appearance

- **Checkbox Size**: 16px (`size-4` in Tailwind: 1rem). The indicator spans the full size with centered content (Primitive, `size-4` class on `CheckboxPrimitive.Root`).
- **Border**: 1px solid, color `apt-border` in default state; changes to `apt-gold` when checked (Primitive, `border border-apt-border` and `data-[checked]:border-apt-gold`).
- **Background Color**: `apt-bg` in default state; changes to `apt-gold` when checked (Primitive, `bg-apt-bg` and `data-[checked]:bg-apt-gold`).
- **Corner Radius**: `rounded` (typically 4px) (Primitive, `rounded` class).
- **Checkmark Icon**: Lucide React `Check` icon, size 3 (12px / 0.75rem), stroke width 3 (Primitive, `<Check className="size-3" strokeWidth={3} />`).
- **Checkmark Color**: `apt-bg` token color in both states, inherited via the Indicator's `text-current` class from the Root's constant `text-apt-bg` (Primitive); the glyph itself renders only while checked, per the Indicator's own conditional-rendering behavior. There is no color swap in the source — only the background fill changes between states.
- **Focus Ring**: 2px ring with `apt-gold/25` color, visible on focus (Primitive, `focus-visible:ring-2 focus-visible:ring-apt-gold/25`).
- **Transition**: `transition-colors` only — border and background color changes are animated; no size, position, or opacity motion is animated (Primitive, `transition-colors` class).
- **Label Styling**: Applied via `aws-checkbox__label` class in the wrapper, or via the passed ReactNode; font and size determined by the label text type (Wrapper, `<span className="aws-checkbox__label">`).
- **Hint Styling**: Applied via `aws-field__hint` class; appears below the checkbox with paragraph styling (Wrapper, `<p className="aws-field__hint">`).

## States

| State | Appearance Change |
|-------|------------------|
| Default | Border and background render from the `apt-border`/`apt-bg` tokens; checkmark not rendered (React/Web: `border-apt-border bg-apt-bg`) |
| Checked | Border and background render from the `apt-gold` token; checkmark renders in the `apt-bg` glyph color (React/Web: `data-[checked]:border-apt-gold data-[checked]:bg-apt-gold`) |
| Focused | A visible focus indicator appears (React/Web: 2px ring at `apt-gold/25` opacity) |
| Disabled | Non-interactive. The Wrapper's native `<input>` carries the standard browser `disabled` attribute. The Primitive shows no visual dimming: Base UI marks its rendered `<span>` `aria-disabled`/`data-disabled` with `tabindex="-1"` rather than native `disabled`, so its `disabled:` opacity/cursor/pointer-events Tailwind utilities never apply; toggling is still blocked internally either way |
| Switch Mode | Wrapper's input carries `role="switch"`; the rendered look (track/thumb vs. box) is set by the `aws-field--checkbox-switch` stylesheet rule, outside both source files |
| Check Mode | Wrapper's input keeps the implicit checkbox role; the rendered look is set by the `aws-field--checkbox-check` stylesheet rule, outside both source files |

## Accessibility

- **Role**: The input element MUST have `role="switch"` when `appearance='switch'`, or implicit `role="checkbox"` when `appearance='check'` (Wrapper, `role={appearance === 'switch' ? 'switch' : undefined}`).
- **Label Association**: The label MUST be associated with the input via the `htmlFor` attribute matching the input's `id` (Wrapper, `<label htmlFor={fieldId}>` / `<input id={fieldId}>`).
- **Disabled Announcement**: The Wrapper signals disabled state to assistive technologies via the native `disabled` attribute on its `<input>` (Wrapper, `disabled={disabled}`). The Primitive signals it instead via `aria-disabled` and `data-disabled` on the rendered `<span role="checkbox">`, with `tabindex="-1"` removing it from the tab order; Base UI puts the native `disabled` attribute only on its hidden companion `<input>`, never on the span assistive technology inspects (Primitive, `CheckboxPrimitive.Root`).
- **Focus Indicator**: A visible focus indicator MUST appear on keyboard focus to aid keyboard navigation (Primitive, `focus-visible:ring-2 focus-visible:ring-apt-gold/25`; React/Web renders this as a 2px ring at 25% opacity).
- **Hint Association**: Not yet wired in the source — see the `hint-description-association` SHOULD requirement above and Design Decision 4.
- **State Changes**: The checked state is communicated to assistive technology by the native `checked` attribute on the wrapper's input (Wrapper, `checked={value}`) and visually by the `Check` glyph rendered inside the primitive's indicator (Primitive, `CheckboxPrimitive.Indicator` / `Check`). The glyph is present in addition to the `apt-gold` fill, so the state does not depend on color perception alone.
- **Minimum Touch Target**: The primitive's hit area is the 16px `size-4` box (Primitive); the wrapper's `<label>` also carries the click target for the whole row (Wrapper, `<label htmlFor={fieldId} className="aws-checkbox">`), but the label's size is set by stylesheet rules outside these two files — see the open question on minimum-touch-target.
- **minimum-touch-target**: NEEDS REVIEW: Not implemented in source. Whether the effective target meets the 44×44pt (Apple HIG) / 24×24 CSS px (WCAG 2.2 AA) minimum cannot be decided from the component source — it depends on the padding and line-height the `aws-checkbox` and `aws-field--checkbox` stylesheet rules apply. The computed box of the rendered `<label>`, measured in the app stylesheet or a browser inspection of a live instance, would settle it.

## Conformance Test Vectors

| ID | Requirements | Layer | Input | Expected |
|----|-------------|-------|-------|----------|
| checkbox-001 | controlled-value | Wrapper | `value={true}`, no change | Checkbox renders checked (checkmark visible) |
| checkbox-002 | controlled-value | Wrapper | `value={false}`, no change | Checkbox renders unchecked (checkmark hidden) |
| checkbox-003 | change-callback | Wrapper | User clicks checkbox, `value={false}` | `onChange(true)` is called with new value |
| checkbox-004 | change-callback | Wrapper | User clicks checkbox, `value={true}` | `onChange(false)` is called with new value |
| checkbox-005 | switch-appearance | Wrapper | `appearance='switch'`, `value={false}` | Input has `role="switch"`; visual look follows the `aws-field--checkbox-switch` stylesheet rule |
| checkbox-006 | check-appearance | Wrapper | `appearance='check'`, `value={false}` | Input has implicit checkbox role; visual look follows the `aws-field--checkbox-check` stylesheet rule |
| checkbox-007 | default-appearance | Wrapper | No `appearance` prop specified | Component renders with switch appearance (`role="switch"`) |
| checkbox-008 | disabled-state | Wrapper | `disabled={true}`, user attempts click | User interaction is prevented; `onChange` is not called |
| checkbox-009 | optional-label | Wrapper | `label="Agree to terms"` | Label text renders adjacent to checkbox, associated via `htmlFor` |
| checkbox-010 | optional-label | Wrapper | No `label` prop | Label text does not render |
| checkbox-011 | optional-hint | Wrapper | `hint="Required to proceed"` | Hint text renders below checkbox in a paragraph element |
| checkbox-012 | optional-hint | Wrapper | No `hint` prop | Hint text does not render |
| checkbox-013 | label-input-association | Wrapper | User clicks on label text | Input receives focus and toggles (checked state changes) |
| checkbox-014 | visual-indicator | Primitive | `checked={true}` | `Check` icon is visible inside the indicator |
| checkbox-015 | visual-indicator | Primitive | `checked={false}` | `Check` icon is not rendered |
| checkbox-016 | focus-ring | Primitive | User tabs to the primitive | Keyboard focus ring (2px, `apt-gold/25`) is visible |
| checkbox-017 | custom-classname | Wrapper | `className="my-custom-class"` passed to the wrapper | Custom class is appended to the wrapper's root `<div>` |
| checkbox-018 | custom-id | Wrapper | `id="my-checkbox"` | Input element has `id="my-checkbox"` and label references it |
| checkbox-019 | checked-without-color | Primitive | Primitive rendered with color rendering suppressed (greyscale) | The `Check` glyph is present in the checked box and absent in the unchecked box |
| checkbox-020 | custom-classname | Primitive | `className="my-custom-class"` passed to the primitive | Custom class is merged into `CheckboxPrimitive.Root`'s class list via `cn()` |
| checkbox-021 | hint-description-association | Wrapper | `hint="Required to proceed"`, input receives focus | Input's `aria-describedby` (or platform equivalent) references the hint element, so assistive technology announces the hint text |
| checkbox-022 | controlled-and-uncontrolled | Primitive | `defaultChecked={true}` passed, no `checked`/`onCheckedChange` | Primitive renders checked initially and manages its own state internally (uncontrolled mode) |
| checkbox-023 | disabled-state | Primitive | `disabled={true}` passed to `CheckboxPrimitive.Root` | Root renders as a `<span role="checkbox">` with `aria-disabled="true"`, `data-disabled`, and `tabindex="-1"`; no opacity/cursor/pointer-events change occurs, since `disabled:opacity-50`/`disabled:pointer-events-none`/`disabled:cursor-not-allowed` never match a `<span>`; toggling is still blocked internally |

## Edge Cases

- **No label or hint provided**: The component renders the checkbox without optional elements. The root container still has `aws-field` and `aws-field--checkbox` classes (Wrapper). MUST render the input and indicator regardless.
- **Very long label text**: No truncation or wrapping specified in source. Text flows according to container width and CSS (`label` is a ReactNode, Wrapper). Implementations MUST NOT truncate, since the source applies no truncation.
- **Very long hint text**: No truncation specified. Hint paragraph wraps according to CSS (Wrapper, `<p className="aws-field__hint">`). Implementations MUST NOT truncate.
- **Disabled state during user interaction**: The wrapper forwards `disabled` to the native `<input>` (Wrapper, `disabled={disabled}`), so the browser suppresses change events and `onChange` is never invoked. The primitive forwards `disabled` to Base UI's `CheckboxPrimitive.Root`, which renders as a `<span role="checkbox">` carrying `aria-disabled`/`data-disabled` and `tabindex="-1"`; the native `disabled` attribute lands only on Base UI's hidden companion `<input>`, so the `disabled:pointer-events-none`/`disabled:cursor-not-allowed`/`disabled:opacity-50` Tailwind utilities written on `CheckboxPrimitive.Root` never match and produce no visible dimming (Primitive). Toggling is still blocked, but internally by Base UI's own click guard rather than by CSS. Implementations MUST suppress the toggle while disabled; they MUST NOT assume the Primitive dims visually, since the source does not achieve that.
- **Custom className conflicts with aws-field classes**: All wrapper classes are joined with `filter` and a space separator; the custom `className` is appended last, so it wins in the cascade (Wrapper, `cls` array). Custom classes MUST be appended after the built-in classes.
- **Missing onChange callback**: `onChange` is a required (non-optional) member of `CheckboxProps` (Wrapper), so TypeScript rejects a call site that omits it, and the change handler invokes it unguarded (`onChange={(e) => onChange(e.target.checked)}`). Implementations MUST treat the change callback as a required parameter rather than tolerating its absence.
- **Null or undefined label/hint**: Conditionally rendered via `{label &&` and `{hint &&` checks; no rendering occurs otherwise (Wrapper). The component MUST omit the elements entirely rather than rendering empty ones.
- **Rapid toggling**: No debounce or rate-limiting specified. Each toggle invokes `onChange` immediately (Wrapper, `onChange={(e) => onChange(e.target.checked)}`). Implementations MUST emit one callback per toggle with no coalescing.
- **Concurrent access**: Not applicable: both implementations are React function components that render and dispatch events on the browser's single UI thread; no shared mutable state exists in either file.
- **Error states and offline behavior**: Not applicable: the component performs no I/O — it reads a boolean prop and calls a callback — so there is no dependency that can fail or disconnect.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` (Wrapper) | boolean | Required | Controlled checked state. MUST be provided. |
| `onChange` (Wrapper) | (value: boolean) => void | Required | Callback invoked when user toggles the checkbox. MUST be provided. |
| `appearance` (Wrapper) | 'switch' \| 'check' | 'switch' | Visual and semantic mode: switch toggles with switch role, check renders as checkbox. |
| `disabled` (Wrapper) | boolean | false | When true, prevents user interaction via the native `disabled` attribute on the input. The same value forwarded to the Primitive produces no visual dimming — see **disabled-state**. |
| `label` (Wrapper) | ReactNode | undefined | Optional label text rendered adjacent to checkbox with associated `htmlFor`. |
| `hint` (Wrapper) | ReactNode | undefined | Optional hint text rendered below checkbox in a paragraph element. |
| `className` (Wrapper) | string | undefined | Custom CSS class(es) appended to the wrapper's root container. |
| `id` (Wrapper) | string | `useId()`-generated id | HTML id attribute for the input element, used for label association. Auto-generated if not provided. |
| `checked` (Primitive) | boolean | undefined | Primitive's controlled checked state, paired with `onCheckedChange`. Not used together with `defaultChecked`. |
| `defaultChecked` (Primitive) | boolean | false | Primitive's initial checked state for uncontrolled usage; replaces `checked`/`onCheckedChange`. |

## Deep Linking

Not applicable: This component is a form input, not a routable page or section. Deep linking is the responsibility of the containing page or form.

## Localization

Not applicable: The component's label, hint, and any ARIA attributes are provided as ReactNode props by the caller and are not hardcoded in the component. Localization is handled at the call site.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | No motion is animated. The only transition in the source is `transition-colors` on the primitive's Root (Primitive), which animates border and background color; neither source file queries `prefers-reduced-motion`. There is nothing to disable under Reduce Motion. |
| Increase Contrast | All colors resolve from the `apt-border`, `apt-bg`, and `apt-gold` design tokens (Primitive); the component hardcodes no color value, so implementations MUST use those tokens and any high-contrast theme variant carries through automatically — see the open question on increase-contrast. |
| Differentiate Without Color | Satisfied. The checked state is signalled by two independent channels: the `apt-gold` border and fill (Primitive, `data-[checked]:border-apt-gold data-[checked]:bg-apt-gold`) and the `Check` glyph rendered by the indicator (Primitive, `CheckboxPrimitive.Indicator` / `Check`), which is absent when unchecked. In switch appearance the wrapper's input also carries `role="switch"` (Wrapper), so assistive technology announces on/off independently of appearance. Implementations MUST keep the glyph, not color alone, as the checked indicator. |

- **increase-contrast**: NEEDS REVIEW: Not implemented in source. Neither source file defines the `apt-*` token values, so whether a high-contrast theme variant exists and whether the checked fill meets WCAG 2.1 AA (4.5:1 for the checkmark on `apt-gold`, 3:1 for the `apt-border` outline on `apt-bg`) cannot be determined here. The stylesheet or theme file that defines the `apt-*` custom properties, run through a contrast checker, would settle it.

## Feature Flags

Not applicable: No feature flags or conditional compilation logic appear in the source code. The component is always enabled.

## Analytics

Not applicable: The component source contains no event tracking, logging, or analytics instrumentation. Analytics integration is the responsibility of the containing form or application.

## Privacy

Not applicable: The component does not collect, store, or transmit user data beyond the boolean checked state passed to the `onChange` callback. No sensitive information is handled by the component itself.

## Logging

Not applicable: No logging or debugging output is present in the component source. Logging is the responsibility of the containing application or the `onChange` callback handler.

## Platform Notes

- **React/Web**: The source platform. Two files implement it. `packages/web/packages/controls/src/user-settings/components/Checkbox.tsx` is the form-field wrapper: a `<div class="aws-field aws-field--checkbox aws-field--checkbox-{appearance}">` containing a `<label htmlFor>` that wraps a native `<input type="checkbox">`, a `<span class="aws-checkbox__indicator">`, and the optional label span, with the hint as a sibling `<p class="aws-field__hint">`. `packages/web/packages/ui/src/components/checkbox.tsx` is the styled primitive: a thin wrapper over `@base-ui/react/checkbox` with `apt-*` Tailwind tokens and a Lucide `Check` glyph in the indicator slot. Specific to web: `useId()` for the generated field id, the `role="switch"` override on a native checkbox input, and the fact that all visual states are expressed as CSS selectors (`focus-visible:`, `data-[checked]`, `disabled:`) rather than as code branches.

- **SwiftUI**: Start from `Toggle(isOn:)` — `.toggleStyle(.switch)` for `appearance == 'switch'`, and a custom `ToggleStyle` drawing a 16pt `RoundedRectangle(cornerRadius: 4)` with an `Image(systemName: "checkmark")` overlay for `appearance == 'check'`, since SwiftUI ships no checkbox style on iOS (`.checkbox` exists on macOS only). Bind the `value`/`onChange` pair to a single `Binding<Bool>`; SwiftUI has no separate change callback. The hint becomes the `Toggle`'s second label line or a `Text` below with `.font(.caption)`. `.disabled(true)` replaces the `disabled` prop and dims the control automatically, so the explicit 50% opacity rule is redundant. Focus ring is system-drawn via `.focusable()`; do not reimplement it.

- **Compose**: Use `Switch(checked:onCheckedChange:)` for switch appearance and `Checkbox(checked:onCheckedChange:)` for check appearance — Material 3 treats them as distinct controls, so branch on `appearance` at the call site rather than styling one into the other. Wrap the control and label in a `Row(verticalAlignment = Alignment.CenterVertically)` with `Modifier.toggleable(value, role = if (appearance == "switch") Role.Switch else Role.Checkbox, onValueChange = ...)` on the row so tapping the label toggles, which is what the web `<label htmlFor>` provides for free; pass `onCheckedChange = null` to the inner `Switch`/`Checkbox` so it does not also fire on tap — otherwise the row's `toggleable` and the control's own callback would both fire, toggling twice. Colors come from `CheckboxDefaults.colors(checkedColor = ...)` mapped to the `apt-gold`/`apt-border`/`apt-bg` tokens. Material's default 48dp minimum touch target already exceeds the web component's 16px box.

- **AppKit / UIKit**: On macOS, use `NSButton(checkboxWithTitle:target:action:)` for check appearance (its `title` carries the label, replacing the separate span) and `NSSwitch` plus an `NSTextField` label for switch appearance; read and write `state` as `.on`/`.off`. On iOS, use `UISwitch` for switch appearance and a `UIButton` with `UIButton.Configuration` plus `UIImage(systemName: "checkmark.square.fill")` / `"square"` for check appearance, since UIKit has no checkbox control. Wire `.valueChanged` (or the button action) to the change callback. The hint is a second `UILabel`/`NSTextField` with a secondary text color beneath the control. Set `isEnabled = false` for the disabled state; unlike the web source, neither framework dims a disabled custom button automatically, so apply `alpha = 0.5` to match.

- **WinUI 3**: Use `CheckBox` when `appearance` is `check` and `ToggleSwitch` when it is `switch`; both derive from `ToggleButton`-style semantics and expose the checked state as a two-way bindable property — `CheckBox.IsChecked` (`bool?`, so coerce `null` to `false`, as the source has no indeterminate state) and `ToggleSwitch.IsOn`. Bind with `{x:Bind ViewModel.Value, Mode=TwoWay}` rather than handling `Checked`/`Unchecked` separately, which matches the source's single `onChange(boolean)` callback; if you use events, handle `CheckBox.Checked` *and* `CheckBox.Unchecked` (or `ToggleSwitch.Toggled`) or the false transition is lost. Put the label in `Content` — that makes the label clickable, the equivalent of `<label htmlFor>` — and suppress `ToggleSwitch.OnContent`/`OffContent` (set `OnContent="{x:Null}"`) because the web source renders no on/off text. The hint is a separate `TextBlock` below with `Style="{StaticResource CaptionTextBlockStyle}"` and `Foreground="{ThemeResource TextFillColorSecondaryBrush}"`; wire `AutomationProperties.DescribedBy` to it, since WinUI does not associate it implicitly. Map the `apt-*` tokens to `SolidColorBrush` entries in a `ResourceDictionary` and override `CheckBoxCheckBackgroundFillChecked`/`CheckBoxCheckBackgroundStrokeChecked` (and `ToggleSwitchFillOn`) rather than rewriting the `ControlTemplate`; the default template's `CommonStates`/`CheckStates` `VisualStateGroup`s already cover the Default, Checked, Focused (`FocusVisualPrimaryBrush`, the analogue of the 2px `apt-gold/25` ring) and Disabled states this ingredient specifies. `IsEnabled="False"` applies the platform's own disabled dimming and blocks input, so no opacity override is needed. WinUI's default `CheckBox` hit area is 32×32px with the glyph at 14px, already larger than the source's 16px box.

## Design Decisions

1. **Decision**: Provide two visual modes via the `appearance` prop — switch mode sets `role="switch"` on the wrapper's input; check mode uses the implicit checkbox role.
**Rationale**: Aligns with platform conventions (Apple HIG distinguishes toggles from checkboxes; Material Design 3 treats Checkbox and Switch as separate controls) and gives assistive technology the correct semantics for each mode.
**Approved**: pending

2. **Decision**: Default the wrapper's `appearance` prop to `'switch'`.
**Rationale**: The wrapper's default parameter, `appearance = 'switch'` (`Checkbox.tsx`), makes toggle-style rendering the out-of-the-box behavior for this form-field component.
**Approved**: pending

3. **Decision**: Type `value` and `onChange` as required (non-optional) members of `CheckboxProps` on the wrapper.
**Rationale**: Enforces controlled-only usage at the form-field layer and prevents accidental uncontrolled use. The underlying primitive (`@base-ui/react/checkbox`'s `Checkbox.Root`) separately supports both controlled and uncontrolled modes, which is why `controlled-and-uncontrolled` (see Behavioral Requirements) is scoped to the primitive only.
**Approved**: pending

4. **Decision**: Rely on `htmlFor` label association and the native `disabled` attribute for accessibility; the source applies no `aria-label` or `aria-describedby`.
**Rationale**: These two source-visible mechanisms cover role and disabled-state announcement for free; the hint-to-input link (`aria-describedby`) is not automatic, which is why it is captured separately as the `hint-description-association` SHOULD requirement rather than assumed here.
**Approved**: pending

5. **Decision**: Size the checkmark glyph at 12px (`size-3`) with a 3px stroke inside the 16px container.
**Rationale**: Smaller than the container to avoid visual clipping; the heavier stroke keeps the glyph legible at that small size.
**Approved**: pending

6. **Decision**: Animate only `transition-colors` on the primitive; no geometry or opacity motion.
**Rationale**: Because no motion exists in the source, there is nothing to suppress under Reduce Motion, so this component takes no Reduce-Motion deviation.
**Approved**: pending

7. **Decision**: Signal the checked state through two independent channels — the `apt-gold` fill and the `Check` glyph.
**Rationale**: The glyph is what makes `checked-without-color` testable; dropping it and keeping only the color fill would regress Differentiate Without Color.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

The `passed` statuses rest on the native `role`/`htmlFor` semantics and the keyboard-operable `<input type="checkbox">` visible in both source files. The two `partial` statuses reflect that the `apt-*` token contrast values and the effective click-target size (label padding/line-height) are defined in an external stylesheet not present in either source file. The Wrapper's own logic — id generation, conditional label/hint rendering, and appearance-driven role selection — is kept out of the Primitive, which delegates all checked/disabled behavior to Base UI and limits its own file to `apt-*` styling (separation-of-concerns). `components.test.tsx`'s `Checkbox` suite exercises the Wrapper's only behavioral logic — the toggle callback and the switch/check role switch — with meaningful assertions; the Primitive is a thin styling pass-through over Base UI with no independent logic of its own to test (unit-test-coverage).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.4.2 | 2026-09-25 | Mike Fullerton | Corrected disabled-state: Primitive dims via no CSS, only aria-disabled span; added compliance rows. |
| 1.4.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.4.0 | 2026-09-22 | Mike Fullerton | Lint pass: tag every requirement, appearance note, configuration option, and test vector with the layer (wrapper vs. primitive) it describes instead of merging the two components; scope `controlled-and-uncontrolled` to the primitive; rename requirements to subject-only kebab-case and update every citation to package path + symbol/prop name instead of invented line numbers; add the `hint-description-association` SHOULD requirement and its test vector; restate the disabled-opacity, focus-ring, and switch/check-mode rules as intents with React/Web notes so they no longer contradict the Platform Notes or the test vectors; fix the Compose note's role selection and inner-control double-fire gap; correct the `checked` prop's controlled/uncontrolled labeling, the `id` default, and the checkmark-color description; rewrite Design Decisions in the three-line Decision/Rationale/Approved form; rebuild Compliance as a linked table scoped to the Accessibility checks that apply; fix WinUI 3 terminology ("recipe" → "ingredient"), link the `switch` ingredient under `related`, retag `disabled-state` to cover the primitive's own dimming, and add test vectors for `controlled-and-uncontrolled` and the primitive's disabled-opacity behavior. |
| 1.3.0 | 2026-09-22 | Claude Haiku 4.5 | Standardize review marker format in Accessibility Options table; keep genuine gaps (touch target size depends on external CSS, token-defined contrast requires theme verification) |
| 1.2.0 | 2026-09-22 | Claude Haiku 4.5 | Fold in ui-blocks form-field wrapper alongside ui-primitives styled primitive; ensure complete platform guidance |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Answer source-visible questions in place (disabled selectors, color transition, checked-state signalling, required change callback); add Windows platform guidance; promote to review |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
