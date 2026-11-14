
- **Labeled = image.** With a `label`, the dot carries `role="img"` and
  `aria-label={label}`, so a standalone dot (e.g. the only status affordance in a
  cell) announces its status word to AT.
- **Unlabeled = decorative.** Without a `label`, the dot is `aria-hidden="true"`
  and has no role — the intended pattern when visible text ("healthy", "down")
  already names the status and a labeled dot would be a redundant announcement.
- Not focusable and not interactive; it is a pure indicator.
- Color is never the *only* signal in the family's compositions: the dot pairs
  with a visible status word (see the demo and StatCard), so it does not rely on
  hue alone to convey meaning.

