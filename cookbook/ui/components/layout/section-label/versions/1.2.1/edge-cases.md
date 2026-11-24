
- **`trailing={null}` / omitted.** `trailing == null` selects the bare-div
  branch, so an explicit `null` behaves exactly like omitting the prop.
- **Falsy-but-present trailing.** `trailing={false}` is not `== null`, so it
  takes the row branch and renders an empty right cell — pass `undefined`/`null`
  (or omit) to get the bare div.
- **Rich children.** `children` is any `ReactNode`, so a label MAY include an
  inline count or icon, though the treatment is tuned for short uppercase text.
- **Not a heading.** Because it is a div, it will not appear in a screen reader's
  heading list — intentional for a display micro-label, but a trap if you needed
  outline semantics.
- **Overriding the color.** A `className` that sets a text-color token overrides
  `apt-text-dim` via `cn()` merge; classes that touch other properties leave the
  dim color in place.

