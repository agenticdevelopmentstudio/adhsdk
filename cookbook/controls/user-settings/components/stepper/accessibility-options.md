
| Option | Behavior |
|--------|----------|
| Reduce Motion | No motion or transitions applied in the component; button and input state changes occur instantly |
| Increase Contrast | Border color and text color SHOULD increase to meet AAA contrast requirements (7:1 minimum); disabled state text SHOULD remain distinguishable |
| Differentiate Without Color | Disabled buttons MUST indicate disabled state via the native `disabled` attribute (browsers render it with reduced opacity and a non-interactive cursor) rather than color alone; the −/+ glyph itself remains visible in both states. Screen readers announce the disabled state independently through the `disabled` attribute (see [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43)) — `aria-label` is not a visible cue and MUST NOT be relied on to satisfy this option. |

