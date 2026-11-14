
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| doc-link-001 | render-as-anchor | `<DefaultDocLink to="/docs">Link</DefaultDocLink>` | Renders as `<a href="/docs">Link</a>` in the DOM |
| doc-link-002 | accept-to-prop, pass-to-href | `to="/about"` | `href` attribute equals `/about` |
| doc-link-003 | accept-children, render-children | `children="Home"` | Link text displays as "Home" inside the anchor |
| doc-link-004 | accept-children, render-children | Multiple child elements (text + JSX) | All children render inside the anchor element |
| doc-link-005 | accept-and-spread-attributes | `className="nav-link"` and `data-testid="home-link"` | Both attributes present on the rendered anchor element |
| doc-link-006 | accept-and-spread-attributes | `onClick={handler}` passed as a prop | Handler is called when the link is clicked |
| doc-link-007 | pass-to-href, render-children | `to="/docs"` and `children="Read Docs"` | Renders as `<a href="/docs">Read Docs</a>` |
| doc-link-008 | empty-to-prop | `to=""` | Renders `<a href="">Link</a>`; the browser treats the empty `href` as navigation to the current page |
| doc-link-009 | missing-to-prop | `to={undefined}` (bypassing the type system) | React omits the `href` attribute entirely rather than rendering the literal string `"undefined"`; the resulting `<a>` has no `href`, so it is excluded from the tab order and is not exposed with the link role until a valid `href` is set |
| doc-link-010 | null-or-undefined-children, non-empty-accessible-label | `children={null}` and no `aria-label` | Anchor renders with no visible text and no accessible name; assistive technology announces it as an unlabeled link |
| doc-link-011 | unsafe-to-scheme | `to="javascript:alert(1)"` | `href` renders as `javascript:alert(1)` unchanged; the component performs no scheme validation |
| doc-link-012 | accept-and-spread-attributes | `href="/other"` forced into the spread attributes via a type-unsafe cast | Because `{...rest}` spreads after `href={to}`, the runtime `href` from the spread wins over `to` |
| doc-link-013 | conforms-to-doclinkcomponent | `const Link: DocLinkComponent = DefaultDocLink` | Type-checks without error, confirming `doc-breadcrumbs` and `doc-nav` can substitute a custom implementation (e.g., a Next.js adapter) in its place |

