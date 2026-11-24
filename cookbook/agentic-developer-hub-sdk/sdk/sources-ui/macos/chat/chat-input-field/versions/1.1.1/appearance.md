
The values below are the defaults a themed host applies through the AppKit-only Configuration options (`cornerRadius`, `showsBorder`, `usesBlockCaret`, `caretBlinks`) documented under Configuration. The component itself does not read the active theme for those four properties — whatever constructs the field passes them in; see Platform Notes for how AppKit and web each keep this in sync with the current theme.

- **Corner radius**: 6pt on standard themes; 0pt (squared off) on terminal/retro themes
- **Padding**: 5pt vertical × 8pt horizontal (inset)
- **Font**: Body font from theme palette (size and weight determined by theme; defaults to platform system body)
- **Background**: `chatInputBackground` semantic color (theme-driven; falls back to platform default surface color)
- **Foreground/Text**: `userText` semantic color (theme-driven; typically a light gray on dark theme)
- **Border**: 1pt solid, color is `chatInputBorder` by default; `chatInputFocus` when focused (theme-driven; hidden on terminal themes)
- **Shadow**: None
- **Placeholder color**: `timestampText` semantic color (theme-driven; typically a dimmer gray than user text)
- **Min/Max size**: Single-line height determined by font metrics; width expands to fill container; no maximum width constraint

