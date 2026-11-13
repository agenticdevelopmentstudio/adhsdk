
- **empty-or-malformed-data**: Empty data, truncated JSON or non-JSON bytes MUST throw the not-valid-JSON error. The underlying decoder error is discarded (`try?`) and replaced by that fixed message, which is lossy but still surfaced to the caller.
- **non-object-root**: A JSON array, string, number or `null` at the root MUST throw the not-valid-JSON error, because the decode is cast to a string-keyed dictionary.
- **web-client**: A file with `web` and no `installed` MUST throw the Web-client message, so the user is told which client type to create.
- **both-keys**: A file with both `installed` and `web` MUST be read as an installed client.
- **wrong-types**: `installed` that is not an object, or `client_id` or `client_secret` that is not a string (a number, `null`, an array), MUST throw the missing-keys error.
- **installed-null**: `"installed": null` with no `web` key MUST throw the missing-keys error; a present `null` is not treated as missing, but it fails the object cast.
- **empty-strings**: An empty `client_id` or `client_secret` MUST throw the missing-keys error. A whitespace-only value MUST be accepted, because `parse(json:)` does not trim. The form model trims before constructing a config; the type does not.
- **slash-escaping**: `installedJSON()` MAY escape a forward slash in a value as a backslash and slash pair, as `JSONSerialization` does by default. The output still decodes to the original string, so the round trip holds.
- **unicode-and-special-characters**: A value with quotes, backslashes or non-ASCII characters MUST survive the `installedJSON()` then `parse(json:)` round trip, because the JSON layer escapes and decodes them.
- **large-input**: The source sets no size limit on the data; the whole input is decoded in memory. A caller that needs a limit MUST impose it before calling.
- **concurrent-calls**: Not applicable beyond `no-shared-state`: both functions are pure and the type is immutable, so there is nothing to serialise.
- **network-and-offline**: Not applicable: the type performs no network, file-system or Keychain access, so there is no unreachable dependency or offline state.
- **cancellation-and-timeout**: Not applicable: both operations are synchronous and complete without suspension, so there is nothing to cancel and no timeout exists.
- **error-text-language**: The thrown reasons are fixed English strings with no localization (see Localization).

