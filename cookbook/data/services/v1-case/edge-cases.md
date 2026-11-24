
- **Null and empty input** (MUST): `fromV1` and `toV1Body` of `null`, a primitive, or `undefined` return it unchanged; an empty object returns `{}`; an empty array returns `[]`. A page with a missing or non-array `data` is turned into `[]` by `listV1Page` before this module maps it.
- **Date, Map and class instances** (MUST): Any non-array object is traversed with `Object.entries`, so a `Date` or `Map` becomes `{}`. Callers pass plain JSON-shaped values.
- **Opaque map containing the type tag** (MUST): `object` is dropped only in the traversed part of a `/v1` response; inside an opaque value an `object` key is preserved because the value is not traversed.
- **Opaque name at any depth** (MUST): The five opaque names apply wherever they appear in a traversed object, so a nested property that merely happens to be called `value` or `body` is also left verbatim.
- **Null `created` or `updated`** (MUST): A `/v1` row with `created: null` is emitted with `created: null` and no `createdAt`; only numbers are converted.
- **Non-finite timestamp** (MUST): `created: NaN` or `Infinity` yields `createdAt: null`.
- **Key collisions** (MUST): Colliding renames, such as `project_id` plus `projectId`, or numeric `created` plus an existing `createdAt`, keep the later key's value silently. Nothing is logged or thrown.
- **Unusual keys** (MUST): A leading underscore (`_id`) camelizes to `Id`; `a__b` to `a_B`; `a_1` to `a1`. Snakeizing `projectID` gives `project_i_d`; a leading capital (`Foo`) gives `_foo`. These follow directly from the two regexes.
- **Reference sharing** (MUST): Opaque values and primitive values are returned by reference or copy as-is; mutating an opaque value in the output mutates the input's.
- **Cyclic input** (MUST NOT be relied on): The mappers have no cycle guard, so a cyclic structure recurses until the engine's stack limit throws a `RangeError`. `/v1` JSON cannot be cyclic.
- **Write with no body** (MUST): `v1Write("POST", undefined)` yields `body: undefined`, so no request body is sent.
- **Error states** (MUST): A non-ok HTTP status, a refresh failure, or a `204 No Content` reply to `v1Json` is thrown by the request layer and reaches the caller unmapped. `v1List` also rejects when a `has_more` page ends on a row with no id, rather than returning a truncated list.
- **Offline or unreachable server** (MUST): The underlying `fetch` rejection propagates unchanged from every wrapper; nothing here retries or queues.
- **Mid-pagination failure** (MUST): If any page of `v1List` fails, the whole call rejects and the pages already fetched are discarded.
- **Concurrent access** (MUST): Every function is stateless, so concurrent calls do not interact. In `v1List`, pages are fetched one at a time.
- **Cancellation and timeout** (MAY be added by a port): The source passes no `AbortSignal` and sets no timeout; `v1List` cannot be aborted between pages.

