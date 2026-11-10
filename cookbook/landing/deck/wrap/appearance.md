
Wrap itself accepts no appearance-related props, but it is not stylistically inert: it ships the `.lp-wrap` class as part of the landing package's own stylesheet, not the consuming application's. The rule lives in `.lp-wrap`, defined in `packages/web/packages/landing/src/css/base.css`:

```css
.lp-wrap {
  width: min(100% - 2.5rem, var(--lp-measure, 70rem));
  margin-inline: auto;
}
```

This caps content width at the smaller of two values — the available width minus a `2.5rem` gutter (`100% - 2.5rem`), or the `--lp-measure` custom property (default `70rem`) at its full value, never `--lp-measure` minus the gutter — and centers it horizontally with `margin-inline: auto`. `margin-inline: auto` splits whatever space is left outside the computed width evenly between the two sides. Only when the gutter branch is binding (the container is narrower than `--lp-measure + 2.5rem`) does that split work out to `1.25rem` per side; when `--lp-measure` is the binding branch instead, the per-side margin is `(available width - --lp-measure) / 2`, unrelated to the `2.5rem` figure.

