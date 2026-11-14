
- **Bar rendering**: Bars are plain HTML elements (`<span>`) with class `mb-bar`, not SVG.
- **Bar quantity**: Three bars in menu state, two bars in close state.
- **Bar dimensions**: Each bar MUST be 16px wide (`--menu-bar-width`) and 3px thick (`--menu-bar-thickness`), with fully rounded ends (`border-radius: 999px`). Bars MUST be spaced with a 3px gap (`--menu-bar-gap`), giving a 6px pitch (thickness + gap); thickness, gap, and pitch MUST all be whole-number CSS pixels so every bar rounds to the same device-pixel thickness regardless of device-pixel ratio or the button's fractional position (`css/base.css`). The icon occupies a 32×32px box (`--menu-size`).
- **Bar colour**: Bars MUST use `background: currentColor`, taking the button's `color` so a consumer themes the icon by setting `color` on the button.
- **Bar transition**: Bars MUST apply `transition: 0.25s` (all properties), which animates the `rotate()` transform applied to the first and last bar when toggling to the close state; see **reduced-motion** in Compliance below.
- **Close icon derivation**: In close state, the close icon (X shape) is derived from the two bars via CSS rotation/transform; the component does not render separate markup for the X.
- **Background**: No background specified in component; inherits from button styling context.
- **Border**: No border specified in component; inherits from button styling context.
- **Shadow**: No shadow specified in component; inherits from button styling context.

