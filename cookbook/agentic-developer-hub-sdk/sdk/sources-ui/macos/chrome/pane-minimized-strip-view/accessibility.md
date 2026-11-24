
- **Role**: Container holding button and icon
- **Restore button role**: Button (role automatically provided by NSButton)
- **Restore button label**: "Restore Pane" (set via accessibility label and accessibility description)
- **Glyph accessibility description**: Tooltip text if provided; when `tooltip` is empty (the default), falls back to "Minimized Pane"
- **Accessibility IDs**: `pane.restore` for restore button, `pane.minimized.glyph` for glyph view
- **Click target size**: The strip is 28 points wide, so a 44×44 target — the iOS touch-target minimum — cannot fit in either dimension. The restore button sizes to its own intrinsic content size (`.accessoryBarAction` bezel, image-only, no minimum-size constraint in source); this is a mouse-driven macOS chrome control, not an iOS touch target. See **touch-target-size** in Compliance for a `partial` accounting of the shortfall.
- **Keyboard navigation**: Restore button is keyboard-accessible via Tab (provided by NSButton)

