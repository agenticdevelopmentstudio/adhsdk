
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | partial | Security |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`separation-of-concerns` passes: `workspace-rows.ts` holds only pure row
helpers, `use-workspaces.ts` only the every-row read state and its
subscription, and `use-workspace-preference.ts` only the preference read
state; the client, keys, storage and endpoints stay in Resource Data.
`unit-test-coverage` passes: `use-workspaces.test.tsx`,
`workspace-rows.test.ts` and `use-workspace-preference.test.tsx` hold a test
for every vector above. `explicit-error-handling` passes: a failed every-row
read reaches the caller on the query result, a failed preference read
settles the state, and the one swallowed failure (the preference write) is a
documented decision. `graceful-degradation` passes: the preference shows the
browser-cache seed before and without the server row, and the label helper
never yields an empty name. `idempotent-operations` passes: recording the
same slug twice leaves the same caches and server row, and one announcement
is one invalidation per client however many readers are mounted.
`secure-storage` is partial: the preferred slug sits in plaintext browser
storage; it is not a credential. `data-minimization` passes: only slug,
name and type are read. `no-hardcoded-strings` fails: the two label
fallbacks are English literals with no catalog (see Localization).

