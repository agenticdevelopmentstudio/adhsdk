
### Field-type catalog (`types.ts`)

- **field-type-catalog**: The model MUST define the closed field-type catalog as exactly these twelve string values: `text`, `textarea`, `markdown`, `select`, `multi_select`, `url`, `email`, `phone`, `boolean`, `date`, `image`, `address` (`FIELD_TYPES`).
- **field-type-guard**: `isFieldType` MUST return `true` only when its argument is a string present in `FIELD_TYPES`, and MUST return `false` for any other value including a syntactically similar but unlisted string.
- **field-def-shape**: A field definition (`FieldDefLike`) MUST carry exactly `key: string`, `type: FieldType`, `required: boolean`, and `config: Record<string, unknown>`.
- **address-value-shape**: An `address` field's stored value MUST be an object whose only recognized keys are `line1`, `line2`, `city`, `region`, `postalCode`, and `country`, each optional and string-typed (`AddressValue`).

### `show_if` evaluation (`show-if.ts`)

- **show-if-data-only**: A `show_if` rule MUST be representable as plain JSON data (`{ field: string, op: string, value: unknown }`), never as a function or closure, so that an owner-authored builder can produce it and a server can evaluate it without executing caller-supplied code.
- **show-if-ops**: `SHOW_IF_OPS` MUST list exactly the six operators a builder may author, in this order: `eq`, `ne`, `truthy`, `falsy`, `in`, `contains`.
- **show-if-default-visible**: `evaluateShowIf` MUST return `true` when the field definition's `showIf` is absent or `null`.
- **show-if-eq**: For `op: 'eq'`, `evaluateShowIf` MUST return whether `values[rule.field]` is deep-equal (per **deep-value-equality**) to `rule.value`.
- **show-if-ne**: For `op: 'ne'`, `evaluateShowIf` MUST return the logical negation of the `eq` comparison on the same inputs.
- **show-if-absent-value-not-a-match**: When `rule.field` is absent from `values`, `evaluateShowIf` MUST treat the referenced value as absent (`undefined`) rather than as a match, so an `eq` rule against any non-`undefined` `rule.value` returns `false` and an `ne` rule returns `true`.
- **show-if-truthy**: For `op: 'truthy'`, `evaluateShowIf` MUST return `true` when the referenced value is a non-empty array, and otherwise MUST return `Boolean(value)`.
- **show-if-falsy**: For `op: 'falsy'`, `evaluateShowIf` MUST return the logical negation of the `truthy` result on the same input.
- **show-if-in**: For `op: 'in'` with an array `rule.value`, `evaluateShowIf` MUST return `true` when any element of `rule.value` is deep-equal to the referenced value, per **deep-value-equality**.
- **show-if-malformed-in-fails-open**: For `op: 'in'` when `rule.value` is not an array, `evaluateShowIf` MUST return `true` rather than treating the malformed rule as a non-match.
- **show-if-contains**: For `op: 'contains'`, `evaluateShowIf` MUST return `true` only when the referenced value is an array and at least one element is deep-equal to `rule.value`; it MUST return `false` when the referenced value is not an array.
- **show-if-unknown-op-fails-open**: For any `op` outside `SHOW_IF_OPS`, `evaluateShowIf` MUST return `true`.
- **show-if-field-lookup**: NEEDS REVIEW: Not implemented in source. `evaluateShowIf` reads the controlling value with a plain bracket lookup, `values[rule.field]`, where `rule.field` is untrusted owner-authored data from the same `jsonb` origin the module explicitly guards against elsewhere in `sameValue` (via `Object.hasOwn` instead of the `in` operator, specifically because of that trust boundary). A `show_if` rule authored with `field: 'constructor'` would read `values.constructor` — an inherited function, not a registrant-entered value — and evaluate operators like `truthy` against it. Neither `show-if.ts` nor `src/__tests__/show-if.test.ts` addresses this; whether it is worth guarding (given `field` is owner-authored, not registrant-authored) is a decision for whoever owns this evaluator's threat model.
- **deep-value-equality**: The comparison behind `eq`/`ne`/`in`/`contains` MUST compare arrays by length and per-index recursive equality, MUST compare plain objects by identical own-key sets with per-key recursive equality, and MUST fall back to `===` for every other pairing (including a scalar compared against an array or object).
- **own-property-membership**: The object branch of the deep comparison MUST test key presence with `Object.hasOwn`, not the `in` operator, so a compared key such as `"constructor"` is judged only against the object's own properties, never the properties it inherits through its prototype chain.
- **compare-depth-cap**: The deep comparison MUST stop recursing at a nesting depth of 32 (`MAX_COMPARE_DEPTH`) and MUST fall back to `===` for any pairing encountered beyond that depth, rather than continuing to recurse.

