
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| landing-card-001 | render-title | `title="Explore Stories"` | Output contains `<h3>Explore Stories</h3>` |
| landing-card-002 | render-children | `children="Browse our collection"` | Output contains text node "Browse our collection" after the title |
| landing-card-003 | support-optional-kicker, render-kicker-before-title | `kicker="Preview"` | Output contains `<span class="lp-card__kicker">Preview</span>` before the `<h3>` |
| landing-card-004 | support-optional-kicker | `kicker={undefined}` (or omitted) | Kicker `<span>` absent from DOM |
| landing-card-005 | use-card-class | Any props | Root `<div>` has class `lp-card` |
| landing-card-006 | use-kicker-class | `kicker="Label"` | Kicker span has class `lp-card__kicker` |
| landing-card-007 | accept-react-nodes | `title={<em>Dynamic</em>}` | Title renders the React element inside the `<h3>` |
| landing-card-008 | accept-react-nodes | `children={<ul><li>Item</li></ul>}` | Children render the list elements after the title |
| landing-card-009 | tolerate-nullish-title | `title={null}` (or `undefined`) | Output contains an empty `<h3></h3>`; no error thrown |
| landing-card-010 | tolerate-nullish-children | `children={null}` (or `undefined`) | Card renders the root `<div>` and `<h3>` with no content after the title; no error thrown |

