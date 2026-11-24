
- **Role/trait**: Implicit `textbox` role (native HTML textarea).
- **Label requirements**: The component MUST be associated with a label via `<label htmlFor="id">`, `aria-label`, or `aria-labelledby`. Wrapping the field in a `<fieldset>` alone does not label it — the surrounding component or form context is responsible for providing one of these mechanisms.
- **Announce state changes**: The component uses `aria-invalid` to communicate validation errors; assistive technologies announce this state when set to `true`.
- **Minimum tap target**: The component MUST meet a minimum touch target height of 44×44pt; the default `min-h-16` (64px) minimum height satisfies this at every viewport width.
- **Keyboard navigation**: The component supports standard textarea keyboard behavior: Tab for focus, arrow keys for navigation, Enter for line breaks (no special intercept).
- **Focus indication**: The focus-visible state provides a visible focus indicator via a border and ring color change. Whether this meets WCAG 2.1 Level AA contrast and visibility standards depends on the underlying `apt-gold` token's contrast against the background (see Compliance) — this component does not define that contrast itself.

