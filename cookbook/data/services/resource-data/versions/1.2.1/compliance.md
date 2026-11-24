
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | partial | Security |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | Reliability |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`secure-storage` is **partial**: the FTD last-id/view-mode values and the
cached workspace slug sit in plaintext `localStorage` with no encryption —
an accepted SPA tradeoff (see Privacy), though none of these values is
itself a credential, unlike the access token `auth-client`'s own
`secure-storage` row covers. `input-sanitization` **passed**: every dynamic
path segment this component builds into a URL
(`workspaceQuery`, `checkWorkspaceSlugAvailable`'s slug) is passed through
`enc`/`encodeURIComponent` before interpolation. `explicit-error-handling`
**passed**: every read/write path in these nine files either rethrows a
caller-visible error or falls back to a documented default — the two
deliberate swallow paths (storage exceptions; `makeEntityDeleteHandler`'s
post-delete `reload()`) are each covered by their own Design Decisions
entry, not silent omissions. `fault-tolerance` **passed**: `retry: false`
plus the long `RESOURCE_GC_TIME`, the storage-exception swallowing, and the
del-not-caught/reload-swallowed split in `makeEntityDeleteHandler`
collectively keep a transient or permission failure from corrupting cache
state or crashing a render. `data-integrity` **passed**: tenant-keyed cache
segments make cross-tenant leakage structurally impossible rather than
merely policed, and `useResourceItemWriter`'s evict-not-tombstone choice
means a deleted row can never be misread back as a cached empty answer.
`data-minimization` **passed**: this component collects no personal data of
its own beyond the opaque `tenantId` it reads via `useTenantId()`.
`no-hardcoded-strings` **failed**: the `'Failed to load.'` fallback in
`use-resource-item.ts`/`use-resource-list.ts` is hardcoded English with no
lookup table or locale parameter anywhere in this component (see
Localization) — a plain, honestly-reported gap in the source, not a hidden
one.

`separation-of-concerns` passes because each of the nine source files owns one concern — `http.ts` request helpers, `tenant.ts` the tenant-id read state, `ftd-storage.ts` and `workspace-prefs.ts` browser persistence, `use-resource-item.ts` and `use-resource-list.ts` the read states over the shared cache, `workspaces.ts` the workspace announcements, `config.ts` the host-injectable prefix, `client-helpers.ts` pure list helpers — with no presentation code. `unit-test-coverage` is partial because `use-resource-item.test.tsx`, `use-resource-list.test.tsx`, `ftd-storage.test.ts`, `http.test.ts`, `tenant.test.ts`, `workspace-prefs.test.ts` and `workspaces-changed.test.ts` in the data package's `__tests__` directory cover most behaviors, but `client-helpers.ts`, `config.ts` and the workspace slug-availability check in `workspaces.ts` have no dedicated test file, and the reload-without-id behavior is untested.

