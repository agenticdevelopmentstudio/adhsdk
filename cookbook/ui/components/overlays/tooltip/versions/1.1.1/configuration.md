
| Option | Type | Default | Owner | Description |
|--------|------|---------|-------|-------------|
| delay | number | 200 | `TooltipProvider` | Milliseconds before the tooltip opens after the user hovers or focuses the trigger |
| side | "top" \| "bottom" \| "left" \| "right" | "top" | `TooltipContent` | Which side of the trigger the tooltip appears on |
| sideOffset | number | 6 | `TooltipContent` | Distance in pixels from the trigger to the tooltip |
| align | "start" \| "center" \| "end" | "center" | `TooltipContent` | Horizontal/vertical alignment of the tooltip relative to the trigger |
| arrow | boolean | true | `TooltipContent` | Whether to display the pointer diamond |
| className | string | undefined | `TooltipContent` | Additional CSS class(es) to apply to the content wrapper |
| children | ReactNode | required | `TooltipContent` | The text or content to display in the tooltip |

