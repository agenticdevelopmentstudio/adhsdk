
- **Role**: Button (implicit from semantic `<button>` element).
- **Label requirements**: MUST have an `aria-label` that conveys the current mode and next action. Label format: when in auto mode, "Appearance: Auto (currently [resolved]). Click to switch to dark." When in dark mode, "Dark mode — click for light". When in light mode, "Light mode — click for auto".
- **Icon accessibility**: Icons are marked with `aria-hidden="true"` to prevent screen reader announcement of the SVG markup; the button label alone communicates the control's purpose.
- **Badge accessibility**: Auto badge SVG is marked with `aria-hidden="true"`.
- **Announce state changes**: State changes are announced via updated `aria-label` and `title` attribute when the component re-renders in response to the 'awt:appearance-changed' event.
- **minimum-tap-target**: NEEDS REVIEW: Not implemented in source. `AppearanceModeToggle.tsx` sets no size on the button; its optional default stylesheet (`appearance-mode-toggle.css`: 0.5rem padding plus a 1.25rem icon, ~36×36px) is not enforced by the component and can be overridden, so whether the effective size in a given host layout clears the 44×44pt iOS / 48×48dp Android minimums needs a human judging the rendered button in context.

