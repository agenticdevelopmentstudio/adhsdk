
Text roles

- **role-cases**: `TextRole` MUST have exactly six cases: `title`, `heading`, `body`, `caption`, `code` and `button`.
- **role-raw-value**: `TextRole` MUST be a `String`-backed enum whose raw value equals the case name (`"title"`, `"heading"`, `"body"`, `"caption"`, `"code"`, `"button"`).
- **role-meaning**: Each role MUST mean what its doc comment says: `title` large window or screen titles; `heading` section or group headers; `body` default body text; `caption` small secondary text; `code` monospaced text; `button` control labels.
- **role-conformances**: `TextRole` MUST be `CaseIterable` and `Sendable`.

Font weight

- **weight-cases**: `FontWeight` MUST have exactly nine cases in this order: `ultraLight`, `thin`, `light`, `regular`, `medium`, `semibold`, `bold`, `heavy`, `black`.
- **weight-codable**: `FontWeight` MUST be `String`-backed, `Codable`, `CaseIterable` and `Sendable`, and its raw value MUST equal the case name.
- **weight-foundation-only**: `FontWeight` MUST NOT depend on any platform font type; the platform bridge is the caller's.

Font style

- **style-fields**: `FontStyle` MUST expose four mutable properties: `family` (optional `String`), `size` (`Double`), `weight` (`FontWeight`) and `monospaced` (`Bool`).
- **style-family-nil**: A `nil` `family` MUST mean the system font.
- **style-size-base**: `FontStyle.size` MUST be the base point size before the theme's `sizeScale` is applied.
- **style-monospaced**: `monospaced` set to true MUST mean the style resolves to a monospaced font (digits and glyphs fixed-width). The resolution itself belongs to the platform bridge.
- **style-init-defaults**: `FontStyle.init(family:size:weight:monospaced:)` MUST default `family` to nil, `weight` to `.regular` and `monospaced` to false; `size` is required.
- **style-conformances**: `FontStyle` MUST be `Codable`, `Equatable` and `Sendable`. Equality is the synthesized memberwise comparison.
- **style-no-size-validation**: `FontStyle` MUST NOT validate or clamp `size`; zero, negative and non-finite values are stored as given.

Typography value

- **typography-fields**: `ThemeTypography` MUST expose two mutable properties: `sizeScale` (`Double`) and `styles` (`[String: FontStyle]`).
- **typography-init-defaults**: `ThemeTypography.init(sizeScale:styles:)` MUST default `sizeScale` to 1.0 and `styles` to the empty dictionary.
- **typography-init-no-clamp**: `ThemeTypography.init` MUST NOT clamp `sizeScale`; a stored scale outside `sizeScaleRange` is kept as given. Clamping is applied by callers (`clamp-callers`).
- **styles-key**: `styles` MUST be keyed by `TextRole.rawValue`, so the dictionary round-trips through `Codable` and `UserDefaults` as a plain string-keyed object.
- **typography-conformances**: `ThemeTypography` MUST be `Codable`, `Equatable` and `Sendable`. Equality is the synthesized memberwise comparison of `sizeScale` and `styles`.
- **styles-unknown-key**: `styles` MAY hold a key that is not a `TextRole` raw value; the type neither rejects it nor reads it, because lookups are by `role.rawValue` only.

Style lookup

- **style-lookup-override**: `style(_:)` MUST return `styles[role.rawValue]` when an entry exists.
- **style-lookup-default**: `style(_:)` MUST return `defaultStyle(role)` when no entry exists for the role.
- **style-lookup-no-mutation**: `style(_:)` MUST NOT write the default into `styles`.
- **style-lookup-whole-entry**: `style(_:)` MUST return the override as one whole `FontStyle`; fields are not merged with the default. An override that sets only `size` therefore also resets `weight` and `monospaced` to the `FontStyle` initializer defaults (`.regular`, false), not to the role's default.

Effective size

- **size-effective**: `size(_:)` MUST return `style(role).size * sizeScale`.
- **size-stored-unchanged**: `size(_:)` MUST NOT change the stored `FontStyle.size` or `sizeScale`.
- **size-uses-stored-scale**: `size(_:)` MUST use the stored `sizeScale` as is, with no clamp, so a `sizeScale` of 0 yields an effective size of 0 for every role.

System defaults

- **default-style-table**: `defaultStyle(_:)` MUST return a style with `family` nil and these values:

| Role | size | weight | monospaced |
|------|------|--------|------------|
| `title` | 22 | `.semibold` | false |
| `heading` | 15 | `.semibold` | false |
| `body` | 13 | `.regular` | false |
| `caption` | 11 | `.regular` | false |
| `code` | 12 | `.regular` | true |
| `button` | 13 | `.medium` | false |

- **default-style-basis**: The default sizes mirror AppKit's standard metrics, so an uncustomized theme looks like the app does today (the source's doc comment).
- **system-constant**: `ThemeTypography.system` MUST equal `ThemeTypography()`: `sizeScale` 1.0, empty `styles`, every role at its system default.
- **default-covers-roles**: `defaultStyle(_:)` MUST return a style with `size` greater than 0 for every `TextRole` case.

Size scale limits

- **scale-range**: `ThemeTypography.sizeScaleRange` MUST be the closed range 0.5 to 4.
- **scale-range-rationale**: The lower bound exists because below 0.5 `size(_:)` collapses every role toward zero and takes any constraint built on an intrinsic size with it; the upper bound exists because above 4 the size exceeds what a layout that assumes a roughly system-sized label can hold (the doc comment).
- **clamp-function**: `clampedSizeScale(_:)` MUST return the value limited to `sizeScaleRange`: a value below 0.5 returns 0.5, a value above 4 returns 4, and a value inside the range is returned unchanged; this holds for finite input (`clamp-nan` covers non-finite input).
- **clamp-infinity**: `clampedSizeScale(_:)` MUST return `1.0` for negative and positive infinity alike, not the nearest bound, because the finite check runs before the limit.
- **clamp-nan**: `clampedSizeScale(_:)` MUST return `1.0`, the unscaled size, for a non-finite input (NaN or either infinity), because `min` and `max` would pass NaN straight through the limit. Covered by `clampNonFinite`.
- **clamp-callers**: The clamp MUST be applied by every path that sets a scale from outside the type: `SemanticPalette.scaled(by:)` (the reader's runtime "Text Size" control) and `ThemeStore.importJSON` (a theme file's declared `typography.sizeScale`). Both call `clampedSizeScale(_:)` so the two cannot drift onto different limits.
- **clamp-repair-not-refuse**: `ThemeStore.importJSON` repairs an out-of-range scale by clamping it rather than rejecting the file, because a bad scale leaves a theme mis-sized, not unusable (its doc comment).

Persistence and side effects

- **codable-synthesized**: `ThemeTypography`, `FontStyle` and `FontWeight` use synthesized `Codable`; `ThemeTypography` encodes as an object with keys `sizeScale` and `styles`, and `FontStyle` as an object with keys `family`, `size`, `weight` and `monospaced`.
- **decode-strict**: Decoding MUST fail with the decoder's own error when a required key is missing (`sizeScale`, `styles`, `size`, `weight`, `monospaced`) or a `weight` string is not one of the nine cases; the type has no custom decoder and substitutes no defaults. A nil `family` is omitted when encoding and decodes as nil when the key is absent.
- **no-side-effects**: Every operation in this contract MUST NOT perform I/O, logging, notification or persistence. Persistence is by the caller, through `Codable`.
- **concurrency**: All types MUST be value types conforming to `Sendable`; any thread MAY read a copy without synchronization. Mutation of a single instance is the caller's to serialize.

