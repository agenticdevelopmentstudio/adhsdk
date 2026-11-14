
- **Decision**: Invalid chips are still added to the value array rather than rejected.
  **Rationale**: Validation is advisory, not blocking. Invalid chips are added and marked visually and with `aria-invalid`, letting the consumer decide whether to block send. This keeps the input dumb and reusable across different validation rules a consumer may enforce.
  **Approved**: pending

- **Decision**: Email de-duplication is case-insensitive; other kinds use exact string comparison.
  **Rationale**: Email addresses are case-insensitive in practical routing (`Ada@x.io` and `ada@x.io` are the same recipient). Other input kinds (phone, text) use exact string comparison to preserve user intent. The comparison uses the default `toLowerCase()`, which applies the locale-insensitive (invariant) Unicode case mapping regardless of the runtime's current locale; a port MUST use the equivalent invariant-culture lowercasing — for example `.lowercased()` in Swift, `lowercase(Locale.ROOT)` in Kotlin, or `ToLowerInvariant()` in .NET — not a locale-aware variant, to match this behavior exactly. Under a locale where casing is context-sensitive (e.g. Turkish, where uppercase `I` lowercases to dotless `ı` only under locale-aware folding), a locale-aware port would fold two logically-identical addresses differently and fail to de-duplicate them; the invariant mapping the source uses avoids that.
  **Approved**: pending

- **Decision**: Two layout modes are offered: fused (default) and separate.
  **Rationale**: The default fused layout mimics the Input primitive for consistency. The separate mode allows designs that need to visually emphasize the existing recipient list (e.g., invitation interfaces that show seeded recipients separately from new entries). Both modes share the same tokenization, validation, and `inputMode` logic — see the note at the top of Behavioral Requirements.
  **Approved**: pending

- **Decision**: Read-only mode disables the input and renders chips as Badge instead of RemovableChip.
  **Rationale**: Read-only mode is designed for displaying fixed recipient lists (e.g., backend-seeded selections) without presenting an editable interface. Using Badge instead of RemovableChip signals to users that removal is not available, reducing accidental interaction attempts.
  **Approved**: pending

- **Decision**: Backspace removes the last chip only in fused mode.
  **Rationale**: Backspace removal is a convenience for compact fused layouts. In separate input mode, the recipients box is never focused, so Backspace is applied to the input text, not to tokens. This avoids accidental deletion in two-part layouts.
  **Approved**: pending

- **Decision**: Both layout modes' chip-and-input containers point at the shared `fieldShellClass` field-shell token rather than each typing out the border/background/radius classes.
  **Rationale**: `fieldShellClass` is already the one home for the form-control shell shared with the Input primitive and its siblings; pointing both RecipientInput layouts at it keeps the field look changing in exactly one place and gives users of other input controls a predictable, consistent appearance.
  **Approved**: pending

