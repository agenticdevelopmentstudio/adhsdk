
No test file sits beside `badge.tsx`. The vectors are derived from the source class strings.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| badge-001 | renders-span, marks-slot | render `<Badge>Beta</Badge>` | a `span` with `data-slot="badge"` and text `Beta` |
| badge-002 | default-neutral, neutral-tone | render `<Badge>Beta</Badge>` | class contains `border-apt-border` and `text-apt-text-dim` |
| badge-003 | accent-tone | `variant="accent"` | class contains `border-apt-gold` and `text-apt-gold` |
| badge-004 | orange-tone | `variant="orange"` | class contains `border-apt-orange` and `text-apt-orange` |
| badge-005 | blue-tone | `variant="blue"` | class contains `border-apt-blue` and `text-apt-blue` |
| badge-006 | success-tone | `variant="success"` | class contains `border-apt-green` and `text-apt-green` |
| badge-007 | error-tone | `variant="error"` | class contains `border-apt-red` and `text-apt-red` |
| badge-008 | merges-classname | `className="ml-2"` | class contains `ml-2` and the neutral tone classes |
| badge-009 | spreads-props | `id="b1" title="Preview"` | element has `id="b1"` and `title="Preview"` |
| badge-010 | uppercase-mono-type, no-wrap, pill-shape | any render | class contains `uppercase`, `font-mono`, `whitespace-nowrap`, `rounded-full` |
| badge-011 | sizes-svg-children | child `svg` inside | class contains `[&_svg]:size-3` and `[&_svg]:shrink-0` |
| badge-012 | exports-variants | `badgeVariants({ variant: "error" })` | returns a string containing `border-apt-red` |

