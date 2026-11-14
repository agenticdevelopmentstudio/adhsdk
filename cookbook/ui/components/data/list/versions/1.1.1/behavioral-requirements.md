
- **semantic-list**: The List component MUST render a `<ul>` element.
- **semantic-item**: The ListItem component MUST render an `<li>` element.
- **classname-merge**: Both List and ListItem MUST accept a `className` prop and merge it with their base styles using the `cn()` utility (`twMerge(clsx(...))`); when the caller's `className` conflicts with a base Tailwind class, the caller's class MUST win.
- **prop-forwarding**: Both List and ListItem MUST forward all remaining React props (`...props`) to their underlying HTML element. This includes props such as `role`, which can override the element's implicit semantics — restoring or removing that semantics is the caller's responsibility.
- **data-slot**: The List component MUST set `data-slot="list"` on the rendered `<ul>`. The ListItem component MUST set `data-slot="list-item"` on the rendered `<li>`.

