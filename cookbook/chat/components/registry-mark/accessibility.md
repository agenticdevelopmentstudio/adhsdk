
- **Role**: The underlying `<a>` element provides the link role (implicit).
- **Label**: Required `label` prop is set as the link's `aria-label` attribute (see **accessible-name**), providing an accessible name (e.g., "Visit X's profile on the registry"). Because the link always opens in a new tab, `label` SHOULD also disclose that — see **new-window-disclosure**.
- **SVG accessibility**: SVG has `aria-hidden="true"` to remove it from the accessibility tree; the link's accessible name suffices.
- **Keyboard navigation**: Link is keyboard-reachable; on `:focus-visible` the companion CSS outlines the link and reveals the popover (see States).
- **Popover keyboard access**: When `tip` content is provided, it contains interactive elements (links); the popover stays visible and keyboard-reachable while focus is anywhere within the mark, via the companion CSS's `:has(:focus-visible)` rule — see **popover-visible-on-focus-or-hover**. The component performs no JS-based focus management (no trapping, no programmatic redirects).
- **Minimum touch target**: The target is at least 44×44 CSS px. The default `--pc-rm-size` of `34px` makes the link `34×53.4px`, so its width does not meet the target at the default size and the component adds no padding or hit-area extension; a host must raise `--pc-rm-size` to at least `44px` to conform.

