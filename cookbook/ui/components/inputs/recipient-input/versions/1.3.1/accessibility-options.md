
RecipientInput does not respond to Reduce Motion (there is no animation to reduce) or Increase Contrast (it inherits whatever contrast the underlying `apt-*` design tokens resolve to; no separate high-contrast styling exists). It does not currently respond to Differentiate Without Color either: valid and invalid chips are distinguished primarily by Badge color (`variant="neutral"` vs `variant="error"`), and the only non-color signal is the `aria-invalid` attribute, which is not visible to sighted users — there is no icon, text, or pattern difference between a valid and an invalid chip.

