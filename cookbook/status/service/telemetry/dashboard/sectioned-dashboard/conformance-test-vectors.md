
The vectors use the test file `telemetry-sectioned-dashboard.test.ts`: `ttlMs` 10,000, `retryMs` 1,000, sections `a` and `b`, a fake clock starting at 1,000,000. Every vector is backed by a test in that file.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| sectioned-001 | read-never-waits, read-starts-refresh, read-cold-start, section-initial-state, loaders-built-per-refresh | Test "a cold read answers immediately and starts a refresh": loaders never resolve; `read("k1")` | `refreshing` true; `a` is `{ data: null, error: null, updatedAt: null }`; loaders built once |
| sectioned-002 | concurrency-default, section-publish-on-finish, refresh-flag | Test "publishes each section as it finishes, in order, one at a time": `a` pending, `b` a spy; read, then resolve `a` | `b` not called until `a` resolves; then `refreshing` false, `a.data` 1, `b.data` "two" |
| sectioned-003 | read-no-double-refresh | Test "reads during a refresh never start another": three reads while `a` pending | Loaders built once |
| sectioned-004 | ttl-after-success, section-due-rule, read-nothing-due | Test "does not refresh again inside the TTL, and does after it": read, advance 9,999 ms, read; advance 1 more ms, read | First later read `refreshing` false, built once; after 10,000 ms total `refreshing` true, built twice |
| sectioned-005 | failure-keeps-data, failure-isolated, failure-logged | Test "a failed section keeps its last good data, reports why, and the rest still load": `a` resolves 1, then throws `HTTP 504` after the TTL | `a` is `{ data: 1, error: "HTTP 504" }`; `b` is `{ data: "x", error: null }`; the source logs one `console.warn` for `a` (the test silences it and does not assert on it) |
| sectioned-006 | retry-after-failure, retry-default | Test "retries sooner after a failure than after a success": `a` always rejects; advance 999 ms, read; advance 1 ms, read | Built once after 999 ms; built twice at 1,000 ms |
| sectioned-007 | retry-only-failing, retry-after-failure | Test "retries only the failing section, backing off with each failure in a row": advance 1,000, read; advance 1,999, read; advance 1, read | Calls to `a` and `b`: [2, 1] after the first retry; still 2 for `a` at +1,999 ms; [3, 1] after the last advance |
| sectioned-008 | incomplete-short-answer | Test "an answer known to be short is shown as a success but retried like a failure": `incomplete` true for `a` when data is -1; read, then advance 1,000 | `a` is `{ data: -1, error: null }`; loaders built again at 1,000 ms |
| sectioned-009 | keys-independent | Test "keeps keys separate": `read("k1")`, `read("k2")` | Loaders built for `["k1"]` then `["k2"]` |
| sectioned-010 | loaders-builder-throws, wedge-guard | Test "a loaders() builder that throws cannot wedge the key refreshing forever": `loaders` throws `bad build`; read, flush, read | Second read `refreshing` false; the source logs `[telemetry] dashboard refresh (k) failed: bad build` (the test silences `console.warn` and does not assert on it) |
| sectioned-011 | settle-never-starts, settle-contract | Test "resolves true at once when nothing was ever read, and never starts a refresh": `settle("k1", 1000)` on a fresh dashboard | Resolves `true`; no loaders built |
| sectioned-012 | settle-contract, settle-result | Test "waits for the refresh in flight, then a second read has the data": read, `settle("k1", 60000)`, resolve `a` | Resolves `true`; next read has `a.data` 1 and `b.data` "two", `refreshing` false |
| sectioned-013 | settle-result, settle-timer-cleared | Test "gives up at the deadline and reports the key still refreshing": `a` never resolves; `settle("k1", 5000)`; advance fake timers 5,000 ms | Resolves `false`; a following read has `refreshing` true |
| sectioned-014 | settle-contract | Test "resolves true once the refresh has finished, without waiting": read, flush, `settle("k1", 60000)` | Resolves `true` |
| sectioned-015 | empty-sections | `emptySections(["a", "b"])` | `{ a: { data: null, error: null, updatedAt: null }, b: { data: null, error: null, updatedAt: null } }` |
| sectioned-016 | read-copy | Read twice around a publish, keeping the first result | The first result's sections are unchanged after the publish |
| sectioned-017 | retry-clamp | `ttlMs` 500, `retryMs` 1,000, a loader that fails | Next attempt is due at 500 ms, not 1,000 ms |
| sectioned-018 | failure-keeps-data, success-publish | A section fails after a success, then succeeds again | After the failure `error` is set with old `data` and `updatedAt`; after the success `error` is `null` and `updatedAt` is the new time |
| sectioned-019 | concurrency-limit | `concurrency` 2 with three due sections and pending loaders | Two loaders start at once; the third starts when one finishes |
| sectioned-020 | failure-keeps-data | A non-`Error` rejection such as the string `"boom"` | `error` is `"boom"` |

