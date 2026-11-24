
- **Role**: Dialog (provided by PopoverContent wrapper; popover panel announces as `role="dialog"`)
- **Accessible name**: Set via `aria-label` on PopoverContent; combines flavor label with title if present (e.g., "Help: Getting Started" or "Information")
- **Icon trait**: Decorative image (via `aria-hidden="true"`); the icon's semantic meaning is captured in the panel's accessible name
- **Keyboard navigation**: Keyboard access to the popover is the responsibility of the trigger control and PopoverContent's dismiss mechanism. On open, PopoverContent (the composed wrapper) focuses and announces the dialog; Help Popover Content itself renders no interactive controls and adds no keyboard behavior beyond the accessible name and content it supplies
- **Screen reader announcement**: On open, screen readers announce the dialog role and accessible name; the title and body text are then available for exploration
- **Minimum tap target**: Not applicable; the component contains no interactive controls. Tap target size is determined by the trigger control that opens the popover.
- **Color contrast**: Text colors (`apt-text`, `apt-text-muted`) are design system tokens; their contrast ratios SHOULD meet WCAG AA standards (requires verification of token definitions)

