
- **namespace-only**: The component MUST be a stateless namespace (a caseless enum) with only static members; it MUST NOT be instantiable and MUST hold no state.
- **object-shape**: `object(properties:required:)` MUST produce a JSON object with exactly three top-level keys: `type` equal to `"object"`, `properties` holding the supplied map, and `required` holding the supplied array.
- **required-default-empty**: When `required` is omitted, `object` MUST emit `required` as an empty array, not omit the key.
- **properties-passthrough**: `object` MUST emit each supplied property fragment unchanged under its name, with no validation of fragment contents.
- **sorted-keys-output**: `object` MUST serialize with sorted keys, so the same inputs always produce byte-identical `Data`.
- **required-order-preserved**: `object` MUST emit the `required` names in the order given, with no sorting or de-duplication.
- **required-not-checked-against-properties**: `object` MUST NOT check that each `required` name exists in `properties`; a missing name is emitted as given.
- **empty-properties**: `object(properties: [:])` MUST produce a valid object schema with an empty `properties` object and an empty `required` array.
- **schema-serialization-fallback**: NEEDS REVIEW: Not implemented in source. When serialization throws, `object` returns the two-byte JSON `{}` through `try?` with no log, error or other signal, so the tool is advertised with a schema that has no `type`, `properties` or `required`. Evidence that would settle it: whether any property map a caller can build is non-serializable (a test with a fragment holding a non-JSON value), and whether callers should learn of the fallback.
- **fragment-string**: `string(_:)` MUST return a fragment with `type` equal to `"string"` and `description` equal to the argument.
- **fragment-integer**: `integer(_:)` MUST return a fragment with `type` equal to `"integer"` and `description` equal to the argument.
- **fragment-number**: `number(_:)` MUST return a fragment with `type` equal to `"number"` and `description` equal to the argument.
- **fragment-boolean**: `boolean(_:)` MUST return a fragment with `type` equal to `"boolean"` and `description` equal to the argument.
- **fragment-description-verbatim**: Each fragment helper MUST carry its description text unmodified, including the empty string.
- **no-side-effects**: The component MUST NOT perform file, network, process or notification side effects.
- **thread-safety**: Every member MUST be safe to call concurrently, since all are pure functions of their arguments.

