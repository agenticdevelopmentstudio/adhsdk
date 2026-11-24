
- **render-as-anchor**: The component MUST render as an HTML `<a>` element.
- **pass-to-href**: The component MUST accept a `to` prop (string) and pass its value to the `href` attribute of the rendered anchor element.
- **render-children**: The component MUST accept `children` (ReactNode) and render them inside the anchor element as the link text content.
- **accept-and-spread-attributes**: The component MUST accept additional HTML anchor attributes (via `Omit<AnchorHTMLAttributes, "href">`) and pass them through to the rendered anchor element without modification (see Design Decisions for spread precedence).
- **conforms-to-doclinkcomponent**: The component MUST be structurally assignable to the `DocLinkComponent` type (`ComponentType<{ to: string; children?: ReactNode } & Omit<AnchorHTMLAttributes<HTMLAnchorElement>, "href">>`), so consumers such as `doc-breadcrumbs` and `doc-nav` can substitute an alternate implementation (for example, a Next.js `Link` adapter) in its place without changing their own code.
