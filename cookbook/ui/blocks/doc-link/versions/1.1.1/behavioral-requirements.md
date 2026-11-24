
- **render-as-anchor**: The component MUST render as an HTML `<a>` element.
- **accept-to-prop**: The component MUST accept a `to` prop (string) specifying the destination path.
- **pass-to-href**: The component MUST pass the `to` prop value to the `href` attribute of the rendered anchor element.
- **accept-children**: The component MUST accept `children` (ReactNode) as the link text content.
- **render-children**: The component MUST render `children` inside the anchor element.
- **accept-and-spread-attributes**: The component MUST accept additional HTML anchor attributes (via `Omit<AnchorHTMLAttributes, "href">`) and pass them through to the rendered anchor element without modification. `{...rest}` is spread after `href={to}` in JSX, so the `Omit` type is what keeps `to` authoritative for `href` in normal, typed usage; a caller that bypasses the type system to smuggle `href` into the spread attributes would have that value win over `to`.
- **conforms-to-doclinkcomponent**: The component MUST be structurally assignable to the `DocLinkComponent` type (`ComponentType<{ to: string; children?: ReactNode } & Omit<AnchorHTMLAttributes<HTMLAnchorElement>, "href">>`), so consumers such as `doc-breadcrumbs` and `doc-nav` can substitute an alternate implementation (for example, a Next.js `Link` adapter) in its place without changing their own code.
- **non-empty-accessible-label**: The caller SHOULD provide non-empty `children` or an `aria-label`; an anchor with no accessible text confuses assistive technology users even though it remains focusable.

