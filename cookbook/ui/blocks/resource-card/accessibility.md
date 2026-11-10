
- **Root element role**: When `href` is set, a native or LinkComponent-wrapped anchor element (implicit link role). When `onClick` is set without `href`, a div with `role="button"`. When neither is set, a div with no explicit role (content container).
- **Keyboard activation**: When role="button", Enter and Space keys MUST trigger the click handler. Anchor elements receive native browser keyboard support. See **keyboard-activation**.
- **Focus indicator**: Focus-visible state applies a visible border color change (focus-accent), satisfying visibility requirements.
- **Text labels**: Title is rendered as plain text; no aria-label or aria-description attributes are used in the component, so content must be self-describing.
- **Identifier label**: Identifier is rendered in monospace and is visually secondary; implementers should ensure context makes its purpose clear (e.g., via a label above it or in documentation).
- **Touch/click target size**: The card's default padding (1.25rem on all sides) combined with its full-width layout MUST produce a touch target of at least 44×44pt in normal use (a title-only card is already taller than 44pt once line-height and padding are included). Implementers who override the default padding or width via `className` are responsible for preserving this minimum.

