
- **case-set**: The type MUST declare exactly two cases, `summarize` and `oversight`, and no others.
- **raw-value-type**: The type MUST be backed by `String`.
- **raw-values-equal-case-names**: The raw value of each case MUST equal the case name: `summarize` has raw value "summarize" and `oversight` has raw value "oversight".
- **log-discriminator**: The raw value MUST be the text written to the `feature` column of an `ai_interactions` log row; the log writer stores the case's raw value, and the interaction log tests read back "summarize" and "oversight".
- **provider-settings-selection**: A lookup of provider settings for a feature MUST return the oversight-specific reader for `oversight` and the general reader for every other case; the source is a single equality test against `oversight`.
- **equality**: Two values MUST compare equal if and only if they are the same case, so a caller can test a feature with an equality comparison (the provider settings lookup does exactly that).
- **concurrency-safe**: The type MUST be declared `Sendable`, so a value can cross an actor or task boundary without a diagnostic.
- **no-additional-conformances-declared**: The type MUST NOT declare `Codable` or `CaseIterable`; it declares only `String` backing and `Sendable`. A caller that needs to enumerate the cases or encode the value must use the raw value.
- **no-error-domain**: The type MUST NOT define or throw any error; the only construction paths are the two literals and the failable raw-value initializer the language synthesizes for a string-backed enumeration, which returns nothing for an unknown string.

