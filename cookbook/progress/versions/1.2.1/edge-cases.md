
- `value` below 0 or above 100 is clamped, never overflowing the track; `aria-valuenow`
  reflects the clamped value. (UI)
- Omitting `value` renders an empty (0%) bar rather than erroring. (UI)
- Fractional values are allowed for the fill width, but `aria-valuenow` is rounded to
  an integer, so `35.6` announces as `36`. (UI)
- There is no indeterminate state in the UI bar — a value is always supplied, defaulting
  to 0. The Controls component below does have an indeterminate mode.
- `indicatorClassName` that also sets a background token overrides the default gold
  fill; a class that only tweaks other properties leaves the gold in place. (UI)
- **non-finite-value-handling** (UI) — `Math.min`/`Math.max` treat `±Infinity` as
  ordinary numbers, so `value={Infinity}` clamps to 100 and `value={-Infinity}` clamps
  to 0 exactly like any other out-of-range finite value (T12, T13) —
  **clamps-below-zero**/**clamps-above-hundred** hold for both. Only `value={NaN}`
  escapes the clamp, because `Math.min`/`Math.max` return `NaN` whenever either operand
  is `NaN`: `aria-valuenow` becomes the literal string `"NaN"` and the fill's `transform`
  becomes `translateX(-NaN%)` (T10). `-NaN%` is not a valid CSS `<length-percentage>`
  token, so a browser drops that declaration; the fill keeps its default (untransformed,
  full-width) layout and paints as a full bar while `aria-valuenow` announces `NaN` to
  assistive technology.
- The Controls `Progress` does not clamp or round `aria-valuenow` the way the UI bar
  does: it reports the raw `value` prop verbatim (negative, over-`max`, or fractional),
  while only the fill's *width* is clamped to the 0–100% range via
  `Math.max(0, Math.min(100, ...))`. So `value={-40}` reports `aria-valuenow="-40"` with
  an empty (`0%`) fill, and `value={140} max={100}` reports `aria-valuenow="140"` with a
  full (`100%`) fill (T16, T17).
- With no `value` and `indeterminate` false, the Controls `Progress` omits
  `aria-valuenow` entirely (unlike the UI bar's **defaults-to-zero**), because its `pct`
  expression short-circuits to `undefined` when `value` is `undefined` (T19).
- The Controls `Progress`'s visible `label` is not programmatically associated with its
  `role="progressbar"` element (no `aria-labelledby`/`id` pairing) — see Accessibility.
- The Controls `Progress`'s indeterminate animation (`aws-progress-indeterminate`) is a
  plain CSS `@keyframes` rule with no `prefers-reduced-motion`/reduce-motion guard in
  `user-settings/styles.css`, unlike the UI bar's **honors-shared-reduce-motion**.

