
- **Dialog role**: Component uses `role="dialog"` and `aria-modal="true"` to signal a modal dialog to assistive technology.
- **Accessible label**: Component applies `aria-label` from the `ariaLabel` prop to the dialog container.
- **Heading**: The heading is rendered as an h2 element to provide semantic structure.
- **Close button label**: Close button has `aria-label="Close"` to describe its purpose to screen readers.
- **Form labels**: Responsibility for form field labeling and accessibility is delegated to the `renderForm` callback.
- **Error announcement**: The `error` value is handed to `renderForm` for inline display; the component itself uses no ARIA live region, so whether an error reaches assistive technology as an announcement (e.g. via `aria-describedby` or a live region) depends on the host's `renderForm` implementation.
- **Keyboard navigation**: DOM order (and default Tab order) is the close (×) button, then the form fields rendered by `renderForm`, then Cancel, then Save; Escape is handled through the same close guard as Cancel and ×.
- **Focus management**: The source calls no focus API. It does not move focus into the dialog on open, does not confine Tab within it while open, and does not restore focus to the invoking control on close — all three left unhandled for a container that declares `role="dialog"` and `aria-modal="true"`, where the WAI-ARIA Authoring Practices dialog pattern and WCAG 2.1 SC 2.4.3 (Focus Order) call for each.
- **Backdrop interaction**: Backdrop click is intentionally non-interactive to prevent accidental dismissal; this is accessible since keyboard and explicit buttons provide alternatives.
- **Minimum touch target**: Cancel and Save are text buttons at the `default` size (`h-8`, 32px tall, width driven by label + padding). The close (×) button uses `icon-sm` (`size-7`, 28×28px), below the 44×44pt/48×48dp guideline, unless a host surface raises the shared `--adh-button-min-height`/`--adh-button-min-width` CSS variables that `Button` reads for exactly this purpose; this dialog does not set them itself.

