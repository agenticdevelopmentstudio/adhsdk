
### Sessions namespace

- **namespace-name**: The namespace MUST be a type named exactly `Sessions`, so every member is addressed as `Sessions.<TypeName>` (for example `Sessions.AccountQuotaReadingDTO`).
- **namespace-public**: The namespace MUST be visible to every module that links the framework declaring it.
- **namespace-uninhabited**: The namespace MUST have no cases and no initializer, so no value of type `Sessions` can be constructed.
- **namespace-stateless**: The namespace MUST hold no stored state of its own; its declaration has no static or instance properties.
- **namespace-empty-declaration**: The declaring file MUST declare no members inside the namespace; members MUST be added by extensions in sibling files.
- **wire-types-inside-namespace**: Every type a session daemon route returns or its clients decode MUST be declared inside the `Sessions` namespace.
- **legacy-names-kept**: Each wire type moved from `StenographerXPCProtocol` MUST keep the type name it had there.
- **legacy-fields-kept**: Each wire type moved from `StenographerXPCProtocol` MUST keep the field names it had there.
- **legacy-payload-decodes**: A payload encoded by the old Stenographer daemon MUST decode into the corresponding `Sessions` type unchanged.
- **foundation-only**: Each of the three files MUST depend on nothing but the platform's standard foundation library.
- **lowest-tier**: The namespace and its two helpers MUST live in the Core tier, below the `Database` tier, so the daemon composition and its clients can both reference them without a dependency on each other.

### VisibleText

- **visible-text-uninhabited**: `VisibleText` MUST be a caseless namespace nested in `Sessions` that exposes only static, stateless functions.
- **visible-letters**: `isVisible` MUST return true for a scalar whose general category is a letter: uppercase (Lu), lowercase (Ll), titlecase (Lt), modifier (Lm) or other (Lo), unless the default-ignorable rule refuses it.
- **visible-numbers**: `isVisible` MUST return true for a scalar whose general category is a number: decimal digit (Nd), letter number (Nl) or other number (No), unless the default-ignorable rule refuses it.
- **visible-punctuation**: `isVisible` MUST return true for a scalar whose general category is punctuation: connector (Pc), dash (Pd), open (Ps), close (Pe), initial quote (Pi), final quote (Pf) or other (Po), unless the default-ignorable rule refuses it.
- **visible-symbols**: `isVisible` MUST return true for a scalar whose general category is a symbol: math (Sm), currency (Sc), modifier (Sk) or other (So), unless the default-ignorable rule refuses it.
- **visible-space-separator**: `isVisible` MUST return true for a scalar whose general category is space separator (Zs), including U+0020 SPACE and U+00A0 NO-BREAK SPACE, unless the default-ignorable rule refuses it.
- **refuse-default-ignorable**: `isVisible` MUST return false for any scalar Unicode lists as Default_Ignorable_Code_Point, whatever its general category; this check MUST take precedence over the category allowlist (U+3164 HANGUL FILLER is category Lo and is refused).
- **refuse-controls**: `isVisible` MUST return false for control characters (Cc), including U+0000, U+0007, U+0009 TAB, U+000A LINE FEED, U+000D and U+001B ESCAPE.
- **refuse-format**: `isVisible` MUST return false for format characters (Cf), including U+200B ZERO WIDTH SPACE and the bidi controls such as U+202E.
- **refuse-marks**: `isVisible` MUST return false for every mark category: nonspacing (Mn), spacing combining (Mc) and enclosing (Me).
- **refuse-line-paragraph-separators**: `isVisible` MUST return false for U+2028 LINE SEPARATOR (Zl) and U+2029 PARAGRAPH SEPARATOR (Zp).
- **refuse-unassigned-private-use**: `isVisible` MUST return false for unassigned (Cn) and private-use (Co) code points.
- **refuse-by-default**: `isVisible` MUST return false for every general category not listed in the allowlist, so a category nobody enumerated is refused rather than admitted.
- **visible-deletes-refused**: `visible` MUST return its input with every scalar for which `isVisible` is false deleted, and MUST NOT substitute any replacement character for a deleted scalar.
- **visible-keeps-order**: `visible` MUST keep the scalars it does not delete in their original order and unchanged.
- **visible-no-normalization**: `visible` MUST NOT apply Unicode normalization; a precomposed letter such as U+00E9 is kept, while a base letter followed by a combining mark (U+0065 U+0301) loses the mark.
- **visible-idempotent**: Applying `visible` to its own output MUST return that output unchanged.
- **visible-pure**: `isVisible` and `visible` MUST be pure: their result MUST depend only on the argument, and they MUST have no side effects.

### StenographerBilling

- **stenographer-billing-uninhabited**: `StenographerBilling` MUST be a caseless namespace nested in `Sessions` whose only member is `settingsKeyPrefix`.
- **stenographer-billing-prefix-value**: `Sessions.StenographerBilling.settingsKeyPrefix` MUST be exactly the string `stenographer_billing_` (21 characters, trailing underscore included).
- **stenographer-billing-prefix-constant**: `settingsKeyPrefix` MUST be an immutable constant, so Stenographer's app and daemon read the same value.
- **stenographer-billing-key-shape**: A Stenographer billing settings key MUST be this prefix followed by the key name that `BillingSettingsKeys` appends (`stenographer_billing_idle_cutoff_minutes` for the idle cutoff).
- **stenographer-billing-legacy-source**: `LegacySessionImporter.SourceKind.stenographerd` MUST report this constant as its billing settings key prefix, distinct from the `billing_` default (`DaemonDatabase.defaultBillingSettingsKeyPrefix`) that `SourceKind.adkd` reports.

