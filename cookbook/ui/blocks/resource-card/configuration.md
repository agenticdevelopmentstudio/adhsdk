
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | `ReactNode` | required | The card's name |
| `identifier` | `ReactNode` | none | Reverse-domain identifier, in monospace |
| `description` | `ReactNode` | none | Body text, clamped to 3 lines |
| `meta` | `ReactNode` | none | Row of mono-dim chips |
| `onClick` | `() => void` | none | Makes the card act; with `href` it also fires on the link |
| `href` | string | none | Makes the whole card a real link |
| `LinkComponent` | `DocLinkComponent` | `DefaultDocLink` (a plain anchor) | The host's router link, used only when `href` is set; receives the destination as `to` |
| `className` | string | none | Merged over the card's classes |

