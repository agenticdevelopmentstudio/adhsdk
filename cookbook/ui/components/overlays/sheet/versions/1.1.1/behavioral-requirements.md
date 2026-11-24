
- **render-compound-components**: Component MUST export individual compound parts: Sheet (root), SheetTrigger, SheetClose, SheetContent, SheetHeader, SheetFooter, SheetTitle, and SheetDescription. `SheetPortal` and `SheetOverlay` are module-local helpers used only inside SheetContent; they are not exported and are not importable by consumers.
- **position-by-side**: SheetContent MUST position the drawer based on a `side` prop ("top" | "right" | "bottom" | "left"), with default value "right".
- **render-overlay**: Component MUST render an overlay element with semi-transparent dark background that appears behind the drawer.
- **backdrop-blur**: Overlay MUST apply a blur effect (backdrop-filter: blur) on supporting browsers.
- **close-button-default-visible**: SheetContent MUST render a close button by default in the top-right corner.
- **close-button-visibility-control**: SheetContent MUST accept a `showCloseButton` boolean prop (default `true`) to control close button visibility.
- **close-icon**: Close button MUST render a close ("X") icon.
- **close-button-accessible-label**: Close button MUST include a screen-reader-accessible label ("Close") identifying its purpose to assistive technology.
- **animate-transitions**: Drawer content and overlay MUST animate with a CSS transition on appearance and disappearance.
- **animation-scale**: Animation duration MUST be calculated using the CSS custom property `--apt-anim-scale` (default 1), with specific durations: 150ms for overlay, 200ms for drawer. A scale of 0 or a negative value MUST result in an instant (zero-duration) transition, since a non-positive value multiplied against either base duration computes to zero or less and CSS clamps a negative transition-duration to 0.
- **close-on-overlay-click**: Clicking the overlay MUST close the drawer by default. Base UI's Dialog root ships pointer dismissal enabled unless a caller passes `disablePointerDismissal`; Sheet does not set that prop, so the inherited default applies. Callers MAY disable it by passing `disablePointerDismissal` to `Sheet`.
- **width-constrained-on-sides**: When positioned left or right, SheetContent MUST constrain width to 75% of the viewport, capped at 24rem on small+ (`sm`, ≥640px) screens.
- **content-composition-props**: Sheet, SheetTrigger, SheetClose, and SheetContent MUST accept and spread component props to their underlying Base UI primitives. Internally, the module-local `SheetPortal` and `SheetOverlay` helpers do the same, but that is unreachable from outside the module since neither is exported (see **render-compound-components**).
- **header-footer-divs**: SheetHeader and SheetFooter MUST render as `<div>` elements with predefined padding and flex layout.
- **title-description-typography**: SheetTitle and SheetDescription MUST wrap Base UI primitives with styled typography.

