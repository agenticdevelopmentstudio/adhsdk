
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | partial | Reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | Reliability |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |

`explicit-error-handling` is **partial**: a malformed required field sinks
the whole entry (and, for a page, the whole page) with a visible thrown
error, but a malformed optional or URL-shaped field resolves silently to
`nil` with no diagnostic recorded anywhere in this file — unlike the
sibling `ExtensionManifest.DecodingFailure` mechanism, there is no record a
caller can inspect to learn that a specific field failed to parse.
`fault-tolerance` is **partial** for the same reason from the other
direction: per-field URL isolation exists, but no per-array-element
isolation exists for `OpenVSXSearchPage.extensions` (see Design Decisions).
`data-integrity` **passed**: every field this file decodes is carried
through unmodified (the URL-as-`String` choice is a type projection a
computed accessor reverses on demand, not a data loss), and none of these
types declares `Encodable`, so there is no lossy round-trip to assess.
`idempotent-operations` **passed**: decoding and `installability(forHostVersion:)`
are both pure functions of their inputs; two decodes of byte-identical JSON
produce `Equatable`-equal values (open-vsx-catalog-017).
`separation-of-concerns` **passed**: this file only models and evaluates
registry metadata — it performs no network request, no file I/O, and no
installation step, all of which live in `OpenVSXClient.swift` and
`VSIXInstaller.swift` outside this recipe's scope. `unit-test-coverage`
**passed**: `OpenVSXCatalogTests.swift` exercises decode robustness for
every URL-shaped field, absent-vs-empty `files`, case-folded identifiers,
and every branch of `installability(forHostVersion:)`, including its
check ordering. `input-sanitization` **passed**: every value parsed from
untrusted registry text (`URL.init(string:)`, `SemanticVersion.init?`,
`VSCodeEngineRange.init?`) is parsed defensively and yields `nil` on
failure rather than crashing or trusting the input. `no-hardcoded-strings`
**passed**: this file defines no user-facing display string to flag (see
Localization) — every string literal in it is a JSON protocol key or a
programmatic case name.

