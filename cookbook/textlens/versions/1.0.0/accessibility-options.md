
`respectReducedMotion` (default `true`) is the one accessibility-driven
behavior in this component: when `true` and the browser reports
`prefers-reduced-motion: reduce`, `start()` never schedules a single
animation frame, so the character spans stay at rest and the sweep never
runs (see **reduced-motion-gate**). Setting `respectReducedMotion: false`
makes the sweep run regardless of that OS/browser setting (see
**reduced-motion-opt-out**). The character split itself (turning the text
into per-character spans) still happens even when reduced motion suppresses
the sweep — `createLens` does not gate the split on this setting, only the
frame-scheduling in `start()`. No other accessibility display option
(contrast, larger text, differentiate-without-color) is read anywhere in
the given sources.

