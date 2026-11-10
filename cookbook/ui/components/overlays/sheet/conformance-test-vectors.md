
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| sheet-001 | render-compound-components | Import Sheet and sub-components | All 8 exports (Sheet, SheetTrigger, SheetClose, SheetContent, SheetHeader, SheetFooter, SheetTitle, SheetDescription) are available and usable; importing `SheetPortal` or `SheetOverlay` fails, since neither is exported. |
| sheet-002 | position-by-side | Render SheetContent with `side="left"` | Drawer appears on left edge of viewport with `data-side="left"` attribute. |
| sheet-003 | position-by-side | Render SheetContent without a `side` prop | Drawer appears on right edge (default) with `data-side="right"` attribute. |
| sheet-004 | render-overlay | Render Sheet with content | Overlay element with `data-slot="sheet-overlay"` appears behind drawer. |
| sheet-005 | backdrop-blur | Inspect overlay's computed style in a supporting browser | Overlay's computed `backdrop-filter` includes a blur value (implemented via the `supports-backdrop-filter:backdrop-blur-xs` Tailwind utility — see React/Web Platform Note). |
| sheet-006 | close-button-default-visible | Render SheetContent without `showCloseButton` prop | Close button renders in top-right corner. |
| sheet-007 | close-button-visibility-control | Render SheetContent with `showCloseButton={false}` | Close button does not render. |
| sheet-008 | close-icon | Inspect the close button's icon graphic | Icon renders as an "X" shape (implemented via lucide-react's `XIcon` — see React/Web Platform Note). |
| sheet-009 | close-button-accessible-label | Render close button and inspect its accessible name | Close button exposes the accessible name "Close" to assistive technology (implemented via a visually hidden span — see React/Web Platform Note). |
| sheet-010 | animate-transitions | Open the drawer and inspect CSS during entry | Drawer and overlay apply `transition` CSS; opacity and transform animate from their starting-style values to their open-state values. |
| sheet-011 | animate-transitions | Close the drawer and inspect CSS during exit | Drawer and overlay apply `transition` CSS; opacity and transform animate from their open-state values to their ending-style values. |
| sheet-012 | animation-scale | Open drawer with `--apt-anim-scale` set to 2 | Overlay animation duration is 300ms (150ms × 2); drawer animation is 400ms (200ms × 2). |
| sheet-013 | animation-scale | Open drawer with `--apt-anim-scale` set to 0 or a negative value | Computed transition-duration is 0 (0 or negative ms clamps to 0), so the drawer and overlay transition instantly with no visible animation. |
| sheet-014 | close-on-overlay-click | Click the overlay while the drawer is open | Drawer closes; `onOpenChange` fires with a pointer/outside-press dismissal reason. |
| sheet-015 | width-constrained-on-sides | Render SheetContent with `side="right"` on a small+ (≥640px) viewport | Width is 75% of viewport width, capped at 24rem (`sm:max-w-sm` applies once 75% would exceed 24rem). |
| sheet-016 | content-composition-props | Render SheetContent with additional `className` | Additional class is applied to the drawer element. |
| sheet-017 | header-footer-divs | Render SheetHeader and SheetFooter | Both render as `<div>` elements with padding (`p-4`) and flex layout. |
| sheet-018 | title-description-typography | Render SheetTitle and SheetDescription | Title renders with `font-medium`, description with muted foreground color. |
| sheet-019 | Edge case: null/empty content | Render SheetContent with no children | Drawer renders visible but empty; no error is thrown. |
| sheet-020 | Edge case: multiple sheets | Render two Sheet instances simultaneously, both open | Both render independently via separate Base UI Portals; because SheetOverlay and SheetContent both use a fixed `z-50`, relative stacking order between the two is determined by DOM order, not managed by the component. |
| sheet-021 | Edge case: animation interruption | Toggle the drawer open, then toggle it closed before the opening transition finishes | The CSS transition is interrupted and reverses from its current computed value (standard CSS transition-interruption behavior); no additional interruption handling exists in source beyond this. |
| sheet-022 | Edge case: side boundary | Render SheetContent with `side="left"` on a 320px-wide viewport | Drawer renders at 75% of viewport width (240px); no additional minimum-width or narrow-viewport safeguard is applied by the component. |

