
- **Reduce Motion**: Seam rendering does not involve animation; no motion reduction required.
- **Increase Contrast**: Tone backgrounds MUST maintain sufficient contrast ratios per WCAG 2.1 AA with text and controls rendered within. This is verified via the tone's CSS color values (see **Appearance**), not Band itself. Band does not respond to `prefers-contrast: more`: its stylesheet declares no contrast media query, so the tones are the same under every contrast setting.
- **Differentiate Without Color**: Seam is a visual boundary; if seams are critical to page structure, content SHOULD include text or heading hierarchy so meaning is not conveyed by seam presence alone.

