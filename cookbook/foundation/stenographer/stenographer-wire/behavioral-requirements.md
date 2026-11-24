
- **encoder-factory**: `StenographerWire.encoder()` MUST return a `JSONEncoder` whose key strategy is `convertToSnakeCase` and whose date strategy is `iso8601`.
- **decoder-factory**: `StenographerWire.decoder()` MUST return a `JSONDecoder` whose key strategy is `convertFromSnakeCase` and whose date strategy is `iso8601`.
- **fresh-instance**: Each call MUST return a new instance, so a caller may keep or change its own copy without affecting any other caller.
- **round-trip**: A type encoded with `encoder()` MUST decode with `decoder()` to an equal value, for property names that survive the snake_case conversion in both directions.
- **nil-omitted**: Every DTO that travels through `encoder()` MUST omit a nil optional property from the encoded object. This holds for a synthesized `Encodable` conformance, which uses `encodeIfPresent`; a DTO with a hand-written `encode(to:)` MUST do the same itself, because the factory does not enforce it.
- **no-other-settings**: The encoder and decoder MUST NOT set any other strategy: data, non-conforming floats and output formatting stay at the `Foundation` defaults.
- **no-validation**: The functions MUST NOT validate input; a malformed body is reported by the `decode` call that uses the decoder, as the standard `DecodingError`.

