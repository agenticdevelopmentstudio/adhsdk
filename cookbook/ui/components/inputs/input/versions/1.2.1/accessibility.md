
- **Role/trait**: HTML input element with role="textbox" (implicit); supports type attribute for specialized roles (search, password)
- **Label requirements**: MUST be associated with an external `<label>` element using matching `id` and `for` attributes; the component itself does not provide a label
- **Announce state changes**: Component supports `aria-invalid="true"` attribute to signal validation errors to screen readers; invalid state MUST be applied at the form/page level alongside visual indicator
- **Announce disabled state**: Native HTML disabled attribute automatically communicated by assistive technology
- **Minimum tap target**: 36px height (h-9) meets the WCAG 2.5.8 minimum of 24px; it does not meet Android's 48dp or iOS's 44pt native minimums, so native ports MUST size the control to their own platform's minimum tap target
- **Keyboard support**: Native HTML input keyboard navigation; focus indicator visible via `focus-visible:ring` and border color change

