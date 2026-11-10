
All user-facing text comes from caller-supplied props (`confirmLabel`, `cancelLabel`). The component supplies one hardcoded string: the busy spinner's `aria-label="Working…"` (see **show-busy-indicator**). The aria-label is rendered as English only; a host requiring localization must wrap or fork the component to substitute a localized label.

