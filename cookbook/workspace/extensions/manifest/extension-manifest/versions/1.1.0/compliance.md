
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`explicit-error-handling` is **partial**: every `contributes.*` array/dictionary
entry failure is recorded as a typed `DecodingFailure` the caller can act on,
but `Command.icon`'s object-form fallback and every `ConfigurationProperty`
field drop a wrong-typed value with no `DecodingFailure` recorded anywhere
— a real, documented gap between `DecodingFailure`'s own doc comment claim
and its leaf-type behavior (see Design Decisions). `fault-tolerance`
**passed**: `LenientDecoding.array`/`.dictionary`/`.value` isolate failures
at array-element, keyed-location, and single-field granularity throughout,
so one malformed entry never sinks a sibling. `data-integrity` is
**partial**: `Contributions.encode(to:)` is deliberately lossy — it omits
`decodingFailures` and every entry that failed to decode — so a round-trip
through this type is not a faithful copy of the manifest that was decoded
(**contributions-encode-lossy**). `idempotent-operations` **passed**:
decoding is a pure function of its input `Data`; two decodes of
byte-identical JSON produce `Equatable`-equal values.
`separation-of-concerns` **passed**: the element/location-isolation logic
lives once in `LenientDecoding`, shared by both `ExtensionManifest.init(from:)`
and `Contributions.init(from:)`, rather than duplicated per contribution
type. `unit-test-coverage` **passed**: `ExtensionManifestTests.swift`
exercises identity strictness, every lenient top-level field, single-object
tolerance, per-element and per-location isolation, the tri-state capability
decode, case-folded identifiers, and the `unreadableKeys` encode exclusion.
`no-hardcoded-strings` **failed**: every `describe(_:)`/`jsonName(of:)`
string is hardcoded English with no lookup table or locale parameter
anywhere in this file (see Localization) — a plain, honestly-reported gap in
the source, not a hidden one.

