
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `side` | "top" \| "bottom" \| "right" \| "left" \| "inline-start" \| "inline-end" | undefined | Position of menu relative to trigger (DropdownMenuContent / DropdownMenuSubContent) |
| `sideOffset` | number | 4 (for DropdownMenuContent); undefined (for DropdownMenuSubContent) | Distance in pixels between menu and trigger edge (DropdownMenuContent / DropdownMenuSubContent) |
| `align` | "start" \| "center" \| "end" | undefined | Alignment of menu along the perpendicular axis to `side` |
| `alignOffset` | number | undefined | Additional offset along the alignment axis |
| `inset` | boolean | false | Add visual indentation to MenuItem, DropdownMenuLabel, DropdownMenuSubTrigger |
| `accent` | boolean | false | Apply the theme's accent styling on MenuItem, CheckboxItem, RadioItem, DropdownMenuSubTrigger |
| `closeOnClick` | boolean | true (for MenuItem, inherited from Base UI's default; explicit true for LinkItem, CheckboxItem, RadioItem) | Close menu when item is clicked |
| `checked` | boolean | undefined | Checked state for CheckboxItem |
| `children` | ReactNode | undefined | Content rendered inside component (text, icons, elements) |

