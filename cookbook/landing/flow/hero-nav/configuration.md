
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rows` | `NavLink[]` (`{ href: string; label: string }`) | required | The links, in order; the page's own sections, such as `indexRows(page)`. |
| `label` | `string` | required | The `nav`'s accessible name; copy that the host owns. |

The lens options (selector, 2000 ms start delay, colour tokens) are fixed in the component and are not props. The tokens `--lp-ink-dim`, `--lp-accent-bright`, `--lp-accent` and `--lp-font-mono` are resolved where the row is mounted, so repainting the tokens repaints the sweep.

