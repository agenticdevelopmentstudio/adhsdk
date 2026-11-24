
**Decision**: Backdrop dismissal is disabled by default for modals and alerts.
**Rationale**: Prevents accidental data loss and clarifies intent (see [backdrop-dismissal-disabled](#requirements/backdrop-dismissal-disabled), which AlertModal and the other composing dialogs inherit unchanged).
**Approved**: pending

**Decision**: Built on Base UI (`@base-ui/react/dialog`) rather than a hand-rolled implementation.
**Rationale**: Inherits focus trapping, portalling, and assistive technology support, reducing maintenance burden and ensuring standards compliance.
**Approved**: pending

**Decision**: Backdrop opacity is 30% black (`bg-black/30`), not 60%.
**Rationale**: Keeps the underlying page legible and subordinate while preserving context. This is a stated preference: the source comment records that the earlier 60% dim put the page out of reach of reading, but cites no review or screenshot.
**Approved**: pending

**Decision**: All colors and spacing use the `apt-*` design-token family.
**Rationale**: Ensures consistent theming across the product without raw hex values or `!important` overrides.
**Approved**: pending

**Decision**: The close button's hit area stays at its `size-4` (16×16px) icon, below the 44×44 target.
**Rationale**: A known gap, not an accepted trade-off: `dialog.tsx` adds no padding to enlarge the target, and no decision has been made to fix or accept it. See `touch-target-size` in Compliance.
**Approved**: pending

**Decision**: The close button's `aria-label="Close"` stays hardcoded in English.
**Rationale**: A known gap, not an accepted trade-off: `DialogContent` offers no `closeLabel` prop, and no decision has been made to add one or accept the limitation. See the two internationalization checks in Compliance.
**Approved**: pending
