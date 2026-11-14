
- **Empty and missing values**: An empty `steps` array, an empty `guidelines`, an empty `condition` and a nil `scheduleSeconds` are all valid (MUST). A missing non-optional key fails to decode (MUST).
- **Unknown environment**: A step whose environment is not `terminal` or `claude` fails to decode (MUST). A stored job holding such a step makes a whole-array decode fail, because the store decodes all steps together.
- **Boundary values**: `scheduleSeconds` accepts any integer; zero and negative values are valid data that the type keeps as given; what they mean is up to the consumer that arms a timer. There is no upper bound.
- **Duplicate ids and names**: The types do not enforce uniqueness. The store keys jobs by `id` and replaces a row with the same id (see the store's upsert), so uniqueness is the store's concern, not this type's.
- **Unsafe ids**: An id with path characters is valid data here; callers that use it in a file path MUST check it first (MUST, per no-validation).
- **Concurrent access**: Not applicable beyond value semantics — each copy is independent, so there is no shared mutable state.
- **Network, timeouts, retry, offline**: Not applicable — the types perform no I/O.

