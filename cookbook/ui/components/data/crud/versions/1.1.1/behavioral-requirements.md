
- **export-interface**: The Crud interface MUST export four boolean properties: `create`, `read`, `update`, `delete`, each representing an independent permission capability.
- **provide-key-list**: An exported constant `CRUD_KEYS` MUST be an ordered array of the four capability names in the order: `["create", "read", "update", "delete"]`.
- **exported-key-type**: `CRUD_KEYS` MUST be declared as a readonly tuple (via `as const`), and an exported `CrudKey` union type MUST be derived from it (`"create" | "read" | "update" | "delete"`); `CRUD_LETTER` MUST be keyed by `CrudKey`.
- **provide-letter-mapping**: An exported `CRUD_LETTER` object MUST map each key to its canonical single-letter representation: `create` → `"C"`, `read` → `"R"`, `update` → `"U"`, `delete` → `"D"`.
- **provide-no-access-default**: A `noAccess()` function MUST return a Crud instance with all four properties set to `false`.
- **provide-read-only-default**: A `readOnly()` function MUST return a Crud instance with `read` set to `true` and all other properties set to `false`.
- **not-mutate-inputs**: `clampToParent()` MUST NOT mutate either of its input objects; the `child` and `parent` arguments MUST retain their original property values after the call.
- **fresh-instance-per-call**: `noAccess()` and `readOnly()` MUST return a newly created object on each call; two separate calls MUST NOT return the same object reference.
- **clamp-child-to-parent**: A `clampToParent(child: Crud, parent: Crud)` function MUST return a new Crud instance where each capability is the logical AND of the child and parent values: if either the child or parent denies a capability, the result MUST deny it.

