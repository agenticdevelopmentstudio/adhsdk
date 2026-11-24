
- **Corner radius**: None; drawer inherits NSDrawer's system-drawn frame.
- **Padding**: Tab strip: 8pt top margin, centered horizontally. Body: 32pt top (when strip shown) or 0pt (when hidden), fill remaining drawer space.
- **Font**: Tab titles use system font; symbol images are system symbols scaled by AppKit's NSSegmentedControl.
- **Background**: Theme's `windowBackground` role for container and bezel overlay.
- **Foreground/Text**: Theme text color via ThemedBackgroundView.
- **Border**: AppKit draws NSDrawerFrame border; bezel overlay repaints it in theme color to avoid system-appearance rim.
- **Shadow**: None; NSDrawer's frame provides system shadow.
- **Min/Max size**: Width draggable between 220–520 points (default 300). Height is window height; locked (not draggable).

