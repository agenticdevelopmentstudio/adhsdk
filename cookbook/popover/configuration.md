
| Option | Type | Default | Variant / Component | Description |
|--------|------|---------|----------------------|-------------|
| `open` | boolean | — | Both — lightweight `Popover`; full-featured `Popover` (forwards Base UI `Popover.Root.Props`) | Controls visibility. Lightweight: hides via CSS when `false` (stays in DOM). Full-featured: unmounts `PopoverContent` when `false` (see **hide-on-close-unmount**). |
| `onOpenChange` | `(open: boolean, eventDetails) => void` | — | Full-featured `Popover` / Base UI `Popover.Root` only | Called when the popover requests to open or close (Escape, outside press, focus-out, trigger press). Required alongside `open` for controlled usage. |
| `defaultOpen` | boolean | `false` | Full-featured `Popover` / Base UI `Popover.Root` only | Initial open state for uncontrolled usage (no `open`/`onOpenChange` passed). |
| `side` | `'top' \| 'bottom' \| 'left' \| 'right'` | `'bottom'` | Full-featured `PopoverContent` only | Which side of the trigger the panel appears on. |
| `placement` | `'top' \| 'bottom'` | `'top'` | Lightweight `Popover` only | Which side of the anchor the panel appears on. |
| `sideOffset` | number | `8` | Full-featured `PopoverContent` only | Gap in pixels between the panel and the trigger element. |
| `align` | `'start' \| 'center' \| 'end'` | `'center'` | Full-featured `PopoverContent` only | Alignment along the axis perpendicular to `side`. |
| `arrow` | boolean | `false` | Full-featured `PopoverContent` only | Whether to render the optional pointer indicator. |
| `className` | string | — | Full-featured `PopoverContent`; lightweight `Popover` | Custom CSS class, concatenated after default classes. |
| `children` | ReactNode | — | Full-featured `PopoverContent`; lightweight `Popover` | Content to display inside the panel. |
| `onMouseEnter` / `onMouseLeave` | `() => void` | — | Lightweight `Popover` only | Passed through to the panel element so a caller can compose hover-driven show/hide. |

