
- **Trigger Button**:
  - Height: 36px (h-9)
  - Width: full parent width
  - Padding: 12px horizontal, vertical centered (px-3)
  - Font: 14px (text-sm), medium weight for label
  - Background: transparent (input base style from `fieldShellClass`)
  - Foreground/Text: `apt-text` (primary text color)
  - Border: 1px solid `apt-border` (from `fieldShellClass`)
  - Hover: border color lightens to `apt-border-strong`
  - Focus-visible: 2px ring of `apt-gold/25` with border color `apt-gold`
  - Disabled: opacity 50%, cursor not-allowed
  - Gap between content: 8px (gap-2)
  
- **Trigger Content Layout**:
  - Left section: icon (14px, `apt-text-muted` color) + label text
  - Right section: chevron icon (14px, `apt-text-muted` color)
  - Content shrinks but does not wrap; icon remains visible on truncate
  
- **Popover**:
  - Width: 288px (w-72)
  - Padding: 4px (p-1) — options define their own padding
  - Align: start (matches trigger left edge)
  - Background: inherits from Popover component
  
- **Option Button**:
  - Height: auto (py-2)
  - Width: full popover width
  - Padding: 8px horizontal, 8px vertical (px-2 py-2)
  - Border-radius: 6px (rounded-md)
  - Font: 14px (text-sm) for label; 12px for description
  - Label font-weight: medium
  - Label color: `apt-text`
  - Description color: `apt-text-dim` (lighter)
  - Gap between icon and content: 8px (gap-2)
  - Highlighted background: `apt-highlight/15` (15% opacity of highlight color)
  - Text alignment: left
  - Cursor: pointer
  
- **Option Icons**:
  - All icons: 14px (size-[14px])
  - Padding-top: 4px (mt-0.5) to optical center align with text baseline
  - Label icon and privacy icon: `apt-text-muted` color
  - Check icon: gold (`apt-gold`) when checked, otherwise opacity-0
  - Coming-soon option: all icons and text at 40% opacity

- **Coming Soon Badge**:
  - Variant: blue
  - Rendered inline with "Team / Org" label

