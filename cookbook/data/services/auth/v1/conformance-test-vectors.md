
Every vector is asserted in `packages/web/packages/auth/src/__tests__/v1.test.ts`, and each test title starts with its vector id.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| v1-001 | query-append, query-drop-nullish | `withV1Query('/api/v1/teams', { limit: 100, starting_after: undefined })` (test: withV1Query appends, replaces, repeats arrays and drops nullish values) | `/api/v1/teams?limit=100` |
| v1-002 | query-replace, keep-filters | `withV1Query('/api/v1/teams?ecosystem_id=e1&limit=5', { limit: 100 })` (same test) | `/api/v1/teams?ecosystem_id=e1&limit=100` |
| v1-003 | query-array-repeat, query-encoding | `withV1Query('/api/v1/account', { 'include[]': ['a', 'b'] })` (same test) | `/api/v1/account?include%5B%5D=a&include%5B%5D=b` |
| v1-004 | query-preserves-fragment | `withV1Query('/x?a=1#top', { b: 2 })` | `/x?a=1&b=2#top` |
| v1-005 | query-empty-array, query-stringify | `withV1Query('/x?k=old', { k: [], n: 5, f: false })` | `/x?n=5&f=false` |
| v1-006 | walk-all-pages, page-size, cursor-advance, keep-filters | Two pages: first returns rows with ids a and b and `has_more` true, second returns id c and `has_more` false; call `listAllV1('/api/v1/teams?ecosystem_id=e1')` (test: listAllV1 walks starting_after while has_more) | Rows with ids a, b, c; requests were `/api/v1/teams?ecosystem_id=e1&limit=100` then `/api/v1/teams?ecosystem_id=e1&limit=100&starting_after=b` |
| v1-007 | truncation-guard | One page `[{ scope: 'x' }]` with `has_more` true; call `listAllV1('/api/v1/usage/counters')` (test: throws rather than truncating) | Rejects with an error matching `no id to page from`; no second request |
| v1-008 | stop-on-empty-page | One page with `data: []` and `has_more` true | Resolves to `[]` after exactly one request |
| v1-009 | cursor-custom | Page `[{ key: 'k1' }]` with `has_more` true, `opts.cursorOf` returning the row's `key`, then a final page | Second request carries `starting_after=k1` |
| v1-010 | cursor-default | Last row `{ id: 7 }` with `has_more` true | Next request carries `starting_after=7` |
| v1-011 | tolerate-malformed-page | Response body `{ object: 'list', data: 'oops', has_more: true }` | `listAllV1` resolves to `[]`; `listV1Page` yields `{ data: [], hasMore: true }` |
| v1-012 | error-propagation | Second page request answers 500 | `listAllV1` rejects with `AuthHttpError` whose status is 500; the first page's rows are not returned |
| v1-013 | single-page, page-unwrap | `listV1Page('/api/v1/teams?limit=1')` with one page `[{ id: 'a' }]` and `has_more` true (test: listV1Page unwraps one page) | `{ data: [{ id: 'a' }], hasMore: true }`, one request, URL unchanged |
| v1-014 | page-unwrap | Page with `has_more` the string `'true'` | `hasMore` is `false` |
| v1-015 | unix-to-iso | `unixToIso(0)` (test: unix timestamps round-trip) | `1970-01-01T00:00:00.000Z` |
| v1-016 | unix-to-iso-nullish | `unixToIso(null)`, `unixToIso(undefined)`, `unixToIso(NaN)` (null case from the same test) | `null` for each |
| v1-017 | unix-to-iso-range | `unixToIso(1e13)` | Throws `RangeError` |
| v1-018 | iso-to-unix | `isoToUnix('2026-01-01T00:00:00.000Z')` (same test) | `1767225600` |
| v1-019 | iso-to-unix | `isoToUnix('2026-01-01T00:00:00.999Z')` | `1767225600` |
| v1-020 | iso-to-unix-invalid | `isoToUnix('not a date')` | `NaN` |
| v1-021 | page-max | Read `V1_PAGE_MAX` | `100` |

