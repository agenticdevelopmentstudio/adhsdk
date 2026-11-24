
- **Header role**: Component renders a semantic `<header>` element.
- **Navigation label**: The bar's `<nav>` element carries the `aria-label` required by **render-bar-nav**, overridable via the `navLabel` prop from `NavChromeProps`.
- **Link announcements**: Navigation links are real `<a>` elements, so screen readers announce them wherever they are rendered. Below the breakpoint the bar's `<nav>` is CSS-hidden and so leaves the accessibility tree (only crawlers still read it); the drawer is the only route assistive technology has to the links there.
- **Duplicate prevention**: Navigation links in the drawer are not duplicated in the bar under `bar='drawer'`, avoiding duplicate link destinations that assistive technology would discover.
- **Drawer management**: Focus trap and `inert` handling are delegated to `NavChrome`.

