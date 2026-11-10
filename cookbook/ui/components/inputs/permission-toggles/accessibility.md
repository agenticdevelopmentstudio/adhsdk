
- **Role**: Each button is a standard `<button>` element. Container has `role="group"`.
- **Pressed state announcement**: Each button MUST use `aria-pressed` to announce whether the permission is enabled or disabled, per **aria-pressed-reflects-on** — the announced state follows the displayed `on` state, not the raw `value`.
- **Labels**: Each button has a visible single-letter label (C, R, U, D) and a `title` attribute providing context (see **title-describes-action**).
- **Keyboard navigation**: Buttons are focusable and activate on Space or Enter (native button behavior). A button that is disabled — globally or because the parent blocks it — uses the native `disabled` attribute, so it is also removed from the tab order; this is native `<button>` semantics, not a separate behavior of this component.
- **Group label**: The container's `aria-label="CRUD permissions"` announces the purpose of the group.
- **Disabled state announcement**: When a button is disabled (either globally or by parent), the native `disabled` attribute is what communicates unavailability to assistive technology — it removes the button from the accessibility tree and the tab order. The reduced opacity and `not-allowed` cursor are visual-only cues for sighted users; they do not themselves communicate anything to assistive technology.
- **minimum-tap-target**: NEEDS REVIEW: Not implemented in source. Buttons are fixed at 28×28px with no mechanism to grow them; Apple HIG and Material Design 3 recommend touch targets of at least 44×44pt / 48×48dp respectively, and whether 28×28px is acceptable for this component or must grow to the platform minimum is undecided (see Design Decision "28×28px button size" for the tradeoff).
- **Color dependency**: Enabled and disabled states are distinguished by color change and opacity. Differentiation also includes cursor style and text content, reducing reliance on color alone.

