
- **renders-label-and-value**: The component MUST render both the `label` and the `value`.
- **tints-value-by-tone**: The component MUST color the value from the `tone`'s family status token, read from the shared `TONE_TEXT_CLASS` table — `neutral`→`text-apt-text`, `muted`→`text-apt-text-dim`, `accent`→`text-apt-gold`, `blue`→`text-apt-blue`, `orange`→`text-apt-orange`, `success`→`text-apt-green`, `error`→`text-apt-red`. This is the one place the seven mappings are written out.
- **defaults-neutral-tone**: With no `tone`, the component MUST render the value in the neutral text token (`text-apt-text`).
- **value-class-overrides-tone**: The component MUST apply `valueClassName` to the value merged after the tone class through `cn()`'s `tailwind-merge` de-confliction, so a caller MAY override the tone hue. (Plain class concatenation would leave both `text-*` classes in the string and let CSS source order — not merge order — decide the winner.)
- **label-uses-micro-caption**: The component MUST render the label in the micro uppercase-mono caption treatment (small, letter-spaced, dimmed).
- **value-uses-figure-type**: The component MUST render the value in the big mono-bold figure treatment (`font-mono text-lg font-bold leading-none`).
- **row-lays-out-on-baseline**: `StatRow` MUST place the label at the left and the value at the right on a shared baseline (`items-baseline justify-between`).
- **column-right-aligns**: `Stat` MUST stack the value above the label, both right-aligned (`flex-col items-end`) when `align` is `"end"` or omitted.
- **column-align-start**: `Stat` MUST, when `align="start"`, stack the value above the label with both left-aligned (`flex-col items-start`).
- **strip-wraps-stats**: `StatStrip` MUST lay its children out in a wrapping row with horizontal and vertical gaps (`flex flex-wrap gap-x-8 gap-y-3`) and MUST merge a caller `className` onto its wrapper.
- **forwards-classname**: The component MUST merge a caller `className` onto the wrapper element.

