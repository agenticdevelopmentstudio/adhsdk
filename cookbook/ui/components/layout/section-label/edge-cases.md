
- **`trailing={null}` / omitted.** `trailing == null` selects the bare-div
  branch, so an explicit `null` behaves exactly like omitting the prop.
- **Falsy-but-present trailing.** `trailing={false}` is not `== null`, so it
  takes the row branch and renders an empty right cell, which breaks the common
  `{cond && <Button/>}` pattern — pass `undefined`/`null` (or omit), for example
  `trailing={cond ? <Button/> : undefined}`, to get the bare div.
- **Rich children.** `children` is any `ReactNode`, so a label MAY include an
  inline count or icon, though the treatment is tuned for short uppercase text.
- **Not a heading.** Because it is a div, it will not appear in a screen reader's
  heading list — intentional for a display micro-label, but a trap if you needed
  outline semantics.
- **Overriding the color.** `cn()` is `twMerge(clsx(...))` (tailwind-merge). It treats a custom `text-apt-*` token as a text color and `text-[0.625rem]` or `text-xs` as a font size, so a `className` that sets a text-color token such as `text-apt-gold` replaces `text-apt-text-dim`, and a size class such as `text-xs` replaces `text-[0.625rem]`. Classes that touch other properties leave both in place.

