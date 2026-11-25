
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | Security |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`separation-of-concerns` passes because the registry owns storage, resolution
and the change signal only, while secret custody sits behind `ModelSecretStore`,
plugin discovery and request execution behind `DaemonAIChat.PluginRuntime`, and
the mapping from a stored configuration to a request bag in
`AIPluginDescriptor+Request.swift`. `unit-test-coverage` is partial:
`ModelRegistryTests.swift` covers ordering, secret handling, timestamps, removal,
validation, role and selector resolution, request values, plugin listing, `test`,
the change signal and the wire forms, but no test covers `listModels`, a failing
secret write, a corrupt row, the change coalescing, the keychain choice, or a
selector with an unknown type. `secure-storage` passes because secret values go
only to the Keychain and never into the SQLite file or the entry JSON.
`explicit-error-handling` is partial: a failed secret delete throws
`removeFailed` (`secret-removal-failure`), but a failed live model list
silently falls back to the static list. `data-integrity` is partial because
the row's read-modify-write is one transaction (`concurrent-upsert`) but the
Keychain writes are not part of it. `no-hardcoded-strings` fails because every error
description and the empty-reply message are English literals with no
localization mechanism.

