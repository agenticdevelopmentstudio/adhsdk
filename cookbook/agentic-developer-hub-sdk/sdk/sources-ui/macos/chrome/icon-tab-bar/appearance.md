
- **Corner radius**: Not set by the component; the capsule track and the rounded selection are drawn by AppKit's segmented control.
- **Padding**: None; the view's top, bottom, leading and trailing edges are pinned to the control's.
- **Font**: Not applicable: segments carry images only, no text.
- **Background**: The control's own capsule track, drawn in the dark or light appearance chosen from the palette's window background (see **theme-track-appearance**).
- **Foreground/Text**: The system symbol images as AppKit draws them in a segmented control.
- **Border**: None set by the component; the focus ring is turned off.
- **Shadow**: None set by the component.
- **Min/Max size**: Each segment is 32 points wide, so the bar is as wide as its segments at the control's default segment spacing; height is the control's intrinsic height. The bar does not grow to fill its container.

