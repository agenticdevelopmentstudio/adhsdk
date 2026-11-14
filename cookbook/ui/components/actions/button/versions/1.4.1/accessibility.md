
- Renders a real, focusable `<button>` (Base UI primitive); keyboard activation
  (Space/Enter) works natively and is independent of the pointer pressed visual.
- The button has no built-in accessible name of its own — the label comes from
  whatever the consumer passes as `children` (text or an icon plus visually
  hidden text) or an explicit `aria-label`/`aria-labelledby` forwarded through
  `...props`; an icon-only button with no such label renders with no accessible name.
- The pressed state is a purely visual affordance via `data-pressed`; it adds no
  ARIA semantics and never overrides `aria-pressed`/`aria-expanded` a consumer sets.
- Focus is shown with a visible `focus-visible` ring built from theme tokens.
- Disabled and invalid states map to the native `disabled`/`aria-invalid`
  attributes, which assistive technology announces natively.
- Minimum tap target: the fixed size-variant heights (`h-6`=24px, `h-7`=28px,
  `h-8`=32px, `h-9`=36px; `size-6`/`size-7`/`size-8`/`size-9` for icon sizes) are
  all below the Apple HIG 44×44pt and Material 48×48dp minimum touch-target
  guidance by default — the component does NOT guarantee an accessible tap
  target on its own. A surface MUST opt in to a larger floor by setting
  `--adh-button-min-height` and/or `--adh-button-min-width` (both default
  `0px`) on an ancestor when the context requires it (per
  [adc.guideline.cookbook.ui.platform-design-languages](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f26a9468-a15c-4cd2-b944-d39221e7eee2)).

