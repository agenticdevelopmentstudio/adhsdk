
- **Header role**: Component renders a semantic `<header>` element.
- **Navigation label**: The `<nav>` element inside the bar MUST have an `aria-label` attribute, defaulting to "Site" unless overridden via `navLabel` prop from `NavChromeProps`.
- **Link announcements**: Navigation links are real `<a>` elements, allowing screen readers to discover them.
- **Duplicate prevention**: Navigation links in the drawer are not duplicated in the bar under `bar='drawer'`, avoiding duplicate link destinations that assistive technology would discover.
- **Drawer management**: Focus trap and `inert` handling are delegated to `NavChrome`.

