
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `brand` | `ReactNode` | `undefined` | Wordmark or branding element rendered in the header bar |
| `links` | `NavChromeProps['links']` | Required | Array of navigation links; always passed to the drawer |
| `barLinks` | `NavChromeProps['links']` | `links` | Array of navigation links for the inline bar only (at the breakpoint or wider); shorter than the full list, typically |
| `action` | `ReactNode` | `undefined` | Call-to-action element pinned to the right of the bar (visible at the breakpoint or wider only) |
| `bar` | `'nav' \| 'drawer'` | `'nav'` | Navigation mode: `'nav'` shows the inline links at the breakpoint or wider; `'drawer'` keeps the burger at every width |
| `footer` | `NavChromeProps['footer']` | `undefined` (no footer rendered) | Footer content passed through to `NavChrome`'s drawer |
| `navLabel` | `NavChromeProps['navLabel']` | `'Site'` | `aria-label` for the inline `<nav>` element, and passed through to `NavChrome`'s own drawer `<nav>` |

