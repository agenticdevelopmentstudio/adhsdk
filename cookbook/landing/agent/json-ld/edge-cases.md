
- **Null or omitted extra**: `withWebSite` MUST return a graph of the added `WebSite` alone. See json-ld-005.
- **Empty graph in extra**: A `@graph` of zero entities MUST contribute nothing. See json-ld-012.
- **Trailing slashes on the URL**: All trailing `/` characters MUST be trimmed from the `@id` base and from nothing else. See json-ld-006.
- **WebSite declared with an array type**: The check is a strict equality, so an `@type` list is not recognized and a second `WebSite` is added; hosts SHOULD declare their own with the plain string type. See json-ld-011.
- **Document with sibling keys**: When `extra` is a `{ "@context", "@graph" }` document, only its `@graph` entities are kept; any other top-level key on that document is discarded. A `@graph` that is not an array makes the object an ordinary entity.
- **Non-object extra**: A string, number or boolean `extra` is not rejected; it is spread into an entity (a number or boolean yields an empty entity, a string yields an entity keyed by character index), so the host SHOULD pass objects, arrays, null or undefined only.
- **Strings containing the script terminator**: `<` is escaped, so `</script>` inside any string value MUST NOT close the element. See json-ld-003.
- **Data JSON cannot serialize**: `JsonLd` calls `JSON.stringify` with no guard, so a circular structure or a BigInt value throws during render and the source has no error state. The host MUST pass JSON-safe data.
- **Boundary values**: Not applicable; the source constrains no length, count or range, and an empty `data` object serializes to an empty object.
- **Concurrent access**: Not applicable; both functions are pure and keep no shared state, so calls cannot interfere.
- **Offline or disconnected state**: Not applicable; neither function makes a network request.

