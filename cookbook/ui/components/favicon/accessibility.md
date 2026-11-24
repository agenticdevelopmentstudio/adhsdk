
- **Role/trait**: The image is decorative: it has empty alternative text and `aria-hidden` of `true`, so assistive technology skips it.
- **Label requirements**: None on the image; the caller's link text names the destination. A caller-supplied `fallback` is rendered as given and carries whatever accessibility the caller gives it.
- **Announce state changes**: Not applicable: the component announces nothing; the move from image to fallback is silent.
- **Minimum tap target**: Not applicable: the component is not interactive, and the icon is a decoration inside a caller's control.