### Validation (`validate.ts`)

- **validate-before-coerce**: Every caller MUST invoke `validateFieldValue` on a submitted value and confirm it returns `null` before invoking `coerceFieldValue` on that same value; `coerceFieldValue` MUST NOT be used as a second validation pass.
- **unrecognized-type-rejected**: `validateFieldValue` MUST return the string `'Unrecognized field type'` when `def.type` is not one of `FIELD_TYPES`, before any other check runs.
- **empty-value-required-gate**: Before any type-specific check, `validateFieldValue` MUST classify `null`, `undefined`, an empty or whitespace-only string, an empty array, and an empty plain object as empty, and for an empty value MUST return `'Required'` when `def.required` is `true` and MUST return `null` otherwise; the literal values `false` and `0` MUST NOT be classified as empty.
- **string-like-type-check**: For the eight string-shaped types (`text`, `textarea`, `markdown`, `url`, `email`, `phone`, `date`, `select`), `validateFieldValue` MUST return `'Must be text'` when a non-empty value is not a string.
- **length-caps**: For `text`, `textarea`, and `markdown`, `validateFieldValue` MUST reject a string longer than `def.config.maxLength` when it is a number, or otherwise longer than the type's default cap (`text`: 255, `textarea`: 2000, `markdown`: 20000), returning `` `Must be ${cap} characters or fewer` ``.
- **url-format**: For `url`, `validateFieldValue` MUST return `'Must be a http(s) URL'` unless the value matches `^https?:\/\/[^\s/$.?#].[^\s]*$` case-insensitively, and MUST additionally apply **length-caps**' rule using a default cap of 2048.
- **email-format**: For `email`, `validateFieldValue` MUST return `'Must be an email address'` unless the value matches `^[^\s@]+@[^\s@]+\.[^\s@]+$`, and MUST additionally apply **length-caps**' rule using a default cap of 254.
- **phone-format**: For `phone`, `validateFieldValue` MUST return `'Must be a phone number'` unless the value matches `^[+]?[\d\s().-]{7,24}$` AND contains between 7 and 20 digit characters inclusive.
- **date-format**: For `date`, `validateFieldValue` MUST return `` 'Must be a date (YYYY-MM-DD)' `` unless the value matches `^\d{4}-\d{2}-\d{2}$` and also parses to a non-`NaN` result via `Date.parse`.
- **boolean-validate**: For `boolean`, `validateFieldValue` MUST accept a native boolean and the strings `'true'`, `'1'`, `'on'`, `'false'`, `'0'`, `'off'`, and MUST return `'Must be true or false'` for any other value.
- **select-options**: For `select`, when `def.config.options` is a non-empty array of strings, `validateFieldValue` MUST return `'Not one of the allowed options'` for a value not in that array; when `options` is absent or empty, any string MUST be accepted.
- **multi-select-scalar-form**: For `multi_select`, `validateFieldValue` MUST accept a bare string as equivalent to a one-element array containing it (the standard single-choice form encoding), MUST accept an array, and MUST return `'Must be a list'` for any other shape.
- **multi-select-max-items**: For `multi_select`, `validateFieldValue` MUST reject a list longer than `def.config.maxItems` when it is a number, or otherwise longer than 50 (`MULTI_SELECT_MAX_ITEMS`), returning `` `Must be ${max} selections or fewer` ``.
- **multi-select-no-duplicates**: For `multi_select`, `validateFieldValue` MUST return `'Must not repeat a selection'` when the list contains the same string-form selection more than once.
- **multi-select-options**: For `multi_select`, when `def.config.options` is non-empty, `validateFieldValue` MUST return `'Not one of the allowed options'` unless every selection in the list is present in `options`.
- **image-id-format**: For `image`, `validateFieldValue` MUST return `'Must be an uploaded image'` unless the value is a string matching `^[A-Za-z0-9_-]{1,36}$`.
- **address-shape-validate**: For `address`, `validateFieldValue` MUST return `'Must be an address'` when the value is not a non-array object, and when the value's `country` is present and non-empty MUST return `'Country must be a two-letter code'` unless it is exactly two characters long; no other sub-field of an object-shaped value is checked.
- **address-subfield-validation**: NEEDS REVIEW: Not implemented in source. `validateFieldValue`'s `address` branch checks only the length of `country`; it never validates the type or length of `line1`, `line2`, `city`, `region`, or `postalCode`, so a non-string value on one of those keys passes validation and is then silently dropped by `coerceFieldValue`'s per-key `typeof v === 'string'` filter, and an unbounded-length string on one of them passes validation and is stored as-is with no cap analogous to `text`'s. This is a genuine gap against the module's own stated contract (`validate.ts`'s header docblock: accept only wire forms for which coercion is a "MEANINGFUL, NON-LOSSY normalization"), not a design choice explained anywhere in `validate.ts`, `types.ts`, or `src/__tests__/validate.test.ts` (whose `address` cases exercise only `country` and an unknown-key drop). Resolving it requires a decision from whoever owns this validation contract on whether address sub-fields get the same type/length floor `text` has.
- **coerce-idempotent**: `coerceFieldValue` MUST be idempotent: applying it to a value it has already produced MUST return an equal value.
- **coerce-boolean**: For `boolean`, `coerceFieldValue` MUST return a native boolean unchanged, and for any other input MUST return `true` only for `'true'`, `'1'`, or `'on'`, and `false` for every other input.
- **coerce-multi-select**: For `multi_select`, `coerceFieldValue` MUST map an array input to an array of strings via the same string coercion used elsewhere in the module, MUST return `[]` for an empty input, and MUST wrap a non-empty scalar input in a single-element string array.
- **coerce-address**: For `address`, `coerceFieldValue` MUST copy only the six declared `AddressValue` keys whose source values are strings into a new object, MUST drop every other key, and MUST return `{}` for a `null`, non-object, or array input.
- **coerce-string-like**: For `text`, `textarea`, `markdown`, `url`, `email`, `phone`, `date`, `select`, and `image`, `coerceFieldValue` MUST return the trimmed string form of the input.
- **unrecognized-type-coerce**: `coerceFieldValue` MUST return `undefined` when `def.type` is not one of `FIELD_TYPES`.
- **searchable-text-visibility-gate**: When `def.visibility` is present and not `'public'`, `searchableText` MUST return `''` before performing any coercion or extraction.
- **searchable-text-unrecognized-type**: `searchableText` MUST return `''` when `def.type` is not one of `FIELD_TYPES`.
- **searchable-text-contact-exclusion**: For `email` and `phone`, `searchableText` MUST return `''` regardless of the value or the field's visibility.
- **searchable-text-non-text-types**: For `url`, `boolean`, `date`, and `image`, `searchableText` MUST return `''`.
- **searchable-text-scalar**: For `text`, `textarea`, `markdown`, and `select`, `searchableText` MUST return the value's coerced (trimmed) string form.
- **searchable-text-multi-select**: For `multi_select`, `searchableText` MUST return the coerced string array's elements joined with a single space and trimmed, regardless of whether the input arrived as an array or as the single-choice bare-string form.
- **searchable-text-address**: For `address`, `searchableText` MUST return the coerced `city`, `region`, and `country` values, in that order, filtered of falsy values, joined with a single space, and trimmed; `line1`, `line2`, and `postalCode` MUST NOT contribute to the result.
- **publish-blocker-required-only**: `publishBlockers` MUST only ever report a field definition whose `required` is `true`.
- **publish-blocker-deleted-exclusion**: `publishBlockers` MUST exclude a field definition whose `deletedAt` is truthy.
- **publish-blocker-hidden-exclusion**: `publishBlockers` MUST exclude a field definition for which `evaluateShowIf` returns `false` against the supplied `values`.
- **publish-blocker-empty-or-invalid**: For a required, non-deleted, currently-shown field definition, `publishBlockers` MUST report it as a blocker when its value is empty (per **empty-value-required-gate**) OR when `validateFieldValue` returns a non-`null` result for it.
- **publish-blocker-label-fallback**: Each reported `PublishBlocker` MUST use `def.label` as its `label` when present, and MUST fall back to `def.key` otherwise; its `key` MUST equal `def.key`.
- **required-gates-publish-not-save**: The model's `required` enforcement (`publishBlockers`) MUST be applied only at publish time, and MUST NOT be applied to reject an independent per-section save, because the owner-defined form's sections are saved independently.
- **vendored-build-ordering**: In the backend's single-file vendored build, the concatenation MUST place `show-if.ts` after `validate.ts` so that `validate.ts`'s reference to `evaluateShowIf` resolves against `show-if.ts`'s hoisted function declaration regardless of file order.

### Visibility tiering (`visibility.ts`)

- **visibility-enum**: The model MUST define exactly three field visibilities, ordered loosest to tightest: `public`, `authenticated`, `private` (`FIELD_VISIBILITIES`), with fixed ranks `public = 0`, `authenticated = 1`, `private = 2`.
- **viewer-scope-excludes-private**: The set of visibilities a read request may be entitled to (`ViewerScope`) MUST be restricted to `public` and `authenticated`; `private` MUST NOT be an admissible viewer scope for `visibilityAdmits`.
- **visibility-admits**: `visibilityAdmits(field, viewer)` MUST return `true` if and only if the rank of `field` is less than or equal to the rank of `viewer`.
- **tightest-visibility**: `tightestVisibility(a, b)` MUST return whichever of `a`/`b` has the higher (tighter) rank, and MUST return `a` when both ranks are equal.
- **visibility-within-ceiling**: `isWithinVisibility(candidate, ceiling)` MUST return `true` if and only if the rank of `candidate` is greater than or equal to the rank of `ceiling`.
- **visibilities-within-list**: `visibilitiesWithin(ceiling)` MUST return every visibility whose rank is greater than or equal to `ceiling`'s, in loosest-first order, and this list MUST always include `ceiling` itself and MUST agree exactly with `isWithinVisibility` for every visibility pair.
- **contact-field-types**: `CONTACT_FIELD_TYPES` MUST contain exactly `email`, `phone`, and `address`.
- **default-visibility-by-type**: `defaultVisibilityForType(type)` MUST return `'private'` when `type` is a contact field type or is not a recognized `FieldType`, and MUST return `'public'` for every other recognized type.
- **visibility-type-influence-once**: Field type MUST influence a field's visibility only through `defaultVisibilityForType` at field-definition creation time; once a field definition's own visibility setting exists, this model's functions MUST treat that stored setting as authoritative independent of the field's type.

### Cross-cutting

- **no-io-side-effects**: Every exported function in `types.ts`, `show-if.ts`, `validate.ts`, and `visibility.ts` MUST be a pure computation over its arguments: none of the four files imports or calls a network, filesystem, timer, random-number, or logging API.
- **no-shared-mutable-state**: None of the four modules MUST hold mutable module-level state; their module-level values (`FIELD_TYPES`, `SHOW_IF_OPS`, the validation regexes, `DEFAULT_MAX_LENGTH`, `RANK`, `CONTACT_FIELD_TYPES`, etc.) MUST be read-only for the lifetime of the process, so concurrent, parallel, or re-entrant calls into any of these functions from multiple callers require no coordination.

