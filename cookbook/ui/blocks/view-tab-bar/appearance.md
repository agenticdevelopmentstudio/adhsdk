
- **Container padding**: Horizontal padding `px-4` (typically 16px on the x-axis)
- **Layout**: Flex row with `items-end` alignment and `gap-4` (typically 16px) spacing between items
- **Tab/Link styling**: Applies `tabItemClass` from the Tabs component (shared underline idiom with gold bottom border on active state)
- **Active indicator**: `data-active=""` attribute (empty string) applied to active tabs and links; styling via CSS attribute selector `[data-active]`
- **Font**: Inherits from `tabItemClass` definition (typically mono labels per the underline idiom)
- **No visible disabled state**: Component does not render disabled tabs
- **Min/Max size**: No explicit constraints; tabs and links flex to accommodate content within the flex row

