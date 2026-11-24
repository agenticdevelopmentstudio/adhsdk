
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| spinner-001 | render-indicator | `<Spinner />` | A circular indeterminate spinner icon is visible on screen (rendered via Lucide `Loader2` in the reference implementation) |
| spinner-002 | spin-animation | `<Spinner />` | Rendered element has a non-empty computed `animation-name` (Tailwind's `animate-spin` keyframe), indicating continuous rotation |
| spinner-003 | accept-classname | `<Spinner className="size-8 text-red-500" />` | Icon renders 2rem (32px) in red color, overriding defaults |
| spinner-004 | accept-props | `<Spinner data-testid="loading-indicator" />` | `data-testid` attribute is present on rendered element and accessible via DOM queries |
| spinner-005 | aria-label | `<Spinner />` rendered in a page | The rendered element exposes an accessible name of `"Loading"` (via the `aria-label` attribute), queryable through the accessibility tree (e.g. `getByRole('status', { name: 'Loading' })`) |
| spinner-006 | status-role | `<Spinner />` rendered in the DOM | Element has `role="status"` in its DOM attributes |
| spinner-007 | default-size | `<Spinner />` with no `className`, or a `className` that omits a `size-*` utility | Icon renders at exactly 1rem (16px) width and height |
| spinner-008 | default-color | `<Spinner />` with no `className`, or a `className` that omits a `text-*` color utility | Icon color matches the design system's muted text token (`text-apt-text-muted`) |

