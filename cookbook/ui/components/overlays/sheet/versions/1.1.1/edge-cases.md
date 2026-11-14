
- **Null/empty content**: If SheetContent is rendered with no children, drawer is still visible but empty. No error is thrown (see sheet-019).
- **Overlay interaction**: Covered by **close-on-overlay-click** — clicking the overlay closes the drawer by default, inherited from Base UI's Dialog root (see sheet-014).
- **Multiple sheets**: The component places no limit on how many Sheet instances may be open at once; each renders independently via its own Base UI Portal. SheetOverlay and SheetContent both use a fixed `z-50`, so the visual stacking order between multiple simultaneously open sheets is determined by DOM order, not managed by the component (see sheet-020).
- **Animation interruption**: Rapidly toggling the drawer open and closed interrupts the current CSS transition; the browser continues from its current computed opacity/transform value toward the new target (standard CSS transition-interruption behavior). No additional interruption handling exists in source beyond this (see sheet-021).
- **Side boundary**: On mobile with `side="left"` or `side="right"`, the 75%-capped-at-24rem width constraint may leave insufficient space; width calculations use viewport units without media-query safety checks for very narrow viewports (see sheet-022).
- **Custom animation scale**: A scale of 0 or negative computes a zero-or-negative transition-duration; CSS clamps this to an instant (zero-duration) transition, per **animation-scale** (see sheet-013). The defined behavior comes from CSS's own duration clamping, not app-level validation.

