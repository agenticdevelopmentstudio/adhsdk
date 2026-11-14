
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

