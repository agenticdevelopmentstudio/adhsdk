
- **Role**: Landmark (`<footer>` renders the implicit `contentinfo` role)
- **Landmark exposure**: The `<footer>` element only exposes the `contentinfo` landmark role when it is NOT nested inside `article`, `section`, `main`, `aside`, or `nav`. `Flow` renders its own children (the page's bands) inside a `<main class="lp-flow">`, so a host MUST render `SiteFooter` as a sibling of the page's `Flow` container itself — outside that `<main>` — and not merely alongside the individual bands as one of `Flow`'s own children, or the footer loses its `contentinfo` role. The component itself renders only the element and does not enforce where it is mounted.
- **Label requirements**: No explicit ARIA labeling required; a page normally has one `<footer>` landmark, so no accessible name is needed to disambiguate it.
- **Keyboard navigation**: Not applicable; the component itself renders no interactive elements — see **style-descendant-links** for the descendant links it styles but does not create.
- **Touch target size**: Not applicable; component is a container, not an interactive control.

