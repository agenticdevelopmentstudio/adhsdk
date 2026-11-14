
- **Empty or missing data**: `{}` and a missing key decode as `nil`, and the all-nil struct is the valid no-opinion state. A `null` value also decodes as `nil`. MUST.
- **Zero and false are overrides**: `paddingTop: 0` and `highlightActivePane: false` are values, not absence; `isEmpty` is false. MUST.
- **Unvalidated numbers**: the source performs no range check on padding or font size. Negative, zero, NaN or huge values are stored as given. A caller that renders them owns the check; the source documents no range. Stated as a fact.
- **Unvalidated font name**: `fontName` is stored as given, with no check that the font is installed. Resolution of a missing font belongs to the terminal appearance consumer, outside these sources. Stated as a fact.
- **Unknown cursor shape**: a stored raw value outside the four cases fails the decode of the whole struct, and so of the enclosing `ColorTheme`. There is no lenient fallback. MUST.
- **Malformed color string**: an unparseable `paneOutline` or `paneBackdrop` fails the whole struct decode. MUST.
- **Unknown extra keys**: the synthesized decoder ignores keys it does not know, so a theme file written by a newer version loses those keys on the next save. SHOULD be treated as expected.
- **Concurrent access**: all three types are `Sendable` value types with no shared mutable state, so concurrent reads of separate copies cannot race. MUST.
- **Error states, offline state, cancellation and timeouts**: not applicable; every operation is synchronous, local and bounded, and the only failure is a thrown decoding error.

