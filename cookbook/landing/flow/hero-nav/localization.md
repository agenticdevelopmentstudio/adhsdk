
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `label` prop | Host-supplied | The `nav`'s accessible name; the test passes "Sections". |
| `rows[].label` | Host-supplied | Each link's text; displayed uppercase by `text-transform`. |
| separator | `\|` | A literal bar that is `aria-hidden`; it is not a translatable string. |

All visible copy is supplied by the host. Layout direction is not handled specially: the row is a flex row, so it follows the document's writing direction by default.

