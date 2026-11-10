
- **Gear Button**:
  - Bezel style: `.accessoryBarAction` (borderless, toolbar-appropriate)
  - Image: `NSImage(systemSymbolName: "gearshape")`
  - Image position: `.imageOnly` (no text)
  - Content tint color: theme's secondary text color, theme-aware (see Platform Notes for the exact API)
  - Tooltip: "Window appearance" (default, customizable)

- **Dialog Window**:
  - Style: `.titled, .closable` (no resize handle, no minimize/maximize)
  - Title: Provided by host at construction
  - Background: theme's window background color, theme-aware (see Platform Notes)
  - Width: Configurable via `width` parameter; falls back to the component's built-in default when omitted (see Platform Notes)
  - Position: Centered horizontally and vertically on the screen the host window is on at open time

- **Slider** (`WindowOptionsSlider`):
  - Title font: `.systemFont(ofSize: .systemFontSize)` (standard control size)
  - Caption font: `.systemFont(ofSize: .systemFontSize)` (standard size)
  - Caption color: `.secondaryLabelColor`
  - Caption alignment: Right-aligned
  - Layout: Title and caption in horizontal stack at top, slider below
  - Title-caption spacing: 6pt horizontal gap with flexible distribution
  - Slider-caption spacing: 6pt vertical gap

- **Toggle** (`WindowOptionsToggle`):
  - Checkbox font: `.systemFont(ofSize: .systemFontSize)` (standard control size)
  - Checkbox state: `.on` / `.off`
  - Layout: Checkbox only (title embedded in checkbox)

- **Reset Button** (`WindowOptionsResetButton`):
  - Bezel style: `.rounded`
  - Title: `"Reset to Defaults"` (static, consistent)
  - Horizontal alignment: Centered under rows
  - Margin: Leading and trailing constraints ensure it does not exceed dialog width but allows centering

