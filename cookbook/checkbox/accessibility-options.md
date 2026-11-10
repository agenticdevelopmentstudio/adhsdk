
| Option | Behavior |
|--------|----------|
| Reduce Motion | No motion is animated. The only transition in the source is `transition-colors` on the primitive's Root (Primitive), which animates border and background color; neither source file queries `prefers-reduced-motion`. There is nothing to disable under Reduce Motion. |
| Increase Contrast | All colors resolve from the `apt-border`, `apt-bg`, and `apt-gold` design tokens (Primitive); the component hardcodes no color value, so implementations MUST use those tokens and any high-contrast theme variant carries through automatically — see the open question on increase-contrast. |
| Differentiate Without Color | Satisfied. The checked state is signalled by two independent channels: the `apt-gold` border and fill (Primitive, `data-[checked]:border-apt-gold data-[checked]:bg-apt-gold`) and the `Check` glyph rendered by the indicator (Primitive, `CheckboxPrimitive.Indicator` / `Check`), which is absent when unchecked. In switch appearance the wrapper's input also carries `role="switch"` (Wrapper), so assistive technology announces on/off independently of appearance. Implementations MUST keep the glyph, not color alone, as the checked indicator. |

- **increase-contrast**: NEEDS REVIEW: Not implemented in source. Neither source file defines the `apt-*` token values, so whether a high-contrast theme variant exists and whether the checked fill meets WCAG 2.1 AA (4.5:1 for the checkmark on `apt-gold`, 3:1 for the `apt-border` outline on `apt-bg`) cannot be determined here. The stylesheet or theme file that defines the `apt-*` custom properties, run through a contrast checker, would settle it.

