
**Decision**: Backdrop dismissal is disabled by default for modals and alerts.
**Rationale**: Prevents accidental data loss and clarifies intent (see **backdrop-dismissal-disabled** above, which AlertModal and the other composing dialogs inherit unchanged); pointer dismissal is opt-in for advanced use cases.
**Approved**: pending

**Decision**: Built on Base UI (`@base-ui/react/dialog`) rather than a hand-rolled implementation.
**Rationale**: Inherits focus trapping, portalling, and assistive technology support, reducing maintenance burden and ensuring standards compliance.
**Approved**: pending

**Decision**: Backdrop opacity is 30% black (`bg-black/30`), not 60%.
**Rationale**: Keeps the underlying page legible and subordinate while preserving context; the harder 60% opacity obscured the page entirely.
**Approved**: pending

**Decision**: All colors and spacing use the `apt-*` design-token family.
**Rationale**: Ensures consistent theming across the product without raw hex values or `!important` overrides.
**Approved**: pending

