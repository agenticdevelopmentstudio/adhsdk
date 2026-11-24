
| ID | Requirements | Input | Expected |
|----|---|---|---|
| separator-001 | semantic-role, horizontal-orientation | No props (defaults) | Renders with separator role and horizontal orientation exposed to assistive technology; on web: `<div role="separator" aria-orientation="horizontal" ...>` with 1px height and full width |
| separator-002 | vertical-orientation, orientation-sync | `orientation="vertical"` | Renders with separator role and vertical orientation exposed to assistive technology; on web: `<div role="separator" aria-orientation="vertical" ...>` with 1px width and full height |
| separator-003 | custom-style-override | `className="custom-class"` (web) | Rendered element includes `custom-class` in its className alongside base styles |
| separator-004 | forwarded-props | `data-testid="my-sep" id="sep1"` (web) | Rendered element includes `data-testid="my-sep"` and `id="sep1"` |
| separator-005 | semantic-role, orientation-sync | `orientation="diagonal"` (unrecognized value, web) | Renders with separator role; `aria-orientation="diagonal"` and `data-orientation="diagonal"` are set verbatim (no validation), but no `data-[orientation=...]` CSS rule matches, so the element receives no explicit height/width beyond `shrink-0` |

