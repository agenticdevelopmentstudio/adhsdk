
- **Dynamic Type / responsive text scaling**: Title, caption, and pendingLabel text are sized in `rem` units (`.lp-shot__name` at 0.7rem, `.lp-shot__placeholder` at 0.78rem), so they scale with the browser's root font size and zoom level; Shot does not fix pixel sizes or otherwise disable scaling.
- **Reduce Motion**: Not applicable; Shot itself renders no animation (see **media-verbatim** and the Clip recipe for motion handling of media).
- **Increase Contrast**: Not addressed; colors are fixed CSS custom properties (`--lp-ink-dim`, `--lp-accent`, `--lp-raise`) with no separate high-contrast variant.
- **Differentiate Without Color**: Not applicable; no information in the frame or placeholder is conveyed by color alone.

