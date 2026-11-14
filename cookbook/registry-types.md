---
id: 3828874a-ce76-4e8d-a106-97a867ed583d
title: "Registry Model"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-09-23
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Field-type catalog, validation, coercion, show_if evaluation and visibility tiering shared across the registry's editor, profile renderer and server."
platforms:
  - typescript
  - web
tags:
  - registry
  - validation
  - visibility
  - data-model
depends-on: []
related:
  - 00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/4ca8a3d5-cdcc-4f74-a2ec-3a198608b419
  - 00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/425271ea-92b6-4df6-9a83-94795f1be377
  - 00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/57cbdb9d-4cf7-4a39-bdd8-99d28be983ca
references: []
approved-by: ""
approved-date: ""
---

# Registry Model

## Overview

The registry model is the framework-free logic package `@adh-sdk/registry-types` (`packages/web/packages/registry-types/src/{types,show-if,validate,visibility}.ts`). It defines the closed catalog of field types a registry owner can put on a form, the shape of a field definition and its values, and four pure computations over that data: whether a field is currently shown (`evaluateShowIf`), whether a submitted value is acceptable (`validateFieldValue`), how an accepted value is normalized for storage and search (`coerceFieldValue`, `searchableText`), and which required fields still block an entry from publishing (`publishBlockers`). A separate module, `visibility.ts`, defines the three-tier audience scale (`public` / `authenticated` / `private`) that gates which of those stored values a given viewer may read.

Per the `show-if.ts` docblock, three callers share this exact code: the entry editor (deciding what to render), the public profile renderer (deciding what to show), and the server (deciding whether `required` applies at all) — the last of which is why the model lives in a UI-independent package rather than beside a rendering layer. The `validate.ts` docblock also records that the backend consumes this package as a single vendored file rather than as a dependency, concatenating `show-if.ts` after `validate.ts`; see **vendored-build-ordering** below.

Every exported function in these four files is a pure, synchronous computation over its arguments: none reads a clock, generates an id, calls the network, touches a filesystem, or holds module-level mutable state. The package has no runtime dependencies (`package.json`: `"description": "... No React, no runtime dependencies"`).

## Behavioral Requirements

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

## Appearance

Not applicable — this is a data-model and validation package with no visual surface, not a visual component.

## States

Not applicable — this is a data-model and validation package with no visual surface, not a visual component. It has no runtime state machine of its own: every exported function computes its result fresh from the arguments it is given on each call.

## Accessibility

