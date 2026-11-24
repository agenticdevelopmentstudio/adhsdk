
`packages/web/packages/data/src/__tests__/v1-case.test.ts` asserts every vector below directly (stubbing `fetch` with `src/__tests__/v1-fetch.ts`); the projects client tests under `src/projects/__tests__/` also run the mappers indirectly. A port's unit tests should assert the same vectors.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| v1-case-001 | camelize-rule, timestamps-to-iso | `fromV1({ id: "p1", project_id: "x", created: 1700000000, updated: 1700000060 })` | `{ id: "p1", projectId: "x", createdAt: "2023-11-14T22:13:20.000Z", updatedAt: "2023-11-14T22:14:20.000Z" }` |
| v1-case-002 | camelize-idempotent | `fromV1({ project_id: "a" })` and `fromV1({ projectId: "a" })` | Both return `{ projectId: "a" }` |
| v1-case-003 | object-tag-dropped | `fromV1({ object: "project", id: "p1" })` | `{ id: "p1" }` |
| v1-case-004 | object-tag-dropped, recursion-depth | `fromV1({ data: [{ object: "item", item_key: "K-1" }] })` | `{ data: [{ itemKey: "K-1" }] }` |
| v1-case-005 | opaque-keys | `fromV1({ counts: { in_progress: 3 } })` | `{ counts: { in_progress: 3 } }` (same keys, not `inProgress`) |
| v1-case-006 | opaque-keys | `fromV1({ config: { sort_by: "x" }, detail: { a_b: 1 }, body: { c_d: 2 }, value: { e_f: 3 } })` | Every nested key keeps its original casing |
| v1-case-007 | opaque-keys | `toV1Body({ config: { sortBy: "x" } })` | `{ config: { sortBy: "x" } }` |
| v1-case-008 | snakeize-rule | `toV1Body({ projectId: "p", createdAt: "x" })` | `{ project_id: "p", created_at: "x" }` |
| v1-case-009 | null-kept, undefined-dropped | `toV1Body({ dueDate: null, note: undefined })` | `{ due_date: null }` |
| v1-case-010 | object-key-kept-on-write | `toV1Body({ object: "x" })` | `{ object: "x" }` |
| v1-case-011 | timestamp-nonnumber-passthrough | `fromV1({ created: null })` | `{ created: null }` |
| v1-case-012 | timestamp-nonfinite-null | `fromV1({ created: NaN })` | `{ createdAt: null }` |
| v1-case-013 | scalar-passthrough | `fromV1(null)`, `fromV1("s")`, `toV1Body(undefined)` | `null`, `"s"`, `undefined` |
| v1-case-014 | array-recursion | `fromV1([{ a_b: 1 }, { c_d: 2 }])` | `[{ aB: 1 }, { cD: 2 }]` |
| v1-case-015 | mapper-pure | Call `toV1Body(x)` on an object `x` with a nested object | `x` is unchanged and the result is a distinct object |
| v1-case-016 | later-key-wins | `fromV1({ project_id: "a", projectId: "b" })` | `{ projectId: "b" }` |
| v1-case-017 | v1write-shape, v1write-no-headers | `v1Write("POST", { projectId: "p" })` | `{ method: "POST", body: "{\"project_id\":\"p\"}" }` with no `headers` key |
| v1-case-018 | v1write-shape | `v1Write("POST", undefined)` | `{ method: "POST", body: undefined }` |
| v1-case-019 | v1json-single | `authedJson` resolves `{ project_id: "x", created: 0 }` | `v1Json(url)` resolves `{ projectId: "x", createdAt: "1970-01-01T00:00:00.000Z" }` |
| v1-case-020 | v1json-errors-propagate | `authedJson` rejects with a 404 error | `v1Json(url)` rejects with that same error object |
| v1-case-021 | v1list-all-pages, v1list-cursor-on-wire-rows | Page one has `has_more` true and last row `id: "r2"`; page two has `has_more` false | `v1List` requests `starting_after=r2` on the second call and resolves all rows camelCased in one array |
| v1-case-022 | v1page-one-page, v1page-url-verbatim | `listV1Page` resolves `{ data: [{ a_b: 1 }], hasMore: true }` | `v1Page(url)` resolves `{ data: [{ aB: 1 }], hasMore: true }` and requested `url` unchanged |
| v1-case-023 | v1list-all-pages | Last row of a `has_more` page has no `id` | `v1List` rejects with the error thrown by `listAllV1` |
| v1-case-024 | fromv1-unchecked-cast | `fromV1<{ a: number }>({ b: "x" })` | Returns `{ b: "x" }` with no error |

