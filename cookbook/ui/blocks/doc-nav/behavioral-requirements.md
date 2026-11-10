
- **render-sections**: Component MUST render top-level section nodes as collapsible controls; clicking the chevron control MUST toggle that section's child-list visibility.
- **render-branches**: Component MUST render branch nodes (children with their own children) as navigable links that always appear when their parent section is expanded, without a second collapse control.
- **render-leaves**: Component MUST render leaf nodes (children with no further children) as navigable links.
- **render-headings**: Component MUST render a leaf node's inline page headings (from `node.headings` array) as a sub-list of links indented beneath that leaf.
- **track-active-page**: Component MUST accept an `activePath` prop and highlight the current page link (using `aria-current="page"` and visual styling) when `activePath` matches the node's `href`.
- **track-ancestor**: Component MUST apply ancestor styling to branch nodes whose `href` is a segment-boundary prefix of `activePath` — `activePath` MUST equal `node.href` followed by `/` and additional path segments, not merely start with the same characters (e.g., `/docs/guides` is an ancestor of `/docs/guides/getting-started`, but `/docs/guide` is not an ancestor of `/docs/guides/getting-started`).
- **support-heading-scrolling**: When a heading link's page is already active (`activePath` matches the leaf's `href`), clicking the heading MUST prevent default navigation and scroll the target heading element into view smoothly; when the page is not active, the link MUST navigate normally.
- **set-hash-on-heading-scroll**: When scrolling to a heading on the active page, component MUST update `window.history.replaceState` to set the URL hash without triggering navigation.
- **preserve-section-state-on-route-change**: Section expansion state MUST NOT change when `activePath` updates; it MUST only change when the toggle control is clicked.
- **manage-drawer-open-state**: Component MUST accept an `open` prop to control drawer visibility and MUST call `onClose` when the scrim backdrop is clicked or the close button is clicked.
- **initialize-expanded-sections**: On mount, component MUST set expanded sections to include all sections whose `href` matches `activePath` exactly, or is a segment-boundary prefix of it (`activePath` equals `node.href` followed by `/` and additional path segments — see **track-ancestor**).
- **order-children**: Component MUST render a node's children in a fixed order: leaf nodes first, then branch nodes; the order does NOT follow the input array order.
- **distinguish-link-component**: Component MUST accept a `LinkComponent` prop and use it for all navigation links; if omitted, MUST default to a plain `<a href>` element.
- **support-top-and-bottom-links**: Component MUST render fixed navigation rows (`topLinks` and `bottomLinks`) above and below the tree respectively, each behind its own divider rule.
- **render-headings-only-on-leaves**: Inline page headings MUST only render when present on leaf nodes; branch nodes MUST NOT render heading sub-lists.

