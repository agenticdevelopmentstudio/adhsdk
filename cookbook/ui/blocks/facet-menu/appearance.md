
- **Trigger Button**:
  - Variant: ghost (low prominence)
  - Size: small
  - Text: label, followed by count in parentheses (when count > 0)
  - Icon: ChevronDown, 14×14px, margin-left 4px
  - Background: transparent in default state, platform-standard hover/pressed backgrounds
  - Foreground: inherit from button component

- **Popover**:
  - Width: 14rem (224px)
  - Background: platform-standard panel background
  - Alignment: start (left-aligned to trigger)
  - Padding: 8px

- **Quick-Select Buttons** ("All" and "None"):
  - Variant: ghost
  - Size: small
  - Arranged horizontally
  - Gap: 4px
  - Row gap: 8px below buttons to option list

- **Option Checkboxes**:
  - Checkbox: 16×16px
  - Label text: 14px (small body text style), rendered inline with checkbox
  - Inline gap: 8px between checkbox and label
  - Row padding: 2px vertical (0.125rem) per row, giving a row about 20px tall; on touch platforms each row MUST have a minimum height of 44px (the web reference implementation does not set one, see the touch-target check in Compliance)
  - Cursor: pointer on label (entire row is clickable)

