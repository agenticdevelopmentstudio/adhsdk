
- **Null / empty input**: A nil optional is omitted from the encoded object, not written as `null`. An empty object decodes only into a type whose properties are all optional.
- **Boundary values**: Not applicable: the factories take no input; numeric and date limits are those of `JSONEncoder` and `JSONDecoder`.
- **Concurrent access**: Each call returns a separate instance, so callers do not share state through this type. A caller that shares one returned encoder or decoder across tasks owns that sharing; the HTTP client keeps one of each as constants for its lifetime.
- **Error states**: The factories cannot fail. A body that is not valid JSON, a missing key, a wrong type or a date that is not ISO-8601 is reported by the caller's `decode` as a `DecodingError`.
- **Key conversion limits**: The snake_case strategies convert by Foundation's rules; a property name with a run of capitals (an acronym such as `baseURL`) encodes to `base_url` but decodes from `base_url` as `baseUrl`, so such a property does not round-trip unless the DTO declares `CodingKeys`. The DTOs in this family avoid acronyms in property names.
- **Dates**: The DTOs in this family carry timestamps as `String` (for example `SessionDTO.startedAt`); the date strategies apply only to a `Date` property, such as `ImportRequestDTO.since`. Only dates in whole-second ISO-8601 form decode; a daemon reply with fractional seconds would fail.
- **Offline / disconnected state**: Not applicable: the type performs no network access.

