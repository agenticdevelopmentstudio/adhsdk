
- **Tiny sizes.** For `size` < 10, `round(size * 0.55)` is below 6, so the glow
  clamps to the 6 px floor — a small dot still shows a visible halo rather than
  vanishing to a flat point.
- **Fractional size.** `size` is applied verbatim to `width`/`height`; only the
  glow radius is rounded, so a fractional `size` renders a fractional dot with an
  integer glow.
- **Empty-string label.** `label=""` is falsy, so the dot falls back to the
  decorative (`aria-hidden`) branch rather than announcing an empty image name.
- **No visible text.** A dot used alone with no adjacent label SHOULD pass
  `label` so its status is not lost to AT (color alone is inaccessible).
- **Glow on light surfaces.** The glow is a 40%-opacity `color-mix` with
  `transparent`, so it blends over any surface token without a hard edge.

