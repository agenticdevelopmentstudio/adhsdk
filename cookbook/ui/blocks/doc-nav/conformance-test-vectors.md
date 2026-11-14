
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| doc-nav-001 | render-sections | nodes with depth 0 | Each section renders a button with `aria-expanded`; activating it hides or shows the section's child list |
| doc-nav-002 | render-branches | node with children that have children | Branch links render without collapse control; appear when parent section is expanded |
| doc-nav-003 | render-leaves | node with children that have no further children | Leaf links render |
| doc-nav-004 | track-active-page | activePath="/docs/guides" with matching node href | Link styled with semibold, primary color, and left accent bar; aria-current="page" set |
| doc-nav-005 | track-ancestor | activePath="/docs/guides/getting-started" with ancestor node href="/docs/guides" | Ancestor link styled with medium weight and primary color; no accent bar |
| doc-nav-006 | support-heading-scrolling | activePath matches leaf, heading link clicked | preventDefault called, target element scrolled into view smoothly, history.replaceState called with hash |
| doc-nav-007 | support-heading-scrolling | activePath does NOT match leaf, heading link clicked | Link navigates normally (default behavior not prevented) |
| doc-nav-008 | preserve-section-state-on-route-change | Section expanded, activePath changed | Expanded state unchanged; only toggle control changes it |
| doc-nav-009 | manage-drawer-open-state | open=true, onClose callback provided | Drawer rendered and visible; clicking scrim calls onClose; clicking close button calls onClose |
| doc-nav-010 | initialize-expanded-sections | activePath="/section1/page" on mount | Sections whose `href` equals `activePath` exactly, or is a segment-boundary prefix of it (e.g. `href="/section1"`), are auto-expanded; other sections collapsed |
| doc-nav-011 | order-children | node with mixed leaves and branches in arbitrary input order | Leaves rendered first, then branches, regardless of input order |
| doc-nav-012 | distinguish-link-component | LinkComponent prop with custom link component provided | Custom component used for all links; defaulting to `<a href>` if omitted |
| doc-nav-013 | support-top-and-bottom-links | topLinks array with entries | Fixed rows render above tree with divider below them |
| doc-nav-014 | support-top-and-bottom-links | bottomLinks array with entries | Fixed rows render below tree with divider above them |
| doc-nav-015 | render-headings-only-on-leaves | branch node with headings array | Heading sub-list does NOT render; headings only on leaves |
| doc-nav-016 | render-headings | leaf node with a non-empty `headings` array | Heading sub-list renders below the leaf link, one entry per heading |
| doc-nav-017 | render-sections | click a section's label | Navigates to the section's `href` through `LinkComponent`; expanded state unchanged |
| doc-nav-018 | order-children | leaves A, B and branches X, Y in input order X, A, Y, B | Rendered A, B, X, Y (input order kept within each group) |
| doc-nav-019 | render-headings | leaf with headings of depths 2 and 3 | Both render in array order at one indent |
| doc-nav-020 | drawer-focus-management | open=true, then Escape pressed | Focus moved into the drawer on open; Escape calls `onClose`; focus returns to the opener |
| doc-nav-021 | label-navigation-landmarks | open=true at `lg+` | Two `<nav>` landmarks, each with a different `aria-label` |
