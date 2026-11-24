
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | failed | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`explicit-error-handling` is **failed**: every failure this file can
encounter — an unreadable directory, an unreadable table file, malformed
JSON/JSONC, an unserializable rewritten tree — is caught with `try?` and
discarded with no signal of any kind, not a thrown error, not a return
value, and not a `DecodingFailure`-style record the way `ExtensionManifest`
produces for its own decode failures (see Logging and Design Decisions).
`fault-tolerance` **passed**: `localize` never throws and every one of its
internal helpers has a defined, total fallback for every failure mode.
`data-integrity` is **partial**: when a table is present, the manifest is
rewritten by parsing and re-serializing through `JSONSerialization`, which
is not a byte-identical round trip — key order and number formatting can
change — though this is only exercised when at least one placeholder needs
resolving (**unchanged-when-no-table** avoids it entirely otherwise).
`idempotent-operations` **passed**: `localize` is a pure function of its
three arguments and the current contents of `directory`; two calls with
unchanged inputs produce identical output. `separation-of-concerns`
**passed**: this file's sole responsibility is placeholder resolution,
sitting beside the manifest it serves and shared by both of its readers
rather than duplicated in each. `unit-test-coverage`
**passed**: `ExtensionManifestLocalizationTests.swift` exercises the default
table, language and region preference, gap fill-in from the default table,
fallback to the default for an untranslated locale, both table-entry
shapes, the byte-identical no-op path, an unresolved key staying visible, a
non-placeholder string containing `%` being left alone, an unreadable table
not sinking the manifest, and non-string values surviving the rewrite.