Not applicable — this is a data-model and validation package with no visual surface, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| registry-model-001 | field-type-catalog | `[...FIELD_TYPES].sort()` | Equals the sorted 12-entry list `address, boolean, date, email, image, markdown, multi_select, phone, select, text, textarea, url` |
| registry-model-002 | field-type-guard | `isFieldType('rating')` | `false` |
| registry-model-003 | empty-value-required-gate | `validateFieldValue(def('text'), '')` then `validateFieldValue(def('text', {required:true}), '')` | `null`, then `'Required'` |
| registry-model-004 | length-caps | `validateFieldValue(def('text', {config:{maxLength:3}}), 'abcd')` then `'abc'` | `'Must be 3 characters or fewer'`, then `null` |
| registry-model-005 | length-caps (boundary) | `validateFieldValue(def('text'), 'a'.repeat(255))` then `'a'.repeat(256)` | `null`, then `'Must be 255 characters or fewer'` |
| registry-model-006 | length-caps (boundary) | `validateFieldValue(def('textarea'), 'a'.repeat(2001))`; `def('markdown')` with 20001 a's | `'Must be 2000 characters or fewer'`; `'Must be 20000 characters or fewer'` |
| registry-model-007 | url-format | `validateFieldValue(def('url'), 'example.com')` then `'https://example.com'` | `'Must be a http(s) URL'`, then `null` |
| registry-model-008 | url-format (boundary) | `validateFieldValue(def('url'), 'https://example.com/' + 'a'.repeat(3000))` | `'Must be 2048 characters or fewer'` |
| registry-model-009 | email-format | `validateFieldValue(def('email'), 'nope')` then `'a@b.co'` | `'Must be an email address'`, then `null` |
| registry-model-010 | email-format (boundary) | `validateFieldValue(def('email'), 'a'.repeat(300) + '@example.com')` | `'Must be 254 characters or fewer'` |
| registry-model-011 | phone-format | `validateFieldValue(def('phone'), '-------')`; `'((((((( '`; `'+1 555 123 4567'` | `'Must be a phone number'`; `'Must be a phone number'`; `null` |
| registry-model-012 | date-format | `validateFieldValue(def('date'), '03/04/2026')` then `'2026-03-04'` | `'Must be a date (YYYY-MM-DD)'`, then `null` |
| registry-model-013 | boolean-validate | `validateFieldValue(def('boolean'), 'true')`; `'true'` on `coerceFieldValue`; `5` on validate | `null`; `true`; `'Must be true or false'` |
| registry-model-014 | select-options | `validateFieldValue(def('select', {config:{options:['a','b']}}), 'c')` then `'a'` | `'Not one of the allowed options'`, then `null` |
| registry-model-015 | multi-select-options | `validateFieldValue(def('multi_select', {config:{options:['a','b']}}), ['a','z'])` then `['a','b']` | `'Not one of the allowed options'`, then `null` |
| registry-model-016 | multi-select-scalar-form, coerce-multi-select | `validateFieldValue(d, 'a')` on `multi_select` with `options:['a','b']`; `coerceFieldValue(d, 'a')` | `null`; `['a']` |
| registry-model-017 | multi-select-max-items (boundary) | `multi_select` with 60 configured options, given a 51-item list vs. a 50-item list | `'Must be 50 selections or fewer'`, then `null` |
| registry-model-018 | multi-select-max-items | `multi_select` with `config:{maxItems:2, options:['a','b','c']}`, given `['a','b','c']` then `['a','b']` | `'Must be 2 selections or fewer'`, then `null` |
| registry-model-019 | multi-select-no-duplicates | `validateFieldValue(d, ['a','a'])` vs. `['a','b']` (options `['a','b']`) | `'Must not repeat a selection'`, then `null` |
| registry-model-020 | image-id-format | `validateFieldValue(def('image'), 'https://evil.example/beacon.gif')`; `'javascript:alert(1)'`; `'att_123'` | `'Must be an uploaded image'`; `'Must be an uploaded image'`; `null` |
| registry-model-021 | address-shape-validate | `validateFieldValue(def('address'), {country:'usa'})` | `'Country must be a two-letter code'` |
| registry-model-022 | coerce-address | `coerceFieldValue(def('address'), {line1:'1 Main St', country:'US', junk:{deep:[1,2,3]}, extra:'nope'})` | `{ line1: '1 Main St', country: 'US' }` |
| registry-model-023 | string-like-type-check | `validateFieldValue(def(type), { nested: [1,2,3] })` for each of `text, textarea, markdown, url, email, phone, date, select` | `'Must be text'` for every one |
| registry-model-024 | unrecognized-type-rejected, unrecognized-type-coerce, searchable-text-unrecognized-type | `validateFieldValue`, `coerceFieldValue`, `searchableText` on `def('rating' as FieldType)` with value `'x'` | `'Unrecognized field type'`; `undefined`; `''` |
| registry-model-025 | validate-before-coerce, coerce-idempotent | For every field type, run the accepted wire forms in the module's own `attemptSave` pattern (validate, then coerce only on `null` error) across all 12 types | Every listed accepted form is accepted and coerces to exactly the value the module documents (e.g. `multi_select` bare string `'a'` → `['a']`); every listed rejected form is rejected and never reaches the coercer |
| registry-model-026 | searchable-text-scalar, searchable-text-multi-select, searchable-text-address, searchable-text-non-text-types, searchable-text-contact-exclusion | `searchableText` on `text:'hello'`, `multi_select:['a','b']`, `address:{city:'Seattle', country:'US'}`, `image:'att_123'`, `boolean:true`, `email:'a@b.co'`, `phone:'+1 555 123 4567'` | `'hello'`; `'a b'`; a string containing `'Seattle'`; `''`; `''`; `''`; `''` |
| registry-model-027 | searchable-text-address | `searchableText(def('address'), { line1: '1 Main St', junk: 'drop me' })` | `''` (no `city`/`region`/`country` survives coercion) |
| registry-model-028 | searchable-text-visibility-gate | `searchableText({...def('text'), visibility:'private'}, 'secret bio')` vs. `{...def('text'), visibility:'public'}` vs. no `visibility` field at all, each with a non-empty string | `''`; the original string; the original string |
| registry-model-029 | empty-value-required-gate, coerce-boolean, coerce-address, coerce-multi-select | For every field type, `validateFieldValue(optional, '')` and `coerceFieldValue(optional, '')`; then `validateFieldValue(required, '')` | `null` and the type's empty form (`''` for string types, `false` for `boolean`, `[]` for `multi_select`, `{}` for `address`); `'Required'` |
| registry-model-030 | publish-blocker-empty-or-invalid, publish-blocker-label-fallback | `publishBlockers([{...def('text',{key:'bio',required:true}), label:'BIO'}], {})` then with `{ bio: 'hi' }` | `[{ key: 'bio', label: 'BIO' }]`, then `[]` |
| registry-model-031 | publish-blocker-hidden-exclusion | A required field `rate` with `showIf: {field:'paid', op:'truthy', value:null}`, evaluated against `{paid:false}` then `{paid:true}` | `[]`, then `[{ key: 'rate', label: 'RATE' }]` |
| registry-model-032 | publish-blocker-deleted-exclusion | `publishBlockers([{...req('bio'), deletedAt:'2026-01-01T00:00:00Z'}], {})` | `[]` |
| registry-model-033 | publish-blocker-empty-or-invalid | A required `boolean` field `remote` evaluated against `{ remote: false }` | `[]` (an explicit `false` answer is not a blocker) |
| registry-model-034 | publish-blocker-empty-or-invalid | A required `url` field `site` evaluated against `{ site: 'not-a-url' }` then `{ site: 'https://example.com' }` | `[{ key: 'site', label: 'SITE' }]`, then `[]` |
| registry-model-035 | show-if-default-visible | `evaluateShowIf({}, {})`; `evaluateShowIf({ showIf: null }, {})` | `true`; `true` |
| registry-model-036 | show-if-eq, show-if-ne | `evaluateShowIf({showIf:{field:'mode',op:'eq',value:'paid'}}, {mode:'paid'})` then `{mode:'free'}`; same rule with `op:'ne'` against the same two states | `true`, `false`; `false`, `true` |
| registry-model-037 | show-if-absent-value-not-a-match | `evaluateShowIf({showIf:{field:'mode',op:'eq',value:'paid'}}, {})` | `false` |
| registry-model-038 | show-if-truthy, show-if-falsy | `evaluateShowIf` with `op:'truthy'` against `mode:true`, `mode:false`, `mode:''`; with `op:'falsy'` against `mode:false` | `true`, `false`, `false`; `true` |
| registry-model-039 | show-if-in, show-if-malformed-in-fails-open | `op:'in', value:['a','b']` against `mode:'b'` then `mode:'c'`; `op:'in', value:'not-an-array'` against `mode:'anything'` | `true`, `false`; `true` |
| registry-model-040 | show-if-contains | `op:'contains', value:'a'` against `mode:['a','z']` then `mode:['z']` | `true`, `false` |
| registry-model-041 | show-if-unknown-op-fails-open | `evaluateShowIf({showIf:{field:'mode',op:'matches-regex',value:'x'}}, {mode:'anything'})` | `true` |
| registry-model-042 | show-if-ops | `[...SHOW_IF_OPS]` | `['eq','ne','truthy','falsy','in','contains']` |
| registry-model-043 | deep-value-equality | `op:'eq'` with `value: {line1:'1 Main St',city:'Seattle',country:'US'}` against a field-for-field identical but distinct object, then against one with `city:'Portland'` | `true`, then `false` |
| registry-model-044 | deep-value-equality | `op:'eq'` with a 4-level-nested `value: {a:{b:{c:[1,2,{d:'deep'}]}}}` against a structurally identical distinct object, then one differing only at the deepest key | `true`, then `false` |
| registry-model-045 | compare-depth-cap | Two distinct object references nested 40 levels deep with identical structure down to level 32 and differing only below it, compared via `op:'eq'` | `false` (levels beyond 32 fall back to `===` on the distinct sub-objects, which is false for two different object references — the cap fails closed: even structurally identical but distinct values nested 33+ levels deep compare unequal) |
| registry-model-046 | own-property-membership | `op:'eq'` with `value: {}` against `mode: Object.create({ constructor: 'poisoned' })` (an object whose only `constructor` is inherited, not its own) | `true` (both sides have zero own keys — `Object.keys` excludes the inherited `constructor` on either side — so the own-key-set comparison is vacuously equal; `Object.hasOwn` is never reached because the key sets already match) |
| registry-model-047 | visibility-enum | `[...FIELD_VISIBILITIES]` | `['public', 'authenticated', 'private']` |
| registry-model-048 | visibility-admits, viewer-scope-excludes-private | `visibilityAdmits('public','public')`, `visibilityAdmits('authenticated','public')`, `visibilityAdmits('private','authenticated')` | `true`, `false`, `false` |
| registry-model-049 | tightest-visibility | `tightestVisibility('public','authenticated')`, `tightestVisibility('authenticated','public')`, `tightestVisibility('public','public')` | `'authenticated'`, `'authenticated'`, `'public'` |
| registry-model-050 | visibility-within-ceiling, visibilities-within-list | `isWithinVisibility('public','authenticated')`; `visibilitiesWithin('authenticated')` | `false`; a list containing `authenticated` and `private` but not `public`, and agreeing with `isWithinVisibility` for every pair |
| registry-model-051 | contact-field-types, default-visibility-by-type | `defaultVisibilityForType('email')`, `('phone')`, `('address')`, `('text')`, `('ssn')`, `('')` | `'private'`, `'private'`, `'private'`, `'public'`, `'private'`, `'private'` |
| registry-model-052 | no-io-side-effects, no-shared-mutable-state | Static review of `types.ts`, `show-if.ts`, `validate.ts`, `visibility.ts` imports | No import of a network, filesystem, timer, or logging API; every module-level binding is `const` |
| registry-model-053 | vendored-build-ordering | The backend's single-file vendored bundle with `show-if.ts` concatenated after `validate.ts`, then `publishBlockers` (defined earlier in the file) calling `evaluateShowIf` (defined later) | Resolves correctly at call time because `evaluateShowIf` is a hoisted function declaration |
| registry-model-054 | show-if-data-only | A `ShowIfRule` value round-tripped through `JSON.stringify` then `JSON.parse` and passed to `evaluateShowIf` | Produces the identical result to the pre-round-trip rule, for every op, because the rule carries no function or closure that serialization could drop |

