
- **Bar rendering**: Bars are plain HTML elements (`<span>`) with class `mb-bar`, not SVG.
- **Bar quantity**: Three bars in menu state, two bars in close state.
- **Bar dimensions**: See **bar-geometry** in [Behavioral Requirements](#requirements/bar-geometry): 16px wide, 1px thick, 4px gap, 5px pitch, in a 32×32px box.
- **Bar colour**: See [bar-current-color](#requirements/bar-current-color).
- **Bar transition**: See [bar-transition](#requirements/bar-transition).
- **Close icon derivation**: In close state, the close icon (X shape) is derived from the two bars via CSS rotation/transform; the component does not render separate markup for the X (see [close-bars-overlaid](#requirements/close-bars-overlaid)).
- **Background**: No background specified in component; inherits from button styling context.
- **Border**: No border specified in component; inherits from button styling context.
- **Shadow**: No shadow specified in component; inherits from button styling context.

