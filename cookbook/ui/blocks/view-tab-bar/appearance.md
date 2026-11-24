
- **Container padding**: Horizontal padding `px-4` (typically 16px on the x-axis)
- **Layout**: The outer container is a flex row (`tabListClass`: `flex items-end gap-4 border-b border-apt-border`), so the tablist and the nav sit side by side with a 16px gap between the two groups; each group is itself a flex row with `items-end` alignment and `gap-4` (16px) between its items
- **Tab/Link styling**: Applies `tabItemClass` from the Tabs component (shared underline idiom with an accent-colored bottom border on active state; the React/Web theme's accent is gold, `border-apt-gold`)
- **Active indicator**: `data-active=""` attribute (empty string) applied to active tabs and links; styling via CSS attribute selector `[data-active]`
- **Font**: Inherits from `tabItemClass` definition (typically mono labels per the underline idiom)
- **No visible disabled state**: Component does not render disabled tabs
- **Min/Max size**: No explicit constraints; tabs and links flex to accommodate content within the flex row

