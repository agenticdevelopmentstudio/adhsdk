
- **empty-or-malformed-data**: Empty data, truncated JSON or non-JSON bytes MUST throw the not-valid-JSON error. The underlying decoder error is discarded (`try?`) and replaced by that fixed message, which is lossy but still surfaced to the caller.
- **non-object-root**: A JSON array, string, number or `null` at the root MUST throw the not-valid-JSON error, because the decode is cast to a string-keyed dictionary.
- **web-client**: See #behavioral-requirements/parse-web-client-rejected.
- **both-keys**: See #behavioral-requirements/parse-installed-wins.
- **wrong-types**: See #behavioral-requirements/parse-installed-keys-required; a number, `null` or array in place of a string or object takes that path.
- **installed-null**: `"installed": null` with no `web` key MUST throw the missing-keys error; a present `null` is not treated as missing, but it fails the object cast.
- **empty-strings**: See #behavioral-requirements/parse-empty-values-rejected and #behavioral-requirements/parse-no-trimming. The form model trims before constructing a config; the type does not.
- **slash-escaping**: `installedJSON()` MAY escape a forward slash in a value as a backslash and slash pair, as `JSONSerialization` does by default. The output still decodes to the original string, so the round trip holds.
- **unicode-and-special-characters**: A value with quotes, backslashes or non-ASCII characters MUST survive the `installedJSON()` then `parse(json:)` round trip, because the JSON layer escapes and decodes them.
- **large-input**: The source sets no size limit on the data; the whole input is decoded in memory. A caller SHOULD impose a limit before calling if the file comes from an untrusted source.
- **missing-keys-message**: The single missing-keys reason names both `installed.client_id` and `installed.client_secret` even when only one is absent, empty or mistyped, because the code does not distinguish which check failed (see Design Decisions).
- **secret-printed-by-description**: The struct's synthesized `description` and `dump` output includes `clientSecret`, and the source adds no masking.
- **concurrent-calls**: Not applicable beyond `no-shared-state`: both functions are pure and the type is immutable, so there is nothing to serialise.
- **network-and-offline**: Not applicable: the type performs no network, file-system or Keychain access, so there is no unreachable dependency or offline state.
- **cancellation-and-timeout**: Not applicable: both operations are synchronous and complete without suspension, so there is nothing to cancel and no timeout exists.
- **error-text-language**: The thrown reasons are fixed English strings with no localization (see Localization).

