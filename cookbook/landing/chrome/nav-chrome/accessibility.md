
- **Role**: The navigation bar is a `<div>` (not a `<header>` to avoid creating an unintended banner landmark when a host header already exists). The drawer is a `<nav>` with `aria-label={navLabel}`.
- **Labels**: Burger button labeled via `aria-label={openLabel}`. Close button labeled via `aria-label={closeLabel}`. Nav drawer labeled via `aria-label={navLabel}`.
- **Focus management**: Focus moves to the close button when the drawer opens. Focus returns to the burger button when the drawer closes (if it was previously open). Fragment link clicks move focus to the target element with `tabindex="-1"`.
- **Inert**: Drawer carries the `inert` attribute when closed (absent when open), preventing keyboard and assistive technology access.
- **Tab trap**: Tab key is trapped inside the drawer when open; focus wraps from last to first and first to last, and is pulled back inside if it ever lands outside the drawer while open. See #requirements/trap-tab-inside-drawer.
- **Escape key**: Escape closes the drawer, the standard dismissal gesture.
- **Scrim**: Scrim has `aria-hidden="true"` and is not focusable; it is a visual overlay for pointer users only.
- **Keyboard accessibility**: All navigation is keyboard-accessible: Escape exits the drawer, Tab and Shift+Tab wrap focus within it, and all links are reachable.
- **Link semantics**: Links are standard `<a>` elements with real `href` attributes, so they degrade gracefully without JavaScript.
- **Minimum touch target**: Component does not define a minimum tap target size; host CSS MUST ensure the burger and close buttons meet WCAG 2.5.8 (24×24 CSS px minimum) and SHOULD meet 2.5.5 (44×44 CSS px).
- **Modal pattern departure**: The drawer is modal to pointer and keyboard (tab-trapped, `inert` when closed), but it does not implement the full WAI-ARIA dialog-modal pattern this ingredient cites for reference: there is no `role="dialog"`/`aria-modal="true"` on the drawer and no `aria-controls` on the burger button. Modality here is enforced procedurally (the tab trap plus `inert`) rather than declared through dialog semantics, and only the drawer is made `inert`: page content behind the open drawer stays in the accessibility tree, so a screen reader's virtual cursor can leave the drawer (see Compliance), which keeps the drawer a `<nav>` landmark rather than an unlabeled dialog; the cited pattern is followed for its focus-trap and Escape-to-dismiss behavior, not adopted as a literal `role="dialog"` implementation.

