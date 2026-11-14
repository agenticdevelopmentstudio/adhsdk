
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| nodes | HdvNavNode[] | required | Top-level sections of the document tree |
| activePath | string | required | Current route path; used to highlight active link and expand parent sections |
| topLinks | DocNavTopLink[] | [] | Fixed navigation rows above the tree |
| bottomLinks | DocNavTopLink[] | [] | Fixed navigation rows below the tree |
| LinkComponent | React component | DefaultDocLink (a href) | Router link component for all navigation links |
| open | boolean | false | Controls drawer visibility; only affects mobile drawer |
| onClose | () => void | undefined | Callback when drawer is dismissed by scrim or close button |
| title | ReactNode | "Navigation" | Drawer heading text |
| closeLabel | string | "Close navigation" | aria-label for drawer close button |
| className | string | undefined | CSS class applied to desktop aside only; not copied to drawer |
| ...rest | HTMLAttributes | {} | Standard HTML attributes (id, data-*, etc.) applied to desktop aside only |

