
The module formats dates with fixed English month names and a fixed UTC zone, and writes the literal suffixes ` UTC`, ` (UTC)`, `ms` and `s`. These are hardcoded English strings that are not externalised, so a viewer with another locale still sees English month names. The fixed zone is deliberate (see Design Decisions); the fixed language is recorded as a pending Design Decision, though the source states no reason for it. Sorting in the with-site function follows the runtime's default locale.

