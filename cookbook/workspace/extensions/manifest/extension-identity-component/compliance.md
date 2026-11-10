
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`separation-of-concerns` passes because the source's own doc comment states
the reason for the type's existence: the same denylist check was needed by
both `VSIXInstaller` and `OpenVSXClient.detail` against the same kind of
manifest field, and only one of the two callers had it, so the rule was
pulled into this one predicate rather than left duplicated (`pure-function`,
Overview). `input-sanitization` passes with a documented nuance: the
predicate refuses a value containing `/`, `\`, `:`, a leading `.`, or a
control character rather than escaping or stripping it — see the "refused,
not escaped" Design Decision above — so it satisfies the check by rejection
rather than by cleansing (`forward-slash-refused`, `backslash-refused`,
`colon-refused`, `leading-dot-refused`, `control-character-refused`).
`unicode-support` passes because the check is deliberately scalar-level and
a denylist of shapes rather than an allowlist of characters, so it accepts
internationalized publisher and extension names by design
(`non-ascii-accepted`, test `internationalisedNamesAreAccepted`).
`unit-test-coverage` passes: nine test functions in
`ExtensionIdentityComponentTests.swift` exercise every refusal branch, the
ordinary and internationalized acceptance paths, the interior-dot exception,
the encoded-separator exception, and the exact numeric edges of the
control-character range.

