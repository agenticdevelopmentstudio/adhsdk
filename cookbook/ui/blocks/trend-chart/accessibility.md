
- **role**: The root is a figure labelled by `ariaLabel`; the tooltip has the `status` role; the legend is a list; the table has a caption, column headers and row headers.
- **labels**: `ariaLabel` is required and names what the chart shows; it is also the table caption.
- **non-visual-access**: All visual marks are hidden from assistive technology; the table view carries every value and is the non-visual path.
- **color-independence**: The legend and tooltip pair each color with the series name, and the table is the color-free view.
- **reduced-motion**: Not applicable: the component has no animation or transition.
- **keyboard-hover-access**: NEEDS REVIEW: Not implemented in source. The tooltip and crosshair open only from pointer events, so keyboard users reach the values only through the table disclosure; a keyboard path over the plot, or acceptance that the table suffices, would settle it.
- **contrast**: NEEDS REVIEW: Not implemented in source. Series colors are caller supplied and dim text uses theme tokens at 10 and 11 pixels; contrast measurements of the tokens against the page background would settle whether the ratio is met.
- **touch-target**: The `View as table` summary is a text line 11 pixels tall with no minimum target size set in source; the plot's touch-pan-y lets vertical scroll pass through.