## Edge Cases

- **Null and empty input**: `null`, `undefined`, an empty string, whitespace-only string, empty array, and empty plain object MUST all be classified as empty by `isEmpty`'s rule inside `validateFieldValue`; an empty value MUST pass validation on an optional field and MUST fail with `'Required'` on a required one (**empty-value-required-gate**). `false` and `0` MUST NOT be treated as empty.
- **Boundary values**: Length caps are exact boundaries — `text` accepts 255 characters and rejects 256; `textarea` accepts 2000 and rejects 2001; `markdown` accepts 20000 and rejects 20001; `url` accepts 2048 and rejects 2049 (measuring the whole string, not just the path); `email` accepts 254 and rejects 255; `multi_select` accepts 50 selections by default and rejects 51, or the configured `config.maxItems` boundary when set; `phone` accepts 7 and 20 digit characters and rejects 6 or 21; the deep-equality depth cap acts at exactly 32 levels of nesting (**compare-depth-cap**).
- **Malformed owner-authored data**: An unrecognized `def.type` (a value outside `FIELD_TYPES`, reachable because the field-definition's stored `type` column carries no database-level constraint per the source comment) MUST be rejected by `validateFieldValue`, MUST coerce to `undefined`, and MUST contribute no search text — all fail **closed**. A `show_if` rule with an unrecognized `op`, or an `op: 'in'` rule whose `value` is not an array, MUST instead fail **open** (the field stays visible) because a rule this build cannot interpret is presumed to come from a newer builder, and hiding the field would silently drop what the registrant already answered. This asymmetry is deliberate; see Design Decisions.
- **Deeply nested or pathological JSON**: A `show_if` rule's stored `value`, and the entry's stored `values`, originate from a `jsonb` column and can be arbitrarily deep or malformed even though they cannot contain a real reference cycle (`JSON.parse` never aliases). The comparison's depth cap (**compare-depth-cap**) bounds the recursion so a pathologically deep blob cannot hang evaluation.
- **Prototype-chain-shaped keys**: A compared object key such as `"constructor"` MUST be judged only by `Object.hasOwn`, never by the `in` operator, so an object that merely inherits a property of that name is not treated as having it (**own-property-membership**).
- **Concurrent access**: Not applicable — every exported function is a pure, synchronous computation over its arguments with no shared mutable state (**no-shared-mutable-state**); any number of callers may invoke any of these functions concurrently, in parallel, or re-entrantly with no coordination and no observable interference between calls.
- **Error states (dependency unavailable)**: Not applicable — none of the four modules calls a network, database, or file-system dependency (**no-io-side-effects**), so there is no dependency-unavailable failure mode for this component to define.
- **Offline or disconnected state**: Not applicable — the model performs no network operation of its own; it computes over whatever `def`/`values` its caller already holds in memory.
- **Cancellation and timeouts**: Not applicable — every function returns synchronously; there is no asynchronous operation, and therefore nothing to cancel or time out.
- **Concurrent calls with conflicting data**: A single call is completely determined by its arguments — two concurrent calls with different `values` snapshots for the same entry simply produce two independent, correct answers for the snapshots they were given; the model itself defines no merge or last-writer-wins rule because it never sees more than one snapshot at a time.
- **A required field whose value is present but invalid**: `publishBlockers` MUST report it exactly as it reports a blank one (**publish-blocker-empty-or-invalid**) — an invalid-but-answered value blocks publish the same as an unanswered one.
- **A required field hidden by its own `show_if` rule**: MUST NOT be reported as a publish blocker (**publish-blocker-hidden-exclusion**), because the registrant has no on-screen control to clear it.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `def.type` | `FieldType` | — (caller-supplied; no default) | Selects which validation, coercion, search-extraction, and default-visibility rules apply. |
| `def.required` | `boolean` | — (caller-supplied; no default) | Gates whether an empty value is acceptable and whether the field can block publish. |
| `def.config.maxLength` | `number` | Type-specific: 255 (`text`), 2000 (`textarea`), 20000 (`markdown`), 2048 (`url`), 254 (`email`) | Overrides the default length cap for the string-shaped types that have one. |
| `def.config.maxItems` | `number` | 50 (`MULTI_SELECT_MAX_ITEMS`) | Overrides the maximum selection count for `multi_select`. |
| `def.config.options` | `string[]` | Absent/empty (no restriction) | Restricts accepted values for `select` and `multi_select`. |
| `def.showIf` | `ShowIfRule \| null` | Absent/`null` (always shown) | Controls whether the field is currently visible and whether `required` applies. |
| `def.deletedAt` | `string \| null` | `null` | When truthy, excludes the field from `publishBlockers` regardless of its other settings. |
| `def.label` | `string` | Falls back to `def.key` | Text `publishBlockers` reports for the field in the registrant-facing checklist. |
| `def.visibility` (as read by `searchableText`) | `FieldVisibility` | Absent (treated as always eligible to contribute text) | When present and not `'public'`, withholds the field's value from `searchableText`. |
| Field-visibility ceiling (as read by `isWithinVisibility`/`visibilitiesWithin`) | `FieldVisibility` | — (caller-supplied per field definition) | Bounds how loose a registrant may set that field's own visibility. |

## Deep Linking

Not applicable: this package defines no routes, screens, or URLs of its own — `types.ts`, `show-if.ts`, `validate.ts`, and `visibility.ts` contain no URL or router-related code.

## Localization

This module produces user-facing strings, so this is documented rather than marked not applicable. Every error string `validateFieldValue` returns is hardcoded English with no localization hook: `'Required'`, `` `Must be ${cap} characters or fewer` ``, `'Must be a http(s) URL'`, `'Must be an email address'`, `'Must be a phone number'`, `` 'Must be a date (YYYY-MM-DD)' ``, `'Must be true or false'`, `'Not one of the allowed options'`, `'Must be a list'`, `` `Must be ${max} selections or fewer` ``, `'Must not repeat a selection'`, `'Must be an uploaded image'`, `'Must be an address'`, `'Country must be a two-letter code'`, and `'Unrecognized field type'`. None of these strings is externalized into a resource file or run through a translation function anywhere in `validate.ts`; a caller that surfaces one of them directly to a registrant shows it in English regardless of the registrant's locale.

## Accessibility Options

Not applicable: this is a data-model and validation package with no rendering, so it responds to none of Reduce Motion, Increase Contrast, or Differentiate Without Color.

## Feature Flags

Not applicable: none of `types.ts`, `show-if.ts`, `validate.ts`, or `visibility.ts` defines or reads a feature-flag key.

## Analytics

Not applicable: none of the four source files emits an analytics or telemetry event.

## Privacy

- **Data considered sensitive**: `visibility.ts` treats `email`, `phone`, and `address` as contact field types — ways to reach a specific person rather than to describe one (`CONTACT_FIELD_TYPES`) — and this model's own text-extraction path additionally withholds `email` and `phone` from full-text search even when the field is publicly visible (**searchable-text-contact-exclusion**), specifically to keep an anonymous search box from being usable to test whether a given phone number or address is registered.
- **Storage**: This module stores nothing itself; it computes values a caller then persists elsewhere. It has no notion of at-rest encryption or database schema.
- **Transmission / disclosure**: `visibilityAdmits(field, viewer)` is the single rule this model provides for whether a value may reach a given audience — a viewer's entitlement rank must be at or above the field's visibility rank (**visibility-admits**). `private` values are deliberately outside `ViewerScope` altogether (**viewer-scope-excludes-private**): no function in this module ever admits a `private` value to a public-plane read; the docblock in `visibility.ts` records that such values instead reach their owner through a separate authenticated entry API this package does not implement.
- **Fail-closed default**: A newly created field definition's starting visibility is decided once, by `defaultVisibilityForType`: contact types and any type this build does not recognize start `private`, and every other recognized type starts `public` (**default-visibility-by-type**). An unrecognized type is treated as if it were a contact type specifically so that a type this build cannot characterize never defaults to public exposure.
- **Retention**: Not applicable — the model holds no data across calls; it has no retention policy of its own to define.

## Logging

Not applicable: none of the four source files calls a logging or diagnostic API.

## Platform Notes

- **SwiftUI**: Port as a framework-free Swift package mirroring `@adh-sdk/registry-types`'s own "no runtime dependencies" stance. `FieldType` becomes a `String`-backed `enum: Codable, CaseIterable, Sendable`; `FieldDefLike` becomes a `Sendable` `struct` with `config` represented as a small `JSONValue` enum (Swift has no direct equivalent of `Record<string, unknown>`); the four modules become free functions or a stateless `enum` namespace, matching their purity. Use `Regex` (or `NSRegularExpression`) for the URL/email/phone/image-id patterns and `ISO8601DateFormatter`/a strict `DateFormatter` for the `date` check in place of `Date.parse`. A SwiftUI form binds directly to the coerced values and calls the validator on each edit, exactly as the entry editor does.
- **Compose**: Port as a Kotlin Multiplatform common-module file with no Android dependency, so it runs identically in a Compose UI and elsewhere. `FieldType` becomes a `@Serializable` `enum class`; `FieldDefLike` becomes a `data class` with `config: Map<String, JsonElement>` (kotlinx.serialization); use `kotlin.text.Regex` for the format checks and `LocalDate.parse` with a strict `DateTimeFormatter` for `date`. The pure-function shape translates directly to a Kotlin `object`.
- **React/Web** (source platform): `packages/web/packages/registry-types/src/{types.ts, show-if.ts, validate.ts, visibility.ts}`, published as `@adh-sdk/registry-types` with no runtime dependencies and no React import — it is consumed by, but architecturally independent of, any of this toolkit's React UI packages. Its `src/index.ts` re-exports the full public surface named in this recipe. Specific to this platform: the backend does not depend on the npm package at build time but vendors these files into a single concatenated source, which is why `evaluateShowIf`'s hoisting matters (**vendored-build-ordering**).
- **AppKit / UIKit**: Uses the identical Swift package described under **SwiftUI** — the model has no view-layer dependency, so nothing AppKit- or UIKit-specific is required. An AppKit/UIKit form typically drives validation imperatively (e.g., on `NSTextField`/`UITextField` editing-end) rather than through a reactive binding, but calls the same functions.
- **WinUI 3**: Model `FieldDefLike` as a C# `record` (`string Key, FieldType Type, bool Required, JsonElement Config`), with `FieldType` as a `string`-backed enum or a `HashSet<string>` membership check mirroring `isFieldType`. Represent `config`/`values` with `System.Text.Json.JsonElement`/`JsonDocument`, since .NET has no built-in `Record<string, unknown>` equivalent. Use `System.Text.RegularExpressions.Regex` for the URL/email/phone/image-id patterns and `DateOnly.TryParseExact(value, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out _)` for the strict `date` check in place of `Date.parse`. Port the deep-equality comparison (**deep-value-equality**) as a small recursive method over `JsonElement`/`IDictionary`/`IList`, since .NET has no built-in deep-equality for arbitrary JSON-shaped data; keep the same 32-level depth cap. No `HttpClient` or `Task`/`async` is needed anywhere in this port — every operation here is synchronous — though the calling code that persists a coerced value will itself be `async`. A dynamic settings form typically surfaces the coerced values through an `ObservableCollection<FieldValue>` view model implementing `INotifyPropertyChanged`, bound to an `ItemsRepeater`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/registry-types/src/` | unverified |

## Design Decisions

**Decision**: `validateFieldValue` and `coerceFieldValue` are two separate functions with a hard calling-order contract (validate, then coerce only on success), rather than one function that validates-and-normalizes.
**Rationale**: The module's own docblock states the rule precisely: a coercer is total (every input has some branch) but not every branch is a *faithful, non-lossy* reading of the input — an `image` value that is an object would stringify to `"[object Object]"` instead of failing, for example. Splitting the two lets each accepted wire form be judged once, explicitly, for whether coercing it would invent or discard information, rather than silently waving a mangled value through.
**Approved**: pending

**Decision**: `show_if` evaluation fails **open** (shows the field) on an unrecognized `op` or a malformed `in` rule, while `validateFieldValue`, `coerceFieldValue`, and `defaultVisibilityForType` fail **closed** (reject / private) on an unrecognized field type.
**Rationale**: These are different risks pointing in different directions. A `show_if` rule this build cannot read is presumed to be authored by a newer builder; hiding the field would silently drop data the registrant already has no way to fix. An unrecognized *field type*, by contrast, is data whose value this build cannot characterize at all — accepting or publicly exposing it is the greater risk, so the default there is refusal / privacy, not visibility.
**Approved**: pending

**Decision**: `required` is enforced only by `publishBlockers`, at publish time, never at save time.
**Rationale**: The owner-defined form can span many fields across independently-saved sections; enforcing `required` on every save would reject the first section a registrant fills in, citing fields in sections they have not opened yet. Editor and server share this exact function so their checklists can never disagree about what is still missing.
**Approved**: pending

**Decision**: Contact field types (`email`, `phone`, `address`) default to `private` visibility on creation; every other type defaults to `public`.
**Rationale**: Publishing a business phone number or address is a legitimate registry choice, so this is a default, not a ban — but it must be a default nobody is surprised by. Starting contact types closed means publishing one is always a decision someone made, not one they inherited from a generic default.
**Approved**: pending

**Decision**: `searchableText` withholds `email` and `phone` from the anonymous search index even when the field's visibility is `public`.
**Rationale**: A directory is searched by who someone is and what they do, not by their phone number; indexing either would turn the search box into a harvesting oracle (`?q=<number>` would answer "is this number registered?" for a caller who cannot see the profile field itself). This exclusion holds regardless of the owner's visibility choice for the field.
**Approved**: pending

**Decision**: The deep-value comparison behind `eq`/`ne`/`in`/`contains` compares plain objects structurally (via `Object.hasOwn` over own keys) rather than by reference, and caps recursion at 32 levels.
**Rationale**: Two field-for-field identical values fetched independently (e.g., an `address`) are different object references; reference equality made `eq` fail closed on exactly the case its own fail-open policy exists to prevent, silently hiding a dependent field forever. `Object.hasOwn` (not the `in` operator) closes the same untrusted-jsonb-input gap the module's comment on `sameValue` describes, so a payload key like `"constructor"` cannot read as present via the prototype chain. The depth cap bounds the cost of a pathologically deep, but never cyclic, `jsonb` value.
**Approved**: pending

**Decision**: `evaluateShowIf` reads the controlling value as `values[rule.field]` — a direct bracket lookup, not an `Object.hasOwn`-guarded one.
**Rationale**: `rule.field` is owner-authored data from the same untrusted `jsonb` origin the module explicitly reasons about elsewhere (see the decision above), but this particular lookup was not brought under the same guard. See the open question recorded in Behavioral Requirements' cross-cutting notes and the corresponding marker below.
**Approved**: pending

## Compliance

This is a non-UI logic package with no network calls, no rendered surface, and no session/token handling, so the platform-design, touch-target, deep-linking, offline, retry, and authentication-related compliance categories do not apply. The checks below are the ones this package's own code exercises.

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`input-sanitization` is partial: `validateFieldValue` gates every value before `coerceFieldValue` or `searchableText` act on it (**validate-before-coerce**), but address sub-fields and the `showIf` field lookup go unchecked (the open questions under **address-subfield-validation** and **show-if-field-lookup**). `fault-tolerance` passes because an unrecognized field type, an unrecognized `show_if` operator, a malformed `in` rule, and a pathologically deep comparison value are all handled with a defined return value rather than a thrown exception (**unrecognized-type-rejected**, **show-if-unknown-op-fails-open**, **show-if-malformed-in-fails-open**, **compare-depth-cap**). `no-hardcoded-strings` fails because every `validateFieldValue` error message is a hardcoded English literal with no localization hook — see Localization above. `show-if.ts`, `types.ts`, `validate.ts`, and `visibility.ts` are non-UI logic with no rendering to entangle (separation-of-concerns passed); the package's own `src/__tests__/show-if.test.ts`, `validate.test.ts`, and `visibility.test.ts` (566 lines across the three files, not the unrelated candidates the evidence search surfaced) directly and thoroughly exercise every one of these source files (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-09-25 | Mike Fullerton | Corrected compare-depth-cap and own-property-membership test vector expected results to match show-if.ts's actual comparison logic. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
