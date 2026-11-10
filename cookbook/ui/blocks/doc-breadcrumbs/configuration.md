
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `crumbs` | `{ label: ReactNode; path: string }[]` | (required) | Array of breadcrumb objects, ordered root-first. Last crumb is the current page. |
| `homeLabel` | `ReactNode` | `"Home"` | Label displayed for the always-present first crumb. |
| `homeHref` | `string` | `"/"` | URL destination for the home crumb. |
| `LinkComponent` | `DocLinkComponent` | `DefaultDocLink` | Custom link component to replace the default. Receives `to: string` (the destination), an optional `children: ReactNode`, and any other anchor attribute except `href` (including `className`). The default, `DefaultDocLink`, renders a plain `<a href={to}>{children}</a>`. |

