
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | string | required | The popover's heading text, e.g., "Markdown quick reference" |
| `entries` | ReadonlyArray<{label: string; syntax: string}> | required | Array of syntax entries to display as label-code pairs |
| `ariaLabel` | string | required | The accessible name for the trigger button, typically matching the title |
| `triggerLabel` | React.ReactNode | undefined | Optional visible text to display on the trigger button alongside the icon |
| `side` | "top" \| "right" \| "bottom" \| "left" | "bottom" | Which edge of the trigger the popover opens from |
| `align` | "start" \| "center" \| "end" | "end" | Alignment of the popover along the edge named by `side` (perpendicular to `side` — e.g., vertical when `side` is `left` or `right`) |
| `className` | string | undefined | Additional CSS classes to apply to the trigger button |
| `contentClassName` | string | "w-80" | CSS class(es) for the popover width; override for wider content |
| `columnsClassName` | string | "grid-cols-[7rem_1fr]" | CSS class(es) for grid column layout; adjust label column width if needed |

