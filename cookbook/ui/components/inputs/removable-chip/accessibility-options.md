
RemovableChip has no animation, so Reduce Motion does not apply. For Increase Contrast and forced-colors modes, the ✕ and the Badge tones take whatever the design-token colors resolve to, so the chip inherits the platform's contrast adjustments only as far as those tokens do; this is why `contrast-ratio` is `partial`. For text scaling, the label and the ✕ sit in an inline flex row, and the 11px ✕ icon does not grow with system font size; this is why `dynamic-type-support` is `partial`.

