
```
value = 0        ├───────────────────────────────┤   (empty track)
value = 35       ██████████·······················    (gold fill, 35%)
value = 100      ███████████████████████████████     (full fill)
```

- Track: `relative h-2 w-full overflow-hidden rounded-full bg-apt-surface-2`; extra
  classes merge via `cn()` through `className`.
- Indicator: `h-full w-full rounded-full bg-apt-gold` with
  `transition-transform duration-[calc(300ms*var(--apt-anim-scale,1))] ease-out`
  (a nominal 300ms, scaled by the shared dev-only slow-motion switch); positioned
  by an inline `transform: translateX(-{100 - pct}%)`.
- Fill color is token-based (`apt-gold` by default) and overridable through
  `indicatorClassName` (e.g. `bg-apt-green` for complete).
- No raw hex; no `!important`.

**Controls**:

- Wrapper: `aws-field aws-field--progress` div; gains `aws-field--progress-indeterminate`
  while `indeterminate` is true.
- Label: `aws-field__label` div, rendered above the track when `label` is provided.
- Track: `aws-progress` div — height `0.5rem`, `--aws-surface` background, `1px`
  `--aws-border-subtle` border, fully rounded, `overflow: hidden`.
- Fill: `aws-progress__bar` div — height `100%`, `--aws-accent` background, `width`
  transition `120ms`; width set inline as a percentage while determinate.
- Indeterminate animation: the fill's width is fixed at `35%` and slides via the
  `aws-progress-indeterminate` keyframe (`translateX(-100%)` to `translateX(285%)`) over
  `1.2s linear infinite`, rather than resizing.
- Hint: `aws-field__hint` paragraph, rendered below the track when `hint` is provided.

