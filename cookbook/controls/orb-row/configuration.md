
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `sites` | `OrbSite[]` | required | Ordered list of sites to render as orbs. Each `OrbSite` requires `id`, `name`, `emoji`, `iconGradient`, and `url` (all `string`); the component renders them directly and does not validate that they are present. |
| `currentSite` | `string` (an `OrbSite.id`) | `undefined` | ID of the site to mark as current; no orb is marked current when omitted or when it matches no site. |
| `docked` | `boolean` | `undefined` (falsy) | When `true`, applies the `is-docked` class for the fixed-position layout variant. |
| `className` | `string` | `undefined` | Appended to the root container's class list. |

