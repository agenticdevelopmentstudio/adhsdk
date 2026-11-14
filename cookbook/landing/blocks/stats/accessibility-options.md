
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: Stats is static and contains no animations. |
| Increase Contrast | Not applicable: The component sets no colors itself, but `blocks.css` supplies fallbacks that render whenever the host leaves the `--lp-*` variables unset: `#d8d8d8` for terms, `#a0a0a0` for details and `rgba(216, 216, 216, 0.18)` for the divider. Their contrast against the host background has not been checked; the divider is decorative. |
| Differentiate Without Color | Not applicable: Stats uses semantic HTML and does not rely on color alone to convey meaning. The `dt`/`dd` structure encodes the relationship independent of color. |

