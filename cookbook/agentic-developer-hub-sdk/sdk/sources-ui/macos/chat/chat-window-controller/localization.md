
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `appearanceTitle` | *(required, no default)* | Caption at the top of the gear's panel, supplied by the host via `ChatWindowConfiguration`; the host is responsible for localizing it. |
| `backdropToggleTitle` | "Background animation" | Label for the backdrop toggle in the appearance panel. `ChatWindowConfiguration.init` bakes this English literal in as the default when a host does not override it — a host that relies on the default rather than supplying its own value MUST still localize it upstream (e.g. give it a strings-catalog key); it is not an invariant, non-user-facing string. |

