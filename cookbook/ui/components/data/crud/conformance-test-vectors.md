
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| crud-001 | export-interface | Compile-time type check: `expectTypeOf<Crud>().toEqualTypeOf<{ create: boolean; read: boolean; update: boolean; delete: boolean }>()` | Assertion compiles without a type error |
| crud-002 | provide-key-list | Access CRUD_KEYS constant | Array equals `["create", "read", "update", "delete"]` in that order |
| crud-003 | exported-key-type | Compile-time type check: `expectTypeOf<CrudKey>().toEqualTypeOf<"create" \| "read" \| "update" \| "delete">()` | Assertion compiles without a type error |
| crud-004 | provide-letter-mapping | Access CRUD_LETTER["create"], CRUD_LETTER["read"], CRUD_LETTER["update"], CRUD_LETTER["delete"] | Returns `"C"`, `"R"`, `"U"`, `"D"` respectively |
| crud-005 | provide-no-access-default | Call noAccess() | Returns `{ create: false, read: false, update: false, delete: false }` |
| crud-006 | provide-read-only-default | Call readOnly() | Returns `{ create: false, read: true, update: false, delete: false }` |
| crud-007 | clamp-child-to-parent | Call clampToParent({ create: true, read: true, update: false, delete: false }, { create: true, read: false, update: true, delete: true }) | Returns `{ create: true, read: false, update: false, delete: false }` |
| crud-008 | clamp-child-to-parent | Call clampToParent({ create: false, read: false, update: false, delete: false }, { create: true, read: true, update: true, delete: true }) | Returns `{ create: false, read: false, update: false, delete: false }` |
| crud-009 | clamp-child-to-parent | Call clampToParent({ create: true, read: true, update: true, delete: true }, noAccess()) | Returns `{ create: false, read: false, update: false, delete: false }` |
| crud-010 | clamp-child-to-parent | Call clampToParent(x, x) where x = `{ create: true, read: false, update: true, delete: false }` | Returns an object equal in value to `x` |
| crud-011 | clamp-child-to-parent | Call clampToParent({ create: true, read: true, update: true, delete: true }, readOnly()) | Returns `{ create: false, read: true, update: false, delete: false }` |
| crud-012 | not-mutate-inputs | Call clampToParent(child, parent) with fixed `child`/`parent` objects, then re-read both after the call | `child` and `parent` are unchanged from their original values |
| crud-013 | fresh-instance-per-call | Call noAccess() twice and compare the two results with `===` | Comparison is `false` — the two calls return different object references |

