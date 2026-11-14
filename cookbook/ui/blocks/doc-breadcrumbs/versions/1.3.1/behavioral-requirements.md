
- **render-navigation-element**: Component MUST render a `<nav>` element with `aria-label="Breadcrumb"`.
- **include-home-crumb**: Component MUST always include a home crumb as the first item, rendered as a link to `homeHref` (default `"/"`).
- **render-crumbs-list**: Component MUST render crumbs as an ordered list (`<ol>`) with each crumb as a list item (`<li>`).
- **render-current-as-text**: Component MUST render the last crumb (current page) as plain text, not a link.
- **render-ancestors-as-links**: Component MUST render all crumbs except the last as links to their `path` values.
- **separate-crumbs**: Component MUST visually separate crumbs with a "/" character.
- **render-nothing-at-root**: Component MUST return `null` when `crumbs` array is empty (no ancestors).
- **accept-custom-link-component**: Component MUST accept an optional `LinkComponent` prop and use it for all links instead of plain `<a>` elements.
- **accept-custom-home-label**: Component MUST accept an optional `homeLabel` prop to override the default "Home" label.
- **accept-custom-home-href**: Component MUST accept an optional `homeHref` prop to override the default "/" destination for the home crumb.
- **accept-crumbs-array**: Component MUST accept a required `crumbs` prop containing an array of objects with `label` (`ReactNode`) and `path` (string) properties, ordered root-first.
- **forward-html-attributes**: Component MUST accept and forward remaining HTMLAttributes to the `<nav>` element.

