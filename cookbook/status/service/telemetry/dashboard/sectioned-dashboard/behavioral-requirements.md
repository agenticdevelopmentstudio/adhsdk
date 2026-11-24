
**Section shape**

- **section-fields**: A `DashboardSection<T>` MUST carry `data` (the last good answer or `null`), `error` (why the latest attempt failed, or `null`) and `updatedAt` (when `data` was fetched, an ISO string, or `null`).
- **section-initial-state**: Before any attempt finishes, every section MUST read as `{ data: null, error: null, updatedAt: null }`.
- **empty-sections**: `emptySections(names)` MUST return an object with one section in that initial state for each name. The dashboard set uses it as the answer for an unconfigured provider.
- **read-shape**: `read(key)` MUST return `{ refreshing, sections }`, with `sections` holding one `DashboardSection` per name in `opts.sections`.
- **read-copy**: `read` MUST return a new `sections` object on each call (a shallow copy), so a caller holding an earlier result does not see later publishes. A section object is replaced, not mutated, when it is published.

**Reads never wait**

- **read-never-waits**: `read` MUST return synchronously, never waiting on a loader.
- **read-starts-refresh**: When `refreshing` is false and at least one section is due, `read` MUST start a refresh for exactly the due sections and return with `refreshing` true, except when the loaders builder throws (see `loaders-builder-throws`).
- **read-cold-start**: The first `read` of a key has every section due (`dueAt` 0), so it MUST start a refresh of all sections.
- **read-no-double-refresh**: While a refresh for a key is in flight, further reads of that key MUST NOT start another.
- **read-nothing-due**: When no section is due, `read` MUST start nothing and return `refreshing` false.
- **section-due-rule**: A section is due when its `dueAt` is less than or equal to `now()`.
- **keys-independent**: State is kept per key; a read or refresh of one key MUST NOT affect another key's sections, schedules or refresh flag.
- **keys-bounded**: Keys MUST come from a bounded set. State per key is created on first read and never removed.

**Refresh**

- **loaders-built-per-refresh**: `opts.loaders(key)` MUST be called once at the start of each refresh, so loaders can compute a time window from the current time.
- **only-due-loaders-run**: A refresh MUST call only the loaders of the sections that were due when it started.
- **concurrency-default**: Due sections MUST run strictly one after another unless `concurrency` is set. The default is 1.
- **concurrency-limit**: With `concurrency` greater than 1, at most that many loaders MUST run at once, taken in order.
- **section-publish-on-finish**: Each section MUST be published to state as soon as its own loader settles; with the default `concurrency` of 1 that is before the next section starts.
- **success-publish**: When a loader resolves, the section MUST become `{ data, error: null, updatedAt }` where `updatedAt` is `new Date(now()).toISOString()`.
- **failure-keeps-data**: When a loader rejects, the section MUST keep its prior `data` and `updatedAt` and take `error` set to the error's `message`, or `String(err)` for a non-`Error` value.
- **failure-isolated**: A failing loader MUST NOT stop the remaining due sections from running.
- **failure-logged**: Each failed section MUST be logged once with `console.warn` as `[telemetry] dashboard section <name> (<key>) failed: <error>`.
- **refresh-flag**: `refreshing` MUST be true from the moment a refresh starts until all of its due sections have settled, and false after.

**Scheduling and backoff**

- **ttl-after-success**: After a successful section, its `dueAt` MUST be `now() + ttlMs` and its failure count MUST reset to 0.
- **retry-default**: `retryMs` defaults to 60,000 ms.
- **retry-clamp**: The effective retry interval MUST be `min(retryMs, ttlMs)`.
- **retry-after-failure**: After a failed section, its `dueAt` MUST be `now() + min(retryMs * 2^(failures - 1), ttlMs)`, where `failures` counts failed attempts in a row including this one. The waits run retryMs, 2 times retryMs, 4 times retryMs and so on, never above `ttlMs`.
- **retry-only-failing**: A section that failed MUST be retried on its own schedule without re-running sections that succeeded.
- **incomplete-short-answer**: When `incomplete(name, data)` returns true for a resolved answer, the section MUST be published as a success (`error` null, data kept) but scheduled and counted like a failure, so it is retried after the backoff instead of the full TTL. The Vercel dashboard uses this when `data.failed > 0 || data.incomplete > 0`.
- **incomplete-optional**: When `incomplete` is not given, every resolved answer MUST count as complete.
- **loaders-builder-throws**: If `opts.loaders(key)` throws, the failure MUST be logged with `console.warn` as `[telemetry] dashboard refresh (<key>) failed: <message>`, every due section that did not settle MUST be scheduled as a failure, and `refreshing` MUST return to false. The builder runs before the first `await` of the refresh, so all of this happens inside the `read` call that triggered it and that `read` already returns `refreshing` false.
- **wedge-guard**: A refresh that ends, whether its loaders resolved, rejected or the builder threw, MUST clear the `refreshing` flag in its `finally` step. A loader that never settles is the loader's own responsibility (see the edge case "Loader that never settles").

**settle**

- **settle-contract**: `settle(key, timeoutMs)` MUST resolve `true` when no refresh is in flight for the key, and otherwise wait for the in-flight refresh or the timeout, whichever comes first.
- **settle-result**: After waiting, `settle` MUST resolve `!state.refreshing`: `true` when the refresh finished, `false` when the deadline passed first.
- **settle-never-starts**: `settle` MUST NOT start a refresh. A key never read resolves `true` at once and builds no loaders.
- **settle-negative-timeout**: A `timeoutMs` below 0 MUST be treated as 0.
- **settle-timer-cleared**: `settle` MUST clear its timeout timer when it returns, so a finished wait leaves no pending timer.
- **settle-use**: A caller that wants a warm answer reads, settles, then reads again. A server-side reader such as `/report` uses this so it does not push the polling that `read` implies onto its own client.

**Concurrency and ordering**

- **single-threaded-state**: State changes happen in ordinary JavaScript turns with no shared threads, so the check of `refreshing` and the start of a refresh in `read` cannot interleave with another `read`.
- **inflight-cleanup**: The in-flight promise MUST be cleared when the refresh ends, but only if it is still the same promise, so a later refresh's handle is never cleared by an earlier one.

**Side effects**

- **side-effects**: The module's only side effects are calls to the supplied loaders, `console.warn` on failures and `setTimeout` inside `settle`. It touches no files, network or storage itself; the loaders do.
- **clock-injection**: `now` defaults to `Date.now` and MAY be replaced for tests.

