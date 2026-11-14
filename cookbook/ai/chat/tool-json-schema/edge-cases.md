
- **Empty properties**: `object(properties: [:])` MUST return a valid schema, never `{}`. MUST.
- **Empty or duplicate required names**: `required` entries are emitted as given, so duplicates and names absent from `properties` appear in the output. MUST.
- **Empty description**: A fragment with an empty description MUST still carry the `description` key. MUST.
- **Unusual property names**: A property name is a dictionary key and is passed to the serializer as is, with no check for emptiness or characters. MUST.
- **Serialization failure**: The failure path of `object` returns `{}` silently; see the open question on `schema-serialization-fallback`.
- **Concurrent access**: Not applicable — every member is a pure function with no shared state.
- **Offline or disconnected state**: Not applicable — the component performs no networking.
- **Large inputs**: No size limit exists; output size grows with the input and nothing is truncated. MUST.

