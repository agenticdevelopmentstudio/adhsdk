
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |

Notes: graceful-degradation passes because every malformed or unexpected
input — an unparseable `baseURL`, a `baseURL` that trims to empty, garbage
JSON, or a JSON entry with wrong-typed fields — resolves to `false`, `nil`,
or `[:]` rather than a thrown error or a crash. explicit-error-handling is
partial because both the whole-document and per-entry decode failures in
`parseSizes(_:)` are discarded via `try?` with zero diagnostic signal, so a
caller cannot distinguish "server returned no models" from "server returned
garbage" (see Logging). data-integrity is partial because
`parse-sizes-array-order-last-write-wins` lets two distinct `models`
entries silently overwrite each other's size under a colliding `name`/`model`
key, with no validation or reported conflict. no-hardcoded-strings passes
because the source contains no user-facing string literal at all to
hardcode — its only string literals are the fixed `loopbackHosts` set, the
`"/v1"` and `"/api/tags"` path fragments, and JSON key names, none of which
is displayed to a user (see Localization).

`separation-of-concerns` passes because `LocalModelServer` holds only pure helpers (loopback detection, tags URL derivation, size parsing and lookup) with no I/O or cache of its own; fetching and caching live in `LocalModelCatalog` and `LocalProviderModelStore`. `unit-test-coverage` passes because `LocalModelServerTests.swift` covers loopback versus remote hosts, stripping the `/v1` suffix from the tags URL, indexing both name and model keys with `:latest` tolerance, garbage input, and a malformed entry not discarding the rest of the listing.

