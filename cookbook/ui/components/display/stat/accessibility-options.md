
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the source renders static markup with no transition or animation at all. |
| Increase Contrast | Depends on the `apt-*` design tokens that the shared `TONE_TEXT_CLASS` table (see Overview) maps tones to; the component itself does no `prefers-contrast` handling. |
| Differentiate Without Color | Tone is conveyed by color only, as already noted in Accessibility; there is no non-color indicator, so callers SHOULD keep `label` descriptive rather than relying on the tint. |

