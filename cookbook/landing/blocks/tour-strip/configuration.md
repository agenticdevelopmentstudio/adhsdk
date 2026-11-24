
| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `eyebrow` | string | Yes | — | Text label for the tour step (e.g., "Introduction"). Rendered in step progress header. |
| `promise` | ReactNode | Yes | — | Primary headline or message for this tour stop. Accepts any valid React node for composability. |
| `position` | object | Yes | — | Object with `step` (current step number, 1-indexed) and `total` (total steps in tour). Used for progress display. |
| `pillars` | TourPillar[] | No | undefined | Optional array of pillar cards, each with `title` (string) and `body` (string). Omitted or empty array disables pillar rendering. |
| `back` | TourStep | No | undefined | Optional navigation step for previous tour stop, with required `href` (string) and `label` (string), and optional `note` (string). When undefined, back link does not render. |
| `next` | TourStep | No | undefined | Optional navigation step for next tour stop, with required `href` (string) and `label` (string), and optional `note` (string). When undefined, next link does not render. |

